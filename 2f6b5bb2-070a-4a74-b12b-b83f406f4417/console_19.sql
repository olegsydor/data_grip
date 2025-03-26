DROP SCHEMA IF EXISTS hotels_data CASCADE;
CREATE SCHEMA IF NOT EXISTS hotels_data;
SET search_path TO hotels_data;

CREATE TABLE IF NOT EXISTS t_hotels
(
	hotel_id serial PRIMARY KEY,
	hotel_name VARCHAR(150) UNIQUE NOT NULL,
	hotel_location_id integer NOT NULL,
	hotel_score smallint DEFAULT 0,
	CONSTRAINT hotel_name_length CHECK (length(trim(hotel_name)) > 0)
);
--CREATE INDEX IF NOT EXISTS t_hotels_hotel_name_btree ON t_hotels(hotel_name);
/*
Адреса отелей. Каждый адрес уникален, потому поле location_name UNIQUE
*/
CREATE TABLE IF NOT EXISTS t_locations
(
	location_id serial PRIMARY KEY,
	location_name VARCHAR(150) UNIQUE NOT NULL,
	CONSTRAINT location_name_length CHECK (length(trim(location_name)) > 0)
);

CREATE TABLE IF NOT EXISTS t_apartments
(
	apartment_id serial PRIMARY KEY,
	hotel_id integer NOT NULL, --FK t_hotels(hotel_id)
    capacity integer NOT NULL,
    type_id integer NOT NULL, --FK t_apartment_types(type_id)
	status CHAR DEFAULT 'U',
	score smallint DEFAULT 0,
	price numeric(9,2),
	CONSTRAINT apartment_capacity CHECK (capacity > 0),
	CONSTRAINT apartment_status CHECK (status IN ('B','F','U'))
);
CREATE INDEX IF NOT EXISTS t_apartments_hotel_id_hash ON t_apartments USING HASH (hotel_id);
CREATE INDEX IF NOT EXISTS t_apartments_type_id_hash ON t_apartments USING HASH (type_id);

CREATE TABLE IF NOT EXISTS t_apartment_types
(
	type_id serial PRIMARY KEY,
	type_name VARCHAR(150) UNIQUE NOT NULL,
	day_price numeric(9,2),
	CONSTRAINT type_name_length CHECK (length(trim(type_name)) > 0)
);

CREATE TABLE IF NOT EXISTS t_clients
(
	client_id serial PRIMARY KEY,
	full_name VARCHAR(150) NOT NULL,
	score smallint DEFAULT 0,
	CONSTRAINT full_name_length CHECK (length(trim(full_name)) > 0)
);
CREATE INDEX IF NOT EXISTS t_clients_full_name_btree ON t_clients(full_name);
CREATE INDEX IF NOT EXISTS t_clients_client_id_hash ON t_clients USING HASH (client_id);

CREATE TABLE IF NOT EXISTS t_bookings
(
	booking_id serial PRIMARY KEY,
	client_id integer NOT NULL, --FK t_clients(client_id)
	apartment_id integer NOT NULL, --FK t_apartments(apartment_id)
	beg_date timestamp with time zone NOT NULL,
	end_date timestamp with time zone NOT NULL,
	full_price numeric(9,2) NOT NULL,
	CONSTRAINT full_price_not_negative CHECK (full_price > 0)
);
CREATE INDEX IF NOT EXISTS t_bookings_client_id_hash ON t_bookings USING HASH (client_id);
CREATE INDEX IF NOT EXISTS t_bookings_apartment_id_hash ON t_bookings USING HASH (apartment_id);
CREATE INDEX IF NOT EXISTS t_bookings_beg_date_btree ON t_bookings(beg_date);
CREATE INDEX IF NOT EXISTS t_bookings_end_date_btree ON t_bookings(end_date);

CREATE TABLE IF NOT EXISTS t_payments
(
	payment_id serial PRIMARY KEY,
	payment_date timestamp with time zone NOT NULL,
	pay_sum numeric(9,2) NOT NULL,
	booking_id integer NOT NULL, --FK t_bookings(booking_id)
	payment_info VARCHAR(250) NOT NULL,
	CONSTRAINT payment_info_length CHECK (length(trim(payment_info)) > 0)
);
CREATE INDEX IF NOT EXISTS t_payments_booking_id_hash ON t_payments USING HASH (booking_id);

/****************************  REFERENCES  **********************************************/
--В одном отеле может быть много номеров
ALTER TABLE IF EXISTS t_apartments
    ADD FOREIGN KEY (hotel_id)
    REFERENCES t_hotels(hotel_id);

--Может быть много номеров одного типа
ALTER TABLE IF EXISTS t_apartments
	ADD FOREIGN KEY (type_id)
    REFERENCES t_apartment_types(type_id);

