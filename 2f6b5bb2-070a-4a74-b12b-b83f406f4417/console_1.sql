create or replace function aux.base32_to_bin(in_value character varying)
    returns text
    language plpgsql
as
$fn$

declare
    each_char  char;
    bit_string text := '';
begin
    foreach each_char in array regexp_split_to_array(in_value, '')
        loop
--             raise notice 'bit_string - %', bit_string;
            bit_string = bit_string || case each_char
                                           when '0' then '00000'
                                           when '1' then '00001'
                                           when '2' then '00010'
                                           when '3' then '00011'
                                           when '4' then '00100'
                                           when '5' then '00101'
                                           when '6' then '00110'
                                           when '7' then '00111'
                                           when '8' then '01000'
                                           when '9' then '01001'
                                           when 'a' then '01010'
                                           when 'b' then '01011'
                                           when 'c' then '01100'
                                           when 'd' then '01101'
                                           when 'e' then '01110'
                                           when 'f' then '01111'
                                           when 'g' then '10000'
                                           when 'h' then '10001'
                                           when 'i' then '10010'
                                           when 'j' then '10011'
                                           when 'k' then '10100'
                                           when 'l' then '10101'
                                           when 'm' then '10110'
                                           when 'n' then '10111'
                                           when 'o' then '11000'
                                           when 'p' then '11001'
                                           when 'q' then '11010'
                                           when 'r' then '11011'
                                           when 's' then '11100'
                                           when 't' then '11101'
                                           when 'u' then '11110'
                                           when 'v' then '11111' end;
        end loop;
    return bit_string;
end;
$fn$
;

select char_length(aux.base32_to_bin('f8cr1bv80000'));
select aux.hex_to_decimal(aux.base32_to_bin('f8cr1bv80000'));

select to_hex('011 110 100 001 100 110 110 000 101 011 111 110 100 000 000 000 000 000 000 000'::bit(4))

select 88888888888888888888::int8;


select aux.base32_to_int8_('gg3ldjio0000') = aux.base32_to_int8('gg3ldjio0000');


create or replace function aux.base32_to_int8(in_string text)
    returns int8
    language plpgsql
as
$$
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    each_char   char;
    ret_result  int8 := 0;

begin
    foreach each_char in array regexp_split_to_array(lower(in_string), '')
        loop
            ret_result = ret_result * 32;
            ret_result = ret_result + (position(each_char in base_string) - 1);
        end loop;
    return ret_result;
end;
$$;


create or replace function aux.base32_to_int8_(in_string text)
    returns int8
    language plpgsql
    immutable
as
$$
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    ret_result  int8 := 0;
    each_char   char;
    i           int  := 1;
    base_length int  := length(in_string);
begin
    while i <= base_length
        loop
            each_char := lower(substring(in_string from i for 1));
            ret_result := ret_result * 32 + (position(each_char in base_string) - 1);
            i := i + 1;
        end loop;

    return ret_result;
end;
$$;

CREATE TABLE aux.your_table_name (
    START_TIME TIMESTAMP,
    START_DATE_ID INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM START_TIME) * 10000 +
                                           EXTRACT(MONTH FROM START_TIME) * 100 +
                                           EXTRACT(DAY FROM START_TIME)) STORED
);

select * from aux.your_table_name
alter table aux.your_table_name add column i int4;

select * from aux.your_table_name

insert into aux.your_table_name (start_time, i) values (clock_timestamp(), 1);

alter table aux.your_table_name add column     START_DATE_ID_V INT GENERATED ALWAYS AS
    (EXTRACT(YEAR FROM START_TIME) * 10000 +
     EXTRACT(MONTH FROM START_TIME) * 100 +
     EXTRACT(DAY FROM START_TIME)) VIRTUAL;

select version()


CREATE TABLE your_table_name (
    START_TIME TIMESTAMP,
    START_DATE_ID INT GENERATED ALWAYS AS
    (EXTRACT(YEAR FROM START_TIME) * 10000 +
     EXTRACT(MONTH FROM START_TIME) * 100 +
     EXTRACT(DAY FROM START_TIME)) VIRTUAL
);


CREATE TABLE trash.so_fix_execution_column_text_ (
	routine_schema information_schema."sql_identifier" COLLATE "C" NULL,
	routine_name information_schema."sql_identifier" COLLATE "C" NULL,
	routine_definition information_schema."character_data" COLLATE "C" NULL,
	md5_before text COLLATE "C" NULL,
	last_update_time timestamptz NULL,
	new_script text NULL,
	execution_order int4 NULL,
	was_executed bool NULL
);


truncate table trash.so_fix_execution_column_text_;

update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE FUNCTION aux.base32_to_int8_(in_string text)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- SO 20240912 temp changes (no changes in fact)
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    ret_result  int8 := 0;
    each_char   char;
    i           int  := 1;
    base_length int  := length(in_string);
begin
    while i <= base_length
        loop
            each_char := lower(substring(in_string from i for 1));
            ret_result := ret_result * 32 + (position(each_char in base_string) - 1);
            i := i + 1;
        end loop;

    return ret_result;
end;
$function$
;

    $insert$
where true
  and routine_schema = 'aux'
  and routine_name = 'base32_to_int8_'
  and new_script is null;

create table trash.check_uniq (
    un_id serial not null,
    limit_request_id int4,
    is_active bool
);

create unique index limit_rq on trash.check_uniq (limit_request_id) where (is_active);

insert into trash.check_uniq (limit_request_id, is_active) values (1, true)
update trash.check_uniq
set is_active = false
where limit_request_id = 1
and is_active;

select * from trash.check_uniq;

