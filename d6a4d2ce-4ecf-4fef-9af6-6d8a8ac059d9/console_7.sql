create function blaze7.get_tprice(in_min_exec_id varchar(30), in_max_time timestamptz )
returns table (status bpchar ,
	reportid varchar(30) ,
	orderid varchar(100) ,
	legnumber int4 ,
	dashsecurityid text ,
	lastreportid text ,
	systemorderid varchar(100) ,
	updatesequence text ,
	userid text ,
	companyid text ,
	exchangeconnectionid bpchar ,
	exchangename text ,
	destination text ,
	routingtableid text ,
	systemid text ,
	orderidint text ,
	reportidint text ,
	generation text ,
	ulbid text ,
	ulask text ,
	ulbidsz text ,
	ulasksz text ,
	nbbobid text ,
	nbboask text ,
	nbbobidsz text ,
	nbboasksz text ,
	bida text ,
	aska text ,
	bidsza text ,
	asksza text ,
	bidb text ,
	askb text ,
	bidszb text ,
	askszb text ,
	bidc text ,
	askc text ,
	bidszc text ,
	askszc text ,
	bidi text ,
	aski text ,
	bidszi text ,
	askszi text ,
	bidp text ,
	askp text ,
	bidszp text ,
	askszp text ,
	bidx text ,
	askx text ,
	bidszx text ,
	askszx text ,
	bidq text ,
	askq text ,
	bidszq text ,
	askszq text ,
	bidz text ,
	askz text ,
	bidszz text ,
	askszz text ,
	bidw text ,
	askw text ,
	bidszw text ,
	askszw text ,
	bidt text ,
	askt text ,
	bidszt text ,
	askszt text ,
	bidm text ,
	askm text ,
	bidszm text ,
	askszm text ,
	bidh text ,
	askh text ,
	bidszh text ,
	askszh text ,
	bidj text ,
	askj text ,
	bidszj text ,
	askszj text ,
	bide text ,
	aske text ,
	bidsze text ,
	asksze text ,
	bidr text ,
	askr text ,
	bidszr text ,
	askszr text ,
	bidd text ,
	askd text ,
	bidszd text ,
	askszd text ,
	bidu text ,
	asku text ,
	bidszu text ,
	askszu text ,
	bids text ,
	asks text ,
	bidszs text ,
	askszs text ,
	bidg text ,
	askg text ,
	bidszg text ,
	askszg text ,
	bidv text ,
	askv text ,
	bidszv text ,
	askszv text ,
	bidea text ,
	askea text ,
	bidszea text ,
	askszea text ,
	bidep text ,
	askep text ,
	bidszep text ,
	askszep text ,
	bidez text ,
	askez text ,
	bidszez text ,
	askszez text ,
	bidey text ,
	askey text ,
	bidszey text ,
	askszey text ,
	bidej text ,
	askej text ,
	bidszej text ,
	askszej text ,
	bidek text ,
	askek text ,
	bidszek text ,
	askszek text ,
	bideq text ,
	askeq text ,
	bidszeq text ,
	askszeq text ,
	bideb text ,
	askeb text ,
	bidszeb text ,
	askszeb text ,
	biden text ,
	asken text ,
	bidszen text ,
	askszen text ,
	bidex text ,
	askex text ,
	bidszex text ,
	askszex text ,
	bidei text ,
	askei text ,
	bidszei text ,
	askszei text ,
	bidec text ,
	askec text ,
	bidszec text ,
	askszec text ,
	bidem text ,
	askem text ,
	bidszem text ,
	askszem text ,
	bideu text ,
	askeu text ,
	bidszeu text ,
	askszeu text ,
	bided text ,
	asked text ,
	bidszed text ,
	askszed text ,
	bidef text ,
	askef text ,
	bidszef text ,
	askszef text ,
	bideg text ,
	askeg text ,
	bidszeg text ,
	askszeg text ,
	_order_id int8 ,
	_chain_id int4 ,
	_db_create_time timestamptz )
language plpgsql
as $fx$
    declare
    min_exec_id varchar(30);
        max_exec_id varchar(30);
        max_time timestamptz;
    begin
        select max(exec_id)