--Может быть несколько отелей в одной локации
ALTER TABLE IF EXISTS t_hotels
	ADD FOREIGN KEY (hotel_location_id)
	REFERENCES t_locations(location_id);
--Номер может быть забронирован множество раз
ALTER TABLE IF EXISTS t_bookings
	ADD FOREIGN KEY (apartment_id)
	REFERENCES t_apartments(apartment_id);
-- У одного клиента может быть множество броней
ALTER TABLE IF EXISTS t_bookings
	ADD FOREIGN KEY (client_id)
	REFERENCES t_clients(client_id);
--Бронирование может быть оплачено несколькими частями
ALTER TABLE IF EXISTS t_payment
	ADD FOREIGN KEY (booking_id)
	REFERENCES t_bookings(booking_id);

/****************************  CRUD FUNCTIONS  ******************************************/
--Add hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_add
	(
	p_hotel_name 		VARCHAR,
	p_hotel_location_id int,
	p_hotel_score 		int
	)
	RETURNS SETOF t_hotels
	AS
	$code$
	DECLARE
		new_id integer := 0;
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		new_id := nextval('t_hotels_hotel_id_seq');
		INSERT INTO t_hotels (hotel_id, hotel_name, hotel_location_id, hotel_score)
		VALUES
		(
		new_id				,
		p_hotel_name 		,
		p_hotel_location_id	,
		p_hotel_score
		);
		RETURN QUERY SELECT h.hotel_id, h.hotel_name, h.hotel_location_id, h.hotel_score FROM t_hotels AS h
						WHERE h.hotel_id = new_id;

	END;
	$code$
	LANGUAGE 'plpgsql';
--Delete hotel-----------------------------------------------

CREATE OR REPLACE FUNCTION hotel_del(p_hotel_id int)
	RETURNS VARCHAR
	AS
	$code$
	DECLARE
		apart_count int := 0;
		result_str VARCHAR := 'OK';
	BEGIN
		IF (p_apartment_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_apartment_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT * FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
			RAISE EXCEPTION 'ERROR: hotel % does not exists', p_hotel_id;
		END IF;

		IF EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.hotel_id = p_hotel_id LIMIT 1) THEN
			RAISE EXCEPTION 'ERROR: hotel % has apartments', p_hotel_id;
		ELSE
			DELETE FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id;
		END IF;
		RETURN result_str;
	END;
	$code$
	LANGUAGE 'plpgsql';