SELECT (pp.proargtypes::regtype[])[0:],
       pg_get_functiondef(pp.oid),
       replace(replace(replace(replace(replace(replace(replace(FORMAT(
                                                                       '%s.%s(%s).sql',
                                                                       pn.nspname, pp.proname,
                                                                       (pp.proargtypes::regtype[])[0:])::text, '{', ''),
                                                       '}', ''), '"', ''), 'character', 'char'), 'char varying',
                               'varchar'), 'integer', 'int'), 'timestamp without time zone', 'tstamp')
from pg_proc pp
         inner join pg_namespace pn on (pp.pronamespace = pn.oid)
         inner join pg_language pl on (pp.prolang = pl.oid)
where pl.lanname NOT IN ('c', 'internal')
  and pn.nspname = 'aux';


SELECT pn.nspname, pp.proname || '(' || array_to_string(pp.proargtypes::regtype[], ',') || ')',
       pg_get_functiondef(pp.oid)
from pg_proc pp
         inner join pg_namespace pn on (pp.pronamespace = pn.oid)
         inner join pg_language pl on (pp.prolang = pl.oid)
where pl.lanname NOT IN ('c', 'internal')
  and pn.nspname = 'aux';



CREATE OR REPLACE drop FUNCTION aux.generate_create_table_statement(p_table_name character varying)
    RETURNS SETOF text AS
$BODY$
DECLARE
    v_table_ddl    text;
    column_record  record;
    table_rec      record;
    constraint_rec record;
    firstrec       boolean;
BEGIN
    FOR table_rec IN
        SELECT c.relname
        FROM pg_catalog.pg_class c
                 LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
--           AND relname ~ ('^(' || p_table_name || ')$')
          AND n.nspname <> 'pg_catalog'
          AND n.nspname <> 'information_schema'
          AND n.nspname !~ '^pg_toast'
          AND pg_catalog.pg_table_is_visible(c.oid)
        ORDER BY c.relname
        LOOP

            FOR column_record IN
                SELECT b.nspname                                       as schema_name,
                       b.relname                                       as table_name,
                       a.attname                                       as column_name,
                       pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
                       CASE
                           WHEN
                               (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                FROM pg_catalog.pg_attrdef d
                                WHERE d.adrelid = a.attrelid
                                  AND d.adnum = a.attnum
                                  AND a.atthasdef) IS NOT NULL THEN
                               'DEFAULT ' || (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                              FROM pg_catalog.pg_attrdef d
                                              WHERE d.adrelid = a.attrelid
                                                AND d.adnum = a.attnum
                                                AND a.atthasdef)
                           ELSE
                               ''
                           END                                         as column_default_value,
                       CASE
                           WHEN a.attnotnull = true THEN
                               'NOT NULL'
                           ELSE
                               'NULL'
                           END                                         as column_not_null,
                       a.attnum                                        as attnum,
                       e.max_attnum                                    as max_attnum
                FROM pg_catalog.pg_attribute a
                         INNER JOIN
                     (SELECT c.oid,
                             n.nspname,
                             c.relname
                      FROM pg_catalog.pg_class c
                               LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                      WHERE c.relname = table_rec.relname
                        AND pg_catalog.pg_table_is_visible(c.oid)
                      ORDER BY 2, 3) b
                     ON a.attrelid = b.oid
                         INNER JOIN
                     (SELECT a.attrelid,
                             max(a.attnum) as max_attnum
                      FROM pg_catalog.pg_attribute a
                      WHERE a.attnum > 0
                        AND NOT a.attisdropped
                      GROUP BY a.attrelid) e
                     ON a.attrelid = e.attrelid
                WHERE a.attnum > 0
                  AND NOT a.attisdropped
                ORDER BY a.attnum
                LOOP
                    IF column_record.attnum = 1 THEN
                        v_table_ddl :=
                                'CREATE TABLE ' || column_record.schema_name || '.' || column_record.table_name || ' (';
                    ELSE
                        v_table_ddl := v_table_ddl || ',';
                    END IF;

                    IF column_record.attnum <= column_record.max_attnum THEN
                        v_table_ddl := v_table_ddl || chr(10) ||
                                       '    ' || column_record.column_name || ' ' || column_record.column_type || ' ' ||
                                       column_record.column_default_value || ' ' || column_record.column_not_null;
                    END IF;
                END LOOP;

            firstrec := TRUE;
            FOR constraint_rec IN
                SELECT conname, pg_get_constraintdef(c.oid) as constrainddef
                FROM pg_constraint c
                WHERE conrelid = (SELECT attrelid
                                  FROM pg_attribute
                                  WHERE attrelid = (SELECT oid
                                                    FROM pg_class
                                                    WHERE relname = table_rec.relname)
                                    AND attname = 'tableoid')
                LOOP
                    v_table_ddl := v_table_ddl || ',' || chr(10);
                    v_table_ddl := v_table_ddl || 'CONSTRAINT ' || constraint_rec.conname;
                    v_table_ddl := v_table_ddl || chr(10) || '    ' || constraint_rec.constrainddef;
                    firstrec := FALSE;
                END LOOP;
            v_table_ddl := v_table_ddl || ');';
            RETURN NEXT v_table_ddl;
        END LOOP;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

your_table_name
select * from aux.generate_create_table_statement('.*');


CREATE OR REPLACE FUNCTION aux.wmv_get_table_definition(
    p_schema_name character varying,
    p_table_name character varying
)
    RETURNS SETOF TEXT
