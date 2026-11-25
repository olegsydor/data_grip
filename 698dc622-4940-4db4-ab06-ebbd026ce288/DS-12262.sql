-- https://dashfinancial.atlassian.net/browse/DS-12262
dash360.delete_broker_comm_all_rates
dash360.delete_broker_comm_rates
dash360.delete_manual_broker
dash360.set_broker_comm_rates
dash360.update_broker_comm_symbol_list
dash360.update_manual_broker
genesis2.load_broker_commission_for_trade -- NO
dash360.delete_broker_comm_symbol_list -- ??


-- DROP FUNCTION dash360.delete_broker_comm_all_rates(text, int4);

CREATE OR REPLACE FUNCTION dash360.delete_broker_comm_all_rates(in_broker_code text, in_user_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11567 Initial creation
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
	l_row_count int;

BEGIN
    IF in_broker_code IS NULL OR btrim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

    insert into broker_comm_rate (rate_id, broker_unq_id, broker_code, symbol_list_unq_id, symbol_list_id,
                                  instrument_type_id, commission_type, tier_type_id, min_price, min_qty, scope_type,
                                  rate_type_id, rate, user_id, is_deleted)
    select rate_id,
           broker_unq_id,
           broker_code,
           symbol_list_unq_id,
           symbol_list_id,
           instrument_type_id,
           commission_type,
           tier_type_id,
           min_price,
           min_qty,
           scope_type,
           rate_type_id,
           rate,
           in_user_id,
           'Y'
    from broker_comm_rate
    where broker_code = in_broker_code
      and is_deleted = 'N';

	update broker_comm_rate set is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
	where broker_code = in_broker_code
	and is_deleted = 'N';

	GET DIAGNOSTICS l_row_count = ROW_COUNT;

    RETURN 'Updated rows: ' || l_row_count::varchar;

END
$function$
;


CREATE OR REPLACE FUNCTION dash360.delete_broker_comm_rates(in_broker_code text, in_rate_id integer, in_user_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
    -- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
	l_row_count int;
BEGIN
    IF in_broker_code IS NULL OR btrim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

    insert into broker_comm_rate (rate_id, broker_unq_id, broker_code, symbol_list_unq_id, symbol_list_id,
                                  instrument_type_id, commission_type, tier_type_id, min_price, min_qty, scope_type,
                                  rate_type_id, rate, user_id, is_deleted)
    select rate_id,
           broker_unq_id,
           broker_code,
           symbol_list_unq_id,
           symbol_list_id,
           instrument_type_id,
           commission_type,
           tier_type_id,
           min_price,
           min_qty,
           scope_type,
           rate_type_id,
           rate,
           in_user_id,
           'Y'
    from broker_comm_rate
    where broker_code = in_broker_code
      and rate_id = in_rate_id
      and is_deleted = 'N';

	update broker_comm_rate set is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
	where broker_code = in_broker_code
	and rate_id = in_rate_id
	and is_deleted = 'N';

	GET DIAGNOSTICS l_row_count = ROW_COUNT;

    RETURN 'Updated rows: ' || l_row_count::varchar;

END
$function$
;


CREATE OR REPLACE FUNCTION dash360.delete_manual_broker(in_broker_code character varying, in_user_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11568 Initial creation
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
l_row_count int;
BEGIN
    IF in_broker_code IS NULL OR trim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM genesis2.broker_comm_rate bcm
        WHERE bcm.broker_code = in_broker_code
          AND bcm.is_deleted = 'N'
    ) THEN
        RAISE EXCEPTION 'There are active commission rates for that broker % ', in_broker_code;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM genesis2.broker_comm_symbol_list bcsl
        WHERE bcsl.broker_code = in_broker_code
          AND bcsl.is_deleted = 'N'
    ) THEN
        RAISE EXCEPTION 'There are active symbol lists for that broker % ', in_broker_code;
    END IF;

    insert into genesis2.manual_brokers(broker_code, broker_mpid, user_id, crd_number, imid, description, is_deleted)
    select broker_code, broker_mpid, in_user_id, crd_number, imid, description, 'Y'
        from genesis2.manual_brokers mb
    WHERE mb.is_deleted = 'N'
	and mb.broker_code = in_broker_code;

    UPDATE genesis2.manual_brokers mb
    SET is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
    WHERE mb.is_deleted = 'N'
	and mb.broker_code = in_broker_code;

    GET DIAGNOSTICS l_row_count = ROW_COUNT;

    RETURN 'Updated rows: ' || l_row_count::varchar;

END;
$function$
;


-- DROP FUNCTION dash360.set_broker_comm_rates(text, text, int4, int4);

CREATE OR REPLACE FUNCTION dash360.set_broker_comm_rates(in_broker_code text, in_rate_changes text, in_user_id integer, in_rate_id integer DEFAULT NULL::integer)
 RETURNS TABLE(rate_id integer, broker_code character varying, instrument_type_id character, commission_type character, tier_type_id character, min_price numeric, min_qty integer, scope_type character, symbol_list_id integer, symbol_list_unq_id integer, rate_type_id character varying, rate numeric)
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11567 Initial creation
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
	l_row_count int;
	l_broker_unq_id int;
	l_symbol_list_unq_id int;
	l_rate_unq_id int;
	l_rate_id int;
	l_rate_changes jsonb := in_rate_changes::jsonb;
BEGIN

--------------------------------CHECK BLOCK
    IF in_broker_code IS NULL OR btrim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

	--Validate broker exists and is active
    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

	--Check when  “instrument_type_id“ = 'O' then “rate_type_id” IS NOT NULL
    IF l_rate_changes->>'instrument_type_id'='O' and nullif(l_rate_changes->>'rate_type_id', '') is null THEN
        RAISE EXCEPTION 'Rate type should be not null for Options';
    END IF;

	--Check that  either "min_price" or "min_qty" is according to their "tier_type_id"
    IF l_rate_changes->>'tier_type_id'='Q' and NULLIF(l_rate_changes->>'min_qty', '') IS NULL THEN
        RAISE EXCEPTION 'min_qty value should be present in accordance to tier_type_id';
	ELSIF l_rate_changes->>'tier_type_id'='P' and NULLIF(l_rate_changes->>'min_price', '') IS NULL THEN
        RAISE EXCEPTION 'min_price value should be present in accordance to tier_type_id';
    END IF;

	--if "scope_type" = 'G' THEN "symbol_list_id" IS NULL
	--if "scope_type" = 'S' check that:"symbol_list_id" IS NOT NULL and  all "tier_type_id" are the same for all items with the same  “symbol_list_id” (including  requested to save)
    IF l_rate_changes->>'scope_type'='G' and NULLIF(l_rate_changes->>'symbol_list_id', '') IS NOT NULL THEN
		RAISE EXCEPTION 'symbol_list_id should be empty for "G" scope type';
	ELSIF l_rate_changes->>'scope_type'='S' and NULLIF(l_rate_changes->>'symbol_list_id', '') IS NULL THEN
        RAISE EXCEPTION 'symbol_list_id should not be empty for "S" scope type';
	ELSIF l_rate_changes->>'scope_type'='S' AND exists (SELECT 1 from (select bcm.symbol_list_id, bcm.tier_type_id FROM genesis2.broker_comm_rate bcm
																       WHERE bcm.scope_type = 'S'
																	   AND bcm.broker_code = in_broker_code
																       AND bcm.is_deleted = 'N'
																	   union
																	   select (l_rate_changes->>'symbol_list_id')::int, l_rate_changes->>'tier_type_id'
																	  ) cte
													    group by cte.symbol_list_id
														having count (cte.tier_type_id) > 1)
		THEN
        RAISE EXCEPTION 'tier_type_id should be the same for all items with the same “symbol_list_id”';
    END IF;
--------------------------------CHECK BLOCK END

	l_broker_unq_id:=(select mb.broker_unq_id from genesis2.manual_brokers mb WHERE mb.broker_code = in_broker_code and mb.is_deleted = 'N');
	l_symbol_list_unq_id:=(select bcsl.symbol_list_unq_id from broker_comm_symbol_list bcsl WHERE bcsl.symbol_list_id = (l_rate_changes->>'symbol_list_id')::int and bcsl.is_deleted = 'N');

	if in_rate_id is not null then
		l_rate_id:=in_rate_id;
		update broker_comm_rate bcr set is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
		where bcr.broker_code = in_broker_code
		and bcr.rate_id = in_rate_id
		and bcr.is_deleted = 'N';
	else
		l_rate_id:=nextval('genesis2.broker_comm_rate_rate_id_seq');
        RAISE notice 'No active rates were updated';
    end if;


	insert into genesis2.broker_comm_rate (rate_id, broker_unq_id, broker_code, symbol_list_unq_id, symbol_list_id, instrument_type_id,
										  commission_type, tier_type_id, min_price, min_qty, scope_type, rate_type_id, rate, user_id)

	select l_rate_id,
           l_broker_unq_id,
           in_broker_code,
           l_symbol_list_unq_id,
           new_rec.symbol_list_id,
           new_rec.instrument_type_id,
           new_rec.commission_type,
           new_rec.tier_type_id,
           new_rec.min_price,
           new_rec.min_qty,
           new_rec.scope_type,
           new_rec.rate_type_id,
           new_rec.rate,
           in_user_id
    from jsonb_populate_record(null::genesis2.broker_comm_rate, l_rate_changes) as new_rec
	returning rate_unq_id into l_rate_unq_id;


    RETURN QUERY
    SELECT
        r.rate_id,
        r.broker_code,
        r.instrument_type_id,
        r.commission_type,
        r.tier_type_id,
        r.min_price,
        r.min_qty,
        r.scope_type,
        r.symbol_list_id,
        r.symbol_list_unq_id,
        r.rate_type_id,
        r.rate
    FROM genesis2.broker_comm_rate r
    WHERE r.rate_unq_id = l_rate_unq_id
      AND r.is_deleted = 'N'
    ORDER BY r.rate_id asc;

END
$function$
;


-- DROP FUNCTION dash360.update_broker_comm_symbol_list(int4, varchar, bpchar, varchar, text, int4);

CREATE OR REPLACE FUNCTION dash360.update_broker_comm_symbol_list(in_symbol_list_id integer, in_broker_code character varying, in_instrument_type_id character, in_symbol_list_name character varying, in_symbols text, in_user_id integer)
 RETURNS TABLE(symbol_list_id integer, broker_code character varying, instrument_type_id character, symbol_list_name character varying, symbols jsonb)
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11569 Initial creation
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
	v_new_symbol_list genesis2.broker_comm_symbol_list%ROWTYPE;
	l_symbols jsonb := in_symbols::jsonb;
BEGIN

	--check valid in_broker_code input
    IF in_broker_code IS NULL OR btrim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

	--check valid in_instrument_type_id input
    IF in_instrument_type_id IS NULL OR btrim(in_instrument_type_id) = '' or in_instrument_type_id not in ('E','O') THEN
        RAISE EXCEPTION 'in_instrument_type_id is required and should be ''E'' or ''O''';
    END IF;

	--check valid in_symbol_list_name input
    IF in_symbol_list_name  IS NULL OR btrim(in_symbol_list_name ) = '' THEN
        RAISE EXCEPTION 'in_symbol_list_name  is required';
    END IF;

	--check valid l_symbols input
    IF l_symbols  IS NULL then
        RAISE EXCEPTION 'symbols is required';
    END IF;

	--Validate broker exists and is active
    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

	--Check that combination of symbol_list_name and broker_code is unique in BROKER_COMM_SYMBOL_LIST
    IF EXISTS (
        SELECT 1
        FROM genesis2.broker_comm_symbol_list bcsl
        WHERE bcsl.broker_code = in_broker_code
		  AND bcsl.symbol_list_name = in_symbol_list_name
		  AND bcsl.symbol_list_id <> in_symbol_list_id
          AND bcsl.is_deleted = 'N'
    ) THEN
        RAISE EXCEPTION 'There is an existing record with the same broker_code:% and symbol_list_name:% ', in_broker_code, in_symbol_list_name;
    END IF;

	--Check that combination of  instrument_type_id  AND each pair of SYMBOL AND SYMBOL_SUFFIX is unique among all other Symbol Lists of broker_code
    IF EXISTS (
		select 1
		FROM genesis2.broker_comm_symbol_list o
		CROSS JOIN LATERAL jsonb_array_elements(o.symbols) AS sym
		where o.broker_code = in_broker_code
		and o.instrument_type_id = in_instrument_type_id
		and o.symbol_list_id <> in_symbol_list_id
		and o.is_deleted = 'N'
		and sym in (select value from jsonb_array_elements(l_symbols))
    ) THEN
        RAISE EXCEPTION 'The broker:% already has such combination of symbol and symbol_suffix:% ', in_broker_code, l_symbols;
    END IF;

	update genesis2.broker_comm_symbol_list bcsl set is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
    WHERE bcsl.is_deleted = 'N'
	and bcsl.symbol_list_id = in_symbol_list_id;

	insert into genesis2.broker_comm_symbol_list (symbol_list_id, broker_code, instrument_type_id, symbol_list_name, symbols, user_id)
	values (in_symbol_list_id, in_broker_code, in_instrument_type_id, in_symbol_list_name, l_symbols, in_user_id)
	returning * into v_new_symbol_list;

	perform dash360.set_broker_comm_rates(in_broker_code=>in_broker_code, in_rate_changes=>(to_jsonb(bcr)-array['rate_unq_id','rate_id'])::text, in_user_id=>in_user_id, in_rate_id=>bcr.rate_id) from genesis2.broker_comm_rate bcr
	where bcr.symbol_list_id = in_symbol_list_id
	and bcr.is_deleted = 'N';

	RETURN QUERY
	SELECT v_new_symbol_list.symbol_list_id, v_new_symbol_list.broker_code, v_new_symbol_list.instrument_type_id, v_new_symbol_list.symbol_list_name, v_new_symbol_list.symbols;

END
$function$
;

-- DROP FUNCTION dash360.update_manual_broker(varchar, varchar, int4, int4, varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.update_manual_broker(in_broker_code character varying, in_broker_mpid character varying, in_user_id integer, in_crd_number integer DEFAULT NULL::integer, in_imid character varying DEFAULT NULL::character varying, in_description character varying DEFAULT NULL::character varying)
 RETURNS TABLE(broker_code character varying, broker_mpid character varying, crd_number integer, imid character varying, description character varying)
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11568 Initial creation
-- PD: 20260630 https://dashfinancial.atlassian.net/browse/DS-11723 added crd_number, imid
-- PD: 20260714 https://dashfinancial.atlassian.net/browse/DS-11770 added description to the output
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
v_new_broker genesis2.manual_brokers%ROWTYPE;
BEGIN
    IF in_broker_code IS NULL OR trim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

    UPDATE genesis2.manual_brokers mb
    SET is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
    WHERE mb.is_deleted = 'N'
	and mb.broker_code = in_broker_code;

    INSERT INTO genesis2.manual_brokers (broker_code,broker_mpid,user_id,crd_number,imid, description)
    VALUES (in_broker_code,in_broker_mpid,in_user_id,in_crd_number,in_imid, in_description)
    RETURNING *
    INTO v_new_broker;

	perform dash360.set_broker_comm_rates(in_broker_code=>in_broker_code, in_rate_changes=>(to_jsonb(bcr)-array['rate_unq_id','rate_id'])::text, in_user_id=>in_user_id, in_rate_id=>bcr.rate_id) from genesis2.broker_comm_rate bcr
	where bcr.broker_code = in_broker_code
	and bcr.is_deleted = 'N';

    RETURN QUERY
    SELECT v_new_broker.broker_code, v_new_broker.broker_mpid, v_new_broker.crd_number, v_new_broker.imid, v_new_broker.description;
END;
$function$
;