--Upsert hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_upsert
	(
	p_hotel_id			integer,
	p_hotel_name 		VARCHAR,
	p_hotel_location_id	int,
	p_hotel_score 		int
	)
	RETURNS SETOF t_hotels
	AS
	$code$
	DECLARE
	new_id integer;
	BEGIN
		IF (p_hotel_id IS NULL) THEN
			new_id := nextval('t_hotels_hotel_id_seq');
		ELSIF NOT EXISTS (SELECT h.hotel_id FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
			RAISE EXCEPTION 'ERROR: hotel with id % does not exists, nothing to update', p_hotel_id;
		ELSE
			new_id := p_hotel_id;
		END IF;

		RETURN QUERY
		INSERT INTO t_hotels (hotel_id, hotel_name, hotel_location_id, hotel_score)
		VALUES
		(
		new_id				,
		p_hotel_name 		,
		p_hotel_location_id	,
		p_hotel_score
		)
		ON CONFLICT (hotel_id)
		DO UPDATE SET
			hotel_name			= EXCLUDED.hotel_name			,
			hotel_location_id	= EXCLUDED.hotel_location_id	,
			hotel_score			= EXCLUDED.hotel_score
		RETURNING hotel_id, hotel_name, hotel_location_id, hotel_score;

	END;
	$code$
	LANGUAGE 'plpgsql';
--Upsert hotel json-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_upsert(p_json_string json)
	RETURNS SETOF t_hotels
	AS
	$code$
	DECLARE
	new_id integer;
	v_hotel_id integer;
	v_hotel_name varchar;
	v_hotel_location_id integer;
	v_score integer;
	BEGIN
		IF (p_json_string IS NULL OR length(trim(p_json_string::text)) = 0) THEN
			RAISE EXCEPTION 'ERROR: parameter p_json_string can not be empty!';
		END IF;

		v_hotel_id			:= (p_json_string ->> 'hotel_id');
		v_hotel_name		:= (p_json_string ->> 'hotel_name');
		v_hotel_location_id	:= (p_json_string ->>'hotel_location_id');
		v_score				:= (p_json_string ->>'score');

		RETURN QUERY
		SELECT * FROM hotel_upsert(v_hotel_id, v_hotel_name, v_hotel_location_id, v_score);
	END;
	$code$
	LANGUAGE 'plpgsql';
--Update hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_upd
	(
	p_hotel_id 			int,
	p_hotel_name		VARCHAR,
	p_hotel_location_id int,
	p_hotel_score 		int
	)
	RETURNS SETOF t_hotels
	AS
	$code$
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT * FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
			RAISE EXCEPTION 'ERROR: hotel % does not exists', p_hotel_id;
		END IF;

		UPDATE t_hotels SET
			hotel_name			= p_hotel_name			,
			hotel_location_id	= p_hotel_location_id	,
			hotel_score			= p_hotel_score
		WHERE hotel_id = p_hotel_id;

		RETURN QUERY SELECT h.* FROM t_hotels AS h
						WHERE h.hotel_id = p_hotel_id;
	END;
	$code$
	LANGUAGE 'plpgsql';
--Get hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_get(p_hotel_id integer)
	RETURNS SETOF t_hotels
	AS
	$code$
	BEGIN
		IF (p_hotel_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_hotel_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT * FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
			RAISE EXCEPTION 'ERROR: hotel % does not exists', p_hotel_id
				USING HINT = 'Please use id of existing hotel';
		END IF;

		RETURN QUERY SELECT h.* FROM t_hotels AS h
						WHERE h.hotel_id = p_hotel_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Search hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION hotel_search
	(
	p_hotel_name		VARCHAR,
	p_hotel_location_id int,
	p_hotel_score 		int
	)
	RETURNS SETOF t_hotels
	AS
	$code$
	BEGIN

		IF p_hotel_name IS NULL AND p_hotel_location_id IS NULL AND p_hotel_score IS NULL THEN
			RAISE EXCEPTION 'ERROR: At least one parameter must be setted'
					USING HINT = 'Please set the parameters!';
		END IF;

		IF length(trim(p_hotel_name)) = 0 THEN
			RAISE EXCEPTION 'ERROR: Parameter p_hotel_name can not be empty string';
		END IF;

		RETURN QUERY SELECT h.* FROM t_hotels AS h
		WHERE
		--h.hotel_name LIKE p_hotel_name;
		(p_hotel_name IS NULL OR h.hotel_name LIKE format('%s%%', trim(p_hotel_name)))
		AND
		(p_hotel_location_id IS NULL OR h.hotel_location_id = p_hotel_location_id)
		AND
		(p_hotel_score IS NULL OR h.hotel_score = p_hotel_score);
	END;
	$code$
	LANGUAGE 'plpgsql';

--Add apartment-----------------------------------------------
CREATE OR REPLACE FUNCTION apartment_add
	(
	p_hotel_id	int,
	p_capacity  int,
	p_type_id   int,
	p_status    char,
	p_score     int,
	p_price     numeric
	)
	RETURNS SETOF t_apartments
	AS
	$code$
	DECLARE
		new_id integer := 0;
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		new_id := nextval('t_apartments_apartment_id_seq');
		INSERT INTO t_apartments (apartment_id, hotel_id, capacity, type_id, status, score, price)
		VALUES
		(
		new_id				,
		p_hotel_id	 		,
		p_capacity			,
		p_type_id			,
		p_status			,
		p_score				,
		p_price
		);

		RETURN QUERY SELECT a.apartment_id, a.hotel_id, a.capacity, a.type_id, a.status, a.score, a.price FROM t_apartments AS a
						WHERE a.apartment_id = new_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Delete apartment-----------------------------------------------
CREATE OR REPLACE FUNCTION apartment_del(p_apartment_id int)
	RETURNS VARCHAR
	AS
	$code$
	DECLARE
		result_str VARCHAR := 'OK';
	BEGIN
		IF (p_apartment_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_apartment_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id) THEN
			RAISE EXCEPTION 'ERROR: apartment % does not exists', p_apartment_id;
		END IF;

		IF EXISTS (SELECT b.apartment_id FROM t_bookings AS b WHERE b.apartment_id = p_apartment_id LIMIT 1) THEN
			RAISE EXCEPTION 'ERROR: apartment % has bookings', p_apartment_id;
		ELSE
			DELETE FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id;
		END IF;
		RETURN result_str;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Update apartment-----------------------------------------------
CREATE OR REPLACE FUNCTION apartment_upd
	(
	p_apartment_id	int,
	p_hotel_id		int,
	p_capacity  	int,
	p_type_id   	int,
	p_status    	char,
	p_score     	int,
	p_price     	numeric
	)
	RETURNS SETOF t_apartments
	AS
	$code$
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id) THEN
			RAISE EXCEPTION 'ERROR: apartment % does not exists', p_apartment_id;
		END IF;

		UPDATE t_apartments SET
			apartment_id = p_apartment_id	,
			hotel_id 	 = p_hotel_id		,
			capacity 	 = p_capacity		,
			type_id  	 = p_type_id		,
			status   	 = p_status			,
			score    	 = p_score			,
			price    	 = p_price

		WHERE apartment_id = p_apartment_id;

		RETURN QUERY SELECT a.apartment_id, a.hotel_id, a.capacity, a.type_id, a.status, a.score, a.price FROM t_apartments AS a
						WHERE a.apartment_id = p_apartment_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Get apartment-----------------------------------------------
CREATE OR REPLACE FUNCTION apartment_get(p_apartment_id int)
	RETURNS SETOF t_apartments
	AS
	$code$
	BEGIN
		IF (p_apartment_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_apartment_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id) THEN
			RAISE EXCEPTION 'ERROR: apartment % does not exists', p_apartment_id
				USING HINT = 'Please use id of existing apartment';
		END IF;

		RETURN QUERY SELECT a.apartment_id, a.hotel_id, a.capacity, a.type_id, a.status, a.score, a.price FROM t_apartments AS a
						WHERE a.apartment_id = p_apartment_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Search apartments by hotel-----------------------------------------------
CREATE OR REPLACE FUNCTION apartment_get_list_by_hotel (p_hotel_id int)
	RETURNS SETOF t_apartments
	AS
	$code$
	BEGIN
	IF (p_hotel_id IS NULL) THEN
		RAISE EXCEPTION 'ERROR: p_hotel_id must be set'
				USING HINT = 'Please set the parameter correctly!';
	END IF;
	IF NOT EXISTS (SELECT a.hotel_id FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
		RAISE EXCEPTION 'ERROR: hotel % does not exists', p_apartment_id
			USING HINT = 'Please use id of existing apartment';
	END IF;

	RETURN QUERY SELECT a.apartment_id, a.hotel_id, a.capacity, a.type_id, a.status, a.score, a.price FROM t_apartments AS a
						WHERE a.hotel_id = p_hotel_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Add client-----------------------------------------------
CREATE OR REPLACE FUNCTION client_add
	(
	p_full_name VARCHAR,
	p_score int
	)
	RETURNS SETOF t_clients
	AS
	$code$
	DECLARE
		new_id integer := 0;
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		new_id := nextval('t_clients_client_id_seq');
		INSERT INTO t_clients (client_id, full_name, score)
		VALUES
		(
		new_id				,
		p_full_name			,
		p_score
		);

		RETURN QUERY SELECT c.client_id, c.full_name, c.score FROM t_clients AS c
						WHERE c.client_id = new_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Delete client-----------------------------------------------
CREATE OR REPLACE FUNCTION client_del(p_client_id int)
	RETURNS VARCHAR
	AS
	$code$
	DECLARE
		result_str VARCHAR := 'OK';
	BEGIN
		IF (p_client_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_client_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT c.client_id, c.full_name, c.score FROM t_clients AS c WHERE c.client_id = p_client_id) THEN
			RAISE EXCEPTION 'ERROR: client % does not exists', p_client_id;
		END IF;

		IF EXISTS (SELECT b.client_id FROM t_bookings AS b WHERE b.client_id = p_client_id LIMIT 1) THEN
			RAISE EXCEPTION 'ERROR: client % has bookings', p_client_id;
		ELSE
			DELETE FROM t_clients AS c WHERE c.client_id = p_client_id;
		END IF;
		RETURN result_str;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Update client-----------------------------------------------
CREATE OR REPLACE FUNCTION client_upd
	(
	p_client_id	int,
	p_full_name VARCHAR,
	p_score 	int
	)
	RETURNS SETOF t_clients
	AS
	$code$
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT c.client_id FROM t_clients AS c WHERE c.client_id = p_client_id LIMIT 1) THEN
			RAISE EXCEPTION 'ERROR: client % does not exists', p_client_id;
		END IF;

		UPDATE t_clients SET
			full_name = p_full_name,
			score 	= p_score
		WHERE client_id = p_client_id;

		RETURN QUERY SELECT c.client_id, c.full_name, c.score FROM t_clients AS c
						WHERE c.client_id = p_client_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Get client-----------------------------------------------
CREATE OR REPLACE FUNCTION client_get(p_client_id int)
	RETURNS SETOF t_clients
	AS
	$code$
	BEGIN
		IF (p_client_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_client_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT c.client_id, c.full_name, c.score FROM t_clients AS c WHERE c.client_id = p_client_id) THEN
			RAISE EXCEPTION 'ERROR: client % does not exists', p_client_id
				USING HINT = 'Please use id of existing client';
		END IF;

		RETURN QUERY SELECT c.client_id, c.full_name, c.score FROM t_clients AS c
						WHERE c.client_id = p_client_id;
	END;
	$code$
	LANGUAGE 'plpgsql';


--Add booking-----------------------------------------------
CREATE OR REPLACE FUNCTION booking_add
	(
	p_client_id int,
	p_apartment_id int,
	p_beg_date timestamp with time zone,
	p_end_date timestamp with time zone,
	p_full_price numeric
	)
	RETURNS SETOF t_bookings
	AS
	$code$
	DECLARE
		new_id integer := 0;
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT c.client_id FROM t_clients AS c WHERE c.client_id = p_client_id) THEN
			RAISE EXCEPTION 'ERROR: client % not found', p_client_id
				USING HINT = 'Please set parameter correctly';
		END IF;
		IF NOT EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id) THEN
			RAISE EXCEPTION 'ERROR: apartment % not found', p_apartment_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF EXISTS (SELECT b.apartment_id FROM t_bookings AS b WHERE b.apartment_id = p_apartment_id AND (p_beg_date, p_end_date) OVERLAPS (b.beg_date, b.end_date)) THEN
			RAISE EXCEPTION 'ERROR: apartment % is already booked', p_apartment_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		new_id := nextval('t_bookings_booking_id_seq');
		INSERT INTO t_bookings (booking_id, client_id, apartment_id, beg_date, end_date, full_price)
		VALUES
		(
		new_id,
		p_client_id,
		p_apartment_id,
		p_beg_date,
		p_end_date,
		p_full_price
		);

		RETURN QUERY SELECT b.booking_id, b.client_id, b.apartment_id, b.beg_date, b.end_date, b.full_price FROM t_bookings AS b
						WHERE b.booking_id = new_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Delete booking-----------------------------------------------