AS
$BODY$
BEGIN
    RETURN query
        WITH table_rec AS (SELECT c.relname,
                                  n.nspname,
                                  c.oid
                           FROM pg_catalog.pg_class c
                                    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                           WHERE relkind in ('r', 'p')
                             AND n.nspname = p_schema_name
                             AND c.relname LIKE p_table_name
                           ORDER BY c.relname),
             col_rec AS (SELECT a.attname                                       AS colname,
                                pg_catalog.format_type(a.atttypid, a.atttypmod) AS coltype,
                                a.attrelid                                      AS oid,
                                ' DEFAULT ' || (SELECT pg_catalog.pg_get_expr(d.adbin, d.adrelid)
                                                FROM pg_catalog.pg_attrdef d
                                                WHERE d.adrelid = a.attrelid
                                                  AND d.adnum = a.attnum
                                                  AND a.atthasdef)              AS column_default_value,
                                CASE
                                    WHEN a.attnotnull = TRUE THEN
                                        'NOT NULL'
                                    ELSE
                                        'NULL'
                                    END                                         AS column_not_null,
                                a.attnum                                        AS attnum
                         FROM pg_catalog.pg_attribute a
                         WHERE a.attnum > 0
                           AND NOT a.attisdropped
                         ORDER BY a.attnum),
             con_rec AS (SELECT conrelid::regclass::text    AS relname,
                                n.nspname,
                                conname,
                                pg_get_constraintdef(c.oid) AS condef,
                                contype,
                                conrelid                    AS oid
                         FROM pg_constraint c
                                  JOIN pg_namespace n ON n.oid = c.connamespace),
             glue AS (SELECT format(
                                     E'-- %1$I.%2$I definition\n\n-- Drop table\n\n-- DROP TABLE IF EXISTS %1$I.%2$I\n\nCREATE TABLE %1$I.%2$I (\n',
                                     table_rec.nspname, table_rec.relname) AS top,
                             format(E'\n);\n\n\n-- adempiere.wmv_ghgaudit foreign keys\n\n', table_rec.nspname,
                                    table_rec.relname)                     AS bottom,
                             oid
                      FROM table_rec),
             cols AS (SELECT string_agg(
                                     format('    %I %s%s %s', colname, coltype, column_default_value, column_not_null),
                                     E',\n') AS lines,
                             oid
                      FROM col_rec
                      GROUP BY oid),
             constrnt AS (SELECT string_agg(format('    CONSTRAINT %s %s', con_rec.conname, con_rec.condef),
                                            E',\n') AS lines,
                                 oid
                          FROM con_rec
                          WHERE contype <> 'f'
                          GROUP BY oid),
             frnkey AS (SELECT string_agg(format('ALTER TABLE %I.%I ADD CONSTRAINT %s %s', nspname, relname, conname,
                                                 condef), E';\n') AS lines,
                               oid
                        FROM con_rec
                        WHERE contype = 'f'
                        GROUP BY oid)
        SELECT concat(glue.top, cols.lines, E',\n', constrnt.lines, glue.bottom, frnkey.lines, ';')
        FROM glue
                 JOIN cols ON cols.oid = glue.oid
                 LEFT JOIN constrnt ON constrnt.oid = glue.oid
                 LEFT JOIN frnkey ON frnkey.oid = glue.oid;
END;
$BODY$
    LANGUAGE plpgsql;