--         into max_exec_id
        from blaze7.order_report;

        create temp table tmp_eq as
        SELECT rep.exec_id,
            mdr.payload AS mdr_payload,
            rep.leg_ref_id,
            rep.payload AS rep_payload,
            rep.exec_type,
            co.order_id,
            co.chain_id,
            co.payload AS co_payload,
            mdr.db_create_time,
            co.cl_ord_id,
            co.crossing_side,
            co.route_type,
                CASE
                    WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
                    ELSE ( SELECT leg.payload ->> 'LegInstrumentType'::text
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                END AS act_instrument_type
        select mdr.*
           FROM blaze7.market_data_report mdr
             JOIN blaze7.order_report rep ON rep.exec_id::text = mdr.exec_id::text
             JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
          WHERE co.order_class <> 'O'::bpchar
        and mdr.exec_id < :max_exec_id
                and (
              mdr.exec_id > :in_min_exec_id
                  or (mdr.exec_id <= :in_min_exec_id and date_trunc('milliseconds', mdr.db_create_time::timestamp) >
                                                 :in_max_time::timestamp at time zone 'US/Central'))

        SELECT rep.exec_id,
            mdr.payload AS mdr_payload,
            rep.leg_ref_id,
            rep.payload AS rep_payload,
            rep.exec_type,
            co.order_id,
            co.chain_id,
            co.payload AS co_payload,
            mdr.db_create_time,
            co.cl_ord_id,
            co.crossing_side,
            co.route_type,
                CASE
                    WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
                    ELSE ( SELECT leg.payload ->> 'LegInstrumentType'::text
                       FROM blaze7.client_order_leg leg
                      WHERE leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                END AS act_instrument_type
        select mdr.*
           FROM blaze7.market_data_report mdr
             JOIN blaze7.order_report rep ON (rep.payload ->> 'ExecRefId'::text) = mdr.exec_id::text
             JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
          WHERE co.order_class = 'O'::bpchar
        and mdr.exec_id < :max_exec_id
                and (
              mdr.exec_id > :in_min_exec_id
                  or (mdr.exec_id <= :in_min_exec_id and date_trunc('milliseconds', mdr.db_create_time::timestamp) >
                                                 :in_max_time::timestamp at time zone 'US/Central'))

    end;

    $fx$


 and (reportid > %(max_exec_id)s
    or
       (reportid < %(max_exec_id)s and date_trunc('milliseconds', x._db_create_time::timestamp) >
                                                 %(max_processed_time_price)s::timestamp at time zone
                                                 'US/Central'))


select mdr.*
FROM blaze7.market_data_report mdr
         JOIN blaze7.order_report rep ON rep.exec_id::text = mdr.exec_id::text
         JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
WHERE co.order_class <> 'O'::bpchar
  and mdr.exec_id < :max_exec_id
  and (
    mdr.exec_id > :in_min_exec_id
        or (mdr.exec_id <= :in_min_exec_id and date_trunc('milliseconds', mdr.db_create_time::timestamp) >
                                               :in_max_time::timestamp at time zone 'US/Central'))

EXPLAIN (ANALYZE, BUFFERS)
WITH filtered_mdr AS MATERIALIZED (
    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id > :in_min_exec_id
      AND mdr.exec_id < :max_exec_id

    UNION ALL

    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id <= :in_min_exec_id
      AND mdr.exec_id < :max_exec_id
      AND date_trunc('milliseconds', mdr.db_create_time::timestamp)
            > (:in_max_time::timestamp AT TIME ZONE 'US/Central')
)
SELECT *
FROM filtered_mdr mdr
JOIN blaze7.order_report rep
    ON rep.exec_id = mdr.exec_id
JOIN blaze7.client_order co
    ON co.order_id = rep.order_id
   AND co.chain_id = rep.chain_id
WHERE co.order_class <> 'O'::bpchar;


WITH filtered_mdr AS MATERIALIZED (
    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id > :in_min_exec_id
      AND mdr.exec_id < :max_exec_id

    UNION ALL

SELECT mdr.*
FROM blaze7.market_data_report mdr
WHERE mdr.exec_id <= :in_min_exec_id
  AND mdr.exec_id < :max_exec_id

  -- Попередній відбір через індекс db_create_time
  AND mdr.db_create_time >
      (:in_max_time::timestamp AT TIME ZONE 'US/Central')
      - INTERVAL '1 hour'

  -- Початкова точна перевірка
  AND date_trunc('milliseconds', mdr.db_create_time::timestamp) >
      (:in_max_time::timestamp AT TIME ZONE 'US/Central')
)
SELECT mdr.*, rep.*--, co.*
FROM filtered_mdr mdr
CROSS JOIN LATERAL (
    SELECT rep.*
    FROM blaze7.order_report rep
    WHERE rep.exec_id = mdr.exec_id
    OFFSET 0
) rep
CROSS JOIN LATERAL (
    SELECT co.*
    FROM blaze7.client_order co
    WHERE co.order_id = rep.order_id
      AND co.chain_id = rep.chain_id
      AND co.order_class <> 'O'::bpchar
    OFFSET 0
) co;

WITH filtered_mdr AS MATERIALIZED (
    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id > :in_min_exec_id
      AND mdr.exec_id < :max_exec_id

    UNION ALL

    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id <= :in_min_exec_id
      AND mdr.exec_id < :max_exec_id
      AND mdr.db_create_time >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central')
          - INTERVAL '1 hour'
      AND date_trunc('milliseconds', mdr.db_create_time::timestamp) >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central')
)
SELECT mdr.*, rep.*, co.*
FROM filtered_mdr mdr
CROSS JOIN LATERAL (
    SELECT rep.*
    FROM blaze7.order_report rep
    WHERE rep.exec_id = mdr.exec_id
    OFFSET 0
) rep
CROSS JOIN LATERAL (
    SELECT co.*
    FROM blaze7.client_order co
    WHERE co.order_id = rep.order_id
      AND co.chain_id = rep.chain_id
      AND co.order_class <> 'O'::bpchar
    OFFSET 0
) co

UNION ALL

SELECT mdr.*, rep.*, co.*
FROM filtered_mdr mdr
CROSS JOIN LATERAL (
    SELECT rep.*
    FROM blaze7.order_report rep
    WHERE rep.payload ->> 'ExecRefId' = mdr.exec_id::text
    OFFSET 0
) rep
CROSS JOIN LATERAL (
    SELECT co.*
    FROM blaze7.client_order co
    WHERE co.order_id = rep.order_id
      AND co.chain_id = rep.chain_id
      AND co.order_class = 'O'::bpchar
    OFFSET 0
) co;


----------

create or replace view blaze7.so_price as
WITH filtered_mdr AS MATERIALIZED (
    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id > :in_min_exec_id
      AND mdr.exec_id < :max_exec_id

    UNION ALL

    SELECT mdr.*
    FROM blaze7.market_data_report mdr
    WHERE mdr.exec_id <= :in_min_exec_id
      AND mdr.exec_id < :max_exec_id
      AND mdr.db_create_time >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central')
          - INTERVAL '1 hour'
      AND date_trunc('milliseconds', mdr.db_create_time::timestamp) >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central')
)
SELECT mdr.*--, rep.*, co.*
FROM filtered_mdr mdr
CROSS JOIN LATERAL (
    SELECT rep.*
    FROM blaze7.order_report rep
    WHERE rep.exec_id = mdr.exec_id
    OFFSET 0
) rep
CROSS JOIN LATERAL (
    SELECT co.*
    FROM blaze7.client_order co
    WHERE co.order_id = rep.order_id
      AND co.chain_id = rep.chain_id
      AND co.order_class <> 'O'::bpchar
    OFFSET 0
) co

UNION ALL

SELECT mdr.*, rep.*, co.*
FROM filtered_mdr mdr
CROSS JOIN LATERAL (
    SELECT rep.*
    FROM blaze7.order_report rep
    WHERE rep.payload ->> 'ExecRefId' = mdr.exec_id::text
    OFFSET 0
) rep
CROSS JOIN LATERAL (
    SELECT co.*
    FROM blaze7.client_order co
    WHERE co.order_id = rep.order_id
      AND co.chain_id = rep.chain_id
      AND co.order_class = 'O'::bpchar
    OFFSET 0
) co;



-- create or replace view blaze7.so_price as

SELECT mdr.*
FROM blaze7.market_data_report mdr
         join lateral (
    SELECT rep.*
    FROM blaze7.order_report rep
             join blaze7.client_order co
                  on co.order_id = rep.order_id
                      AND co.chain_id = rep.chain_id
                      AND co.order_class <> 'O'::bpchar
    WHERE rep.exec_id = mdr.exec_id

    union all
    SELECT rep.*
    FROM blaze7.order_report rep
             join blaze7.client_order co
                  on co.order_id = rep.order_id
                      AND co.chain_id = rep.chain_id
                      AND co.order_class = 'O'::bpchar
    WHERE rep.payload ->> 'ExecRefId' = mdr.exec_id::text

    ) rep on true