CREATE OR REPLACE FUNCTION booking_del(p_booking_id int)
	RETURNS VARCHAR
	AS
	$code$
	DECLARE
		result_str VARCHAR := 'OK';
	BEGIN
		IF (p_booking_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_booking_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT b.booking_id FROM t_bookings AS b WHERE b.booking_id = p_booking_id) THEN
			RAISE EXCEPTION 'ERROR: booking % does not exists', p_booking_id;
		END IF;

		IF EXISTS (SELECT p.payment_id FROM t_payments AS p WHERE p.booking_id = p_booking_id LIMIT 1) THEN
			RAISE EXCEPTION 'ERROR: booking % has already payd', p_booking_id;
		ELSE
			DELETE FROM t_bookings AS b WHERE b.booking_id = p_booking_id;
		END IF;
		RETURN result_str;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Update booking-----------------------------------------------
CREATE OR REPLACE FUNCTION booking_upd
	(
	p_booking_id int,
	p_client_id int,
	p_apartment_id int,
	p_beg_date timestamp with time zone,
	p_end_date timestamp with time zone,
	p_full_price numeric
	)
	RETURNS SETOF t_bookings
	AS
	$code$
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT b.booking_id FROM t_bookings AS b WHERE b.booking_id = p_booking_id) THEN
			RAISE EXCEPTION 'ERROR: booking % does not exists', p_booking_id;
		END IF;

		IF NOT EXISTS (SELECT c.client_id FROM t_clients AS c WHERE c.client_id = p_client_id) THEN
			RAISE EXCEPTION 'ERROR: client % not found', p_client_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT a.apartment_id FROM t_apartments AS a WHERE a.apartment_id = p_apartment_id) THEN
			RAISE EXCEPTION 'ERROR: apartment % not found', p_apartment_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF EXISTS (SELECT b.apartment_id FROM t_bookings AS b WHERE b.apartment_id = p_apartment_id AND (p_beg_date, p_end_date) OVERLAPS (b.beg_date, b.end_date)) THEN
			RAISE EXCEPTION 'ERROR: apartment % is already booked', p_apartment_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		UPDATE t_bookings SET
			client_id		= p_client_id		,
			apartment_id	= p_apartment_id	,
			beg_date		= p_beg_date		,
			end_date		= p_end_date		,
			full_price		= p_full_price
		WHERE booking_id = p_booking_id;

		RETURN QUERY SELECT b.booking_id, b.client_id, b.apartment_id, b.beg_date, b.end_date, b.full_price FROM t_bookings AS b
						WHERE b.booking_id = p_booking_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Get booking-----------------------------------------------