CREATE TABLE dwh.flat_trade_record (
	trade_record_id int8 NOT NULL,
	trade_record_time timestamp NULL, -- Exec time from PARENT level EXECUTION
	db_create_time timestamp NULL,
	date_id int4 NOT NULL, -- based on exec_time of the parent level order
	is_busted bpchar(1) NULL,
	orig_trade_record_id int8 NULL, -- If we split trade we bust the old one and create two or more new trades with old_trade_record_if in the orig_trade_record_id field
	trade_record_trans_type bpchar(1) NULL, -- Based on client_order.trans_type of the parent level order
	trade_record_reason bpchar(1) NULL, -- Initially based on STRATEGY_DECISION_REASON_CODE field of the parent level of client_order record¶- 'P': post-trade modification/correction (all splits, clearing changes)¶- 'A': manual (away) trade¶- 'B': trade bust/cancel (electronic or manual)¶- 'L': manual allocation¶- 'U': Manual unallocation
	subsystem_id varchar(20) NULL, -- Based on client_order.SUB_SYSTEM_ID of the parent order level
	user_id int4 NULL, -- Based on client_order.user_id of the parent order level
	account_id int4 NULL, -- Based on client_order.account_id of the parent order level
	client_order_id varchar(256) NULL, -- client_order_id of the parent level record
	instrument_id int4 NULL, -- Based on client_order.instrument_id of the parent order level
	side bpchar(1) NULL, -- Side of the parent level order
	open_close bpchar(1) NULL, -- Based on client_order.open_close of the parent order level
	fix_connection_id int2 NULL, -- Fix_connection_id of the parent level order. Base on cl.fix_connection_id
	exec_id int8 NULL, -- Exec ID of the parent level trade
	exchange_id varchar(6) NULL, -- Base on execution.EXCHANGE_ID of the parent order level
	trade_liquidity_indicator varchar(256) NULL, -- Based on execution.TRADE_LIQUIDITY_INDICATOR of the parent order trade
	secondary_order_id varchar(256) NULL, -- Based on execution.SECONDARY_ORDER_ID of the parent order trade. Means street client_order_id???
	exch_exec_id varchar(128) NULL, -- Based on execution.exch_exec_id of the parent order trade. Means exec_id that arrives form the exchange
	secondary_exch_exec_id varchar(128) NULL, -- Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange
	last_mkt varchar(5) NULL, -- Based on execution.last_mkt of the parent order trade.
	last_qty int4 NULL, -- Based on execution.last_qty of the parent order trade. Means quantity
	last_px numeric(16, 8) NULL, -- Based on execution.last_px of the parent order trade. Means price
	ex_destination varchar(5) NULL, -- Based on client_order.ex_destination of the parent order level
	sub_strategy varchar(128) NULL, -- Based on client_order.sub_strategy of the parent order level
	street_order_id int8 NULL, -- street order_id str.order_id
	order_id int8 NULL, -- parent order ID cl.order_id
	street_order_qty int4 NULL, -- order_qty arrives from STREET level of client_order table
	order_qty int4 NULL, -- order_qty arrives from PARENT level of client_order table
	multileg_reporting_type bpchar(1) NULL, -- MULTILEG_REPORTING_TYPE arrives from PARENT level of client_order table
	is_largest_leg bpchar(1) NULL, -- by default 'N'
	street_max_floor int4 NULL, -- MAX_FLOOR field of the STREET level client order
	exec_broker varchar(32) NULL, -- based on  street client_order.opt_exec_broker
	cmta varchar(3) NULL, -- Based on client_order.Clearing_firm_id of he parent level order. if it is empty we use 439 fix message if still empty we use  clearing_account.CMTA
	street_time_in_force bpchar(1) NULL, -- Based on client_order.TIME_IN_FORCE of the strret level order
	street_order_type bpchar(1) NULL, -- Based on client_order.ORDER_TYPE of the strret level order
	opt_customer_firm bpchar(1) NULL, -- Based on client_order.OPT_CUSTOMER_FIRM of the parent level order
	street_mpid varchar(18) NULL, -- Based on client_order.MPID of the strret level order
	is_cross_order bpchar(1) NULL, -- N if cross_order_id of the parent level order is null and Y in other case
	street_is_cross_order bpchar(1) NULL, -- N if cross_order_id of the street level order is null and Y in other case
	street_cross_type bpchar(1) NULL, -- CROSS_TYPE of the street level order
	cross_is_originator bpchar(1) NULL, -- Based on the IS_ORIGINATOR of the PARENT level client_order
	street_cross_is_originator bpchar(1) NULL, -- Based on the IS_ORIGINATOR of the STREET level client_order
	contra_account bpchar(1) NULL, -- Based on the CONTRA_ACCOUNT_CAPACITY field of the PARENT level exection
	contra_broker varchar(256) NULL, -- Based on the CONTRA_BROKER field of the PARENT level exection
	trade_exec_broker varchar(32) NULL, -- based on execution.exec_broker
	order_fix_message_id int8 NULL, -- Based on the fix_message_id field of the PARENT level client_order
	trade_fix_message_id int8 NULL, -- Based on the fix_message_id field of the PARENT level EXECUTION
	street_order_fix_message_id int8 NULL, -- Based on the fix_message_id field of the STREET level of client_order table
	bid_price numeric(16, 4) NULL, -- EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_price)
	ask_price numeric(16, 4) NULL, -- EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_price)
	trade_id numeric(24) NULL, -- A-la FK to market_data.trade.trade_id
	client_id varchar(255) NULL, -- Based on the client_id field of the PARENT level client_order
	street_transaction_id int8 NULL, -- client_order.transaction_id of the street level
	transaction_id int8 NULL, -- client_order.transaction_id of the parent order level
	tcce_account_dash_commission_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_account_execution_cost numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_firm_dash_commission_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_firm_execution_cost numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_mss_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_maker_taker_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_occ_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_option_regulatory_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_royalty_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_sec_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_transaction_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	tcce_trade_processing_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table
	order_price numeric(12, 4) NULL, -- Based on client_order.PRICE of the parent order level
	order_process_time timestamp NULL, -- Based on client_order.PROCESS_TIME of the parent order level
	clearing_account_number varchar(25) NULL,
	sub_account varchar(30) NULL,
	remarks varchar(100) NULL,
	optional_data varchar(25) NULL,
	street_client_order_id varchar(256) NULL,
	fix_comp_id varchar(30) NULL,
	ask_qty int4 NULL, -- EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_qty)
	bid_qty int4 NULL, -- EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_qty)
	leaves_qty int4 NULL, -- Based on the LEAVES_QTY field of the PARENT level EXECUTION
	is_billed bpchar(1) NULL, -- Value indicates if trade is billed, not billed or prepared for recalculation. 'Y', 'N', 'R', 'D'. 'E' - TCCE error
	street_exec_inst varchar(128) NULL, -- based on EXEC_INST of the street level order
	principal_amount numeric(16, 4) NULL,
	trading_firm_id varchar(9) NULL,
	fee_sensitivity int2 NULL, -- Fee sencitivity of the parent level execution. Arrives from the 9090 fix message tag
	street_order_price numeric(12, 4) NULL, -- arrives from client_order.price of street order level
	routing_time_bid_price numeric(16, 4) NULL, -- Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)
	routing_time_bid_qty int4 NULL, -- Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)
	routing_time_ask_price numeric(16, 4) NULL, -- Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)
	routing_time_ask_qty int4 NULL, -- Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)
	is_street_order_marketable bpchar(1) NULL, -- Y/N
	tcce_admin_maker_taker_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table AMTK book_record_type_id
	tcce_admin_transaction_fee_amount numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table ATF book_record_type_id
	account_schedule_rate_type varchar(1) NULL,
	trading_firm_schedule_rate_type varchar(1) NULL,
	strategy_decision_reason_code int2 NULL, -- Routing reason. Based on strategy_decision_reason_code of the strret order. Parent order field is used in case street order value is null
	pg_big_data_create_time timestamp(6) DEFAULT clock_timestamp() NULL,
	compliance_id varchar(256) NULL, -- Based on client_order.compliance_id of the parent level order
	floor_broker_id varchar(255) NULL, -- Tag 143 of the customer order. Assigned value used to identify specific message destination's location (i.e. geographic location and/or desk, trader)
	auction_id int8 NULL, -- AUCTION_ID based on execution.AUCTION_ID of the parent order level
	street_opt_customer_firm varchar(1) NULL, -- Customer_or_firm id fo the street order level. Arrives from tag 47 or tag 204
	street_exec_broker varchar(32) NULL, -- Exec Broker of street level order. Based on tag value provided in d_exchange
	multileg_order_id int8 NULL, -- The vaule is based on CO_MULTILEG_ORDER_ID of the parent order
	trading_firm_unq_id int4 NULL, -- FK to d_trading_firm
	internal_component_type varchar(1) NULL, -- INTERNAL_COMPONENT_TYPE of the parent execution level
	instrument_type_id varchar(1) NULL, -- E/O ... Equity , Option etc..
	street_trade_fix_message_id int8 NULL, -- Fix message_id of the street level trade
	pt_basket_id varchar(100) NULL, -- Basket_id of the parent order. Base on 9047 tag of parent order fix message
	pt_order_id int8 NULL, -- Order_id based on parent order fix message tag 10112
	trade_exchange_id varchar(6) NULL, -- exhcnage_id of the venue where trade was really executed. Based on Last_mkt field
	transact_time timestamp NULL, -- Based on Tag 60 of the execution report
	client_commission_rate numeric(20, 8) NULL, -- Client commission rate per unit. Customer uses to charge its client
	blaze_account_alias varchar(255) NULL, -- Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only
	customer_review_status bpchar(1) DEFAULT NULL::bpchar NULL,
	street_account_name varchar(255) NULL, -- street_account_name based on Tag 1 of of street trade fix message or street order fix messgae. Arrives from genesis2.trade_record
	branch_sequence_number varchar(256) NULL, -- Based on 9861 tag of parent execution
	trade_text varchar(100) NULL, -- Based on 58 tag of parent execution
	frequent_trader_id varchar(6) NULL, -- CBOE-specific field "FrequentTraderID" based on tag 21097 of the street trade message. Arrives from PG genesis2.trade_record
	int_liq_source_type varchar(1) NULL, -- INTernal LIQuidity SOURCE TYPE.  'A' - ATS, 'C' - Consolidator
	load_batch_id int8 NULL, -- The field for ETL purposes
	allocation_avg_price numeric(12, 6) NULL, -- Avarenge price of allocated trades
	account_nickname varchar(40) NULL, -- account_nickname. should be populated from the dash360 as free text during allocation
	clearing_account_id int4 NULL, -- FK to d_clearing_account
	market_participant_id varchar(18) NULL, -- Tag 115 of the parent order. Based on client_order.MPID field of the parent order level
	alternative_compliance_id varchar(256) NULL, -- Tag 6376 of the parent order. Based on client_order.ALTERNATIVE_COMPLIANCE_ID field of the parent order level
	clearing_fee_amout numeric(20, 8) NULL, -- Based on trade_level Book record CLRF book_record_type
	street_trade_record_time timestamp NULL, -- Exec time from street level EXECUTION
	penny_nickel bpchar(1) NULL,
	market_data_trade_time timestamp NULL, -- trade_time from market_data.trade
	tcce_admin_trade_processing_fee numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table ATPF book_record_type_id
	tcce_admin_royalty_fee numeric(20, 8) NULL, -- Arrives from the postgres PROD trade_level_book_record table ARTY book_record_type_id
	street_order_process_time timestamp NULL,
	leg_ref_id varchar(60) NULL,
	spread_transaction_fee_amount numeric(20, 8) NULL,
	qcc_rebate_amount numeric(20, 8) NULL,
	cat_fee_amount numeric(20, 8) NULL
)
PARTITION BY RANGE (date_id);
CREATE INDEX flat_trade_record_account_id_idx ON ONLY dwh.flat_trade_record USING btree (account_id);
CREATE INDEX flat_trade_record_date_id_idx ON ONLY dwh.flat_trade_record USING btree (date_id);
CREATE INDEX flat_trade_record_exec_id_idx ON ONLY dwh.flat_trade_record USING btree (exec_id);
CREATE INDEX flat_trade_record_instrument_id_idx ON ONLY dwh.flat_trade_record USING btree (instrument_id);
CREATE INDEX flat_trade_record_order_id_idx ON ONLY dwh.flat_trade_record USING btree (order_id);
CREATE INDEX flat_trade_record_pt_basket_id_idx ON ONLY dwh.flat_trade_record USING btree (pt_basket_id);
CREATE INDEX flat_trade_record_secondary_order_id_idx ON ONLY dwh.flat_trade_record USING btree (secondary_order_id);
CREATE INDEX flat_trade_record_street_client_order_id_idx ON ONLY dwh.flat_trade_record USING btree (street_client_order_id);
CREATE INDEX flat_trade_record_street_order_id_idx ON ONLY dwh.flat_trade_record USING btree (street_order_id);
CREATE UNIQUE INDEX flat_trade_record_trade_record_id_date_id_idx ON ONLY dwh.flat_trade_record USING btree (trade_record_id, date_id);