CREATE OR REPLACE FUNCTION booking_get(p_booking_id int)
	RETURNS SETOF t_bookings
	AS
	$code$
	BEGIN
		IF (p_booking_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_booking_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT b.booking_id FROM t_bookings AS b WHERE b.booking_id = p_booking_id) THEN
			RAISE EXCEPTION 'ERROR: booking % does not exists', p_booking_id
				USING HINT = 'Please use id of existing booking';
		END IF;

		RETURN QUERY SELECT b.booking_id, b.client_id, b.apartment_id, b.beg_date, b.end_date, b.full_price FROM t_bookings AS b
						WHERE b.booking_id = p_booking_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Add payment-----------------------------------------------
CREATE OR REPLACE FUNCTION payment_add
	(
	p_payment_date timestamp with time zone,
	p_pay_sum numeric,
	p_booking_id int,
	p_payment_info varchar
	)
	RETURNS SETOF t_payments
	AS
	$code$
	DECLARE
		new_id integer := 0;
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/
		IF NOT EXISTS (SELECT b.booking_id FROM t_bookings AS b WHERE b.booking_id = p_booking_id) THEN
			RAISE EXCEPTION 'ERROR: booking % does not exists', p_booking_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF length(trim(p_payment_info)) = 0 THEN
			RAISE EXCEPTION 'ERROR: Parameter p_payment_info can not be empty string';
		END IF;

		new_id := nextval('t_payments_payment_id_seq');
		INSERT INTO t_payments (payment_id, payment_date, pay_sum, booking_id, payment_info)
		VALUES
		(
		new_id			,
		p_payment_date	,
		p_pay_sum		,
		p_booking_id	,
		p_payment_info
		);

		RETURN QUERY SELECT p.payment_id, p.payment_date, p.pay_sum, p.booking_id, p.payment_info FROM t_payments AS p
						WHERE p.payment_id = new_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Delete payment-----------------------------------------------