-- Column comments

COMMENT ON COLUMN dwh.flat_trade_record.trade_record_time IS 'Exec time from PARENT level EXECUTION';
COMMENT ON COLUMN dwh.flat_trade_record.date_id IS 'based on exec_time of the parent level order';
COMMENT ON COLUMN dwh.flat_trade_record.orig_trade_record_id IS 'If we split trade we bust the old one and create two or more new trades with old_trade_record_if in the orig_trade_record_id field';
COMMENT ON COLUMN dwh.flat_trade_record.trade_record_trans_type IS 'Based on client_order.trans_type of the parent level order';
COMMENT ON COLUMN dwh.flat_trade_record.trade_record_reason IS 'Initially based on STRATEGY_DECISION_REASON_CODE field of the parent level of client_order record
- ''P'': post-trade modification/correction (all splits, clearing changes)
- ''A'': manual (away) trade
- ''B'': trade bust/cancel (electronic or manual)
- ''L'': manual allocation
- ''U'': Manual unallocation';
COMMENT ON COLUMN dwh.flat_trade_record.subsystem_id IS 'Based on client_order.SUB_SYSTEM_ID of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.user_id IS 'Based on client_order.user_id of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.account_id IS 'Based on client_order.account_id of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.client_order_id IS 'client_order_id of the parent level record';
COMMENT ON COLUMN dwh.flat_trade_record.instrument_id IS 'Based on client_order.instrument_id of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.side IS 'Side of the parent level order';
COMMENT ON COLUMN dwh.flat_trade_record.open_close IS 'Based on client_order.open_close of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.fix_connection_id IS 'Fix_connection_id of the parent level order. Base on cl.fix_connection_id';
COMMENT ON COLUMN dwh.flat_trade_record.exec_id IS 'Exec ID of the parent level trade';
COMMENT ON COLUMN dwh.flat_trade_record.exchange_id IS 'Base on execution.EXCHANGE_ID of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.trade_liquidity_indicator IS 'Based on execution.TRADE_LIQUIDITY_INDICATOR of the parent order trade';
COMMENT ON COLUMN dwh.flat_trade_record.secondary_order_id IS 'Based on execution.SECONDARY_ORDER_ID of the parent order trade. Means street client_order_id???';
COMMENT ON COLUMN dwh.flat_trade_record.exch_exec_id IS 'Based on execution.exch_exec_id of the parent order trade. Means exec_id that arrives form the exchange';
COMMENT ON COLUMN dwh.flat_trade_record.secondary_exch_exec_id IS 'Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange';
COMMENT ON COLUMN dwh.flat_trade_record.last_mkt IS 'Based on execution.last_mkt of the parent order trade.';
COMMENT ON COLUMN dwh.flat_trade_record.last_qty IS 'Based on execution.last_qty of the parent order trade. Means quantity';
COMMENT ON COLUMN dwh.flat_trade_record.last_px IS 'Based on execution.last_px of the parent order trade. Means price';
COMMENT ON COLUMN dwh.flat_trade_record.ex_destination IS 'Based on client_order.ex_destination of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.sub_strategy IS 'Based on client_order.sub_strategy of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.street_order_id IS 'street order_id str.order_id';
COMMENT ON COLUMN dwh.flat_trade_record.order_id IS 'parent order ID cl.order_id';
COMMENT ON COLUMN dwh.flat_trade_record.street_order_qty IS 'order_qty arrives from STREET level of client_order table';
COMMENT ON COLUMN dwh.flat_trade_record.order_qty IS 'order_qty arrives from PARENT level of client_order table';
COMMENT ON COLUMN dwh.flat_trade_record.multileg_reporting_type IS 'MULTILEG_REPORTING_TYPE arrives from PARENT level of client_order table';
COMMENT ON COLUMN dwh.flat_trade_record.is_largest_leg IS 'by default ''N'' ';
COMMENT ON COLUMN dwh.flat_trade_record.street_max_floor IS 'MAX_FLOOR field of the STREET level client order';
COMMENT ON COLUMN dwh.flat_trade_record.exec_broker IS 'based on  street client_order.opt_exec_broker ';
COMMENT ON COLUMN dwh.flat_trade_record.cmta IS 'Based on client_order.Clearing_firm_id of he parent level order. if it is empty we use 439 fix message if still empty we use  clearing_account.CMTA';
COMMENT ON COLUMN dwh.flat_trade_record.street_time_in_force IS 'Based on client_order.TIME_IN_FORCE of the strret level order';
COMMENT ON COLUMN dwh.flat_trade_record.street_order_type IS 'Based on client_order.ORDER_TYPE of the strret level order';
COMMENT ON COLUMN dwh.flat_trade_record.opt_customer_firm IS 'Based on client_order.OPT_CUSTOMER_FIRM of the parent level order';
COMMENT ON COLUMN dwh.flat_trade_record.street_mpid IS 'Based on client_order.MPID of the strret level order';
COMMENT ON COLUMN dwh.flat_trade_record.is_cross_order IS 'N if cross_order_id of the parent level order is null and Y in other case';
COMMENT ON COLUMN dwh.flat_trade_record.street_is_cross_order IS 'N if cross_order_id of the street level order is null and Y in other case';
COMMENT ON COLUMN dwh.flat_trade_record.street_cross_type IS 'CROSS_TYPE of the street level order';
COMMENT ON COLUMN dwh.flat_trade_record.cross_is_originator IS 'Based on the IS_ORIGINATOR of the PARENT level client_order';
COMMENT ON COLUMN dwh.flat_trade_record.street_cross_is_originator IS 'Based on the IS_ORIGINATOR of the STREET level client_order';
COMMENT ON COLUMN dwh.flat_trade_record.contra_account IS 'Based on the CONTRA_ACCOUNT_CAPACITY field of the PARENT level exection';
COMMENT ON COLUMN dwh.flat_trade_record.contra_broker IS 'Based on the CONTRA_BROKER field of the PARENT level exection';
COMMENT ON COLUMN dwh.flat_trade_record.trade_exec_broker IS 'based on execution.exec_broker';
COMMENT ON COLUMN dwh.flat_trade_record.order_fix_message_id IS 'Based on the fix_message_id field of the PARENT level client_order';
COMMENT ON COLUMN dwh.flat_trade_record.trade_fix_message_id IS 'Based on the fix_message_id field of the PARENT level EXECUTION';
COMMENT ON COLUMN dwh.flat_trade_record.street_order_fix_message_id IS 'Based on the fix_message_id field of the STREET level of client_order table';
COMMENT ON COLUMN dwh.flat_trade_record.bid_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_price)';
COMMENT ON COLUMN dwh.flat_trade_record.ask_price IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_price)';
COMMENT ON COLUMN dwh.flat_trade_record.trade_id IS 'A-la FK to market_data.trade.trade_id';
COMMENT ON COLUMN dwh.flat_trade_record.client_id IS 'Based on the client_id field of the PARENT level client_order';
COMMENT ON COLUMN dwh.flat_trade_record.street_transaction_id IS 'client_order.transaction_id of the street level';
COMMENT ON COLUMN dwh.flat_trade_record.transaction_id IS 'client_order.transaction_id of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_account_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_account_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_firm_dash_commission_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_firm_execution_cost IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_mss_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_occ_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_option_regulatory_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_royalty_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_sec_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_trade_processing_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table';
COMMENT ON COLUMN dwh.flat_trade_record.order_price IS 'Based on client_order.PRICE of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.order_process_time IS 'Based on client_order.PROCESS_TIME of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.ask_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.ask_qty)';
COMMENT ON COLUMN dwh.flat_trade_record.bid_qty IS 'EXECUTION-time NBBO, captured using historical market data  API (based on market_data.trade.bid_qty)';
COMMENT ON COLUMN dwh.flat_trade_record.leaves_qty IS 'Based on the LEAVES_QTY field of the PARENT level EXECUTION';
COMMENT ON COLUMN dwh.flat_trade_record.is_billed IS 'Value indicates if trade is billed, not billed or prepared for recalculation. ''Y'', ''N'', ''R'', ''D''. ''E'' - TCCE error';
COMMENT ON COLUMN dwh.flat_trade_record.street_exec_inst IS 'based on EXEC_INST of the street level order';
COMMENT ON COLUMN dwh.flat_trade_record.fee_sensitivity IS 'Fee sencitivity of the parent level execution. Arrives from the 9090 fix message tag';
COMMENT ON COLUMN dwh.flat_trade_record.street_order_price IS 'arrives from client_order.price of street order level';
COMMENT ON COLUMN dwh.flat_trade_record.routing_time_bid_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';
COMMENT ON COLUMN dwh.flat_trade_record.routing_time_bid_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';
COMMENT ON COLUMN dwh.flat_trade_record.routing_time_ask_price IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';
COMMENT ON COLUMN dwh.flat_trade_record.routing_time_ask_qty IS 'Routing-time NBBO.  Provided by SOR instances (L1_snapshot for street level)';
COMMENT ON COLUMN dwh.flat_trade_record.is_street_order_marketable IS 'Y/N ';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_maker_taker_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table AMTK book_record_type_id';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_transaction_fee_amount IS 'Arrives from the postgres PROD trade_level_book_record table ATF book_record_type_id';
COMMENT ON COLUMN dwh.flat_trade_record.strategy_decision_reason_code IS 'Routing reason. Based on strategy_decision_reason_code of the strret order. Parent order field is used in case street order value is null';
COMMENT ON COLUMN dwh.flat_trade_record.compliance_id IS 'Based on client_order.compliance_id of the parent level order';
COMMENT ON COLUMN dwh.flat_trade_record.floor_broker_id IS 'Tag 143 of the customer order. Assigned value used to identify specific message destination''s location (i.e. geographic location and/or desk, trader)';
COMMENT ON COLUMN dwh.flat_trade_record.auction_id IS 'AUCTION_ID based on execution.AUCTION_ID of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.street_opt_customer_firm IS 'Customer_or_firm id fo the street order level. Arrives from tag 47 or tag 204';
COMMENT ON COLUMN dwh.flat_trade_record.street_exec_broker IS 'Exec Broker of street level order. Based on tag value provided in d_exchange';
COMMENT ON COLUMN dwh.flat_trade_record.multileg_order_id IS 'The vaule is based on CO_MULTILEG_ORDER_ID of the parent order';
COMMENT ON COLUMN dwh.flat_trade_record.trading_firm_unq_id IS 'FK to d_trading_firm';
COMMENT ON COLUMN dwh.flat_trade_record.internal_component_type IS 'INTERNAL_COMPONENT_TYPE of the parent execution level';
COMMENT ON COLUMN dwh.flat_trade_record.instrument_type_id IS 'E/O ... Equity , Option etc..';
COMMENT ON COLUMN dwh.flat_trade_record.street_trade_fix_message_id IS 'Fix message_id of the street level trade';
COMMENT ON COLUMN dwh.flat_trade_record.pt_basket_id IS 'Basket_id of the parent order. Base on 9047 tag of parent order fix message';
COMMENT ON COLUMN dwh.flat_trade_record.pt_order_id IS 'Order_id based on parent order fix message tag 10112';
COMMENT ON COLUMN dwh.flat_trade_record.trade_exchange_id IS 'exhcnage_id of the venue where trade was really executed. Based on Last_mkt field';
COMMENT ON COLUMN dwh.flat_trade_record.transact_time IS 'Based on Tag 60 of the execution report';
COMMENT ON COLUMN dwh.flat_trade_record.client_commission_rate IS 'Client commission rate per unit. Customer uses to charge its client';
COMMENT ON COLUMN dwh.flat_trade_record.blaze_account_alias IS 'Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only';
COMMENT ON COLUMN dwh.flat_trade_record.street_account_name IS 'street_account_name based on Tag 1 of of street trade fix message or street order fix messgae. Arrives from genesis2.trade_record';
COMMENT ON COLUMN dwh.flat_trade_record.branch_sequence_number IS 'Based on 9861 tag of parent execution ';
COMMENT ON COLUMN dwh.flat_trade_record.trade_text IS 'Based on 58 tag of parent execution ';
COMMENT ON COLUMN dwh.flat_trade_record.frequent_trader_id IS 'CBOE-specific field "FrequentTraderID" based on tag 21097 of the street trade message. Arrives from PG genesis2.trade_record';
COMMENT ON COLUMN dwh.flat_trade_record.int_liq_source_type IS 'INTernal LIQuidity SOURCE TYPE.  ''A'' - ATS, ''C'' - Consolidator';
COMMENT ON COLUMN dwh.flat_trade_record.load_batch_id IS 'The field for ETL purposes';
COMMENT ON COLUMN dwh.flat_trade_record.allocation_avg_price IS 'Avarenge price of allocated trades';
COMMENT ON COLUMN dwh.flat_trade_record.account_nickname IS 'account_nickname. should be populated from the dash360 as free text during allocation';
COMMENT ON COLUMN dwh.flat_trade_record.clearing_account_id IS 'FK to d_clearing_account';
COMMENT ON COLUMN dwh.flat_trade_record.market_participant_id IS 'Tag 115 of the parent order. Based on client_order.MPID field of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.alternative_compliance_id IS 'Tag 6376 of the parent order. Based on client_order.ALTERNATIVE_COMPLIANCE_ID field of the parent order level';
COMMENT ON COLUMN dwh.flat_trade_record.clearing_fee_amout IS 'Based on trade_level Book record CLRF book_record_type';
COMMENT ON COLUMN dwh.flat_trade_record.street_trade_record_time IS 'Exec time from street level EXECUTION';
COMMENT ON COLUMN dwh.flat_trade_record.market_data_trade_time IS 'trade_time from market_data.trade';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_trade_processing_fee IS 'Arrives from the postgres PROD trade_level_book_record table ATPF book_record_type_id';
COMMENT ON COLUMN dwh.flat_trade_record.tcce_admin_royalty_fee IS 'Arrives from the postgres PROD trade_level_book_record table ARTY book_record_type_id';