CREATE OR REPLACE FUNCTION payment_del(p_payment_id int)
	RETURNS VARCHAR
	AS
	$code$
	DECLARE
		result_str VARCHAR := 'OK';
	BEGIN

		IF NOT EXISTS (SELECT p.payment_id FROM t_payments AS p WHERE p.payment_id = p_payment_id) THEN
			RAISE EXCEPTION 'ERROR: payment % does not exists', p_payment_id;
		END IF;
		DELETE FROM t_payments AS p WHERE p.payment_id = p_payment_id;
		RETURN result_str;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Update payment-----------------------------------------------
CREATE OR REPLACE FUNCTION payment_upd
	(
	p_payment_id int,
	p_payment_date timestamp with time zone,
	p_pay_sum numeric,
	p_booking_id int,
	p_payment_info varchar
	)
	RETURNS SETOF t_payments
	AS
	$code$
	BEGIN
		/*
		Проверки убраны, так как добавлены соответствующие constraints
		*/

		IF NOT EXISTS (SELECT b.booking_id FROM t_bookings AS b WHERE b.booking_id = p_booking_id) THEN
			RAISE EXCEPTION 'ERROR: booking % does not exists', p_booking_id
				USING HINT = 'Please set parameter correctly';
		END IF;

		UPDATE t_payments SET
			payment_date	= p_payment_date	,
			pay_sum			= p_pay_sum 		,
			booking_id		= p_booking_id		,
			payment_info	= p_payment_info
		WHERE payment_id = p_payment_id;

		RETURN QUERY SELECT p.payment_id, p.payment_date, p.pay_sum, p.booking_id, p.payment_info FROM t_payments AS p
						WHERE p.payment_id = p_payment_id;
	END;
	$code$
	LANGUAGE 'plpgsql';

--Get payment-----------------------------------------------
CREATE OR REPLACE FUNCTION payment_get(p_payment_id int)
	RETURNS SETOF t_payments
	AS
	$code$
	BEGIN
		IF (p_payment_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_payment_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT p.payment_id FROM t_payments AS p WHERE p.payment_id = p_payment_id) THEN
			RAISE EXCEPTION 'ERROR: payment % does not exists', p_booking_id
				USING HINT = 'Please use id of existing payment';
		END IF;

		RETURN QUERY SELECT p.payment_id, p.payment_date, p.pay_sum, p.booking_id, p.payment_info FROM t_payments AS p
						WHERE p.payment_id = p_payment_id;
	END;
	$code$
	LANGUAGE 'plpgsql';