CREATE OR REPLACE FUNCTION aux.describe_table(p_schema_name character varying, p_table_name character varying)
  RETURNS SETOF text AS
$BODY$
DECLARE
    v_table_ddl   text;
    column_record record;
    table_rec record;
    constraint_rec record;
    firstrec boolean;
BEGIN
    FOR table_rec IN
        SELECT n.nspname, c.relname, c.oid, relkind FROM pg_catalog.pg_class c
            LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                WHERE relkind in ('r', 'p')
                AND n.nspname = p_schema_name
                AND relname~ ('^('||p_table_name||')$')
          ORDER BY c.relname
    LOOP
        FOR column_record IN
            SELECT
                b.nspname as schema_name,
                b.relname as table_name,
                a.attname as column_name,
                pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
                CASE WHEN
                    (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                     FROM pg_catalog.pg_attrdef d
                     WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) IS NOT NULL THEN
                    'DEFAULT '|| (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                  FROM pg_catalog.pg_attrdef d
                                  WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
                ELSE
                    ''
                END as column_default_value,
                CASE WHEN a.attnotnull = true THEN
                    'NOT NULL'
                ELSE
                    'NULL'
                END as column_not_null,
                a.attnum as attnum,
                e.max_attnum as max_attnum
            FROM
                pg_catalog.pg_attribute a
                INNER JOIN
                 (SELECT c.oid,
                    n.nspname,
                    c.relname
                  FROM pg_catalog.pg_class c
                       LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                  WHERE c.oid = table_rec.oid
                  ORDER BY 2, 3) b
                ON a.attrelid = b.oid
                INNER JOIN
                 (SELECT
                      a.attrelid,
                      max(a.attnum) as max_attnum
                  FROM pg_catalog.pg_attribute a
                  WHERE a.attnum > 0
                    AND NOT a.attisdropped
                  GROUP BY a.attrelid) e
                ON a.attrelid=e.attrelid
            WHERE a.attnum > 0
              AND NOT a.attisdropped
            ORDER BY a.attnum
        LOOP
            IF column_record.attnum = 1 THEN
                v_table_ddl:='CREATE TABLE '||column_record.schema_name||'.'||column_record.table_name||' (';
            ELSE
                v_table_ddl:=v_table_ddl||',';
            END IF;

            IF column_record.attnum <= column_record.max_attnum THEN
                v_table_ddl:=v_table_ddl||chr(10)||
                         '    '||column_record.column_name||' '||column_record.column_type||' '||column_record.column_default_value||' '||column_record.column_not_null;
            END IF;
        END LOOP;

        firstrec := TRUE;
        FOR constraint_rec IN
            SELECT conname, pg_get_constraintdef(c.oid) as constrainddef
                FROM pg_constraint c
                    WHERE conrelid=(
                        SELECT attrelid FROM pg_attribute
                        WHERE attrelid = (
                            SELECT oid FROM pg_class WHERE relname = table_rec.relname
                                AND relnamespace = (SELECT ns.oid FROM pg_namespace ns WHERE ns.nspname = p_schema_name)
                        ) AND attname='tableoid'
                    )
        LOOP
            v_table_ddl:=v_table_ddl||','||chr(10);
            v_table_ddl:=v_table_ddl||'CONSTRAINT '||constraint_rec.conname;
            v_table_ddl:=v_table_ddl||chr(10)||'    '||constraint_rec.constrainddef;
            firstrec := FALSE;
        END LOOP;
        v_table_ddl:=v_table_ddl||');';
        RETURN NEXT v_table_ddl;
    END LOOP;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select * from aux.describe_table('dwh', 'flat_trade_record');
select * from aux.wmv_get_table_definition('dwh', 'flat_trade_record')

SELECT schema_name, *
FROM information_schema.schemata
WHERE schema_name NOT IN ('tash')
and schema_name not like 'pg_%';