/****************************Выборка свободных апартаментов в указанном отеле на указанный диапазон***********/
CREATE OR REPLACE FUNCTION get_free_apartments(
	p_hotel_id int,
	p_beg_date timestamp with time zone,
	p_day_count int
	) RETURNS SETOF t_apartments
	AS
	$code$
	DECLARE
	v_end_date timestamp with time zone;
	BEGIN
		IF (p_hotel_id IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_hotel_id does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF (p_beg_date IS NULL) THEN
			RAISE EXCEPTION 'ERROR: parameter p_beg_date does not set'
				USING HINT = 'Please set parameter correctly';
		END IF;

		IF NOT EXISTS (SELECT * FROM t_hotels AS h WHERE h.hotel_id = p_hotel_id) THEN
			RAISE EXCEPTION 'ERROR: hotel % does not exists', p_hotel_id
				USING HINT = 'Please use id of existing hotel';
		END IF;

		v_end_date := p_beg_date + make_interval(days => p_day_count);

		RETURN QUERY
		SELECT all_apart.* FROM
		(
			--Выбрать все апартаменты данного отеля
			SELECT a.* FROM t_apartments AS a WHERE hotel_id = p_hotel_id
		) AS all_apart
		EXCEPT --Исключить данные нижней выборки
		(
			--Выбрать все апартаменты данного отеля, которые заняты на заданный период
			SELECT a.* FROM t_bookings AS b
				JOIN t_apartments AS a ON a.apartment_id = b.apartment_id AND a.hotel_id = p_hotel_id
				AND (b.beg_date, b.end_date) OVERLAPS (p_beg_date, v_end_date)
		);
	END;
	$code$
	LANGUAGE 'plpgsql';
/****************************  VIEWS  ****************************************/
CREATE OR REPLACE VIEW v_top_hotel
(
	hotel_name,
	rating
) AS
SELECT h.hotel_name, h.hotel_score FROM t_hotels AS h
WHERE h.hotel_score =(SELECT max(hotel_score) FROM t_hotels);

CREATE OR REPLACE VIEW v_top_apartment
(
	apartment_id,
	rating
) AS
SELECT a.apartment_id, a.score FROM t_apartments AS a
WHERE a.score =(SELECT max(score) FROM t_apartments);

CREATE OR REPLACE VIEW v_top_client
(
	full_name,
	rating
) AS
SELECT c.full_name, c.score FROM t_clients AS c
WHERE c.score =(SELECT max(score) FROM t_clients);

/****************************  TEST DATA *************************************/
INSERT INTO t_apartment_types (type_name, day_price)
VALUES
('Standard — стандартный номер'										, 100.0),
('Studio, студия — однокомнатный номер, больше стандартного'		, 200.0),
('Single — одноместный номер'										, 300.0),
('DBL — двухместный номер'											, 400.0),
('Double — одна двуспальная кровать'								, 500.0),
('Twin — две односпальные кровати'									, 600.0),
('Business — двухкомнатный номер, состоит из гостиной и спальни'	, 700.0),
('TRPL — трёхместный номер'											, 800.0),
('EXB — дополнительная кровать'										, 900.0),
('CH — с ребёнком (например 0-6 лет /до 12 /до 14)'					, 1000.0),
('Superior — номер повышенной комфортности'							, 1100.0),
('Villa — размещение в бунгало'										, 1200.0),
('Family room — семейный номер (2-х или 3-комнатный)'				, 1300.0),
('Main Building — комната, расположенная в главном здании'			, 1400.0),
('Duplex — двухуровневый номер'										, 1500.0),
('Junior Suite — номер улучшенной планировки (полулюкс)'			, 1600.0),
('Suite, сюит — номер улучшенной планировки и категории (люкс)'		, 1700.0),
('De Luxe — номера повышенной комфортности'							, 1800.0);

INSERT INTO t_locations (location_name)
VALUES
('Country 1, city 1, street 1'),
('Country 2, city 2, street 2'),
('Country 3, city 3, street 3'),
('Country 4, city 4, street 4');

SELECT * FROM hotel_add('Grand hotel', 4, 2);
SELECT * FROM hotel_add('Simple hotel', 4, 1);
SELECT * FROM apartment_add(1, 3, 2, 'U', 1, 0.00);
SELECT * FROM apartment_add(1, 3, 2, 'U', 1, 0.00);
SELECT * FROM apartment_add(1, 3, 2, 'U', 1, 0.00);
SELECT * FROM apartment_get(1);
SELECT * FROM apartment_upd(1, 1, 4, 8, 'F', 4, 400.00);
SELECT * FROM apartment_del(3);
SELECT * FROM apartment_add(1, 2, 2, 'F', 3, 300.00);
SELECT * FROM apartment_add(1, 2, 9, 'F', 5, 400.00);

SELECT * FROM client_add('Петр Иванович Иванов', 8);
SELECT * FROM client_upd(1,'Петр Иванович Иванидзе', 8);
SELECT * FROM client_get(1);
SELECT * FROM client_add('Иван Митрофанович Евлампиев', 8);
SELECT * FROM client_del(2);

SELECT * FROM booking_add(1, 1, NOW(), NOW() + interval '7 day', 100.00);
SELECT * FROM booking_upd(1, 1, 1, NOW()+ interval '8 day', NOW() + interval '14 day', 200.00);
SELECT * FROM booking_get(1);
SELECT * FROM booking_add(1, 1, NOW() - interval '3 day', NOW() - interval '2 day', 10.00);
SELECT * FROM booking_del(2);

SELECT * FROM booking_add (1, 1, NOW() - interval '7 day', NOW() - interval '5 day', 100.00);
SELECT * FROM booking_add (1, 1, NOW() + interval '14 day', NOW() + interval '18 day', 100.00);
SELECT * FROM booking_del(4);
SELECT * FROM booking_add (1, 1, NOW() + interval '17 day', NOW() + interval '21 day', 100.00);
SELECT * FROM booking_add (1, 4, make_timestamptz(2025, 3, 16, 12, 00, 00.0), make_timestamptz(2025, 3, 18, 12, 00, 00.0), 100.00);

SELECT * FROM payment_add(NOW(), 130.25, 1, 'Sense bank standard info');
SELECT * FROM payment_upd(1, NOW() + interval '8 day', 140.25, 1, 'Sense bank updated info');
SELECT * FROM payment_get(1);
SELECT * FROM payment_add(NOW(), 130.25, 1, 'Oschad bank standard info');
SELECT * FROM payment_del(2);
SELECT * FROM get_free_apartments(1, make_timestamptz(2025, 3, 17, 12, 00, 00.0), 10);

SELECT * FROM v_top_hotel;
SELECT * FROM v_top_apartment;
SELECT * FROM v_top_client;



SELECT * FROM hotel_upsert(null, 'Upsert hotel', 1, 8);
/*
id вставленного отеля 3
При незаданном параметре hotel_id вставляем запись
*/

SELECT * FROM hotel_upsert(3, 'Edited Upsert hotel', 1, 8);
-- "Edited Upsert hotel"

--SELECT * FROM hotel_upsert(80, 'Wrong Upsert hotel', 1, 8);
/*
ERROR: hotel 80 does not exists, nothing to update
CONTEXT:  функция PL/pgSQL hotel_upsert(integer,character varying,integer,integer), строка 8, оператор RAISEОШИБКА:  ERROR: hotel 80 does not exists, nothing to update
SQL state: P0001
При введении несуществующего ID редактирование и вставка запрещены
*/
SELECT * FROM hotel_upsert('{"hotel_id": null, "hotel_name": "Hilton", "hotel_location_id": 1, "score": 5}');
/*****************************************************************/


create or replace function hotel_upsert_ol(
    p_hotel_name varchar,
    p_hotel_location_id int,
    p_hotel_score int,
    p_hotel_id integer default null -- default should be after strict args
)
    returns setof t_hotels
as
$code$
declare

begin

    return query
        insert into t_hotels (hotel_id, hotel_name, hotel_location_id, hotel_score)
            values (coalesce(p_hotel_id, nextval('t_hotels_hotel_id_seq')),
                    p_hotel_name,
                    p_hotel_location_id,
                    p_hotel_score)
            on conflict (hotel_id)
                do update set
                    hotel_name = excluded.hotel_name ,
                    hotel_location_id = excluded.hotel_location_id ,
                    hotel_score = excluded.hotel_score
            returning t_hotels.*;

end;
$code$
    language 'plpgsql';


SELECT * FROM hotel_upsert_ol( 'Edited Upsert hotel', 1, 8);

select last_value, * from pg_sequences
where sequencename = 't_hotels_hotel_id_seq';



CREATE OR REPLACE FUNCTION hotel_upsert_ol_jsn(
    in_jsn text
)
    RETURNS SETOF t_hotels
AS
$code$
DECLARE
    f_jsn jsonb;
BEGIN
    f_jsn := in_jsn::jsonb;

    RETURN QUERY
        INSERT INTO t_hotels (hotel_id, hotel_name, hotel_location_id, hotel_score)
            select coalesce(hotel_id, nextval('t_hotels_hotel_id_seq')),
                   hotel_name,
                   hotel_location_id,
                   hotel_score
            from
                jsonb_populate_record(null::t_hotels, f_jsn)
            ON CONFLICT (hotel_id)
                DO UPDATE SET
                    hotel_name = EXCLUDED.hotel_name ,
                    hotel_location_id = EXCLUDED.hotel_location_id ,
                    hotel_score = EXCLUDED.hotel_score
            RETURNING t_hotels.*;

END;
$code$
    LANGUAGE 'plpgsql';

select * from hotel_upsert_ol_jsn('{"hotel_id":3,"hotel_name":"Edited 3 times Upsert hotel","hotel_location_id":1,"hotel_score":8}');
select * from hotel_upsert_ol_jsn('{"hotel_name":"New hotel","hotel_location_id":1,"hotel_score":8}')