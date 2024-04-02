CREATE DATABASE big_data WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';

CREATE ROLE dwh WITH
	SUPERUSER
	CREATEDB
	CREATEROLE
	INHERIT
	LOGIN
	REPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE SCHEMA ats_reporting;


ALTER SCHEMA ats_reporting OWNER TO dwh;

--
-- Name: compliance; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA compliance;


ALTER SCHEMA compliance OWNER TO dwh;

--
-- Name: consolidator; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA consolidator;


ALTER SCHEMA consolidator OWNER TO dwh;

--
-- Name: dash360; Type: SCHEMA; Schema: -; Owner: dash360
--

CREATE SCHEMA dash360;

CREATE ROLE dhw_readonly WITH
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOLOGIN
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE dash360 WITH
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	LOGIN
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

GRANT dhw_readonly TO dash360;

CREATE ROLE genesis2_reader WITH
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOLOGIN
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;
GRANT genesis2_reader TO dash360;

ALTER SCHEMA dash360 OWNER TO dash360;

--
-- Name: dash_reporting; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA dash_reporting;


ALTER SCHEMA dash_reporting OWNER TO dwh;

--
-- Name: data_marts; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA data_marts;


ALTER SCHEMA data_marts OWNER TO dwh;

--
-- Name: db_management; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA db_management;


ALTER SCHEMA db_management OWNER TO dwh;

--
-- Name: dm_partitions; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA dm_partitions;


ALTER SCHEMA dm_partitions OWNER TO dwh;

--
-- Name: dq; Type: SCHEMA; Schema: -; Owner: dq_group
--

CREATE SCHEMA dq;


-- ALTER SCHEMA dq OWNER TO dq_group;

--
-- Name: dwh; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA dwh;


ALTER SCHEMA dwh OWNER TO dwh;

--
-- Name: dwh_new; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dwh_new;


ALTER SCHEMA dwh_new OWNER TO postgres;

--
-- Name: eod_reports; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA eod_reports;


ALTER SCHEMA eod_reports OWNER TO dwh;

--
-- Name: eq_tca; Type: SCHEMA; Schema: -; Owner: eq_tca_group
--

CREATE SCHEMA eq_tca;


-- ALTER SCHEMA eq_tca OWNER TO eq_tca_group;

--
-- Name: external_data; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA external_data;


ALTER SCHEMA external_data OWNER TO dwh;

--
-- Name: external_data_partitions; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA external_data_partitions;


ALTER SCHEMA external_data_partitions OWNER TO dwh;

--
-- Name: fc_partitions; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA fc_partitions;


ALTER SCHEMA fc_partitions OWNER TO dwh;

--
-- Name: fintech_dwh; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA fintech_dwh;


ALTER SCHEMA fintech_dwh OWNER TO dwh;

--
-- Name: fintech_reports; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA fintech_reports;


ALTER SCHEMA fintech_reports OWNER TO postgres;

--
-- Name: fix_capture; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA fix_capture;


ALTER SCHEMA fix_capture OWNER TO dwh;

--
-- Name: market_data; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA market_data;


ALTER SCHEMA market_data OWNER TO dwh;

--
-- Name: md_partitions; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA md_partitions;


ALTER SCHEMA md_partitions OWNER TO dwh;

--
-- Name: opt_tca; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA opt_tca;


ALTER SCHEMA opt_tca OWNER TO postgres;

--
-- Name: order_trail; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA order_trail;


ALTER SCHEMA order_trail OWNER TO dwh;

--
-- Name: partitions; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA partitions;


ALTER SCHEMA partitions OWNER TO dwh;

--
-- Name: partitions_new; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA partitions_new;


ALTER SCHEMA partitions_new OWNER TO postgres;

--
-- Name: prod_big_data; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA prod_big_data;


ALTER SCHEMA prod_big_data OWNER TO dwh;

--
-- Name: pt; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA pt;


ALTER SCHEMA pt OWNER TO dwh;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: repman; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA repman;


ALTER SCHEMA repman OWNER TO dwh;

--
-- Name: SCHEMA repman; Type: COMMENT; Schema: -; Owner: dwh
--

COMMENT ON SCHEMA repman IS 'Main purpose is replication to Amazon.
The project was closed due to slow performance on the Amazon side';


--
-- Name: squeeze; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA squeeze;


ALTER SCHEMA squeeze OWNER TO postgres;

--
-- Name: staging; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA staging;


ALTER SCHEMA staging OWNER TO dwh;

--
-- Name: storm_catalog; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA storm_catalog;


ALTER SCHEMA storm_catalog OWNER TO dwh;

--
-- Name: tca; Type: SCHEMA; Schema: -; Owner: dhw_admin
--

CREATE SCHEMA tca;


-- ALTER SCHEMA tca OWNER TO dhw_admin;

--
-- Name: test; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA test;


ALTER SCHEMA test OWNER TO dwh;

--
-- Name: trash; Type: SCHEMA; Schema: -; Owner: dwh
--

CREATE SCHEMA trash;


ALTER SCHEMA trash OWNER TO dwh;

--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: amcheck; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS amcheck WITH SCHEMA public;


--
-- Name: EXTENSION amcheck; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION amcheck IS 'functions for verifying relation integrity';


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA dwh;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: oracle_fdw; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS oracle_fdw WITH SCHEMA market_data;


--
-- Name: EXTENSION oracle_fdw; Type: COMMENT; Schema: -; Owner:
--

-- COMMENT ON EXTENSION oracle_fdw IS 'foreign data wrapper for Oracle access';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA dwh;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: pgstattuple; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA dwh;


--
-- Name: EXTENSION pgstattuple; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgstattuple IS 'show tuple-level statistics';


--
-- Name: plpgsql_check; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS plpgsql_check WITH SCHEMA public;


--
-- Name: EXTENSION plpgsql_check; Type: COMMENT; Schema: -; Owner:
--

-- COMMENT ON EXTENSION plpgsql_check IS 'extended check for plpgsql functions';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: tds_fdw; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS tds_fdw WITH SCHEMA public;


--
-- Name: EXTENSION tds_fdw; Type: COMMENT; Schema: -; Owner:
--

-- COMMENT ON EXTENSION tds_fdw IS 'Foreign data wrapper for querying a TDS database (Sybase or Microsoft SQL Server)';


--
-- Name: calculation_scheme; Type: TYPE; Schema: public; Owner: james_doherty
--

-- CREATE TYPE public.calculation_scheme AS ENUM (
--     'BBRG',
--     'DASH',
--     'CUSTOM'
-- );
--
--
-- ALTER TYPE public.calculation_scheme OWNER TO james_doherty;
--
-- --
-- -- Name: start_price_scheme; Type: TYPE; Schema: public; Owner: james_doherty
-- --
--
-- CREATE TYPE public.start_price_scheme AS ENUM (
--     'DASH1',
--     'DASH',
--     'CUSTOM'
-- );
--
--
-- ALTER TYPE public.start_price_scheme OWNER TO james_doherty;


CREATE TABLE compliance.sor_cat_in_sender_imid_config (
    id integer NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    config_sub_type character varying(255),
    effective_date date DEFAULT '2023-01-01'::date,
    fix_comp_id character varying(255),
    fix_tag integer,
    imid_source character varying(255),
    trading_firm_id character varying(255),
    with_obo boolean DEFAULT false NOT NULL,
    description character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    user_id integer NOT NULL
);

ALTER TABLE compliance.sor_cat_in_sender_imid_config OWNER TO dwh;


CREATE TABLE compliance.sor_cat_out_sender_imid_config (
    id integer NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    config_sub_type character varying(255),
    effective_date date DEFAULT '2023-01-01'::date,
    exchange_id character varying(255) NOT NULL,
    account_name character varying(255),
    fix_comp_id character varying(255),
    fix_tag integer,
    fix_value character varying(255),
    collect_first_tag_arr integer[],
    "default" character varying(255),
    imid_source character varying(255),
    description character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE compliance.sor_cat_out_sender_imid_config OWNER TO dwh;



ALTER TYPE public.start_price_scheme OWNER TO james_doherty;

--
-- Name: delete_sor_cat_in_sender_imid_config(bigint, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.delete_sor_cat_in_sender_imid_config(p_id bigint, p_user_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	-- check if the record is already deleted
    if exists (
        select 1
        from compliance.sor_cat_in_sender_imid_config
        where id = p_id and is_deleted
    ) then
        raise exception 'record with id % is already deleted', p_id using ERRCODE = 'P0000';
    end if;

    -- continue only if the record is not already deleted
	perform compliance.set_active_sor_cat_in_sender_imid_config(p_id, false, p_user_id);
    update compliance.sor_cat_in_sender_imid_config
    set is_deleted = true
    where id = p_id;
end;
$$;


ALTER FUNCTION compliance.delete_sor_cat_in_sender_imid_config(p_id bigint, p_user_id integer) OWNER TO dwh;

--
-- Name: delete_sor_cat_out_sender_imid_config(bigint, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.delete_sor_cat_out_sender_imid_config(p_id bigint, p_user_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	-- check if the record is already deleted
    if exists (
        select 1
        from compliance.sor_cat_out_sender_imid_config
        where id = p_id and is_deleted
    ) then
        raise exception 'record with id % is already deleted', p_id using ERRCODE = 'P0000';
    end if;

    -- continue only if the record is not already deleted
	perform compliance.set_active_sor_cat_out_sender_imid_config(p_id, false, p_user_id);
    update compliance.sor_cat_out_sender_imid_config
    set is_deleted = true
    where id = p_id;
end;
$$;


ALTER FUNCTION compliance.delete_sor_cat_out_sender_imid_config(p_id bigint, p_user_id integer) OWNER TO dwh;

--
-- Name: get_blaze_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_blaze_cat_report(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  l_mpid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin



    truncate table  compliance.cat_report;
    --to do: add child order records
    --loop by client_mpid

    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE','') --and imid = 'DFIN'
    )
    loop

    	perform compliance.insert_moir_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moim_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moic_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mono_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mooa_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mooc_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moom_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moor_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    	perform compliance.insert_moor_sor2exch_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moor_synt_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_momr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mocr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_moco_record(mpid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_meir_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meim_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meic_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meno_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meno_tts_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
 	    perform compliance.insert_meoa_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meoa_tts_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meoc_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meoc_tts_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meom_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meom_tts_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_tts_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_sor2exch_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_synt_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_meco_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_memr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mecr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

	    perform compliance.insert_mlno_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mloa_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlor_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlmr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlcr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

	    perform compliance.insert_mlir_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlim_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlom_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mloc_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mlic_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

	   --
	    perform compliance.insert_meof_repr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

	    perform compliance.insert_moof_repr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    end loop;

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE','') --and imid = 'DFIN'
    )
    --loop by client_mpid

    loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = l_mpid;

		if client_total_size > 0 then
			update compliance.cat_report
			set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
			where client_mpid = l_mpid;
	    end if;


	    select max(cat_submitter_crd) into l_crd_number from compliance.blaze_d_entity_cat where imid = l_mpid;

	    if client_total_size > 0 then
		    update compliance.cat_report
	        --set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_2c'||coalesce(file_group,'BLAZE')||'_OrderEvents_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv'
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||coalesce(file_group,'BLAZE')||'_OrderEvents_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv'
	        where client_mpid = l_mpid;

	    /*
 		else
 		    insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    select coalesce(nullif(l_crd_number,''),'104031')||'_'||mpid||'_'||to_char(current_date-1, 'YYYYMMDD')||'_'||'BLAZE'||'_OrderEvents_'||'000001'||'.csv',
 		   		   mpid,'BLAZE',2,'',1,0,1,0;
 		*/
	--

 		end if;

 	    for l_file_group in (select distinct file_group from compliance.blaze_d_entity_cat where imid = l_mpid  and coalesce(cat_submitter_imid,'') not in ('NONE',''))
 	    loop
 	        select count(1) into l_cnt from COMPLIANCE.CAT_REPORT where client_mpid = l_mpid and file_group = l_file_group;
 	    	if l_cnt = 0
 	    	then
 	    		 insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    	 	--select coalesce(nullif(l_crd_number,''),'104031')||'_'||l_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_2c'||l_file_group||'_OrderEvents_'||'000001'||'.csv',
 		    	 	select coalesce(nullif(l_crd_number,''),'104031')||'_'||l_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||l_file_group||'_OrderEvents_'||'000001'||'.csv',
 		   		  			l_mpid,l_file_group,2,'',1,0,1,0;
  			end if;
		end loop;

    end loop;

	------------------------------------------------------------------------------

	OPEN rs FOR
	/*
		select FILE_NAME, ROE from
		(select *
		from COMPLIANCE.CAT_REPORT
		union all
		select *
		from COMPLIANCE.CAT_REPORT_2C) T
		order by FILE_NAME, ROE_NUMBER;
	*/
		select file_name, roe
		from compliance.cat_report
		where roe is not null
		order by file_name, roe_number;

	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_blaze_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_blaze_cat_report_2c_table(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_blaze_cat_report_2c_table(in_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

  size_limit bigint;
  min_total_size bigint;
  min_client_roe_number bigint;
  max_client_roe_number bigint;
  client_total_size bigint;
  mpid varchar;

  l_file_group varchar;
  l_cnt bigint;
  l_crd_number varchar;

  l_file_shift int;
begin

    l_file_shift := 0;

    truncate table  compliance.cat_report;
    update compliance.blaze_d_entity_cat set account_holder_type = '' where account_holder_type = ' ';
    update compliance.blaze_client_order set user_acc_holder_type = '' where user_acc_holder_type = ' ' and date_id = to_char(in_date,'YYYYMMDD')::int;

    --to do: add child order records
    --loop by client_mpid
    --for mpid in (select distinct cl.broker_dealer_mpid from compliance.blaze_client_order cl where cl.date_id = to_char(in_date,'YYYYMMDD')::int)
    --for mpid in (select distinct broker_dealer_mpid from compliance.blaze_trading_firm )
    for mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    loop
		perform compliance.insert_moir_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mono_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_mooa_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mooc_record_2(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moom_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moor_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    	perform compliance.insert_moor_sor2exch_record_2(mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_moco_record(mpid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_meir_record(mpid,to_char(in_date,'YYYYMMDD')::int);
  		perform compliance.insert_meim_record(mpid,to_char(in_date,'YYYYMMDD')::int);
   		perform compliance.insert_meic_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meno_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meoa_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meoc_record_2(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meom_record(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meor_sor2exch_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_synt_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_meco_record(mpid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_meno_tts_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meoa_tts_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meom_tts_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meoc_tts_record_2(mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meor_tts_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);

    end loop;

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    for mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))

    --loop by client_mpid
    loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = mpid;

		update compliance.cat_report
		set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
		where client_mpid = mpid;

	    select max(crd_number) into l_crd_number from compliance.blaze_d_entity_cat where imid = mpid;

		update compliance.cat_report
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_2c'||coalesce(file_group,'BLAZE')||'_OrderEvents_'||lpad(coalesce(roe_file_number+l_file_shift,1+l_file_shift)::varchar, 6, '0')||'.csv'
	        where client_mpid = mpid;

 	    for l_file_group in (select distinct file_group from compliance.blaze_d_entity_cat where imid = mpid  and coalesce(cat_submitter_imid,'') not in ('NONE',''))
 	    loop
 	        select count(1) into l_cnt from compliance.cat_report where client_mpid = mpid and file_group = l_file_group;
 	    	if l_cnt = 0
 	    	then
 	    		insert into compliance.cat_report (file_name, client_mpid, file_group, order_ind, roe, roe_number, roe_size, roe_file_number,total_size)
 		    	 	select coalesce(nullif(l_crd_number,''),'104031')||'_'||mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_2c'||l_file_group||'_OrderEvents_'||lpad((1+l_file_shift)::varchar, 6, '0')||'.csv',
 		   		  			mpid,l_file_group,2,'',1,0,1,0;
  			end if;
		end loop;

    end loop;


  	delete from compliance.cat_report_2c
    where true;

 	insert into compliance.cat_report_2c
 	select *
   	from compliance.cat_report;
	------------------------------------------------------------------------------



end;$$;


ALTER FUNCTION compliance.get_blaze_cat_report_2c_table(in_date date) OWNER TO dwh;

--
-- Name: get_blaze_cat_report_2d(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_blaze_cat_report_2d(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  l_mpid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin


    truncate table  compliance.cat_report;
    --to do: add child order records
    --loop by client_mpid

    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    loop


	    perform compliance.insert_meno_record_2d(l_mpid,to_char(in_date,'YYYYMMDD')::int);

    end loop;

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    --loop by client_mpid

    loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = l_mpid;

		if client_total_size > 0 then
			update compliance.cat_report
			set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
			where client_mpid = l_mpid;
	    end if;


	    select max(crd_number) into l_crd_number from compliance.blaze_d_entity_cat where imid = l_mpid;

	    if client_total_size > 0 then
		    update compliance.cat_report
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||coalesce(file_group,'BLAZE')||'_OrderEvents_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv'
	        where client_mpid = l_mpid;
	    /*
 		else
 		    insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    select coalesce(nullif(l_crd_number,''),'104031')||'_'||mpid||'_'||to_char(current_date-1, 'YYYYMMDD')||'_'||'BLAZE'||'_OrderEvents_'||'000001'||'.csv',
 		   		   mpid,'BLAZE',2,'',1,0,1,0;
 		*/
 		end if;

 	    for l_file_group in (select distinct file_group from compliance.blaze_d_entity_cat where imid = l_mpid  and coalesce(cat_submitter_imid,'') not in ('NONE',''))
 	    loop
 	        select count(1) into l_cnt from COMPLIANCE.CAT_REPORT where client_mpid = l_mpid and file_group = l_file_group;
 	    	if l_cnt = 0
 	    	then
 	    		 insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    	 	select coalesce(nullif(l_crd_number,''),'104031')||'_'||l_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||l_file_group||'_OrderEvents_'||'000001'||'.csv',
 		   		  			l_mpid,l_file_group,2,'',1,0,1,0;
  			end if;
		end loop;

    end loop;

	------------------------------------------------------------------------------

	OPEN rs FOR
	/*
		select FILE_NAME, ROE from
		(select *
		from COMPLIANCE.CAT_REPORT
		union all
		select *
		from COMPLIANCE.CAT_REPORT_2C) T
		order by FILE_NAME, ROE_NUMBER;
	*/
		select file_name, roe
		from compliance.cat_report
		where roe is not null
		order by file_name, roe_number;

	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_blaze_cat_report_2d(in_date date) OWNER TO dwh;

--
-- Name: get_blaze_first_orig(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_blaze_first_orig(in_order_id character varying, in_date_id integer, OUT out_orig_order_id character varying, OUT out_date_id integer) RETURNS record
    LANGUAGE plpgsql
    AS $$


begin

  with recursive orig as(

	select order_id, cancel_order_id, leg_number, date_id, 1 as level
	    from compliance.blaze_client_order
	    where order_id = in_order_id
	    and leg_number = 1
	    and date_id  = in_date_id
	    union all

	    select r.order_id, e.cancel_order_id, e.leg_number, e.date_id, r.level + 1
	    from compliance.blaze_client_order e
	    join orig r on r.cancel_order_id = e.order_id  and r.leg_number = e.leg_number and (e.time_in_force = 'GTC' or e.date_id = r.date_id)
	    where e.cancel_order_id <> '00000000-0000-0000-0000-000000000000'

	)

	select cancel_order_id, date_id from (
	select r.cancel_order_id,
		   r.date_id, level, max(level) over (partition by r.order_id) as maxlevel
	from orig r
	) t
	where level = maxlevel
	into out_orig_order_id, out_date_id;


end;
$$;


ALTER FUNCTION compliance.get_blaze_first_orig(in_order_id character varying, in_date_id integer, OUT out_orig_order_id character varying, OUT out_date_id integer) OWNER TO dwh;

--
-- Name: get_blaze_underlying_count(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_blaze_underlying_count(in_order_id character varying, in_date_id integer) RETURNS smallint
    LANGUAGE plpgsql
    AS $$

declare
begin
return
	(
		select count(distinct cl.symbol)
		from compliance.blaze_client_order cl
		where cl.date_id = in_date_id
		and cl.order_id = in_order_id
	);

end;
$$;


ALTER FUNCTION compliance.get_blaze_underlying_count(in_order_id character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_cat_report(in_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit bigint;
  min_total_size bigint;
  min_client_roe_number bigint;
  max_client_roe_number bigint;
  client_total_size bigint;
  l_mpid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin


    truncate table  compliance.cat_report;
    --to do: add child order records
    --loop by client_mpid
    --for mpid in (select distinct cl.broker_dealer_mpid from compliance.blaze_trading_firm cl /*where cl.broker_dealer_mpid = 'GFIS'*/)
    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    loop

    	--perform compliance.insert_meof_repr_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    	perform compliance.insert_mlno_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

    /*
		perform compliance.insert_moir_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mono_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mooc_record_2(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moom_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_moor_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    	perform compliance.insert_moor_sor2exch_record_2(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_mooa_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_moco_record(mpid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_meir_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meim_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meic_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meno_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meno_tts_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
 	    perform compliance.insert_meoa_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meoa_tts_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meoc_record_2(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meoc_tts_record_2(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meom_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	    perform compliance.insert_meom_tts_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_tts_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_sor2exch_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_meor_synt_record_2c(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_meco_record(mpid,to_char(in_date,'YYYYMMDD')::int);

	*/
    end loop;

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    --loop by client_mpid

    loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = l_mpid;

		if client_total_size > 0 then
			update compliance.cat_report
			set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
			where client_mpid = l_mpid;
	    end if;


	    select max(crd_number) into l_crd_number from compliance.blaze_d_entity_cat where imid = l_mpid;

	    if client_total_size > 0 then
		    update compliance.cat_report
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(current_date-1, 'YYYYMMDD')||'_'||coalesce(file_group,'BLAZE')||'_OrderEvents_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv'
	        where client_mpid = l_mpid;
	    /*
 		else
 		    insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    select coalesce(nullif(l_crd_number,''),'104031')||'_'||mpid||'_'||to_char(current_date-1, 'YYYYMMDD')||'_'||'BLAZE'||'_OrderEvents_'||'000001'||'.csv',
 		   		   mpid,'BLAZE',2,'',1,0,1,0;
 		*/
 		end if;

 	    for l_file_group in (select distinct file_group from compliance.blaze_d_entity_cat where imid = l_mpid  and coalesce(cat_submitter_imid,'') not in ('NONE',''))
 	    loop
 	        select count(1) into l_cnt from COMPLIANCE.CAT_REPORT where client_mpid = l_mpid and file_group = l_file_group;
 	    	if l_cnt = 0
 	    	then
 	    		 insert into COMPLIANCE.CAT_REPORT (FILE_NAME, CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, ROE_FILE_NUMBER,TOTAL_SIZE)
 		    	 	select coalesce(nullif(l_crd_number,''),'104031')||'_'||l_mpid||'_'||to_char(current_date-1, 'YYYYMMDD')||'_'||l_file_group||'_OrderEvents_'||'000001'||'.csv',
 		   		  			l_mpid,l_file_group,2,'',1,0,1,0;
  			end if;
		end loop;

    end loop;



end;$$;


ALTER FUNCTION compliance.get_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_config_5_manual_flag(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_config_5_manual_flag(in_order_id character varying, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;
begin

  res = '';
  select
  	case
  		when coalesce(cl.client_event_type_id_1,0) = 2 and coalesce(cl.client_event_type_id_2,0) = 0 and cl.child_orders = 0 and upper(cl.system_name) = 'BLAZE' and exm.report_id is null then 'COM'
  		when coalesce(cl.client_event_type_id_1,0) = 2 and coalesce(cl.client_event_type_id_2,0) = 0 and cl.child_orders = 0 and upper(cl.system_name) = 'BLAZE7' and exm.report_id is null then 'DEST'
		when coalesce(cl.client_event_type_id_2,0) = 4 and cl.aors_destination is null and cl.child_orders = 0 and coalesce(cl.obo_user,'') is not null and exm.report_id is null then 'DEST'
		else 'NO'
	end
  into res
	from compliance.blaze_client_order cl
	left join lateral
			(select exc.report_id
			 from compliance.blaze_execution exc
			 where cl.order_id = exc.order_id
				and exc.leg_number = cl.leg_number
				and exc.report_id = exc.child_report_id
				and lower(exc.exchange_transaction_id) like '%manual%'
				and lower(exc.status) like '%fill%'
				and exc.sent_to_broker <> 'NOREPORT'
				limit 1
			) exm on true

	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = 1
	limit 1;
  return res;
end;
$$;


ALTER FUNCTION compliance.get_config_5_manual_flag(in_order_id character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_custom_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_custom_cat_report(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  l_mpid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin

    truncate table  compliance.cat_report;

    l_mpid := 'CTTD';
    l_crd_number := '104031';
	------------------------------------------------------------------------------
	for l_mpid in (select client_imid from compliance.custom_client_imid)
    --loop by client_mpid
    loop

		perform compliance.insert_cust_atlas_mono_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_cust_atlas_mlno_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_cust_atlas_moor_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_cust_atlas_mlor_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

    end loop;


	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    for l_mpid in (select client_imid from compliance.custom_client_imid)
    --loop by client_mpid

    loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = l_mpid;

		if client_total_size > 0 then
			update compliance.cat_report
			set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
			where client_mpid = l_mpid;
	    end if;


	    if client_total_size > 0 then
		    update compliance.cat_report
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||coalesce(file_group,'TEST')||'_OrderEvents_'||lpad((roe_file_number+1)::varchar, 6, '0')||'.csv'
	        where client_mpid = l_mpid;

 		end if;

    end loop;

	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		order by coalesce(file_group,'TEST'), ROE_NUMBER;
		--select 'test_file_name','roe';
	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_custom_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_custom_field(character varying, character varying, integer, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_custom_field(in_config_id character varying, in_order_id character varying, in_leg_num integer, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;
begin

  res = '';
  select
  	case
		when in_config_id like '%3%' then coalesce(',TraderID='||cl.sending_user,'')
		when in_config_id like '%1%' then coalesce(',ACCT='||cl.account,'')
		when in_config_id like '%2%' then coalesce(',ACCT='||cl.sub_account,'')||
						 			 --coalesce(',IBDRECEIVETIME='||cl.date_id::varchar||lpad(coalesce(nullif(cl.sub_account_3,''),'235959'),6,'0'),'')||
									 coalesce(',IBDRECEIVETIME='||to_char(coalesce(cl.order_event_time,cl.create_date_time),'YYYYMMDDHH24MISS'),'')||
						 			 coalesce(',USER='||cl.user_login,'')

		--when in_config_id = '2' then coalesce(',ACCT='||cl.sub_account,'')||coalesce(',IBDRECEIVETIME='||cl.date_id::varchar||to_char(cl.create_date_time,'HH24MISS'),'')
		when in_config_id like '%4%' then coalesce(',TraderID='||cl.sending_user,'')||coalesce(',ACCT='||cl.account,'')
		else ''
	end
  into res
	from compliance.blaze_client_order cl
	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = in_leg_num;
  return res;
end;
$$;


ALTER FUNCTION compliance.get_custom_field(in_config_id character varying, in_order_id character varying, in_leg_num integer, in_date_id integer) OWNER TO dwh;

--
-- Name: get_eq_sor_trading_session(bigint, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_eq_sor_trading_session(in_order_id bigint, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;

begin

  res = '';

  select
  	case

  	    when cl.cross_order_id is not null or cl.multileg_reporting_type = '2' then 'REG'
  		when cl.time_in_force_id = 'M' then 'ALL'
  		when cl.time_in_force_id in ('1','2','C','7') then 'REG'
  		when cl.time_in_force_id = '6' then 'REGPOST'
  		when to_char(cl.process_time,'HH24:MI:SS:MS') < '09:30:00:000' then
  			case
  			 when cl.time_in_force_id in ('3','4') then 'PRE'
  			 when cl.time_in_force_id in ('0','5') and to_char(cl.algo_end_time,'HH24:MI:SS:MS') <= '09:30:00:000' then 'PRE'
  			 when cl.time_in_force_id = '0' and coalesce(to_char(cl.algo_start_time,'HH24:MI:SS:MS'),'09:00:00:000') < '09:30:00:000' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') > '16:00:00:000' then 'ALL'
  			 when cl.time_in_force_id = '5' and coalesce(to_char(cl.algo_start_time,'HH24:MI:SS:MS'),'09:00:00:000') < '09:30:00:000' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'20:00:00:000') > '16:00:00:000' then 'ALL'
  			 --
  			 when cl.time_in_force_id = '5' and coalesce(to_char(cl.algo_start_time,'HH24:MI:SS:MS'),'09:00:00:000') < '09:30:00:000' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') > '09:30:00:000' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') <= '16:00:00:000' then 'PREREG'
  			 when cl.time_in_force_id = '0' and coalesce(to_char(cl.algo_start_time,'HH24:MI:SS:MS'),'09:00:00:000') < '09:30:00:000'
  			 								and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') > '09:30:00:000' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') <= '16:00:00:000'
  			 								and coalesce(dts.target_strategy_group_id,0) not in (2,101) then 'PREREG'
  			 when cl.time_in_force_id = '0' and coalesce(to_char(cl.algo_start_time,'HH24:MI:SS:MS'),'09:00:00:000') < '09:30:00:000'
  			 								and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') > '09:30:00:000' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') <= '16:00:00:000'
  			 								and coalesce(dts.target_strategy_group_id,0) in (2,101) then 'REG'
  			 --
  			 when cl.time_in_force_id = '5' and to_char(cl.algo_start_time,'HH24:MI:SS:MS') >= '09:30:00:000' and to_char(cl.algo_start_time,'HH24:MI:SS:MS')  <= '16:00:00:000' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '0' and to_char(cl.algo_start_time,'HH24:MI:SS:MS') >= '09:30:00:000' and to_char(cl.algo_start_time,'HH24:MI:SS:MS')  <= '16:00:00:000' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') <= '16:00:00:000' then 'REG'
  			 --
  			 when cl.time_in_force_id = '5' and to_char(cl.algo_start_time,'HH24:MI:SS:MS') >= '09:30:00:000' and to_char(cl.algo_start_time,'HH24:MI:SS:MS')  <= '16:00:00:000' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'20:00:00:000') > '16:00:00:000' then 'REGPOST'
  			 when cl.time_in_force_id = '0' and to_char(cl.algo_start_time,'HH24:MI:SS:MS') >= '09:30:00:000' and to_char(cl.algo_start_time,'HH24:MI:SS:MS')  <= '16:00:00:000' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') > '16:00:00:000' then 'REGPOST'
  			 --
  			 else 'REG'
  			end
  		when to_char(cl.process_time,'HH24:MI:SS:MS') >= '09:30:00:000' and  to_char(cl.process_time,'HH24:MI:SS:MS') < '16:00:00:000' then
  			case
  			 when cl.time_in_force_id  in ('3','4') then 'REG'
  			 when cl.time_in_force_id = '5' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '0' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'16:00:00:000') <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '5' and coalesce(to_char(cl.algo_end_time,'HH24:MI:SS:MS'),'20:00:00:000') > '16:00:00:000' then 'REGPOST'
  			 when cl.time_in_force_id = '0' and to_char(cl.algo_end_time,'HH24:MI:SS:MS') > '16:00:00:000' then 'REGPOST'
  			 else 'REG'
  			end
  		when to_char(cl.process_time,'HH24:MI:SS:MS') >= '16:00:00:000' --and cl.time_in_force_id in ('0','3','4','5')
  			then 'POST'
    end
  into res
  from client_order cl
  left join d_target_strategy dts  on (dts.target_strategy_name = cl.sub_strategy_desc)
  where cl.create_date_id = in_date_id
    and cl.order_id = in_order_id
  limit 1
  ;

  return res;
end;
$$;


ALTER FUNCTION compliance.get_eq_sor_trading_session(in_order_id bigint, in_date_id integer) OWNER TO dwh;

--
-- Name: get_file_group(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_file_group(in_dcom_file_group character varying, in_com_file_group character varying, in_dcom_config_id character varying, in_com_config_id character varying, in_order_id character varying, in_message_category character varying, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;
  l_default_file_group varchar;
  l_file_group varchar;
  l_config_id varchar;
  l_system_name varchar;
  l_client_event_type_id_1 int;
  l_client_event_type_id_2 int;
  l_child_orders int;
  l_aors_destination varchar;
  l_child_aors_destination varchar;
begin

  res = '';
  l_default_file_group = '';
  l_config_id = '';

  select cl.client_event_type_id_1, cl.client_event_type_id_2, upper(cl.system_name), cl.child_orders, cl.aors_destination, chld.aors_destination
  into l_client_event_type_id_1, l_client_event_type_id_2, l_system_name, l_child_orders, l_aors_destination, l_child_aors_destination
  from compliance.blaze_client_order cl
	left join compliance.blaze_client_order chld on chld.parent_order_id = cl.order_id and cl.leg_number = 1
	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = 1;


  if in_message_category = 'NEW' then
  begin
	if l_client_event_type_id_1 = 1 or l_client_event_type_id_2 = 4 or l_system_name = 'BLAZE7'
		then
			begin
				l_default_file_group = coalesce(in_dcom_file_group, in_com_file_group);
		    	l_config_id = coalesce(in_dcom_config_id, in_com_config_id);
			end;
		else
			begin
				l_default_file_group = in_com_file_group;
				l_config_id = in_com_config_id;
			end;
	end if;
	if l_config_id not like '%6%'
		then l_file_group = l_default_file_group;
		else
			if l_child_orders = 0
			then
				if l_aors_destination like '%DASH%'
					then l_file_group = 'BLAZEDFIN';
					else l_file_group = l_default_file_group;
				end if;
			else
				if l_child_aors_destination like '%DASH%'
					then l_file_group = 'BLAZEDFIN';
					else l_file_group = l_default_file_group;
				end if;
			end if;
	end if;
  end;
  end if;

  if in_message_category = 'ROUTE' then
  begin
	if (l_client_event_type_id_2 = 3 and l_system_name = 'BLAZE7') or l_client_event_type_id_2 = 4
		then
			begin
				l_default_file_group = in_dcom_file_group;
		    	l_config_id = in_dcom_config_id;
			end;
	 	else
			begin
				l_default_file_group = in_com_file_group;
				l_config_id = in_com_config_id;
			end;
	end if;
	if l_config_id not like '%6%'
		then l_file_group = l_default_file_group;
		else
			if l_aors_destination like '%DASH%'
				then l_file_group = 'BLAZEDFIN';
				else l_file_group = l_default_file_group;
			end if;
	end if;
  end;
  end if;


  if in_message_category = 'INTERNAL' then
  begin
	if l_client_event_type_id_1 in (1,6)
		then
			begin
				l_default_file_group = coalesce(in_dcom_file_group, in_com_file_group);
		    	l_config_id = coalesce(in_dcom_config_id, in_com_config_id);
			end;
		else
			begin
				l_default_file_group = in_com_file_group;
				l_config_id = in_com_config_id;
			end;
	end if;
	if l_config_id not like '%6%'
		then l_file_group = l_default_file_group;
		else
			if l_child_orders = 0
			then
				if l_aors_destination like '%DASH%'
					then l_file_group = 'BLAZEDFIN';
					else l_file_group = l_default_file_group;
				end if;
			else
				if l_child_aors_destination like '%DASH%'
					then l_file_group = 'BLAZEDFIN';
					else l_file_group = l_default_file_group;
				end if;
			end if;
	end if;
  end;
  end if;


  res = l_file_group;
  return res;

end;
$$;


ALTER FUNCTION compliance.get_file_group(in_dcom_file_group character varying, in_com_file_group character varying, in_dcom_config_id character varying, in_com_config_id character varying, in_order_id character varying, in_message_category character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_handl_inst(character varying, integer, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_handl_inst(in_order_id character varying, in_leg_num integer, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;

  is_aon  varchar;
  is_dnrt varchar;
  is_fok  varchar;
  is_loc  varchar;
  is_loo  varchar;
  is_moc  varchar;
  is_moo  varchar;
  is_nh   varchar;
  is_opt  varchar;
  is_stp  varchar;
  is_rsv  varchar;
  is_disq varchar;
begin

  res = '';
  select case when cl.is_all_or_none = 'Y' then 'AON' end,
  		 case when cl.exec_inst = 'n' then 'DNRT' end,
  		 case when cl.exec_inst = '1' then 'NH' end,
  		 case when cl.time_in_force = 'FOK' then 'FOK' end,
  		 case when cl.time_in_force = 'CLO' and cl.order_type = 'Limit' then 'LOC' end,
  		 case when cl.time_in_force = 'CLO' and cl.order_type = 'Market' then 'MOC' end,
  		 case when cl.time_in_force in ('OPG','SLO') and cl.order_type = 'Limit' then 'LOO' end,
  		 case when cl.time_in_force in ('OPG','SLO') and cl.order_type = 'Market' then 'MOO'end,
  		 case when cl.leg_count > 1 and cl.instrument_type_id = 'E' then 'OPT' end,
  		 case when upper(cl.order_type) in ('STOP','STOP LIMIT') then 'STOP='||to_char(cl.stop_price, 'FM9999999990.09999999') end,
  		 case when cl.max_display_qty > 0 then 'RSV' end,
  		 case when cl.max_display_qty > 0 then 'DISQ='||cl.max_display_qty::varchar end
    into is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_disq
	from compliance.blaze_client_order cl
	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = in_leg_num;


  res =  concat_ws('|',is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_disq);
  return res;
end;
$$;


ALTER FUNCTION compliance.get_handl_inst(in_order_id character varying, in_leg_num integer, in_date_id integer) OWNER TO dwh;

--
-- Name: get_handl_inst_2c(character varying, integer, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_handl_inst_2c(in_order_id character varying, in_leg_num integer, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;

  is_aon  varchar;
  is_dnrt varchar;
  is_fok  varchar;
  is_loc  varchar;
  is_loo  varchar;
  is_moc  varchar;
  is_moo  varchar;
  is_nh   varchar;
  is_opt  varchar;
  is_stp  varchar;
  is_rsv  varchar;
  is_disq varchar;
 --
  is_d varchar;
  is_dir varchar;
  is_ovd varchar;
  is_peg varchar;
  is_idx varchar;
begin

  res = '';
  select case when cl.is_all_or_none = 'Y' then 'AON' end,
  		 case when cl.exec_inst = 'n' then 'DNRT' end,
  		 case when (cl.exec_inst = '1' or cl.is_not_held = 'Y') then 'NH' end,
  		 case when cl.time_in_force = 'FOK' then 'FOK' end,
  		 case when cl.time_in_force = 'CLO' and cl.order_type = 'Limit' then 'LOC' end,
  		 case when cl.time_in_force = 'CLO' and cl.order_type = 'Market' then 'MOC' end,
  		 case when cl.time_in_force in ('OPG','SLO') and cl.order_type = 'Limit' then 'LOO' end,
  		 case when cl.time_in_force in ('OPG','SLO') and cl.order_type = 'Market' then 'MOO'end,
  		 case when cl.leg_count > 1 and cl.instrument_type_id = 'E' and 1 = 2 then 'OPT' end,
  		 case when upper(cl.order_type) in ('STOP','STOP LIMIT') then 'STOP='||to_char(cl.stop_price, 'FM9999999990.09999999') end,
  		 case when cl.max_display_qty > 0 then 'RSV' end,
  		 case when cl.max_display_qty > 0 then 'DISQ='||cl.max_display_qty::varchar end,
  		 --
  		 case when cl.exec_inst = 'd' then 'd' end,
  		-- case when cl.ex_destination in ('XASE','XPSE','BATO','EDGO','XBOX','C2OX','XCBO','GMNI','XISX','MCRY','XMIO','XNDQ','XBXO','XPHO','MPRL','EMLD') then 'DIR' end,
  		 case when cl.ex_destination in ('TWAP','VWAP') then 'OVD' end,
  		 case when cl.ex_destination in ('SPEG') then 'PEG' end,
  		 case when cl.ex_destination in ('SMTX','SWPX','MSWX') then 'IDX' end

    into is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_disq,is_d,is_ovd,is_peg,is_idx

	from compliance.blaze_client_order cl
	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = in_leg_num
	limit 1
	;


  res =  concat_ws('|',is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_disq,is_d,is_ovd,is_peg,is_idx);
  return res;
end;
$$;


ALTER FUNCTION compliance.get_handl_inst_2c(in_order_id character varying, in_leg_num integer, in_date_id integer) OWNER TO dwh;

--
-- Name: get_leg_details(character varying, integer, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_leg_details(in_order_id character varying, in_leg_count integer, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;

  leg_info varchar;
  leg_num int;

begin

  res = '';
  leg_info = '';

  leg_num := 1;
  while leg_num <= in_leg_count loop

		select leg_num::varchar||'@'||
			   case
			   		when cl.instrument_type_id = 'E' then
			   			replace(replace(cl.symbol,'.',' '),'/',' ')
			  	 	else ''
			   end||'@'||
			   case
			   		when cl.instrument_type_id = 'O' then
			   		replace(replace(cl.osi_symbol,'.',' '),'/',' ')
			   		else ''
			   end||'@'||
			   case
			   		when cl.instrument_type_id = 'E' then ''
			  		when cl.open_close = 'C' then 'Close'
			  		when cl.open_close = 'O' then 'Open'
			  		else ''
			   end||'@'||
			   case cl.side
			    	when '1' then 'B'
			    	when '2' then 'SL'
			    	when '5' then 'SS'
			    	when '6' then 'SX'
			    	else 'B'
			    end||'@'||--side
			    cl.ratio

		into leg_info

		from compliance.blaze_client_order cl
		where cl.date_id = in_date_id
		and cl.order_id = in_order_id
		and cl.leg_number = leg_num
		limit 1
			;
  		leg_num := leg_num+1;

  		if res = '' then
			res := leg_info;
			else res :=  res||'|'||leg_info;
  		end if;

  end loop;

  return res;
end;
$$;


ALTER FUNCTION compliance.get_leg_details(in_order_id character varying, in_leg_count integer, in_date_id integer) OWNER TO dwh;

--
-- Name: get_obo_cat_report_2d_table(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_obo_cat_report_2d_table(in_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  --rs refcursor;
  l_size_limit bigint;
  l_min_total_size bigint;
  l_min_client_roe_number bigint;
  l_max_client_roe_number bigint;
  l_client_total_size bigint;
  l_imid varchar;
  l_crd_number varchar;

  l_load_id int8;
  l_step_id int;
begin


    select nextval('load_timing_seq') into l_load_id;
      l_step_id:=1;
    select public.load_log(l_load_id, l_step_id, 'compliance.get_obo_cat_report_2d_table STARTED ===', 0, 'O')
      into l_step_id;


    l_crd_number := '104031';

    truncate table  compliance.cat_report;

    for l_imid in (select distinct cat_imid
    				from d_trading_firm
    				where cat_report_on_behalf_of = 'Y'
    				--and cat_imid = 'BELV'
    				)
    loop

    --


    	perform compliance.insert_sor_obo_meno_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meoa_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meoc_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meom_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_sor_obo_meor_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_memr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mecr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_sor_obo_mono_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mooa_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mooc_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_moom_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_moor_record_2d(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_momr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mocr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_sor_obo_mlno_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mloa_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mlom_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
  		perform compliance.insert_sor_obo_mloc_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
  		perform compliance.insert_sor_obo_mlor_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
  		perform compliance.insert_sor_obo_mlmr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
  		perform compliance.insert_sor_obo_mlcr_record(l_imid,to_char(in_date,'YYYYMMDD')::int);



    end loop;

	l_size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    for l_imid in (select distinct cat_imid
    				from d_trading_firm
    				where cat_report_on_behalf_of = 'Y'
    				--and cat_imid = 'BELV'
    				)

    --loop by client_mpid
    loop
    	select min(roe_number) into l_min_client_roe_number from compliance.cat_report where client_mpid = l_imid;
		select max(roe_number) into l_max_client_roe_number from compliance.cat_report where client_mpid = l_imid;
		select total_size - roe_size into l_min_total_size from compliance.cat_report where roe_number = l_min_client_roe_number;
		select sum(roe_size) into l_client_total_size from compliance.cat_report where client_mpid = l_imid;

		update compliance.cat_report
		set roe_file_number = trunc((total_size - l_min_total_size) /l_size_limit) + 1
		where client_mpid = l_imid;

	    if l_imid = 'BELV'
	    	then l_crd_number := '132605';
	    	else l_crd_number := '104031';
		end if;

 		update compliance.cat_report
	    set file_name = l_crd_number||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||coalesce(file_group,'SOR')||'_OrderEvents_'||lpad(coalesce(roe_file_number,1)::varchar, 6, '0')||'.csv'
	    --
	    where client_mpid = l_imid;



	    if coalesce(l_client_total_size,0) = 0 and l_imid <> 'MYDM' then
	   		insert into compliance.cat_report (file_name, client_mpid, file_group, order_ind, roe, roe_number, roe_size, roe_file_number, total_size)
 		    	 	select l_crd_number||'_'||l_imid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||'SOR'||'_OrderEvents_'||'000001'||'.csv',
 		   		  			l_imid, 'SOR', 2, '', 1, 0, 1, 0;
	    end if;


    end loop;


	------------------------------------------------------------------------------
   select public.load_log(l_load_id, l_step_id, 'compliance.get_obo_cat_report_2d_table COMPLETED  =====', 0, 'O')
      into l_step_id;



end;$$;


ALTER FUNCTION compliance.get_obo_cat_report_2d_table(in_date date) OWNER TO dwh;

--
-- Name: get_pairs_obo_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_pairs_obo_cat_report(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  l_mpid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin


    truncate table  compliance.cat_report;
	l_mpid := 'MYDM';
    l_crd_number := '104031';
	------------------------------------------------------------------------------
	/*
	for l_mpid in (select client_imid from compliance.custom_client_imid)
    --loop by client_mpid
    loop


    end loop;
    */

    perform compliance.insert_pair_obo_meno_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_pair_obo_meom_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_pair_obo_meoc_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_pair_obo_meor_record(l_mpid,to_char(in_date,'YYYYMMDD')::int);

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000


    --for l_mpid in (select distinct imid from compliance.blaze_d_entity_cat where coalesce(imid,'') not in ('NONE','') and coalesce(cat_submitter_imid,'') not in ('NONE',''))
    --loop by client_mpid

    --for l_mpid in (select client_imid from compliance.custom_client_imid)
    --loop by client_mpid

    --loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where client_mpid = l_mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where client_mpid = l_mpid;

		if client_total_size > 0 then
			update compliance.cat_report
			set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
			where client_mpid = l_mpid;
	    end if;


	    if client_total_size > 0 then
		    update compliance.cat_report
	        set file_name = coalesce(nullif(l_crd_number,''),'104031')||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_2c'||coalesce(file_group,'PAIRS')||'_OrderEvents_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv'
	        where client_mpid = l_mpid;

 		end if;

    --end loop;

	------------------------------------------------------------------------------

	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		order by coalesce(file_group,'PAIRS'), ROE_NUMBER;
	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_pairs_obo_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_pending(character varying, integer, character varying, character varying); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_pending(in_order_id character varying, in_date_id integer, in_dest_config character varying, in_com_config character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  v_conf varchar;
  res varchar;
begin
  v_conf = '';
  res = '';
  select
  	case
		 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(in_dest_config,in_com_config,'')
		 else coalesce(in_com_config,'')
	end
  into v_conf
	from compliance.blaze_client_order cl
	where cl.date_id = in_date_id
	and cl.order_id = in_order_id
	and cl.leg_number = 1
	limit 1;


  select case when v_conf like '%7%' then '' else 'PENDING' end into res;

  return res;
end;
$$;


ALTER FUNCTION compliance.get_pending(in_order_id character varying, in_date_id integer, in_dest_config character varying, in_com_config character varying) OWNER TO dwh;

--
-- Name: get_represented_orders(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_represented_orders(in_order_id character varying, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;
begin

  res = '';

  select string_agg(
  		  case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		  end||'@'||
		  to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||'@'||
		  case
		  	when cl.leg_count = 1 then cl.order_qty
		  	else cl.complex_qty
		  end
		  , '|' order by cl.order_id)
	into res

	from compliance.blaze_client_order cl
	where cl.date_id = in_date_id
	and cl.representative_order_id = in_order_id
	and cl.leg_number = 1
	group by cl.representative_order_id
	limit 1;

  return res;
end;
$$;


ALTER FUNCTION compliance.get_represented_orders(in_order_id character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_sender_imid(character varying, character varying); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sender_imid(in_cat_imid character varying, in_cat_mpid character varying) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    RETURN (compliance.get_crd_number(in_cat_imid)||':'||in_cat_mpid);
END;
$$;


ALTER FUNCTION compliance.get_sender_imid(in_cat_imid character varying, in_cat_mpid character varying) OWNER TO dwh;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: sor_cat_in_sender_imid_config; Type: TABLE; Schema: compliance; Owner: dwh
--

CREATE TABLE compliance.sor_cat_in_sender_imid_config (
    id integer NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    config_sub_type character varying(255),
    effective_date date DEFAULT '2023-01-01'::date,
    fix_comp_id character varying(255),
    fix_tag integer,
    imid_source character varying(255),
    trading_firm_id character varying(255),
    with_obo boolean DEFAULT false NOT NULL,
    description character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE compliance.sor_cat_in_sender_imid_config OWNER TO dwh;

--
-- Name: get_sor_cat_in_sender_imid_config(bigint); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_cat_in_sender_imid_config(id_arg bigint DEFAULT NULL::bigint) RETURNS TABLE(result_record compliance.sor_cat_in_sender_imid_config)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM compliance.sor_cat_in_sender_imid_config c
    WHERE c.is_deleted = false AND (id_arg IS NULL OR c.id = id_arg);
END;
$$;


ALTER FUNCTION compliance.get_sor_cat_in_sender_imid_config(id_arg bigint) OWNER TO dwh;

--
-- Name: sor_cat_out_sender_imid_config; Type: TABLE; Schema: compliance; Owner: dwh
--

CREATE TABLE compliance.sor_cat_out_sender_imid_config (
    id integer NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    config_sub_type character varying(255),
    effective_date date DEFAULT '2023-01-01'::date,
    exchange_id character varying(255) NOT NULL,
    account_name character varying(255),
    fix_comp_id character varying(255),
    fix_tag integer,
    fix_value character varying(255),
    collect_first_tag_arr integer[],
    "default" character varying(255),
    imid_source character varying(255),
    description character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE compliance.sor_cat_out_sender_imid_config OWNER TO dwh;

--
-- Name: get_sor_cat_out_sender_imid_config(bigint); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_cat_out_sender_imid_config(id_arg bigint DEFAULT NULL::bigint) RETURNS TABLE(result_record compliance.sor_cat_out_sender_imid_config)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM compliance.sor_cat_out_sender_imid_config c
    WHERE c.is_deleted = false AND (id_arg IS NULL OR c.id = id_arg);
END;
$$;


ALTER FUNCTION compliance.get_sor_cat_out_sender_imid_config(id_arg bigint) OWNER TO dwh;

--
-- Name: get_sor_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_cat_report(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  mpid varchar;
  l_file_group varchar[];
  j int;
begin


    truncate table  compliance.cat_report;

    mpid := 'DFIN';
    l_file_group[1] := 'ATLASOPTIN';
 	l_file_group[2] := 'ATLASOPTOUT';
 	l_file_group[3] := 'ATLASEQIN';
 	l_file_group[4] := 'ATLASEQOUT';


 	perform compliance.insert_sor_mooa_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mono_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moir_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moim_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moic_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mooc_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_moom_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    --opt out
	perform compliance.insert_sor_moor_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_momr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mocr_record(mpid,to_char(in_date,'YYYYMMDD')::int);

    --eq in

	perform compliance.insert_sor_meoa_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_meno_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meir_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meim_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meic_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);

	perform compliance.insert_sor_meoc_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_meom_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    --eq out
	perform compliance.insert_sor_meor_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_memr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mecr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    --ml
    perform compliance.insert_sor_mlno_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mloa_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlom_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mloc_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlor_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlmr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlcr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlir_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlim_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlic_record(mpid,to_char(in_date,'YYYYMMDD')::int);

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    --for mpid in (select distinct client_mpid from compliance.cat_report)
    j := 1;
    while j < 5 loop

    	select min(roe_number) into min_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select coalesce(total_size,0) - coalesce(roe_size,0) into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;

		--update OATS_REPORT set ROE_FILE_NUMBER = trunc(TOTAL_SIZE/SIZE_LIMIT);
		update compliance.cat_report
		set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
		where file_group = l_file_group[j]; --client_mpid = mpid;

        j := j+1;
    end loop;

	update compliance.cat_report
	set file_name = '104031_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||file_group||'_'||'OrderEvents'||'_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv';


	------------------------------------------------------------------------------

	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		where ROE is not null and FILE_NAME is not null
		order by FILE_NAME, ROE_NUMBER;
	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_sor_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_sor_cat_report_new(date, boolean); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_cat_report_new(in_date date, is_recovery boolean DEFAULT false) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  mpid varchar;
  l_file_group varchar[];
  j int;
  f_date int = to_char(in_date,'YYYYMMDD')::int;
  f_prefix varchar = '';
  l_dblink_name varchar;
  l_cnt           integer;
  l_step_id        integer;
  l_load_id        integer;
  l_sync_act_session_cnt int;
  l_sync_total_session_cnt int;
  scr2            record;
  l_sql varchar;
  is_recovery_str varchar = CASE WHEN is_recovery is true THEN 'true' ELSE 'false' end;

begin
    IF is_recovery IS TRUE THEN
     f_prefix := '_RECOVERED';
    END IF;

    mpid := 'DFIN';
    l_file_group[1] := 'ATLASOPTIN';
 	l_file_group[2] := 'ATLASOPTOUT';
 	l_file_group[3] := 'ATLASEQIN';
 	l_file_group[4] := 'ATLASEQOUT';


   select nextval('public.load_timing_seq') into l_load_id;

  --truncate table start
       l_dblink_name:= 'get_sor_cat_report_new-'||'truncate_table';
       select public.load_log(l_load_id, l_step_id, format('l_dblink_name: %s',l_dblink_name), 0, 'O') into l_step_id;
       perform public.dblink_connect(l_dblink_name,'dbname=big_data user=dwh');
       perform public.dblink_exec(l_dblink_name, 'truncate table compliance.cat_report');
       perform public.dblink_exec(l_dblink_name,'COMMIT;');
       perform public.dblink_disconnect(l_dblink_name);
   --truncate table end

   -- db links for events start
       l_dblink_name:= 'get_sor_cat_report_new-'||'insert_sor_mooa_record_2d_r';
       select public.load_log(l_load_id, l_step_id, format('l_dblink_name: %s',l_dblink_name), 0, 'O') into l_step_id;
       perform public.dblink_connect(l_dblink_name,'dbname=big_data user=dwh');
       l_sql:= format('select compliance.insert_sor_mooa_record_2d_r(%L,%s,%s)', mpid, f_date, is_recovery_str);
       select public.dblink_send_query(l_dblink_name, l_sql) into l_cnt;

       l_dblink_name:= 'get_sor_cat_report_new-'||'insert_sor_mono_record_2d_r';
       select public.load_log(l_load_id, l_step_id, format('l_dblink_name: %s',l_dblink_name), 0, 'O') into l_step_id;
       perform public.dblink_connect(l_dblink_name,'dbname=big_data user=dwh');
       l_sql:= format('select compliance.insert_sor_mono_record_2d_r(%L,%s,%s)', mpid, f_date, is_recovery_str);
       select public.dblink_send_query(l_dblink_name, l_sql) into l_cnt;

       -- cycle for waiting and closing threads
     select sum(public.dblink_is_busy(ss.s)), count(1)
     into l_sync_act_session_cnt, l_sync_total_session_cnt
     from ( select unnest( public.dblink_get_connections() ) s ) ss
     where ss.s like 'get_sor_cat_report_new-%';

  l_cnt:=l_sync_total_session_cnt;

    WHILE l_sync_total_session_cnt>0
    loop
       for scr2 in (select s from (select unnest(public.dblink_get_connections()) s) ss where public.dblink_is_busy(ss.s) = 0  and ss.s like 'get_sor_cat_report_new-%')
       loop
          perform public.dblink_disconnect(scr2.s);
       end loop;

       select sum(public.dblink_is_busy(ss.s)), count(1)
       into l_sync_act_session_cnt, l_sync_total_session_cnt
       from (select unnest(public.dblink_get_connections()) s) ss
       where ss.s like 'get_sor_cat_report_new-%';

      select public.load_log(l_load_id, l_step_id, format('Sessions in progress: %s',l_sync_act_session_cnt), l_sync_total_session_cnt, 'O')
      into l_step_id;
    perform pg_sleep(5);

    end loop;
   --db links for events end

   -- crrectly set roe numbers
   create sequence id_seq;
	update cat_report set roe_number = nextval('id_seq');
   drop sequence id_seq;

--  coalesce(sum(ROE_SIZE),0) + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row) TOTAL_SIZE
  --

-- 	perform compliance.insert_sor_mooa_record_2d_r(mpid,f_date,is_recovery);
--	perform compliance.insert_sor_mono_record_2d_r(mpid,f_date,is_recovery);
--    perform compliance.insert_sor_moir_record_2d(mpid,f_date);
--    perform compliance.insert_sor_moim_record(mpid,f_date);
--    perform compliance.insert_sor_moic_record(mpid,f_date);
--	perform compliance.insert_sor_mooc_record_2d(mpid,f_date);
--	perform compliance.insert_sor_moom_record_2d(mpid,f_date);
--    --opt out
--	perform compliance.insert_sor_moor_record_2d(mpid,f_date);
--	perform compliance.insert_sor_momr_record(mpid,f_date);
--	perform compliance.insert_sor_mocr_record(mpid,f_date);
--
--    --eq in
--
--	perform compliance.insert_sor_meoa_record_2d(mpid,f_date);
--	perform compliance.insert_sor_meno_record_2d(mpid,f_date);
--    perform compliance.insert_sor_meir_record_2d(mpid,f_date);
--    perform compliance.insert_sor_meim_record_2d(mpid,f_date);
--    perform compliance.insert_sor_meic_record_2d(mpid,f_date);
--
--	perform compliance.insert_sor_meoc_record_2d(mpid,f_date);
--	perform compliance.insert_sor_meom_record_2d(mpid,f_date);
--    --eq out
--	perform compliance.insert_sor_meor_record_2d(mpid,f_date);
--	perform compliance.insert_sor_memr_record(mpid,f_date);
--    perform compliance.insert_sor_mecr_record(mpid,f_date);
--    --ml
--    perform compliance.insert_sor_mlno_record(mpid,f_date);
--    perform compliance.insert_sor_mloa_record(mpid,f_date);
--    perform compliance.insert_sor_mlom_record(mpid,f_date);
--    perform compliance.insert_sor_mloc_record(mpid,f_date);
--    perform compliance.insert_sor_mlor_record(mpid,f_date);
--    perform compliance.insert_sor_mlmr_record(mpid,f_date);
--    perform compliance.insert_sor_mlcr_record(mpid,f_date);
--    perform compliance.insert_sor_mlir_record(mpid,f_date);
--    perform compliance.insert_sor_mlim_record(mpid,f_date);
--    perform compliance.insert_sor_mlic_record(mpid,f_date);

	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
--    for mpid in (select distinct client_mpid from compliance.cat_report)
    j := 1;
    while j < 5 loop

    	select min(roe_number) into min_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select coalesce(total_size,0) - coalesce(roe_size,0) into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;

		update compliance.cat_report
		set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
		where file_group = l_file_group[j]; --client_mpid = mpid;

        j := j+1;
    end loop;

	update compliance.cat_report
	set file_name = '104031_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||file_group||f_prefix||'_'||'OrderEvents'||'_'||lpad((roe_file_number)::varchar, 6, '0')||'.csv';


	------------------------------------------------------------------------------



	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		where ROE is not null and FILE_NAME is not null
		order by FILE_NAME, ROE_NUMBER;
	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_sor_cat_report_new(in_date date, is_recovery boolean) OWNER TO dwh;

--
-- Name: get_sor_cat_report_r(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_cat_report_r(in_date date) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
declare
    rs refcursor;
begin

 	perform compliance.get_sor_cat_report_new(in_date, true);

	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		where ROE is not null and FILE_NAME is not null
		order by FILE_NAME, ROE_NUMBER;
	RETURN rs;

end;$$;


ALTER FUNCTION compliance.get_sor_cat_report_r(in_date date) OWNER TO dwh;

--
-- Name: get_sor_first_orig(bigint, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_first_orig(in_order_id bigint, in_date_id integer, OUT out_cl_ord_id character varying, OUT out_date_id integer) RETURNS record
    LANGUAGE plpgsql
    AS $$

declare
  res varchar;

begin

  res = '';

	with recursive orig as(

	    select order_id, orig_order_id, 1 as level
	    from client_order
	    where order_id = in_order_id
	    and create_date_id  = in_date_id

	    union all

	    select r.order_id, e.orig_order_id, r.level + 1
	    from client_order e
	    join orig r on e.order_id = r.orig_order_id
	    where e.orig_order_id > 0

	)

	select client_order_id, create_date_id from (
	select r.order_id, r.orig_order_id, e.client_order_id, e.create_date_id, level, max(level) over (partition by r.order_id) as maxlevel
	from orig r
	left join client_order e on r.orig_order_id = e.order_id
	) t
	where level = maxlevel
	into out_cl_ord_id, out_date_id;


end;
$$;


ALTER FUNCTION compliance.get_sor_first_orig(in_order_id bigint, in_date_id integer, OUT out_cl_ord_id character varying, OUT out_date_id integer) OWNER TO dwh;

--
-- Name: get_sor_handl_inst(bigint, character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_handl_inst(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

declare
  res varchar;

  is_alg varchar;
  is_aon  varchar;
  is_dnrt varchar;
  is_fok  varchar;
  is_loc  varchar;
  is_loo  varchar;
  is_moc  varchar;
  is_moo  varchar;
  is_nh   varchar;
  is_opt  varchar;
  is_stp varchar;
  is_rsv varchar;
  is_peg varchar;
  is_dir varchar;
  is_disq varchar;
  is_midp varchar;
  is_marp varchar;
  is_d varchar;
  is_idx varchar;
  is_ovd varchar;
  is_tmo varchar;
  is_pso varchar;
  is_wdp varchar;


  tag_9003 varchar;
  tag_9004 varchar;
  tag_9303 varchar;
  tag_76 varchar;
  tag_7906 varchar;
  tag_9183 varchar;
  tag_9016 varchar;
  tag_9416 varchar;
  tag_9140 varchar;
  tag_9487 varchar;
  tag_389 varchar;

begin

  select fmj.fix_message->>'9003',fmj.fix_message->>'9004',fmj.fix_message->>'9303',fmj.fix_message->>'76',fmj.fix_message->>'7906',fmj.fix_message->>'9183',fmj.fix_message->>'9016',
  		 fmj.fix_message->>'9416',fmj.fix_message->>'9140',fmj.fix_message->>'9487',fmj.fix_message->>'389'
  into tag_9003, tag_9004, tag_9303, tag_76, tag_7906, tag_9183, tag_9016, tag_9416, tag_9140, tag_9487, tag_389
  from fix_capture.fix_message_json fmj
  where fmj.date_id = in_date_id
    and fmj.fix_message_id = (select fix_message_id from client_order where order_id = in_order_id and create_date_id = in_date_id  limit 1)
  limit 1
  ;

  res = '';

  select
       case when cl.sub_strategy_desc <> 'DMA' then 'ALG' end as is_alg,
  	   case when cl.exec_instruction ~ '(G)' then 'AON' end as is_aon,
       case when cl.exec_instruction ~ '(n|6|h|Z)' or tag_9303 in ('B','BL') or tag_76 = 'DNR' or tag_7906 = '3' or tag_9183 = 'h' then 'DNRT' end as is_dnrt,
       case when cl.exec_instruction ~ '(1)' then 'NH' end as is_nh,
       case when cl.time_in_force_id = '4' then 'FOK' end as is_fok,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '2' then 'LOC' end as is_loc,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '1' then 'MOC' end as is_moc,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '2' then 'LOO' end as is_loo,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '1' then 'MOO'end as is_moo,
       case when cl.multileg_reporting_type = '2' and in_instrument_type_id = 'E' then 'OPT' end as is_opt,
       case when cl.order_type_id in ('3','4') then 'STOP='||to_char(cl.stop_price, 'FM9999999990.09999999') end as is_stp,
       case when cl.max_floor > 0 then 'RSV' end as is_rsv,
       case when cl.sub_strategy_desc = 'SYNTPEG' then 'PEG' end as is_peg,
       case when cl.sub_strategy_desc = 'DMA' then 'DIR' end as is_dir,
       case when cl.max_floor > 0 then 'DISQ='||cl.max_floor::varchar end as is_disq,
       case when cl.exec_instruction ~ '(M)' and cl.order_type_id = 'P' then 'M' end as is_midp,
       case when cl.exec_instruction ~ '(P)' and cl.order_type_id = 'P' then 'P' end as is_marp,
       case when cl.exec_instruction ~ '(d)' then 'd' end as is_d,
       case when cl.cross_order_id is not null then 'IDX' end as is_idx,
       case when cl.sub_strategy_desc in ('VWAP','TWAP') or tag_9016 = '2' then 'OVD' end as is_ovd,
       case when tag_9003 is not null then 'TMO' end as is_tmo,
       --case when cl.exec_instruction ~ '(M|6)' or tag_9303 in ('B','P') or tag_76 in ('DNR','PO','POST') or tag_9416 = 'A' or tag_9183 = 'p' or tag_9140 = 'P' or tag_9487= 'ALO' then 'PSO' end as is_pso,
       case when tag_389 is not null then 'WDP' end as is_wdp

  into is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp
  from client_order cl
  where cl.create_date_id = in_date_id
    and cl.order_id = in_order_id
  limit 1
  ;


  res =  concat_ws('|',is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp);
  return res;
end;
$$;


ALTER FUNCTION compliance.get_sor_handl_inst(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_sor_handl_inst_2d(bigint, character varying, integer, json); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_handl_inst_2d(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer, in_fix_msg json) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$

declare
  res varchar;

  is_alg varchar;
  is_aon  varchar;
  is_dnrt varchar;
  is_fok  varchar;
  is_loc  varchar;
  is_loo  varchar;
  is_moc  varchar;
  is_moo  varchar;
  is_nh   varchar;
  is_opt  varchar;
  is_stp varchar;
  is_rsv varchar;
  is_peg varchar;
  is_dir varchar;
  is_disq varchar;
  is_midp varchar;
  is_marp varchar;
  is_d varchar;
  is_idx varchar;
  is_ovd varchar;
  is_tmo varchar;
  is_wdp varchar;
  is_r varchar;
  is_rlo varchar;
  is_io varchar;


  tag_9303 varchar;
  tag_76 varchar;
  tag_57 varchar;
  tag_7906 varchar;
  tag_9183 varchar;
  tag_9016 varchar;
  tag_9152 varchar;
  tag_9140 varchar;
  tag_9416 varchar;
  tag_9355 varchar;
  tag_389 varchar;
  tag_336 varchar;
  tag_9291 varchar;

begin

  select in_fix_msg->>'9303',in_fix_msg->>'76',in_fix_msg->>'57',in_fix_msg->>'7906',in_fix_msg->>'9183',in_fix_msg->>'9016',in_fix_msg->>'9152',in_fix_msg->>'9140',in_fix_msg->>'9416',in_fix_msg->>'9355',
  		 in_fix_msg->>'389',in_fix_msg->>'336',in_fix_msg->>'9291'
  into tag_9303, tag_76, tag_57, tag_7906, tag_9183, tag_9016, tag_9152, tag_9140, tag_9416, tag_9355, tag_389, tag_336, tag_9291;
 -- from (select in_fix_msg) fmj;

  res = '';

  select
       case
       		when cl.sub_strategy_desc = 'VEGA' then 'ALGS'
       		when cl.sub_strategy_desc not in ('DMA','VEGA') then 'ALG'
       end as is_alg,
  	   case when cl.exec_instruction ~ '(G)' then 'AON' end as is_aon,
       case when cl.exec_instruction ~ '(n|6|h|Z)' or tag_9303 in ('B','BL') or tag_76 = 'DNR' or tag_7906 = '3' or tag_9183 = 'h' then 'DNRT' end as is_dnrt,
       case when cl.exec_instruction ~ '(1)' or tag_9291 = 'N' then 'NH' end as is_nh,
       case when cl.time_in_force_id = '4' then 'FOK' end as is_fok,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '2' then 'LOC' end as is_loc,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '1' then 'MOC' end as is_moc,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '2' then 'LOO' end as is_loo,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '1' then 'MOO'end as is_moo,
       case when cl.order_type_id in ('3','4') then 'STOP='||to_char(cl.stop_price, 'FM9999999990.09999999') end as is_stp,
       case when cl.max_floor > 0 then 'RSV' end as is_rsv,
       case when cl.sub_strategy_desc = 'SYNTPEG' then 'PEG' end as is_peg,
       case when cl.sub_strategy_desc = 'DMA' then 'DIR' end as is_dir,
       case when cl.max_floor > 0 then 'DISQ='||cl.max_floor::varchar end as is_disq,
       case when cl.exec_instruction ~ '(M)' and cl.order_type_id = 'P' then 'M' end as is_midp,
       case when cl.exec_instruction ~ '(P)' and cl.order_type_id = 'P' then 'P' end as is_marp,
       case when cl.exec_instruction ~ '(d)' then 'd' end as is_d,
       case when cl.cross_order_id is not null then 'IDX' end as is_idx,
       case when cl.sub_strategy_desc in ('VWAP','TWAP') or tag_9016 = '2' then 'OVD' end as is_ovd,
       case when cl.algo_start_time is not null then 'TMO='||to_char(cl.algo_start_time,'YYYYMMDD HH24MISS.MS') end as is_tmo,
       case when tag_389 is not null then 'WDP' end as is_wdp,
       case when cl.sub_strategy_desc = 'SENSOR' and cl.exec_instruction ~ '(R)' then 'R' end as is_r,
       case when tag_57 = 'RET' then 'RLO' end as is_rlo,
       case when tag_9152 in ('I','D')
       	      or (cl.exchange_id in ('ARCAE','XASE') and cl.order_type_id = '2' and cl.time_in_force_id = '2' and tag_9416 = '8')
       	      or (cl.exchange_id = 'XNYS' and cl.order_type_id = '2' and cl.time_in_force_id = '7' and tag_336 = '2' and tag_9416 = '8')
       	      or (cl.exchange_id = 'NSDQE' and cl.order_type_id = '2' and cl.time_in_force_id = '3' and tag_9355 in ('O','C'))
       	    then 'IO' end as is_io

  into is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp,is_r,is_rlo,is_io
  from client_order cl
  inner join d_account ac on cl.account_id = ac.account_id and ac.is_active
  where cl.create_date_id = in_date_id
    and cl.order_id = in_order_id
  limit 1
  ;


  res =  concat_ws('|',is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp,is_r,is_rlo,is_io);
  return res;
end;
$$;


ALTER FUNCTION compliance.get_sor_handl_inst_2d(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer, in_fix_msg json) OWNER TO dwh;

--
-- Name: get_sor_handl_inst_sy(bigint, character varying, integer, json); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_handl_inst_sy(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer, in_fix_msg json) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$

declare
  res varchar;

  is_alg varchar;
  is_aon  varchar;
  is_dnrt varchar;
  is_fok  varchar;
  is_loc  varchar;
  is_loo  varchar;
  is_moc  varchar;
  is_moo  varchar;
  is_nh   varchar;
  is_opt  varchar;
  is_stp varchar;
  is_rsv varchar;
  is_peg varchar;
  is_dir varchar;
  is_disq varchar;
  is_midp varchar;
  is_marp varchar;
  is_d varchar;
  is_idx varchar;
  is_ovd varchar;
  is_tmo varchar;
  is_pso varchar;
  is_wdp varchar;
  is_sr varchar;


  tag_9303 varchar;
  tag_76 varchar;
  tag_7906 varchar;
  tag_9183 varchar;
  tag_9016 varchar;
  --tag_9416 varchar;
  --tag_9140 varchar;
  --tag_9487 varchar;
  tag_389 varchar;

begin

  select in_fix_msg->>'9303',in_fix_msg->>'76',in_fix_msg->>'7906',in_fix_msg->>'9183',in_fix_msg->>'9016',in_fix_msg->>'389'
  into tag_9303, tag_76, tag_7906, tag_9183, tag_9016, tag_389;
 -- from (select in_fix_msg) fmj;

  res = '';

  select
       case
       		when cl.sub_strategy_desc = 'VEGA' then 'ALGS'
       		when cl.sub_strategy_desc not in ('DMA','VEGA') then 'ALG'
       end as is_alg,
  	   case when cl.exec_instruction ~ '(G)' then 'AON' end as is_aon,
       case when cl.exec_instruction ~ '(n|6|h|Z)' or tag_9303 in ('B','BL') or tag_76 = 'DNR' or tag_7906 = '3' or tag_9183 = 'h' then 'DNRT' end as is_dnrt,
       case when cl.exec_instruction ~ '(1)' then 'NH' end as is_nh,
       case when cl.time_in_force_id = '4' then 'FOK' end as is_fok,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '2' then 'LOC' end as is_loc,
       case when cl.time_in_force_id = '7' and cl.order_type_id = '1' then 'MOC' end as is_moc,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '2' then 'LOO' end as is_loo,
       case when cl.time_in_force_id = '2' and cl.order_type_id = '1' then 'MOO'end as is_moo,
       case when cl.multileg_reporting_type = '2' and in_instrument_type_id = 'E' then 'OPT' end as is_opt,
       case when cl.order_type_id in ('3','4') then 'STOP='||to_char(cl.stop_price, 'FM9999999990.09999999') end as is_stp,
       case when cl.max_floor > 0 then 'RSV' end as is_rsv,
       case when cl.sub_strategy_desc = 'SYNTPEG' then 'PEG' end as is_peg,
       case when cl.sub_strategy_desc = 'DMA' then 'DIR' end as is_dir,
       case when cl.max_floor > 0 then 'DISQ='||cl.max_floor::varchar end as is_disq,
       case when cl.exec_instruction ~ '(M)' and cl.order_type_id = 'P' then 'M' end as is_midp,
       case when cl.exec_instruction ~ '(P)' and cl.order_type_id = 'P' then 'P' end as is_marp,
       case when cl.exec_instruction ~ '(d)' then 'd' end as is_d,
       case when cl.cross_order_id is not null then 'IDX' end as is_idx,
       case when cl.sub_strategy_desc in ('VWAP','TWAP') or tag_9016 = '2' then 'OVD' end as is_ovd,
       case when cl.algo_start_time is not null then 'TMO='||to_char(cl.algo_start_time,'YYYYMMDD HH24MISS.MS') end as is_tmo,
       case when tag_389 is not null then 'WDP' end as is_wdp--,
       --case when cl.ex_destination = 'LIQPT' then 'SR' end as is_sr

  into is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp--,is_sr
  from client_order cl
  where cl.create_date_id = in_date_id
    and cl.order_id = in_order_id
  limit 1
  ;


  res =  concat_ws('|',is_alg,is_aon,is_dnrt,is_nh,is_fok,is_loc,is_moc,is_loo,is_moo,is_opt,is_stp,is_rsv,is_peg,is_dir,is_disq,is_midp,is_marp,is_d,is_idx,is_ovd,is_tmo,is_wdp);
  return res;
end;
$$;


ALTER FUNCTION compliance.get_sor_handl_inst_sy(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer, in_fix_msg json) OWNER TO dwh;

--
-- Name: get_sor_trading_session(bigint, character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_sor_trading_session(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  res varchar;
  l_algo_start_time varchar;
  l_algo_end_time varchar;
begin


  res = '';

  select to_char(to_timestamp(fix_message->>'9003', 'YYYYMMDD-HH24:MI:SS.MS')::timestamp at time zone 'UTC', 'HH24:MI:SS:MS'),
  		 to_char(to_timestamp(fix_message->>'9004', 'YYYYMMDD-HH24:MI:SS.MS')::timestamp at time zone 'UTC', 'HH24:MI:SS:MS')
  into l_algo_start_time, l_algo_end_time
  from fix_capture.fix_message_json fmj
  where fmj.date_id = in_date_id
    and fmj.fix_message_id = (select fix_message_id from client_order where order_id = in_order_id and create_date_id = in_date_id  limit 1)
  limit 1
  ;

  select
  	case
  		when in_instrument_type_id = 'O' then 'REG'
  	    when cl.cross_order_id is not null or cl.multileg_reporting_type = '2' then 'REG'
  		when cl.time_in_force_id = 'M' then 'ALL'
  		when cl.time_in_force_id in ('1','2','C','7') then 'REG'
  		when cl.time_in_force_id = '6' then 'REGPOST'
  		when to_char(cl.process_time,'HH24:MI:SS:MS') < '09:30:00:000' then
  			case
  			 when cl.time_in_force_id in ('3','4') then 'PRE'
  			 when cl.time_in_force_id in ('0','5') and l_algo_end_time <= '09:30:00:000' then 'PRE'
  			 when cl.time_in_force_id = '0' and coalesce(l_algo_start_time,'09:00:00:000') < '09:30:00:000' and l_algo_end_time > '16:00:00:000' then 'ALL'
  			 when cl.time_in_force_id = '5' and coalesce(l_algo_start_time,'09:00:00:000') < '09:30:00:000' and coalesce(l_algo_end_time,'20:00:00:000') > '16:00:00:000' then 'ALL'
  			 --
  			 when cl.time_in_force_id = '5' and coalesce(l_algo_start_time,'09:00:00:000') < '09:30:00:000' and l_algo_end_time > '09:30:00:000' and l_algo_end_time <= '16:00:00:000' then 'PREREG'
  			 when cl.time_in_force_id = '0' and coalesce(l_algo_start_time,'09:00:00:000') < '09:30:00:000'
  			 								and coalesce(l_algo_end_time,'16:00:00:000') > '09:30:00:000' and coalesce(l_algo_end_time,'16:00:00:000') <= '16:00:00:000'
  			 								and coalesce(dts.target_strategy_group_id,0) not in (2,101) then 'PREREG'
  			 when cl.time_in_force_id = '0' and coalesce(l_algo_start_time,'09:00:00:000') < '09:30:00:000'
  			 								and coalesce(l_algo_end_time,'16:00:00:000') > '09:30:00:000' and coalesce(l_algo_end_time,'16:00:00:000') <= '16:00:00:000'
  			 								and coalesce(dts.target_strategy_group_id,0) in (2,101) then 'REG'
  			 --
  			 when cl.time_in_force_id = '5' and l_algo_start_time >= '09:30:00:000' and l_algo_start_time  <= '16:00:00:000' and l_algo_end_time <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '0' and l_algo_start_time >= '09:30:00:000' and l_algo_start_time  <= '16:00:00:000' and coalesce(l_algo_end_time,'16:00:00:000') <= '16:00:00:000' then 'REG'
  			 --
  			 when cl.time_in_force_id = '5' and l_algo_start_time >= '09:30:00:000' and l_algo_start_time  <= '16:00:00:000' and coalesce(l_algo_end_time,'20:00:00:000') > '16:00:00:000' then 'REGPOST'
  			 when cl.time_in_force_id = '0' and l_algo_start_time >= '09:30:00:000' and l_algo_start_time  <= '16:00:00:000' and l_algo_end_time > '16:00:00:000' then 'REGPOST'
  			 --
  			 else 'REG'
  			end
  		when to_char(cl.process_time,'HH24:MI:SS:MS') >= '09:30:00:000' and  to_char(cl.process_time,'HH24:MI:SS:MS') < '16:00:00:000' then
  			case
  			 when cl.time_in_force_id  in ('3','4') then 'REG'
  			 when cl.time_in_force_id = '5' and l_algo_end_time <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '0' and coalesce(l_algo_end_time,'16:00:00:000') <= '16:00:00:000' then 'REG'
  			 when cl.time_in_force_id = '5' and coalesce(l_algo_end_time,'20:00:00:000') > '16:00:00:000' then 'REGPOST'
  			 when cl.time_in_force_id = '0' and l_algo_end_time > '16:00:00:000' then 'REGPOST'
  			 else 'REG'
  			end
  		when to_char(cl.process_time,'HH24:MI:SS:MS') >= '16:00:00:000' and cl.time_in_force_id in ('0','3','4','5') then 'POST'
    end
  into res
  from client_order cl
  left join d_target_strategy dts  on (dts.target_strategy_name = cl.sub_strategy_desc)
  where cl.create_date_id = in_date_id
    and cl.order_id = in_order_id
  limit 1
  ;



  return res;
end;
$$;


ALTER FUNCTION compliance.get_sor_trading_session(in_order_id bigint, in_instrument_type_id character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: get_test_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_test_cat_report(in_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  l_size_limit bigint;
  l_min_total_size bigint;
  l_min_client_roe_number bigint;
  l_max_client_roe_number bigint;
  l_client_total_size bigint;
  l_imid varchar;
  l_file_group varchar;
  l_crd_number varchar;
  l_cnt bigint;
begin


    truncate table  compliance.cat_report;
	--l_imid := 'MYDM';
    l_crd_number := '104031';
	------------------------------------------------------------------------------
	for l_imid in (select distinct cat_imid
    				from d_trading_firm
    				where cat_report_on_behalf_of = 'Y'
    				--and cat_imid = 'CTTD'
    				)
    loop

		perform compliance.insert_sor_obo_mono_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_mooc_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_moom_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_moor_record(l_imid,to_char(in_date,'YYYYMMDD')::int);

		perform compliance.insert_sor_obo_meno_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meoc_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meom_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		perform compliance.insert_sor_obo_meor_record(l_imid,to_char(in_date,'YYYYMMDD')::int);

	--
		--perform compliance.insert_pair_obo_meno_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
		--perform compliance.insert_pair_obo_meom_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
   	 	--perform compliance.insert_pair_obo_meoc_record(l_imid,to_char(in_date,'YYYYMMDD')::int);
   	    --perform compliance.insert_pair_obo_meor_record(l_imid,to_char(in_date,'YYYYMMDD')::int);

    end loop;


	l_size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000


     for l_imid in (select distinct cat_imid
    				from d_trading_firm
    				where cat_report_on_behalf_of = 'Y'
    				--and cat_imid = 'CTTD'
    				)

    --loop by client_mpid
    loop
    	select min(roe_number) into l_min_client_roe_number from compliance.cat_report where client_mpid = l_imid;
		select max(roe_number) into l_max_client_roe_number from compliance.cat_report where client_mpid = l_imid;
		select total_size - roe_size into l_min_total_size from compliance.cat_report where roe_number = l_min_client_roe_number;
		select sum(roe_size) into l_client_total_size from compliance.cat_report where client_mpid = l_imid;

		update compliance.cat_report
		set roe_file_number = trunc((total_size - l_min_total_size) /l_size_limit) + 1
		where client_mpid = l_imid;

	    if l_imid = 'BELV'
	    	then l_crd_number := '132605';
	    	else l_crd_number := '104031';
		end if;

 		update compliance.cat_report
	    set file_name = l_crd_number||'_'||client_mpid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||coalesce(file_group,'SOR')||'_OrderEvents_'||lpad(coalesce(roe_file_number,1)::varchar, 6, '0')||'.csv'
	    where client_mpid = l_imid;
	    /*
	    if coalesce(l_client_total_size,0) = 0 and l_imid <> 'MYDM' then
	   		insert into compliance.cat_report (file_name, client_mpid, file_group, order_ind, roe, roe_number, roe_size, roe_file_number, total_size)
 		    	 	select l_crd_number||'_'||l_imid||'_'||to_char(in_date, 'YYYYMMDD')||'_'||'SOR'||'_OrderEvents_'||'000001'||'.csv',
 		   		  			l_imid, 'SOR', 2, '', 1, 0, 1, 0;
	    end if;
	    */
    end loop;




end;$$;


ALTER FUNCTION compliance.get_test_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_test_sor_cat_report(date); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_test_sor_cat_report(in_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  rs refcursor;
  size_limit numeric;
  min_total_size numeric;
  min_client_roe_number numeric;
  max_client_roe_number numeric;
  client_total_size numeric;
  mpid varchar;

  l_file_group varchar[];
  j int;

begin

    truncate table  compliance.cat_report;

   	l_file_group[1] := 'ATLASOPTIN';
 	l_file_group[2] := 'ATLASOPTOUT';
 	l_file_group[3] := 'ATLASEQIN';
 	l_file_group[4] := 'ATLASEQOUT';

    mpid := 'DFIN';

   /*
   perform compliance.insert_sor_brkpt_meoa_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
   perform compliance.insert_sor_brkpt_mooa_record(mpid,to_char(in_date,'YYYYMMDD')::int);
   perform compliance.insert_sor_brkpt_moor_record(mpid,to_char(in_date,'YYYYMMDD')::int);
   perform compliance.insert_sor_brkpt_meor_record_2c(mpid,to_char(in_date,'YYYYMMDD')::int);
   */

    --opt in
	perform compliance.insert_sor_mooa_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mono_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moir_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moim_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_moic_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mooc_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_moom_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);

    --opt out
	perform compliance.insert_sor_moor_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_momr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_mocr_record(mpid,to_char(in_date,'YYYYMMDD')::int);

    --eq in

	perform compliance.insert_sor_meoa_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_meno_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meir_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meim_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_meic_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);

	perform compliance.insert_sor_meoc_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_meom_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
    --eq out
	perform compliance.insert_sor_meor_record_2d(mpid,to_char(in_date,'YYYYMMDD')::int);
	perform compliance.insert_sor_memr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mecr_record(mpid,to_char(in_date,'YYYYMMDD')::int);

    perform compliance.insert_sor_mlno_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mloa_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlom_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mloc_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlor_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlmr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlcr_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlir_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlim_record(mpid,to_char(in_date,'YYYYMMDD')::int);
    perform compliance.insert_sor_mlic_record(mpid,to_char(in_date,'YYYYMMDD')::int);

    --
    --
    --
	size_limit := 1000000000 - 350; --350 is max one roe size--to set larger size_limit: 1000 000 000

    --select count(distinct CLIENT_MPID) into size_limit from OATS_REPORT;
    --for mpid in (select distinct client_mpid from compliance.cat_report)
    j := 1;
    while j < 5 loop
    --loop by client_mpid
    --loop
    	select min(roe_number) into min_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select max(roe_number) into max_client_roe_number from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;
		select total_size - roe_size into min_total_size from compliance.cat_report where roe_number = min_client_roe_number;
		select sum(roe_size) into client_total_size from compliance.cat_report where file_group = l_file_group[j]; --client_mpid = mpid;

		--update OATS_REPORT set ROE_FILE_NUMBER = trunc(TOTAL_SIZE/SIZE_LIMIT);
		update compliance.cat_report
		set roe_file_number = trunc((total_size - min_total_size) /size_limit) + 1
		where file_group = l_file_group[j]; --client_mpid = mpid;

        j := j+1;
    end loop;
    --end loop;

	update compliance.cat_report
	set file_name = '104031_'||client_mpid||'_'||to_char(current_timestamp, 'YYYYMMDD')||'_'||file_group||'_'||'OrderEvents'||'_'||lpad(roe_file_number::varchar, 6, '0')||'.csv';


	------------------------------------------------------------------------------
	/*
	OPEN rs FOR
		select FILE_NAME, ROE
		from COMPLIANCE.CAT_REPORT
		order by ROE_NUMBER;
	RETURN rs;
	*/
end;$$;


ALTER FUNCTION compliance.get_test_sor_cat_report(in_date date) OWNER TO dwh;

--
-- Name: get_underlying_by_root(character varying); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.get_underlying_by_root(in_root_symbol character varying) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    RETURN (
        select min(uin.display_instrument_id)
			 from d_option_series os
			 join d_instrument uin on uin.instrument_id = os.underlying_instrument_id and uin.is_active = true
			 where os.root_symbol = in_root_symbol
			 and os.is_active = true
			 --and os.option_series_id not in (select option_series_id from compliance.suppressed_sor_option_series)
			 limit 1
    );
END;
$$;


ALTER FUNCTION compliance.get_underlying_by_root(in_root_symbol character varying) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mlcr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mlcr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CUST_CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CUST_CAT_REPORT;

  insert into COMPLIANCE.CUST_CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(coc.event_timestamp,'YYYYMMDD')||'_'||coc.client_oid||'_'||'CR'||'_'||coc.custom_log_import_batch_id::varchar||','||
		'MLCR'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		--
		bm.osi_symbol||','||

		''||','||--originatingIMID
		to_char(coc.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		'false'||','||--manual flag
		''||','||--electronicTimestamp
		co.qty::varchar||','||--cancelled_qty [13]
		''||','|| --[14]
		coalesce(ccn.crd_number||':'||co.clearing_firm,'')||','|| -- [15]
		'CBOE'||','|| --destination
		'E'||','||--destinationType
		co.client_oid||','||--routedOrderID [18]
		coalesce(co.username,'')||coalesce(co.session_sub_id,'')||','||--session
		'false'||','|| --routeRejectedFlag [20]
		co.num_legs||','||
		''



		:: varchar

		as ROE

		from compliance.custom_order_event co
		left join compliance.crd_number_list ccn on (co.clearing_firm = ccn.cat_imid
			 										 and
			 									 	 (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									     )
		inner join compliance.custom_order_cancel coc on co.client_oid = coc.client_oid and coc.date_id = in_date_id and coc.custom_log_import_batch_id  = co.custom_log_import_batch_id
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)

		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs > 1
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mlcr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mlno_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mlno_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;



  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(co.event_timestamp,'YYYYMMDD')||'_'||co.client_oid||'_'||'NO'||'_'||co.custom_log_import_batch_id::varchar||','||
		'MLNO'||','||
		in_reporter_imid||','||--in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||
		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		coalesce(legs.complex_instrument_underlying,'')||','||
		to_char(co.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp
		'false'||','||--manual flag [10]
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID
		'false'||','||--electronicDupFlag - need to check
		''||','||--electronicTimestamp
		'T'||','||--deptType [15]
		case
		    when upper(co.ordtype) in ('LIMIT') and co.price is not null then to_char(abs(co.price), 'FM9999999990.09999999')
			else ''
		end||','||
		co.qty::varchar||','|| --[17]
		''||','||--minQty
		case
		    when upper(co.ordtype) in ('LIMIT') then 'LMT'
			else 'MKT'
		end||','|| --[19]
		case
			when upper(co.time_in_force) in ('GTC','IOC') then upper(co.time_in_force)
			when upper(co.time_in_force) in ('GTX') then 'GTX='||to_char(co.event_timestamp,'YYYYMMDD')
			when upper(co.time_in_force) in ('GTD') then 'GTD='||to_char(co.event_timestamp,'YYYYMMDD')
			else 'DAY='||to_char(co.event_timestamp,'YYYYMMDD')
		end||','|| --[20]
		case
		    when co.session_eligibility = 'R' then 'REG'
			else 'ALL'
		end||','|| --[21]
		--handling instructions
		-----------------------
		concat_ws('|',
			case
				when upper(co.time_in_force) in ('FOK') then upper(co.time_in_force)
			end,
			case
				when co.self_match is not null then 'STP'
			end,
			case
				when coalesce(co.auction_id,'0') <> '0' then 'AucResp='||co.auction_id
			end,
			case
				when upper(co.ordtype) in ('LIMIT') and upper(co.time_in_force) = 'ATOPEN' then 'LOO'
				when upper(co.ordtype) in ('MARKET') and upper(co.time_in_force) = 'ATOPEN' then 'MOO'
				when upper(co.ordtype) in ('LIMIT') and upper(co.time_in_force) = 'ATCLOSE' then 'LOC'
				when upper(co.ordtype) in ('MARKET') and upper(co.time_in_force) = 'ATCLOSE' then 'MOC'
			end
		)||','||
		-----------------------
		coalesce(cad.fdid, 'PENDING')||','||--firmDesignatedID (#account) [23]
		coalesce(cad.account_holder_type,'A')||','||--accountHolderType
		'false'||','||--affiliate flag [25]
		''||','||--aggregated orders
		'N'||','||--representativeInd (combined) [27]
		------
		'false'||','||--solicitationFlag [28] --2d
		--
		''||','|| --RFGID
		co.num_legs||','||
        'PU'||','|| --[31] price type
		legs.leg_info

		:: varchar

		as ROE

		from compliance.custom_order_event co
		inner join lateral
			(select
					oli.complex_instrument_id,
					oli.complex_instrument_underlying,
			 string_agg(oli.leg_number::varchar||'@'||
							   case
							   		when oli.leg_security_type = 'E' then
							   			 bm.osi_symbol
							  	 	else ''
							   end||'@'||
							   case
							   		when oli.leg_security_type  = 'O' then
							   			 bm.osi_symbol
							   		else ''
							   end||'@'||
							   case
							   		when oli.leg_security_type = 'E' then ''
							  		when upper(co.side) = 'SELL' then 'Close'
							  		when upper(co.side) = 'BUY' then 'Open'
							  		else ''
							   end||'@'||
							   case
							    	when oli.leg_ratio > 0 then 'B'
							    	when oli.leg_ratio < 0 then 'SL'
							    	else 'B'
							    end||'@'||--side
							    abs(oli.leg_ratio)::varchar, '|' order by oli.leg_number) as leg_info
			 from compliance.custom_order_leg_info oli
			 inner join compliance.custom_bats_osi_mapping bm on oli.leg_symbol = bm.bats_symbol
			 inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
			 where oli.date_id = in_date_id
			 and oli.complex_instrument_id = co.symbol
			 and bosi.date_id = in_date_id
			 group by
			 		  oli.complex_instrument_id,
					  oli.complex_instrument_underlying
			 limit 1
			) legs on true
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		--and to_char(co.event_timestamp,'YYYYMMDD')::int  = in_date_id
		and co.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs > 1
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mlno_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mloc_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mloc_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CUST_CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CUST_CAT_REPORT;

  insert into COMPLIANCE.CUST_CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(coc.event_timestamp,'YYYYMMDD')||'_'||coc.client_oid||'_'||'OC'||'_'||coc.custom_log_import_batch_id::varchar||','||
		'MLOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		--
		bm.osi_symbol||','||
		to_char(coc.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[9]
		'false'||','||--manual flag
		''||','||--electronicTimestamp [11]
		co.qty::varchar||','||--cancelled_qty
		'0'||','||--leaves
		'C'||','||--initiator[14]
		to_char(coc.request_timestamp,'YYYYMMDD HH24MISS.MS')


		:: varchar

		as ROE

		from compliance.custom_order_event co
		inner join compliance.custom_order_cancel coc on co.client_oid = coc.client_oid and coc.date_id = in_date_id and coc.custom_log_import_batch_id  = co.custom_log_import_batch_id
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs > 1
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mloc_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mlor_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mlor_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               'ATLCUST' as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(co.event_timestamp,'YYYYMMDD')||'_'||co.client_oid||'_'||'OR'||'_'||co.custom_log_import_batch_id::varchar||','||
		'MLOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||
		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		coalesce(legs.complex_instrument_underlying,'')||','||
		to_char(co.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--[9]
		'false'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||

		coalesce(ccn.crd_number||':'||co.clearing_firm,'')||','||--senderIMID--v2
		'CBOE'||','||--destination[14]

		'E'||','||--destinationType (F=Industry Member)
		co.client_oid||','||--routedOrderID
		coalesce(co.username,'')||coalesce(co.session_sub_id,'')||','||--session [17]
		--
		case
		    when upper(co.ordtype) in ('LIMIT') and co.price is not null then to_char(abs(co.price), 'FM9999999990.09999999')
			else ''
		end||','||--[18]
		co.qty::varchar||','||
		''||','||--minQty
		case
		    when upper(co.ordtype) in ('LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when upper(co.time_in_force) in ('GTC','IOC') then upper(co.time_in_force)
			when upper(co.time_in_force) in ('GTX') then 'GTX='||to_char(co.event_timestamp,'YYYYMMDD')
			when upper(co.time_in_force) in ('GTD') then 'GTD='||to_char(co.event_timestamp,'YYYYMMDD')
			else 'DAY='||to_char(co.event_timestamp,'YYYYMMDD')
		end||','||
		case
		    when co.session_eligibility = 'R' then 'REG'
			else 'ALL'
		end||','||--[23]
		--handling instructions
		-----------------------
		''||','||
		-----------------------
		'false'||','||--affiliate flag
		case
			when coalesce(rej.cnt,0) > 0 then 'true'
			else 'false'
		end||','||--routeRejectedFlag
		case
		  when upper(co.capacity) = 'MARKETMAKER' then 'M'
		  else 'M'
		end||','||--exchOriginCode [27]
		''||','||--pairedOrderID
		co.num_legs||','||
        'PU'||','|| --[30] price type
		legs.leg_info


		:: varchar

		as ROE

		from compliance.custom_order_event co
		inner join lateral
			(select
					oli.complex_instrument_id,
					oli.complex_instrument_underlying,
			 string_agg(oli.leg_number::varchar||'@'||
							   case
							   		when oli.leg_security_type = 'E' then
							   			 bm.osi_symbol
							  	 	else ''
							   end||'@'||
							   case
							   		when oli.leg_security_type  = 'O' then
							   			 bm.osi_symbol
							   		else ''
							   end||'@'||
							   case
							   		when oli.leg_security_type = 'E' then ''
							  		when upper(co.side) = 'SELL' then 'Close'
							  		when upper(co.side) = 'BUY' then 'Open'
							  		else ''
							   end||'@'||
							   case
							    	when oli.leg_ratio > 0 then 'B'
							    	when oli.leg_ratio < 0 then 'SL'
							    	else 'B'
							    end||'@'||--side
							    abs(oli.leg_ratio)::varchar, '|' order by oli.leg_number) as leg_info
			 from compliance.custom_order_leg_info oli
			 inner join compliance.custom_bats_osi_mapping bm on oli.leg_symbol = bm.bats_symbol
			 inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
			 where oli.date_id = in_date_id
			 and oli.complex_instrument_id = co.symbol
			 and bosi.date_id = in_date_id
			 group by
			 		  oli.complex_instrument_id,
					  oli.complex_instrument_underlying
			 limit 1
			) legs on true
		left join compliance.crd_number_list ccn on (co.clearing_firm = ccn.cat_imid
			 										 and
			 									 	 (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									     )

		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_order_mapping om on (om.boe_client_oid = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		left join lateral
	        (select count(1) as cnt
	         from compliance.custom_order_reject cor
	         where cor.client_oid = co.client_oid
	         and cor.date_id = in_date_id
	         and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id
	         limit 1
	        ) rej on true
		where 1 = 1
		--and to_char(co.event_timestamp,'YYYYMMDD')::int  = in_date_id
		and co.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs > 1
		--and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mlor_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mocr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mocr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CUST_CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CUST_CAT_REPORT;

  insert into COMPLIANCE.CUST_CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(coc.event_timestamp,'YYYYMMDD')||'_'||coc.client_oid||'_'||'CR'||'_'||coc.custom_log_import_batch_id::varchar||','||
		'MOCR'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		--
		bm.osi_symbol||','||

		''||','||--originatingIMID
		to_char(coc.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		'false'||','||--manual flag
		''||','||--electronicTimestamp
		co.qty::varchar||','||--cancelled_qty [13]
		''||','|| --[14]
		coalesce(ccn.crd_number||':'||co.clearing_firm,'')||','|| -- [15]
		'CBOE'||','|| --destination
		'E'||','||--destinationType
		co.client_oid||','||--routedOrderID [18]
		coalesce(co.username,'')||coalesce(co.session_sub_id,'')||','||--session
		'false'||','|| --routeRejectedFlag [20]
		'false'--multiLegInd



		:: varchar

		as ROE

		from compliance.custom_order_event co
		left join compliance.crd_number_list ccn on (co.clearing_firm = ccn.cat_imid
			 										 and
			 									 	 (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									     )
		inner join compliance.custom_order_cancel coc on co.client_oid = coc.client_oid and coc.date_id = in_date_id and coc.custom_log_import_batch_id  = co.custom_log_import_batch_id
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)

		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs is null
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mocr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mono_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mono_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;



  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(co.event_timestamp,'YYYYMMDD')||'_'||co.client_oid||'_'||'NO'||'_'||co.custom_log_import_batch_id::varchar||','||
		'MONO'||','||
		in_reporter_imid||','||--in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||
		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		bm.osi_symbol||','||
		to_char(co.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp
		--this is not manual event
		'false'||','||--manual flag
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID
		'false'||','||--electronicDupFlag - need to check
		''||','||--electronicTimestamp
		'T'||','||--deptType
		case upper(co.side)
		  when 'BUY' then 'B' else 'SL'
		end||','||--side
		case
		    when upper(co.ordtype) in ('LIMIT') and co.price is not null then to_char(abs(co.price), 'FM9999999990.09999999')
			else ''
		end||','||
		co.qty::varchar||','||
		''||','||--minQty
		case
		    when upper(co.ordtype) in ('LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when upper(co.time_in_force) in ('GTC','IOC') then upper(co.time_in_force)
			when upper(co.time_in_force) in ('GTX') then 'GTX='||to_char(co.event_timestamp,'YYYYMMDD')
			when upper(co.time_in_force) in ('GTD') then 'GTD='||to_char(co.event_timestamp,'YYYYMMDD')
			else 'DAY='||to_char(co.event_timestamp,'YYYYMMDD')
		end||','||
		case
		    when co.session_eligibility = 'R' then 'REG'
			else 'ALL'
		end||','||
		--handling instructions
		-----------------------
		concat_ws('|',
			case
				when upper(co.time_in_force) in ('FOK') then upper(co.time_in_force)
			end,
			case
				when co.self_match is not null then 'STP'
			end,
			case
				when coalesce(co.auction_id,'0') <> '0' then 'AucResp='||co.auction_id
			end,
			case
				when upper(co.ordtype) in ('LIMIT') and upper(co.time_in_force) = 'ATOPEN' then 'LOO'
				when upper(co.ordtype) in ('MARKET') and upper(co.time_in_force) = 'ATOPEN' then 'MOO'
				when upper(co.ordtype) in ('LIMIT') and upper(co.time_in_force) = 'ATCLOSE' then 'LOC'
				when upper(co.ordtype) in ('MARKET') and upper(co.time_in_force) = 'ATCLOSE' then 'MOC'
			end
		)||','||
		-----------------------
		coalesce(cad.fdid, 'PENDING')||','||--firmDesignatedID (#account)
		coalesce(cad.account_holder_type,'A')||','||--accountHolderType
		'false'||','||--affiliate flag
		''||','||--aggregated orders
		------
		'false'||','||--solicitationFlag [28] --2d
		''||','||--Open/Close
		'N'||','||--representativeInd (combined)
		--2d
		''||','||--retired [31]
		''||','|| --[32]
		'' --[33]

		:: varchar

		as ROE

		from compliance.custom_order_event co
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		--and to_char(co.event_timestamp,'YYYYMMDD')::int  = in_date_id
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs is null
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mono_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_mooc_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_mooc_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CUST_CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CUST_CAT_REPORT;

  insert into COMPLIANCE.CUST_CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Option Order -------------------------
        select  in_reporter_imid as CLIENT_MPID, --to take correctly
        'ATLCUST' as FILE_GROUP,
	    '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(coc.event_timestamp,'YYYYMMDD')||'_'||coc.client_oid||'_'||'OC'||'_'||coc.custom_log_import_batch_id::varchar||','||
		'MOOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		--
		bm.osi_symbol||','||

		''||','||--originatingIMID
		to_char(coc.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		'false'||','||--manual flag
		''||','||--electronicTimestamp
		co.qty::varchar||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		'C'||','||--initiator[15]
		''||','||--
		to_char(coc.request_timestamp,'YYYYMMDD HH24MISS.MS') --electronic


		:: varchar

		as ROE

		from compliance.custom_order_event co
		inner join compliance.custom_order_cancel coc on co.client_oid = coc.client_oid and coc.date_id = in_date_id and coc.custom_log_import_batch_id  = co.custom_log_import_batch_id
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_account_data cad on cad.clearing_account  = co.clearing_accnt
		left join compliance.custom_order_mapping om on (om.boe_client_oid  = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		where 1 = 1
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs is null
		and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_mooc_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_cust_atlas_moor_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_cust_atlas_moor_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               'ATLCUST' as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(co.event_timestamp,'YYYYMMDD')||'_'||co.client_oid||'_'||'OR'||'_'||co.custom_log_import_batch_id::varchar||','||
		'MOOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(co.event_timestamp,'YYYYMMDD')||' 000000.000'||','||
		coalesce(io.in_oid,co.client_oid||'_'||co.custom_log_import_batch_id::varchar)||','||
		bm.osi_symbol||','||
		''||','||--originatingIMID
		to_char(co.event_timestamp,'YYYYMMDD HH24MISS.MS')||','||--[10]
		'false'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||
		--co.clearing_firm||','||--senderIMID
		coalesce(ccn.crd_number||':'||co.clearing_firm,'')||','||--senderIMID--v2
		'CBOE'||','||--destination[15]

		'E'||','||--destinationType (F=Industry Member)
		co.client_oid||','||--routedOrderID
		coalesce(co.username,'')||coalesce(co.session_sub_id,'')||','||--session
		--
		case upper(co.side)
		  when 'BUY' then 'B' else 'SL'
		end||','||--side
		case
		    when upper(co.ordtype) in ('LIMIT') and co.price is not null then to_char(abs(co.price), 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		co.qty::varchar||','||
		''||','||--minQty
		case
		    when upper(co.ordtype) in ('LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when upper(co.time_in_force) in ('GTC','IOC') then upper(co.time_in_force)
			when upper(co.time_in_force) in ('GTX') then 'GTX='||to_char(co.event_timestamp,'YYYYMMDD')
			when upper(co.time_in_force) in ('GTD') then 'GTD='||to_char(co.event_timestamp,'YYYYMMDD')
			else 'DAY='||to_char(co.event_timestamp,'YYYYMMDD')
		end||','||
		case
		    when co.session_eligibility = 'R' then 'REG'
			else 'ALL'
		end||','||--[25]
		--handling instructions
		-----------------------
		''||','||
		-----------------------
		case
			when coalesce(rej.cnt,0) > 0 then 'true'
			else 'false'
		end||','||--routeRejectedFlag
		case
		  when upper(co.capacity) = 'MARKETMAKER' then 'M'
		  else 'M'
		end||','||--exchOriginCode
		'false'||','||--affiliate flag
		'false'||','||--multiLegInd [30]
		''||','||--Open/Close
		''||','||--retired [32]
		''||','||--retired [33]
		''||','||--pairedOrderID [34]
		''--netPrice [35]

		:: varchar

		as ROE

		from compliance.custom_order_event co
		left join compliance.crd_number_list ccn on (co.clearing_firm = ccn.cat_imid
			 										 and
			 									 	 (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									     )
		inner join compliance.custom_bats_osi_mapping bm on co.symbol  = bm.bats_symbol
		inner join compliance.custom_log_import_batch bosi on lower(bosi.client_name) = lower(co.client_name) and bosi.custom_log_import_batch_id = bm.custom_log_import_batch_id
		inner join compliance.custom_client_imid ci on lower(ci.client_name) = lower(co.client_name)
		left join compliance.custom_order_mapping om on (om.boe_client_oid = co.client_oid and om.custom_log_import_batch_id  = co.custom_log_import_batch_id )
		left join compliance.custom_in_order io on (io.atlas_oid = om.atlas_oid and io.custom_log_import_batch_id  = om.custom_log_import_batch_id )
		left join lateral
	        (select count(1) as cnt
	         from compliance.custom_order_reject cor
	         where cor.client_oid = co.client_oid
	         and cor.date_id = in_date_id
	         and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id
	         limit 1
	        ) rej on true
		where 1 = 1
		--and to_char(co.event_timestamp,'YYYYMMDD')::int  = in_date_id
		and co.date_id = in_date_id
		and bosi.date_id = in_date_id
		and ci.client_imid = in_reporter_imid
		and co.num_legs is null
		--and co.client_oid not in (select cor.client_oid from compliance.custom_order_reject cor where cor.date_id = in_date_id and cor.custom_log_import_batch_id  = co.custom_log_import_batch_id )

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_cust_atlas_moor_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meco_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meco_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               com.file_group as FILE_GROUP,
              '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_ch'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MECO'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		cl.order_id||','|| --[7]
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		to_char(coalesce(po.create_date_time,cl.create_date_time),'YYYYMMDD')||' 000000.000'||','||
		coalesce(po.order_id, cl.parent_order_id, 'empty')||','||--[10] parentOrderID

		''||','||--originatingIMID
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--[12]

		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[14]
		cl.order_qty||','||
		coalesce(cl.min_quantity::varchar,'')||','||--minQty
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC','GTX') then cl.time_in_force
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','|| --[18]
		'REG'||','||--tradingSession

		--handling instructions
		-----------------------
		compliance.get_handl_inst(cl.order_Id, cl.leg_number,cl.date_id)||','||
		-----------------------
		''||','||-- seqNum[21]
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''--nbboTimestamp [31]
		||
		compliance.get_custom_field(in_reporter_imid,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl

		left join compliance.blaze_d_entity_cat com	on com.company_id  = cl.company_id
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number

		where cl.date_id = in_date_id
		and (cl.broker_dealer_mpid = in_reporter_imid or cl.receiving_broker_mpid = in_reporter_imid) -- receiving?
		and cl.client_event_type_id_1 in (7)

		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

    ) T_ROE
  )ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meco_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mecom_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mecom_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               com.file_group as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_cm'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MECOM'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		cl.order_id||','|| --[7]
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		to_char(coalesce(orig.create_date_time,cl.create_date_time),'YYYYMMDD')||' 000000.000'||','||
		coalesce(orig.order_id, cl.cancel_order_id, 'empty')||','||--[10] priortOrderID

		''||','||--originatingIMID
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--[12]

		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[14]
		cl.order_qty||','||
		coalesce(cl.min_quantity::varchar,'')||','||--minQty
		--
		cl.order_qty||','||--leavesQty - to be adjusted
		--
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC','GTX') then cl.time_in_force
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','|| --[19]
		'REG'||','||--tradingSession

		--handling instructions
		-----------------------
		compliance.get_handl_inst(cl.order_Id, cl.leg_number,cl.date_id)||','||
		-----------------------
		''||','||-- seqNum[22]
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''--nbboTimestamp [32]
		||
		compliance.get_custom_field(in_reporter_imid,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl

		left join compliance.blaze_d_entity_cat com	on com.company_id  = cl.company_id
		left join compliance.blaze_client_order orig on orig.order_id = cl.cancel_order_id and orig.instrument_type_id = 'E' and orig.leg_number = cl.leg_number
		where cl.date_id = in_date_id
		and (cl.broker_dealer_mpid = in_reporter_imid or cl.receiving_broker_mpid = in_reporter_imid) --receiving?
		and cl.client_event_type_id_1 in (7)
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mecom_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mecr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mecr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Route Cancelled-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        /*
               case
                 when cl.client_event_type_id_2 in (3,4) and cl.receiving_broker_mpid = in_reporter_imid then dcom.file_group
                 else com.file_group
               end as FILE_GROUP,
        */
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'ROUTE', in_date_id ) as FILE_GROUP,
        '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_cr'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_'||cl.leg_number::varchar||','||
		'MECR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.date_id::varchar||' 000000.000'
		    else coalesce(po.date_id::varchar||' 000000.000', cl.date_id::varchar||' 000000.000')
		end	||','||
		--parent order, child can be suppressed (no 7)
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when cl.client_event_type_id_2 = 3 and upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.transaction64_order_id::text,'')
		    else coalesce(po.order_id, cl.order_id)
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||--[8]
		''||','||--originatingIMID
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then to_char(cl.create_date_time,'YYYYMMDD HH24MISS') --manual route
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
        end||','||--[10]
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then 'true'
			else 'false'
		end||','||--manual flag[11]

		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp [12]
		exc.last_qty::varchar||','||--cancelled_qty[13]
		''||','|| --[14]
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||
		--
		coalesce(cd.cat_sender_imid, in_reporter_imid)||','||--senderIMID
		--in_reporter_imid||','||--senderIMID [15]
		--
		case
			when cl.receiving_broker_mpid = in_reporter_imid or cl.client_event_type_id_2 = 3 then
		  	case
				when cl.ex_destination = 'XCHI' then
					coalesce(fbcn.crd_number||':'||cl.stock_floor_broker, '') --v2

				when coalesce(drt.is_exchange::varchar,'0') = '1' then
					coalesce(drt.cat_destination_id, '')

			    else
			    	--coalesce(drt.cat_crd_number||':'||drt.cat_destination_id, '')--v2
			    	coalesce(drt.crd_number||':'||drt.cat_destination_id, '')--v2
		   	end
			else
				--coalesce(dcom.imid,'') -- broker routing --v1
				coalesce(dccn.crd_number||':'||dcom.imid,'') --v2
		end||','||--destination[16]
		case
		  when cl.ex_destination = 'XCHI' then 'F'
		  when cl.aors_destination in ('AODIR','NYAOTNT','NYAODIR','PODIR','NYPOTNT','NYPODIR','CBOE') then 'E'
		  when coalesce(drt.is_exchange::varchar,'0') = '1' then 'E'
		  else 'F'
		end||','||--destinationType (F=Industry Member)
		case
			when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.fix_cl_ord_id,cl.order_id)
			when cl.aors_destination = 'LBCHX' then
				case
		    		when cl.side in ('1','8','9') then 'B'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    		else 'S'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    	end
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.routed_onyx_order_id,cl.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||--routedOrderID[18]
		case
			when cl.ex_destination = 'XCHI' then ''
			else coalesce(drt.cat_session,'')
		end||','||--session [19]
		--
		case
			when 1 = 2 --coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject')
				then 'true'
			else 'false'
		end||','||--routeRejectedFlag [20]
		----------------------------
		''||','||--seqNum [21]
		case
			when cl.ex_destination = 'XCHI' and ito.order_id is not null then 'true'
			else 'false'
		end -- multilegInd [22]
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
        inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
        --
		left join compliance.blaze_d_stock_floor_broker fbcn on fbcn.stock_floor_broker = cl.stock_floor_broker
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.crd_number_list dccn on (dcom.imid = dccn.cat_imid
			 										  and
			 									      (dccn.crd_amount = 1 or dccn.is_default = 'Y')
			 									      )
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number --and ((po.date_id > 20200619 and po.time_in_force in ('GTC','GTD')) or po.date_id = in_date_id)
		left join lateral
			( select p.order_id
			  from dwh.client_order p
			  inner join dwh.client_order str on str.parent_order_id = p.order_id and str.create_date_id = in_date_id
			  where p.client_order_id = cl.routed_onyx_order_id
			  	and cl.leg_number::varchar = coalesce(p.co_client_leg_ref_id,'1')
			  	and p.create_date_id  = in_date_id
			  	and p.ex_destination = 'W'
			  	and str.exchange_id = 'C1PAR'
			  	limit 1) spo on true
		--
		left join lateral
			( select p.order_id, p.side
			  from compliance.blaze_client_order p
			  where p.system_order_id = coalesce(po.slr_friendly_id::varchar, cl.slr_friendly_id::varchar)
			  	and p.instrument_type_id = 'E'
			  	and p.date_id  = in_date_id
			  	and p.ex_destination = 'ITO'
			  	limit 1) ito on true
		--
		--modification route should be reported
		left join compliance.blaze_client_order orcl on orcl.order_id = cl.cancel_order_id and orcl.instrument_type_id = 'E' and orcl.leg_number = cl.leg_number
		--
		left join compliance.blaze_d_route drt on (drt.ex_destination = cl.ex_destination )
		--
        left join compliance.blaze_client2destination cd on (cd.ex_destination = cl.ex_destination and cd.client_imid = in_reporter_imid)
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = coalesce(exc.child_report_id, exc.report_id)
	    and cl.date_id > 20200619
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))
		--
		and ((cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name <> 'BLAZE7' and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --electronic market routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			  or
			 (cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_1 = 5 and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --broker routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 4 and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		--suppress manual for configuration = 5
		and ((cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null) is false
				or coalesce(com.cat_configuration,'') not like '%5%')
		and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and coalesce(drt.cat_route_suppress::varchar, '0' ) = '0'
		and cl.instrument_type_id = 'E'
		--and coalesce(cl.order_status,'') not in ('Reject','Ex Reject','Report Cancel Replace Reject')

		and spo.order_id is null
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mecr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meic_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meic_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Internal Route Cancelled-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        /*
               case
                 when cl.client_event_type_id_1 in (1,6) then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
               */
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEIC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||

		''||','||--originatingIMID
		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp +
		'false'||','||--manual flag
		''||','||--electronicTimestamp [12]
		exc.last_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		'C'||','||--initiator[15] (ReplaceOrderID)
		--=========--
		--2d fields--
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','|| --[16] requestTimestamp (need to take from 'F' msg)
		'' --[17]
		--=========--
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = exc.child_report_id
	    and cl.date_id > 20200619
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid  and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																   --and coalesce(dcom.imid,com.imid) = coalesce(cl.user_imid,''))
																																   and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)
		--suppress manual for configuration = 5--
		and (cl.client_event_type_id_1 in (1,3)  or coalesce(dcom.cat_configuration,'') not like '%5%')
		--
		--and cl.generation = 0
		and cl.instrument_type_id = 'E'
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count = 1
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meic_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meim_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meim_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Inernal Route Modified-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_m'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEIM'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		--===================
		to_char(coalesce(orig.create_date_time, cl.create_date_time),'YYYYMMDD')||' 000000.000'||','||--priorOrderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(orig.transaction64_order_id::text,orig.order_id)
			else orig.order_id
		end||','||--priorOrderID[10]
		--
		--cl.cancel_order_id||','||--priorOrderID[10]
		--===================
		''||','||--originatingIMID

		--2d - timestamp should be taken from 5/5 execution
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp
		--

		'false'||','||--manual flag
		''||','||--electronicTimestamp
		coalesce(dcom.dept_type,'A')||','||--deptType(Agency)[15]
		coalesce(dcom.receiving_desk_type,'A')||','||--receivingDeskType
		--
		''||','||--infoBarrierID
		'C'||','||--initiator
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||--[21]
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		cl.order_qty||','||--leavesQty - to be adjusted

		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[27]
		--=========--
		--2d fields--
		--use execution 5/5 for eventTimestamp
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','|| --[28] requestTimestamp
		'' --[29]
		--=========--
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		--

		from compliance.blaze_client_order cl
		inner join compliance.blaze_client_order orig on cl.cancel_order_id = orig.order_id and orig.instrument_type_id = 'E' and orig.leg_number = cl.leg_number
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order pcl on cl.parent_order_id = pcl.order_id and pcl.instrument_type_id = 'E' and pcl.leg_number = cl.leg_number and pcl.date_id > 20200619
		--=====================
		--left join dwh.client_order scl on scl.client_order_id = cl.system_order_id and scl.create_date_id = in_date_id and scl.parent_order_id is not null and scl.ex_destination = 'BRKPT' and coalesce(scl.co_client_leg_ref_id,'1')  = cl.leg_number::varchar
		--left join dwh.client_order pscl on pscl.order_id = scl.parent_order_id and pscl.create_date_id = in_date_id
		--=====================
		where cl.date_id = in_date_id
		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid  and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																   --and coalesce(dcom.imid,com.imid) = coalesce(cl.user_imid,''))
																																   and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count = 1
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meim_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meir_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meir_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Internal Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_i'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEIR'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		case
			when cl.generation > 0 then to_char(coalesce(pcl.create_date_time, cl.create_date_time),'YYYYMMDD')||' 000000.000'
			else to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'
		end||','||--parentOrderKeyDate
		case
			when cl.generation > 0  and cl.system_name = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.parent_order_id)
			when cl.generation > 0 then cl.parent_order_id
			when cl.client_event_type_id_1 in (1,3) and cl.broker_dealer_mpid = 'SGAS' and position('*' in cl.free_text) > 0 then substring(cl.free_text, 1, position('*' in cl.free_text)-1)
			when cl.client_event_type_id_1 in (1,3) then coalesce(cl.cat_order_id,cl.system_order_id)
			else ''
		end||','||--parentOrderID[10]

		''||','||--originatingIMID
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp
		--this is not manual event:
		'false'||','||--manual flag
		''||','||--electronicTimestamp
		coalesce(dcom.dept_type,'A')||','||--deptType(Agency)[15]
		--
		coalesce(dcom.receiving_desk_type,'A')||','||--receivingDeskType
		--
		''||','||--infoBarrierID
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||--[20]
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		--2d fields
		'false'||','|| --[26]
		'' --[27]
		--
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order pcl on cl.parent_order_id = pcl.order_id and pcl.instrument_type_id = 'E' and pcl.leg_number = cl.leg_number

		where cl.date_id = in_date_id
		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid  and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																   --and coalesce(dcom.imid,com.imid) = cl.user_imid)
																																   and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count = 1
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meir_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_memr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_memr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Route Modified-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        /*
               case
                 when cl.client_event_type_id_2 in (3,4) and cl.receiving_broker_mpid = in_reporter_imid then dcom.file_group
                 else com.file_group
               end as FILE_GROUP,
        */
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'ROUTE', in_date_id ) as FILE_GROUP,
        '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_mr'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_'||cl.leg_number::varchar||','||
		'MEMR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.date_id::varchar||' 000000.000'
		    else coalesce(po.date_id::varchar||' 000000.000', cl.date_id::varchar||' 000000.000')
		end	||','||
		--parent order, child can be suppressed (no 7)
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when cl.client_event_type_id_2 = 3 and upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.transaction64_order_id::text,'')
		    else coalesce(po.order_id, cl.order_id)
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','|| --[8]
		''||','||--originatingIMID
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then to_char(cl.create_date_time,'YYYYMMDD HH24MISS') --manual route
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
        end||','||--[10]
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then 'true'
			else 'false'
		end||','||--manual flag (true for manual route)

		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp temp.removed
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||
		--
		coalesce(cd.cat_sender_imid, in_reporter_imid)||','||--senderIMID [13]

		--
		case
			when cl.receiving_broker_mpid = in_reporter_imid or cl.client_event_type_id_2 = 3 then
		  	case
				when cl.ex_destination = 'XCHI' then
					coalesce(fbcn.crd_number||':'||cl.stock_floor_broker, '') --v2

				when coalesce(drt.is_exchange::varchar,'0') = '1' then
					coalesce(drt.cat_destination_id, '')

			    else
			    	--coalesce(drt.cat_crd_number||':'||drt.cat_destination_id, '')--v2
			    	coalesce(drt.crd_number||':'||drt.cat_destination_id, '')--v2
		   	end
			else
				--coalesce(dcom.imid,'') -- broker routing --v1
				coalesce(dccn.crd_number||':'||dcom.imid,'') --v2
		end||','||--destination[14]
		case
		  when cl.ex_destination = 'XCHI' then 'F'
		  when cl.aors_destination in ('AODIR','NYAOTNT','NYAODIR','PODIR','NYPOTNT','NYPODIR','CBOE') then 'E'
		  when coalesce(drt.is_exchange::varchar,'0') = '1' then 'E'
		  else 'F'
		end||','||--destinationType (F=Industry Member) [15]
		case
			when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.fix_cl_ord_id,cl.order_id)
			when cl.aors_destination = 'LBCHX' then
				case
		    		when cl.side in ('1','8','9') then 'B'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    		else 'S'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    	end
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.routed_onyx_order_id,cl.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||--routedOrderID [16]
		--
		case
		    when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (orig.fix_cl_ord_id,orig.order_id)
			when cl.aors_destination = 'LBCHX' then
				case
		    		when cl.side in ('1','8','9') then 'B'||coalesce (orig.routed_onyx_order_id,orig.order_id)
		    		else 'S'||coalesce (orig.routed_onyx_order_id,orig.order_id)
		    	end
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (orig.routed_onyx_order_id,orig.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(orig.transaction64_order_id::text,orig.order_id)
			else orig.order_id
		end||','||--priorRoutedOrderID [17]
		--
		case
			when cl.ex_destination = 'XCHI' then ''
			else coalesce(drt.cat_session,'')
		end||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.order_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty [22]
		''||','|| --[23]
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','|| --[24]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','|| --[25]
		'REG'||','||--[26]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd [28]
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		----------- 2c -------------
		case
			when coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject') then 'true'
			else 'false'
		end||','||--routeRejectedFlag [30]
		----------------------------
		'false'||','||--dupROIDCond[31]
		''||','||--seqNum [32]
		''||','||-- [33] netPrice
		case
			when cl.ex_destination = 'XCHI' and ito.order_id is not null then 'true'
			else 'false'
		end-- [34] multilegInd
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		inner join compliance.blaze_client_order orig on orig.order_id = cl.cancel_order_id
		left join compliance.blaze_d_stock_floor_broker fbcn on fbcn.stock_floor_broker = cl.stock_floor_broker
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.crd_number_list dccn on (dcom.imid = dccn.cat_imid
			 										  and
			 									      (dccn.crd_amount = 1 or dccn.is_default = 'Y')
			 									      )
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number --and ((po.date_id > 20200619 and po.time_in_force in ('GTC','GTD')) or po.date_id = in_date_id)
		left join lateral
			( select p.order_id
			  from dwh.client_order p
			  inner join dwh.client_order str on str.parent_order_id = p.order_id and str.create_date_id = in_date_id
			  where p.client_order_id = cl.routed_onyx_order_id
			  	and cl.leg_number::varchar = coalesce(p.co_client_leg_ref_id,'1')
			  	and p.create_date_id  = in_date_id
			  	and p.ex_destination = 'W'
			  	and str.exchange_id = 'C1PAR'
			  	limit 1) spo on true
		left join lateral
			( select p.order_id, p.side
			  from compliance.blaze_client_order p
			  where p.system_order_id = coalesce(po.slr_friendly_id::varchar, cl.slr_friendly_id::varchar)
			  	and p.instrument_type_id = 'E'
			  	and p.date_id  = in_date_id
			  	and p.ex_destination = 'ITO'
			  	limit 1) ito on true
		--
		--modification route should be reported
		left join compliance.blaze_client_order orcl on orcl.order_id = cl.cancel_order_id and orcl.instrument_type_id = 'E' and orcl.leg_number = cl.leg_number
		--
		left join compliance.blaze_d_route drt on (drt.ex_destination = cl.ex_destination )
		--
        left join compliance.blaze_client2destination cd on (cd.ex_destination = cl.ex_destination and cd.client_imid = in_reporter_imid)
		where cl.date_id = in_date_id
		and ((cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name <> 'BLAZE7' and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --electronic market routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			  or
			 (cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_1 = 5 and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --broker routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 4 and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		--suppress manual for configuration = 5
		and ((cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null) is false
				or coalesce(com.cat_configuration,'') not like '%5%')
		and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and coalesce(drt.cat_route_suppress::varchar, '0' ) = '0'
		and cl.instrument_type_id = 'E'
		--and coalesce(cl.order_status,'') not in ('Reject','Ex Reject','Report Cancel Replace Reject')
		--
		and (cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000' --and coalesce(cl.client_event_type_id_1,0) <> 2
			)
		--
		and spo.order_id is null
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_memr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meno_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meno_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt integer;
prev_size integer;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order New-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        		/*
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 or upper(cl.system_name) = 'BLAZE7' then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
         		*/
        		compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'NEW', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		to_char(cl.create_date_time,'YYYYMMDD')||'_'||cl.system_order_id::varchar||'_n'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MENO'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		--B7 logic
		case upper(cl.system_name)
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||

		case
		    --representative is electronic
		    --when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.leg_count > 1
		    --proprietary
		    when cl.user_acc_holder_type in ('V','P')
		    	then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--Timestamp for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')
			--Electronic
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--eventTimestamp

		case
		    when cl.user_acc_holder_type in ('V','P') then 'false'
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then 'true'
			else 'false'
		end||','||--manual flag[10]

		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then 'false' --manual order
			when li.order_id is not null then 'true'
			else 'false'
		end||','||--electronicDupFlag
		case
		    --proprietary
		    when cl.user_acc_holder_type in ('V','P')
		    	then ''
			--for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--electronic
			else ''
		end||','||--electronicTimestamp
		--suppressed for 2a/2b
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then '' --manual order
			when li.order_id is not null then to_char(li.create_date_time,'YYYYMMDD')||' 000000.000'
			else ''
		end||','||--manualOrderKeyDate [13]
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then '' --manual order
			when li.order_id is not null then
				case upper(li.system_name)
					when 'BLAZE7' then coalesce(li.transaction64_order_id::text,li.order_id)
					else li.order_id
				end
			else ''
		end||','||--manualOrderID
		--
		case
			when cl.client_event_type_id_1 in (2) and upper(cl.system_name) = 'BLAZE' then coalesce(com.dept_type,'A')
			else coalesce(dcom.dept_type,com.dept_type,'A')
		end||','||--deptType(Agency)[15]
		-- 2c
		'false'||','||--solicitationFlag [16]
		--
		''||','||--reservedForFutureUse
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(abs(coalesce(cl.order_price,0)), 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			--else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
			else 'DAY='||cl.date_id::varchar
		end||','||
		'REG'||','||
		--handling instructions[25]
		-----------------------
		--compliance.get_handl_inst_2c(cl.order_id, cl.leg_number, cl.date_id)||','||
		--
		concat_ws
			('|',
			nullif(compliance.get_handl_inst_2c(cl.order_id, cl.leg_number, cl.date_id),''),
			case
				when nullif(cl.slr_friendly_id,0) is not null then 'OPT'
			end
			)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||
		case
			when cl.client_event_type_id_1 in (1,2) and cl.obo_user is null then coalesce(nullif(cl.user_fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.fdid,''),nullif(cl.user_fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
		    --
			else coalesce(nullif(com.fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
		end||','||--firmDesignatedID (#account)
		case
			when cl.client_event_type_id_1 in (1,2)  and cl.obo_user is null then coalesce(nullif(cl.user_acc_holder_type,''),'A')
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.account_holder_type,''),nullif(cl.user_acc_holder_type,''),'A')
			--
			else coalesce(nullif(com.account_holder_type,''),'A')
		end||','||--accountHolderType --[28]
		case
			when cl.client_event_type_id_1 = 1 and dcom.parent = cl.user_parent then 'true'
			when cl.client_event_type_id_1 = 2 and cl.acc_affiliate_flag = '1' then 'true'
			when cl.client_event_type_id_2 = 4 and dcom.parent = com.parent then 'true'
			else 'false'
		end||','||--affiliate flag
		''||','||--infoBarrierID[30]
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then compliance.get_represented_orders(cl.order_id, cl.date_id)
			else ''
		end||','||--aggregated orders
		'false'||','||--negotiatedTradeFlag
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then 'Y'
			else 'N'
		end||','||--representativeInd
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||--[45]
		--2d
		'' --[46]
		--
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_client_order li on li.linked_order_id = cl.order_id and li.is_linked = 'Y' and li.date_id = in_date_id
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)

		where cl.date_id = in_date_id
		--
		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and coalesce(com.is_broker_dealer,'0') = '0') --incoming broker routing
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '0') --manual order entry
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '0') --manual order entry
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '0' ) --fix staging
			)
		--
		--suppress manual for configuration = 5--v2
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'DEST' --
			or coalesce(compliance.get_config_5_manual_flag(cl.replace_order_id, in_date_id),'DEST') <> 'DEST'
			or coalesce(dcom.cat_configuration,'') not like '%5%')
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'COM' --
			or coalesce(compliance.get_config_5_manual_flag(cl.replace_order_id, in_date_id),'COM') <> 'COM'
			or coalesce(com.cat_configuration,'') not like '%5%')
		--
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject')
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and (cl.ex_destination not in ('ITO','XCHI') or coalesce(nullif(cl.slr_friendly_id,0)::varchar,cl.system_order_id) = cl.system_order_id)
		--
		--and nullif(cl.slr_friendly_id,0) is null
		--
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meno_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meno_tts_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meno_tts_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt integer;
prev_size integer;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_n'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MENO'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		cl.order_id||','||

		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||

		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--eventTimestamp
		'true'||','||--manual flag[10]

		'false'||','||--electronicDupFlag
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp
		--suppressed for 2a/2b
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--manualOrderKeyDate [13]
		''||','||--cl.order_id||','||--manualOrderID
		--
		case
			when cl.client_event_type_id_1 in (2) then coalesce(com.dept_type,'A')
			else coalesce(dcom.dept_type,'A')
		end||','||--deptType(Agency)[15]
		'false'||','||-- solicitationFlag [16]
		''||','||--reservedForFutureUse
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when cl.tied_stock_price > 0 then to_char(cl.tied_stock_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.tied_stock_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
		    when cl.tied_stock_price > 0  then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||
		--handling instructions[25]
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||
		case
			when cl.client_event_type_id_1 in (1,2) and cl.obo_user is null then coalesce(nullif(cl.user_fdid,''),'PENDING')
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.fdid,''),nullif(cl.user_fdid,''),'PENDING')
			--
			else coalesce(nullif(com.fdid,''),'PENDING')
		end||','||--firmDesignatedID (#account)
		case
			when cl.client_event_type_id_1 in (1,2)  and cl.obo_user is null then coalesce(nullif(cl.user_acc_holder_type,''),'A')
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.account_holder_type,''),nullif(cl.user_acc_holder_type,''),'A')
			--
			else coalesce(nullif(com.account_holder_type,''),'A')
		end||','||--accountHolderType --[28]
		case
			when cl.client_event_type_id_1 = 1 and dcom.parent = cl.user_parent then 'true'
			when cl.client_event_type_id_1 = 2 and cl.acc_affiliate_flag = '1' then 'true'
			when cl.client_event_type_id_2 = 4 and dcom.parent = com.parent then 'true'
			else 'false'
		end||','||--affiliate flag
		''||','||--infoBarrierID[30]
		''||','||--aggregated orders
		'false'||','||--negotiatedTradeFlag
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.leg_count > 1 then 'YF'
			else 'N'
		end||','||--representativeInd
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||--[45]
		--2d
		'' --[46]
		--
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where cl.date_id = in_date_id
		--
		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '0') --manual order entry
			)
		--
		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		and coalesce(cl.stock_floor_broker,'') <> 'AWAY'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meno_tts_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoa_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoa_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        /*
               case
                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 or cl.system_name = 'BLAZE7' then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
               */
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'NEW', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_a'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOA'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS') -- this is for manual orders
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--eventTimestamp
		case
			when cl.client_event_type_id_1 = 2 or (cl.client_event_type_id_2 = 4 and cl.obo_user is not null)  then 'true'
			else 'false'
		end||','||--manual flag [10]
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then 'false' --manual order
			when cl.is_linked = 'Y' and cl.linked_order_id <> '00000000-0000-0000-0000-000000000000' then 'true'
			else 'false'
		end||','||--electronicDupFlag
		case
			--merged events:
		    when nullif(cl.electronic_order_time,'') is not null
		    	then to_char(cl.create_date_time,'YYYYMMDD')||' '||replace(substring(cl.electronic_order_time, 12, 12),':','')
		    --
			when cl.client_event_type_id_1 = 2 or (cl.client_event_type_id_2 = 4 and cl.obo_user is not null)
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		    else '' --manual flag is false
		end||','||--electronicTimestamp
		------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--receiverIMID [13]
		------------------------------------------
		case
			when cl.client_event_type_id_1 in (1,3) then
				--coalesce(cl.user_imid,com.imid,'')--v1
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			when cl.client_event_type_id_1 = 2 and (cl.obo_user is null or cl.company_id = cl.dest_company_id) then
				--coalesce(cl.user_imid,'')--v1
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			else
				--coalesce(com.imid,cl.user_imid,'')--v1
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
		end||','||--senderIMID
		------------------------------------------
		'F'||','||--senderType (F=Industry Member)
		--B7 logic
		case
			--merged events:
		    when nullif(cl.electronic_order_id,'') is not null
		    	then cl.electronic_order_id
		    --
			when cl.client_event_type_id_1 in (1,3) and pcl.order_id is not null then
				coalesce(fxm.fix_message->>'8006',pcl.client_order_id,cl.system_order_id,cl.order_id) --add 8006 from parent fix message
			when cl.client_event_type_id_1 in (1,3) then coalesce(cl.cat_order_id,cl.system_order_id,cl.order_id)
			when cl.client_event_type_id_2 = 4  and cl.system_name = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			when cl.client_event_type_id_2 = 4  then cl.order_id
			else ''
		end||','||--routedOrderID[16]
		--
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then '' --manual order
			when cl.is_linked = 'Y' and cl.linked_order_id <> '00000000-0000-0000-0000-000000000000' then to_char(li.create_date_time,'YYYYMMDD')||' 000000.000'
			else ''
		end||','||--manualOrderKeyDate
		case
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then '' --manual order
			when cl.is_linked = 'Y' and cl.linked_order_id <> '00000000-0000-0000-0000-000000000000' then li.order_id
			else ''
		end||','||--manualOrderID
		case
			when cl.client_event_type_id_1 in (1,3) and dcom.parent = cl.user_parent then 'true'
			when cl.client_event_type_id_1 = 2 and cl.acc_affiliate_flag = '1' then 'true'
			when cl.client_event_type_id_2 = 4 and dcom.parent = com.parent then 'true'
			else 'false'
		end||','||--affiliate flag
		case
			when cl.client_event_type_id_1 in (2) then coalesce(com.dept_type,'A')
			else coalesce(dcom.dept_type,'A')
		end||','||--deptType(Agency)
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||--[25]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd (need to take from ExecInst=f and TIF=Day/IOC )
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||--custDspIntrFlag[30]
		''||','||--infoBarrierID[31]
		--------------n/a-------------
		''||','||--seqNum
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||-- [43]
		'false'||','|| -- solicitationFlag[44]
		--2d
		''||','|| --[45] pairedOrderID
		'' --[46]
		--
		||


		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_client_order li on li.order_id = cl.linked_order_id
		left join compliance.crd_number_list ucn on (upper(cl.user_imid) = ucn.cat_imid
			 										 and
			 									    (ucn.crd_amount = 1 or ucn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.crd_number_list ccn on (com.imid = ccn.cat_imid
			 										 and
			 									    (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)

		left join dwh.client_order scl on (scl.client_order_id = cl.system_order_id
									  and scl.create_date_id = in_date_id
									  and scl.parent_order_id is not null
									  and scl.ex_destination = 'BRKPT'
									  and scl.multileg_reporting_type <> '3'
									  and coalesce(scl.co_client_leg_ref_id,'1')  = cl.leg_number::varchar)
		left join dwh.client_order pcl on pcl.order_id = scl.parent_order_id and pcl.create_date_id = in_date_id
		left join lateral
	        (select j.fix_message
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = pcl.fix_message_id
	         and j.date_id = in_date_id
	         limit 1
	        ) fxm on true
		where cl.date_id = in_date_id
		--
		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and com.is_broker_dealer = '1') --incoming broker routing, acceptance
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and cl.system_name = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '1')
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '1')
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
			 																													  --and coalesce(dcom.imid,com.imid,'') <> coalesce(cl.user_imid,''))
			 																													  and coalesce(cl.user_imid,com.imid,'') <> coalesce(dcom.imid,''))
			)
		--
		--suppress manual for configuration = 5--
		--broker routing, obo
		and (coalesce(cl.client_event_type_id_2,0) <> 4 or coalesce(cl.obo_user,'') is null or coalesce(dcom.cat_configuration,'') not like '%5%')
		--manual entry
		and (coalesce(cl.client_event_type_id_1,0) <> 2 or  coalesce(com.cat_configuration,'') not like '%5%')
		--
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and coalesce(cl.system_order_type,'')  <> 'Stitched Single'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, FILE_GROUP, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoa_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoa_tts_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoa_tts_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_a'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MEOA'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		cl.order_id||','||

		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||

		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--eventTimestamp
		'true'||','||--manual flag [10]
		'false'||','||--electronicDupFlag - need to check
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp
		------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--receiverIMID [13]
		------------------------------------------
		case
			when cl.client_event_type_id_1 = 1 then
				--coalesce(cl.user_imid,com.imid,'')--v1
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			when cl.client_event_type_id_1 = 2 and (cl.obo_user is null or cl.company_id = cl.dest_company_id) then
				--coalesce(cl.user_imid,'')--v1
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			else
				--coalesce(com.imid,cl.user_imid,'')--v1
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
		end||','||--senderIMID
		'F'||','||--senderType (F=Industry Member)
		case
			when cl.client_event_type_id_1 = 1  then coalesce(cl.system_order_id,cl.order_id)
			when cl.client_event_type_id_2 = 4 and cl.system_name = 'AORS' and cl.generation = 0 then coalesce(cl.system_order_id,cl.order_id)
			when cl.client_event_type_id_2 = 4 and cl.system_name = 'BLAZE' and cl.generation > 0 then cl.order_id
			else ''
		end||','||--routedOrderID[16]
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID
		case
			when cl.client_event_type_id_1 = 1 and dcom.parent = cl.user_parent then 'true'
			when cl.client_event_type_id_1 = 2 and cl.acc_affiliate_flag = '1' then 'true'
			when cl.client_event_type_id_2 = 4 and dcom.parent = com.parent then 'true'
			else 'false'
		end||','||--affiliate flag
		case
			when cl.client_event_type_id_1 in (2) then coalesce(com.dept_type,'A')
			else coalesce(dcom.dept_type,'A')
		end||','||--deptType(Agency)
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when cl.tied_stock_price > 0 then to_char(cl.tied_stock_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.tied_stock_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
		    when cl.tied_stock_price > 0  then 'LMT'
			else 'MKT'
		end||','||--[25]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd (need to take from ExecInst=f and TIF=Day/IOC )
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||--custDspIntrFlag[30]
		''||','||--infoBarrierID[31]
		--------------n/a-------------
		''||','||--seqNum
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||--[43]
		'false'||','|| -- solicitationFlag[44]
		--2d
		''||','|| --[45] pairedOrderID
		'' --[46]
		--
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.crd_number_list ucn on (upper(cl.user_imid) = ucn.cat_imid
			 										 and
			 									    (ucn.crd_amount = 1 or ucn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.crd_number_list ccn on (com.imid = ccn.cat_imid
			 										 and
			 									    (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where cl.date_id = in_date_id
		--
		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '1')
			)
		--
		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		and coalesce(cl.stock_floor_broker,'') <> 'AWAY'
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, FILE_GROUP, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoa_tts_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--orderKeyDate
		(select to_char(max(exc.transaction_date_time) ,'YYYYMMDD')||' 000000.000'
			from compliance.blaze_execution exc
			where exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number)||','||
		cl.order_id||','||
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		--------------------------
		--to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		(select to_char(max(exc.transaction_date_time) ,'YYYYMMDD HH24MISS.MS')
			from compliance.blaze_execution exc
			where exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number)||','||
		--
		case
			when cl.client_event_type_id_1 = 1 then 'false'
			else 'true'
		end||','||--manual flag
		''||','||--electronicTimestamp
		cl.order_qty-cl.filled_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
			when cl.client_event_type_id_1 = 1 then 'C' --electronic
			else 'F'
		end||','||--initiator[15]
		''--seqNum
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		--inner join compliance.blaze_execution exc on exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number
		where cl.date_id = in_date_id

		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid ) --incoming broker routing, acceptance
			 or
			 (cl.client_event_type_id_1 = 1 and cl.receiving_broker_mpid = in_reporter_imid and dcom.imid <> cl.user_imid)
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid ) --suppression for manual events
			)

		--and cl.generation = 0
		and cl.instrument_type_id = 'E'
		and exists (select 1 from compliance.blaze_execution exc
					where exc.order_id = cl.order_id
					and exc.status in ('Canceled','Ex Rpt Out')
					and cl.leg_number = exc.leg_number
					and exc.report_id  = exc.child_report_id
					)
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_record_2(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_record_2(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 or cl.system_name = 'BLAZE7' then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		exc.date_id::varchar||'_'||exc.report_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then cl.transaction64_order_id::text
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		--------------------------
		case
			when cl.client_event_type_id_1 in (1,3) then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')
		end||','||--eventTimestamp[10]
		--
		case
			when cl.client_event_type_id_1 in (1,3) then 'false'
			else 'true'
		end||','||--manual flag
		''||','||--electronicTimestamp
		--cl.order_qty-cl.filled_qty||','||--cancelled_qty
		exc.last_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
			when cl.client_event_type_id_1 in (1,3) then 'C' --electronic
			else 'F'
		end||','||--initiator[15]
		''--seqNum
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = exc.child_report_id
	    and cl.date_id > 20200619
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','')) --incoming broker routing, acceptance
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and cl.system_name = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid --and dcom.imid <> coalesce(cl.sender_imid,cl.user_imid))
			 																													  and coalesce(cl.user_imid,com.imid,'') <> coalesce(dcom.imid,''))
			)
		--suppress manual for configuration = 5--
		and (cl.client_event_type_id_1 in (1,3)  or coalesce(dcom.cat_configuration,'') <> '5')
		--
		--and cl.generation = 0
		and cl.instrument_type_id = 'E'
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_record_2(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;
/*
 * WHEN (r.SystemID = 2 and r.Status = 133 and r.Order64ID = 0) or (r.ContraBroker <> '' and r.Order64ID <> 0)  then 'trader cancel'
 */

begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Cancelled-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'NEW', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(exc.transaction_date_time,'YYYYMMDD')||'_'||exc.report_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case upper(cl.system_name)
			when 'BLAZE7' then cl.transaction64_order_id::text
			else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		--------------------------
		case
		/*
			when cl.client_event_type_id_1 in (1,3) then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')
		*/
			when exc.system_name = 'BLAZE' and exc.status = 'Canceled' and coalesce(exc.order64_id,'0') = '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS') --manual
			when nullif(exc.contra_broker,'') <>'' and coalesce(exc.order64_id,'0') <> '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--eventTimestamp[10]

		--
		case
		/*
			when cl.client_event_type_id_1 in (1,3) then 'false'
			else 'true'
		*/
			when exc.system_name = 'BLAZE' and exc.status = 'Canceled' and coalesce(exc.order64_id,'0') = '0' then 'true'--manual
			when nullif(exc.contra_broker,'') <>'' and coalesce(exc.order64_id,'0') <> '0' then 'true'
			else 'false'
		end||','||--manual flag
		case
			when exc.system_name = 'BLAZE' and exc.status = 'Canceled' and coalesce(exc.order64_id,'0') = '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS') --manual
			when nullif(exc.contra_broker,'') <>'' and coalesce(exc.order64_id,'0') <> '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
			else ''
		end||','||--electronicTimestamp
		--cl.order_qty-cl.filled_qty||','||--cancelled_qty
		exc.last_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
		/*
			when cl.client_event_type_id_1 in (1,3) then 'C' --electronic
			else 'F'
		*/
			when exc.system_name = 'BLAZE' and exc.status = 'Canceled' and coalesce(exc.order64_id,'0') = '0' then 'F'--manual
			when nullif(exc.contra_broker,'') <>'' and coalesce(exc.order64_id,'0') <> '0' then 'F'
			else 'C' --electronic
		end||','||--initiator[15]
		''||','||---seqNum
		case
		/*
			when cl.client_event_type_id_1 in (1,3) then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')
		*/
			when exc.system_name = 'BLAZE' and exc.status = 'Canceled' and coalesce(exc.order64_id,'0') = '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS') --manual
			when nullif(exc.contra_broker,'') <>'' and coalesce(exc.order64_id,'0') <> '0' then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS') --electronic
		end||','||--requestTimestamp[17]
		'' --infoBarrierId
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		--and exc.report_id  = exc.child_report_id
		and exc.report_id  = coalesce(exc.child_report_id, exc.report_id)
	    and cl.date_id > 20200619
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','')) --incoming broker routing, acceptance
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid --and dcom.imid <> coalesce(cl.sender_imid,cl.user_imid))
			 																													  and coalesce(cl.user_imid,com.imid,'') <> coalesce(dcom.imid,''))
			)
		--suppress manual for configuration = 5--
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'DEST' or coalesce(dcom.cat_configuration,'') not like '%5%')
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'COM' or coalesce(com.cat_configuration,'') not like '%5%')
		--
		--and cl.generation = 0
		and cl.instrument_type_id = 'E'
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and (cl.ex_destination not in ('ITO','XCHI') or coalesce(nullif(cl.slr_friendly_id,0)::varchar,cl.system_order_id) = cl.system_order_id)
		--
		--and nullif(cl.slr_friendly_id,0) is null
		--
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_tts_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_tts_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--orderKeyDate
		(select to_char(max(exc.transaction_date_time) ,'YYYYMMDD')||' 000000.000'
			from compliance.blaze_execution exc
			where exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number)||','||
		cl.order_id||','||
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		--------------------------
		--to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		(select to_char(max(exc.transaction_date_time) ,'YYYYMMDD HH24MISS.MS')
			from compliance.blaze_execution exc
			where exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number)||','||
		--
		'true'||','||--manual flag
		''||','||--electronicTimestamp
		cl.order_qty-cl.filled_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
			when cl.client_event_type_id_1 = 1 then 'C' --electronic
			else 'F'
		end||','||--initiator[15]
		''--seqNum
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		--inner join compliance.blaze_execution exc on exc.order_id = cl.order_id and exc.status in ('Canceled','Ex Rpt Out') and cl.leg_number = exc.leg_number
		where cl.date_id = in_date_id

		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','')) --incoming broker routing, acceptance
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 = 1 and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and dcom.imid <> cl.user_imid)
			)

		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		and cl.stock_floor_broker is not null
		and exists (select 1 from compliance.blaze_execution exc
					where exc.order_id = cl.order_id
					and exc.status in ('Canceled','Ex Rpt Out')
					and cl.leg_number = exc.leg_number
					and exc.report_id  = exc.child_report_id )
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_tts_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_tts_record_2(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_tts_record_2(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		exc.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		cl.order_id||','||
		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||
		''||','||--originatingIMID
		--------------------------
		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp[10]
		--
		'true'||','||--manual flag
		''||','||--electronicTimestamp
		cl.tied_stock_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
			when cl.client_event_type_id_1 = 1 then 'C' --electronic
			else 'F'
		end||','||--initiator[15]
		''--seqNum
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where exc.date_id  = in_date_id
		and cl.date_id > 20200619
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = exc.child_report_id
		and exc.cum_qty = 0
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			)

		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		--and cl.stock_floor_broker is not null
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_tts_record_2(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meoc_tts_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meoc_tts_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Cancel-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		exc.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MEOC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate

		cl.order_id||','||
		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||
		''||','||--originatingIMID
		--------------------------
		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')||','||--eventTimestamp[10]
		--
		'true'||','||--manual flag
		''||','||--electronicTimestamp
		cl.tied_stock_qty||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		case
			when cl.client_event_type_id_1 = 1 then 'C' --electronic
			else 'F'
		end||','||--initiator[15]
		''||','||---seqNum
		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')||','||--requestTimestamp[17]
		'' --infoBarrierId

		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where exc.date_id  = in_date_id
		and cl.date_id > 20200619
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = exc.child_report_id
		and exc.cum_qty = 0
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			)

		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		--and cl.stock_floor_broker is not null
		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meoc_tts_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meof_repr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meof_repr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Full.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when upper(cl.system_name) = 'BLAZE' then com.file_group
                 else coalesce(dcom.file_group, com.file_group)
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(exc.transaction_date_time,'YYYYMMDD')||'_'||exc.report_id::varchar||'_rf'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOF'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		--report id
		exc.report_id||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||

		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS')||','||--[9]
		--
		'true'||','||--manual flag (true for manual route)
		--

		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp [11]
		--
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		'Y'||','||
		'false'||','||--[13]
		''||','||--[14] cancelTimestamp
		---------------------------------------------------------------------------------------------------------------------------------------------------------

		exc.last_qty||','||
		exc.last_px||','||
		''||','|| --[17] capacity
		--
		--[18] clientDetails
				to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||'@'||
				case cl.system_name
					when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
					else cl.order_id
				end||'@'||
				case cl.side
				    when '1' then 'B'
				    when '2' then 'SL'
				    when '5' then 'SS'
				    when '6' then 'SX'
				    else 'B'
				end||'@'||
				''||'@'||--blank
				''||'@'||--fdid
				''||'@'||--acc.hold.type
				''--orig.IMID
		||','||
		--[19] firmDetails
				to_char(rep.create_date_time,'YYYYMMDD')||' 000000.000'||'@'||
				case rep.system_name
					when 'BLAZE7' then coalesce(rep.transaction64_order_id::text,rep.order_id)
					else rep.order_id
				end||'@'||
				case rep.side
				    when '1' then 'B'
				    when '2' then 'SL'
				    when '5' then 'SS'
				    when '6' then 'SX'
				    else 'B'
				end||'@'||
				''||'@'||--blank
				''||'@'||--fdid
				''||'@'||--acc.hold.type
				''--orig.IMID
		||','||
		''
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		inner join compliance.blaze_client_order rep on cl.representative_order_id = rep.order_id
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number
		inner join compliance.blaze_execution exc on (cl.order_id = exc.order_id and exc.leg_number = cl.leg_number and exc.report_id = exc.child_report_id and lower(exc.exchange_transaction_id) like '%manual%' and lower(exc.status) like '%fill%')

		left join compliance.blaze_d_sent_to_broker stb on stb.sent_to_broker = exc.sent_to_broker
		where exc.date_id = in_date_id
		and cl.date_id = in_date_id
		and ((cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE','') --and coalesce(cl.user_is_broker_dealer,'0') = '0'
			 )
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') --and coalesce(cl.user_is_broker_dealer,'0') = '0'
			 )
			)

        --and cl.child_orders = 0
		and cl.instrument_type_id = 'E'
		--and cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
		and cl.representative_order_id <> '00000000-0000-0000-0000-000000000000'
		--and (nullif(exc.sent_to_broker,'') is not null or in_reporter_imid = 'SGAS')
		--and exc.sent_to_broker <> 'NOREPORT'
		--and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--and cl.leg_count = 1
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meof_repr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meom_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meom_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Modify-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'NEW', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		to_char(cl.create_date_time,'YYYYMMDD')||'_'||cl.system_order_id::varchar||'_m'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOM'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		case upper(cl.system_name)
			when 'BLAZE7' then cl.transaction64_order_id::text
			else cl.order_id
		end||','||
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		to_char(orig.create_date_time,'YYYYMMDD')||' 000000.000'||','||--priorOrderDate
		--B7 logic
		case upper(cl.system_name)
			when 'BLAZE7' then coalesce(orig.transaction64_order_id::text, orig.order_id)
			else orig.order_id
		end||','||--priorOrderID[10]
		--

		''||','||--originatingIMID
		--
		case
			when cl.user_acc_holder_type in ('V','P')
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--Timestamp for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')
			--Electronic
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--eventTimestamp
		case
			when cl.user_acc_holder_type in ('V','P') then 'false'
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then 'true'
			else 'false'
		end||','||--manual flag
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID[15]
		--
		'false'||','||--electronicDupFlag - need to check
		case
			--proprietary
		    when cl.user_acc_holder_type in ('V','P')
		    	then ''
			--for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--electronic
			else ''
		end||','||--electronicTimestamp
		--
		case
			--when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then ''
			when ((cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1')
				   or
				  (cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1')
				   or
				  (cl.client_event_type_id_1 in (1,3) and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1')
				  )
				 then
				    (select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
					--
				 	in_reporter_imid
		    else ''
		end||','||--receiverIMID
		case
			when cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1' then
				--coalesce(com.imid,'')
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			when cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1' and (cl.obo_user is null or cl.company_id = cl.dest_company_id) then
				--coalesce(cl.user_imid,'')
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			when cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1' and cl.obo_user is not null then
				--coalesce(com.imid,cl.user_imid,'')
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			when cl.client_event_type_id_1 in (1,3) and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1' then
				--coalesce(cl.user_imid,com.imid,'')
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			else ''
		end||','||--senderIMID
		case
			--when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then ''
			when ((cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1')
				   or
				  (cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1')
				   or
				  (cl.client_event_type_id_1 in (1,3) and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1')
				  )
				 then 'F'
			else ''
		end||','||--senderType (F=Industry Member) [20]
		case
		    when cl.client_event_type_id_1 in (1,3) and pcl.order_id is not null then
				--coalesce(pcl.client_order_id,cl.system_order_id,cl.order_id)
				coalesce(fxm.fix_message->>'8006',pcl.compliance_id,cl.cat_order_id,cl.order_id)
			when cl.client_event_type_id_1 in (1,3) then coalesce(cl.cat_order_id,cl.system_order_id,cl.order_id)
			when cl.client_event_type_id_2 = 4  and upper(cl.system_name) = 'BLAZE7' then cl.transaction64_order_id::text
			when cl.client_event_type_id_2 = 4  and cl.generation > 0 then cl.order_id
			else ''
		end||','||--routedOrderID [21]
		--quote--
		case
			--proprietary
			when cl.user_acc_holder_type in ('V','P')
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--Timestamp for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2
				then to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')
			--Electronic
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--[22]
		''||','||--
		''||','||--
		''||','||--[25]
		--
		case
			when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then 'C' --electronic
			else 'F'
		end||','||--initiator
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(abs(coalesce(cl.order_price,0)), 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty[30]
		cl.order_qty||','||--leavesQty - to be adjusted
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||--[32]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			--else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
			else 'DAY='||cl.date_id::varchar
		end||','||
		'REG'||','||
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd (need to take from ExecInst=f and TIF=Day/IOC )[35]
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||--custDspIntrFla
		''||','||--infoBarrierID
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then compliance.get_represented_orders(cl.order_id, cl.date_id)
			else ''
		end||','||--aggregatedOrders
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then 'Y'
			else 'N'
		end||','||--representativeInd [40]
		--------------n/a-------------
		''||','||--seqNum
		''||','||
		''||','||
		''||','||
		''||','||--[45]
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''--[53]netPrice
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.crd_number_list ucn on (upper(cl.user_imid) = ucn.cat_imid
			 										 and
			 									 	 (ucn.crd_amount = 1 or ucn.is_default = 'Y')
			 									     )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.crd_number_list ccn on (com.imid = ccn.cat_imid
			 										 and
			 									    (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_client_order orig on orig.order_id = cl.cancel_order_id and orig.instrument_type_id = 'E' and orig.leg_number = cl.leg_number
		left join dwh.client_order scl on (scl.client_order_id = cl.system_order_id
									  and scl.create_date_id = in_date_id
									  and scl.parent_order_id is not null
									  and scl.ex_destination = 'BRKPT'
									  and scl.multileg_reporting_type <> '3'
									  and coalesce(scl.co_client_leg_ref_id,'1')  = cl.leg_number::varchar)
		left join dwh.client_order pcl on pcl.order_id = scl.parent_order_id and pcl.create_date_id = in_date_id
		left join lateral
	        (select j.fix_message
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = pcl.fix_message_id
	         and j.date_id = in_date_id
	         limit 1
	        ) fxm on true
		where cl.date_id = in_date_id

		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and upper(cl.system_name) = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid --and coalesce(dcom.imid,com.imid,'') <> coalesce(cl.user_imid,'')) --FIX Staging
			 																													  and coalesce(cl.user_imid,com.imid,'') <> coalesce(dcom.imid,''))
			 )

		--suppress manual for configuration = 5--v2
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'DEST' --
			or coalesce(compliance.get_config_5_manual_flag(cl.replace_order_id, in_date_id),'DEST') <> 'DEST'
			or coalesce(dcom.cat_configuration,'') not like '%5%')
		and (compliance.get_config_5_manual_flag(cl.order_id, in_date_id) <> 'COM' --
			or coalesce(compliance.get_config_5_manual_flag(cl.replace_order_id, in_date_id),'COM') <> 'COM'
			or coalesce(com.cat_configuration,'') not like '%5%')
		--
		and cl.instrument_type_id = 'E'
		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
		and (cl.ex_destination not in ('ITO','XCHI') or coalesce(nullif(cl.slr_friendly_id,0)::varchar,cl.system_order_id) = cl.system_order_id)
		--
		--and nullif(cl.slr_friendly_id,0) is null
		--
		and (
			coalesce(cl.system_order_type,'')  <> 'Stitched Single'
			or exists (select 1 from compliance.blaze_client_order ch where ch.parent_order_id = cl.order_id)
			)
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--report rejected orders
		--and coalesce(cl.order_status,'') not in ('Report Cancel Replace Reject')
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meom_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meom_tts_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meom_tts_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Modify-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.file_group, com.file_group)
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_m'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||(cl.leg_number-1)::varchar||','||
		'MEOM'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		cl.order_id||','||
		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||
		to_char(orig.create_date_time,'YYYYMMDD')||' 000000.000'||','||--priorOrderDate
		orig.order_id||','||--priorOrderID[10]
		''||','||--originatingIMID
		--
		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--eventTimestamp
		'true'||','||--manual flag
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID[15]
		--
		'false'||','||--electronicDupFlag - need to check
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp
		--
		case
			--when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then ''
			when ((cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1')
				   or
				  (cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1')
				   or
				  (cl.client_event_type_id_1 = 1 and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1')
				  )
				 then
				 	(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
					--
				 	in_reporter_imid
		    else ''
		end||','||--receiverIMID
		case
			when cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1' then
				--coalesce(com.imid,'')
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			when cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1' and (cl.obo_user is null or cl.company_id = cl.dest_company_id) then
				--coalesce(cl.user_imid,'')
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			when cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1' and cl.obo_user is not null then
				--coalesce(com.imid,cl.user_imid,'')
				coalesce(coalesce(ccn.crd_number||':','')||com.imid,coalesce(ucn.crd_number||':','')||cl.user_imid,'')--v2
			when cl.client_event_type_id_1 = 1 and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1' then
				--coalesce(cl.user_imid,com.imid,'')
				coalesce(coalesce(ucn.crd_number||':','')||cl.user_imid,coalesce(ccn.crd_number||':','')||com.imid,'')--v2
			else ''
		end||','||--senderIMID
		case
			--when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 = 2 then ''
			when ((cl.client_event_type_id_2 = 4 and com.is_broker_dealer = '1')
				   or
				  (cl.client_event_type_id_1 = 2 and coalesce(cl.user_is_broker_dealer,'0') = '1')
				   or
				  (cl.client_event_type_id_1 = 1 and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1')
				  )
				 then 'F'
			else ''
		end||','||--senderType (F=Industry Member) [20]
		case
		    when cl.system_name = 'AORS'  then coalesce(cl.system_order_id,'')
			when cl.client_event_type_id_2 = 4  then coalesce(cl.system_order_id,cl.order_id,'')
			else ''
		end||','||--routedOrderID

		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--requestTimestamp
		''||','||--
		''||','||--
		''||','||--[25]
		--
		case
			when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then 'C' --electronic
			else 'F'
		end||','||--initiator
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when cl.tied_stock_price > 0 then to_char(cl.tied_stock_price, 'FM9999999990.09999999')
			else ''
		end||','||
		cl.tied_stock_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty[30]
		cl.tied_stock_qty||','||--leavesQty - to be adjusted
		case
		    when cl.tied_stock_price > 0  then 'LMT'
			else 'MKT'
		end||','||--
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd (need to take from ExecInst=f and TIF=Day/IOC )[35]
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.is_hidden = '1' then 'true'
			else 'false'
		end||','||--custDspIntrFla
		''||','||--infoBarrierID
		''||','||--aggregatedOrders
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.leg_count > 1 then 'YF'
			else 'N'
		end||','||--representativeInd [40]
		--------------n/a-------------
		''||','||--seqNum
		''||','||
		''||','||
		''||','||
		''||','||--[45]
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''||','||
		''--[53]netPrice
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 = 1 or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.crd_number_list ucn on (upper(cl.user_imid) = ucn.cat_imid
			 										 and
			 									 	 (ucn.crd_amount = 1 or ucn.is_default = 'Y')
			 									     )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.crd_number_list ccn on (com.imid = ccn.cat_imid
			 										 and
			 									    (ccn.crd_amount = 1 or ccn.is_default = 'Y')
			 									    )
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_client_order orig on orig.order_id = cl.cancel_order_id and orig.instrument_type_id = 'O' and orig.leg_number = cl.leg_number
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where cl.date_id = in_date_id

		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE',''))
			)

		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		--and cl.stock_floor_broker is not null
		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meom_tts_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Route-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        /*
               case
                 when cl.client_event_type_id_2 in (3,4) and cl.receiving_broker_mpid = in_reporter_imid then dcom.file_group
                 else com.file_group
               end as FILE_GROUP,
        */
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'ROUTE', in_date_id ) as FILE_GROUP,
        '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(cl.create_date_time,'YYYYMMDD')||'_'||cl.system_order_id::varchar||'_r'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_'||cl.leg_number::varchar||','||
		'MEOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'
		    else coalesce(to_char(po.create_date_time,'YYYYMMDD')||' 000000.000', to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000')
		end	||','||
		--parent order, child can be suppressed (no 7)
		case
			when cl.ex_destination = 'XCHI' and ito.order_id is not null then ito.order_id
		    when cl.client_event_type_id_2 = 3 and upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.transaction64_order_id::text,'')
			when cl.client_event_type_id_2 = 4 and upper(cl.system_name) = 'BLAZE7' and cl.receiving_broker_mpid = in_reporter_imid then coalesce(cl.transaction64_order_id::text,cl.order_id)
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
			when po.client_event_type_id_1 = 7 then po.parent_order_id
		    else coalesce(po.order_id, cl.order_id)
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		case
			when nullif(cl.call_time,'') is not null then
		    	 to_char(coalesce(compliance.try_cast_to_timestamp(cl.call_time), cl.create_date_time),'YYYYMMDD HH24MISS.MS')
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then to_char(cl.create_date_time,'YYYYMMDD HH24MISS') --manual route
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
        end||','||--[10]
		case
			when nullif(cl.call_time,'') is not null then 'true'
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then 'true'
			else 'false'
		end||','||--manual flag (true for manual route)

		'false'||','||--electronicDupFlag - need to check

		case
		--merged events:
		    when nullif(cl.call_time,'') is not null then
		    	to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		    else ''
		end||','||--electronicTimestamp
		--''||','||
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||
		--
		coalesce(cd.cat_sender_imid, in_reporter_imid)||','||--senderIMID
		--in_reporter_imid||','||--senderIMID
		--
		case
			when cl.receiving_broker_mpid = in_reporter_imid or cl.client_event_type_id_2 = 3 then
		  	case
				when cl.ex_destination = 'XCHI' then
					coalesce(fbcn.crd_number||':'||cl.stock_floor_broker, '') --v2

				when coalesce(drt.is_exchange::varchar,'0') = '1' then
					coalesce(drt.cat_destination_id, '')

			    else
			    	--coalesce(drt.cat_crd_number||':'||drt.cat_destination_id, '')--v2
			    	coalesce(drt.crd_number||':'||drt.cat_destination_id, '')--v2
		   	end
			else
				--coalesce(dcom.imid,'') -- broker routing --v1
				coalesce(dccn.crd_number||':'||dcom.imid,'') --v2
		end||','||--destination[15]
		case
		  when cl.ex_destination = 'XCHI' then 'F'
		  when cl.aors_destination in ('AODIR','NYAOTNT','NYAODIR','PODIR','NYPOTNT','NYPODIR','CBOE') then 'E'
		  when coalesce(drt.is_exchange::varchar,'0') = '1' then 'E'
		  else 'F'
		end||','||--destinationType (F=Industry Member)
		case
			--merged events:
		    --when nullif(cl.electronic_order_id,'') is not null then cl.electronic_order_id
		    --
			when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.fix_cl_ord_id,cl.order_id)
			when cl.aors_destination = 'LBCHX' then
				case
		    		when cl.side in ('1','8','9') then 'B'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    		else 'S'||coalesce (cl.routed_onyx_order_id,cl.order_id)
		    	end
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.routed_onyx_order_id,cl.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||--routedOrderID
		case
			when cl.ex_destination = 'XCHI' then ''
			else coalesce(drt.cat_session,'')
		end||','||--session
		--
		case
		    when cl.side = '1' or (cl.ex_destination = 'XCHI' and  ito.side = '1') then 'B'
		    when cl.side = '2' or (cl.ex_destination = 'XCHI' and  ito.side = '2') then 'SL'
		    when cl.side = '5' or (cl.ex_destination = 'XCHI' and  ito.side = '5') then 'SS'
		    when cl.side = '6' or (cl.ex_destination = 'XCHI' and  ito.side = '6') then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.leg_count > 1 then ''
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.order_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		----------- 2c -------------
		case
			when coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject','Ex Rej','Ex Rep Rej') then 'true'
			else 'false'
		end||','||--routeRejectedFlag
		----------------------------
		'false'||','||--dupROIDCond[30]
		''||','||--seqNum [31]
		--2d fields
		case
			when cl.ex_destination = 'XCHI' and ito.order_id is not null then 'true'
			else 'false'
		end||','|| --[32]
		coalesce(nullif (cl.crossing_order_link_id,'00000000-0000-0000-0000-000000000000'),'')||','|| --[33] pairedOrderID
		''||','||
		''||','||
		''||','||
		''-- [37]
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl

		left join compliance.blaze_d_stock_floor_broker fbcn on fbcn.stock_floor_broker = cl.stock_floor_broker
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.crd_number_list dccn on (dcom.imid = dccn.cat_imid
			 										  and
			 									      (dccn.crd_amount = 1 or dccn.is_default = 'Y')
			 									      )
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number --and ((po.date_id > 20200619 and po.time_in_force in ('GTC','GTD')) or po.date_id = in_date_id)
		left join lateral
			( select p.order_id
			  from dwh.client_order p
			  inner join dwh.client_order str on str.parent_order_id = p.order_id and str.create_date_id = in_date_id
			  where p.client_order_id = cl.routed_onyx_order_id
			  	and cl.leg_number::varchar = coalesce(p.co_client_leg_ref_id,'1')
			  	and p.create_date_id  = in_date_id
			  	and p.ex_destination = 'W'
			  	and str.exchange_id = 'C1PAR'
			  	limit 1) spo on true
		--
		left join lateral
			( select p.order_id, p.side
			  from compliance.blaze_client_order p
			  where p.system_order_id = coalesce(po.slr_friendly_id::varchar, cl.slr_friendly_id::varchar)
			  	and p.instrument_type_id = 'E'
			  	and p.date_id  = in_date_id
			  	and p.ex_destination = 'ITO'
			  	limit 1) ito on true
		--
		left join compliance.blaze_d_route drt on (drt.ex_destination = cl.ex_destination )
		--
        left join compliance.blaze_client2destination cd on (cd.ex_destination = cl.ex_destination and cd.client_imid = in_reporter_imid)
		where cl.date_id = in_date_id
		and ((cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name <> 'BLAZE7' and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --electronic market routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			  or
			 (cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_1 = 5 and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --broker routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 4 and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		--suppress manual for configuration = 5
		and ((cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null) is false
				or coalesce(com.cat_configuration,'') not like '%5%')

		and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and coalesce(drt.cat_route_suppress::varchar, '0' ) = '0'
		and cl.instrument_type_id = 'E'

		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'

		and spo.order_id is null
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count = 1
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_sor2exch_record_2c(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_sor2exch_record_2c(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin

  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Route Collapsed-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               dcom.file_group as FILE_GROUP, -- use from d_entity
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.create_date_id::varchar||'_'||cl.order_id::varchar||'_'||'clp'||coalesce(bco.client_event_type_id_1,0)||coalesce(bco.client_event_type_id_2,0)||'_'||'1'||','||--leg ref id?
		'MEOR'||','||
		in_reporter_imid||','||  -- client's imid here
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when (bco.client_event_type_id_1 = 2 and bco.client_event_type_id_2 = 3) or bco.client_event_type_id_2 = 4 then bco.date_id::varchar||' 000000.000'
		    else coalesce(bpo.date_id::varchar,bco.date_id::varchar)||' 000000.000'
		end||','||
		--parent order
		--use parent_leg_order_id for stitched
		case
			when bpo.client_event_type_id_1 in (1,3,6) and bpo.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then coalesce(orig.order_id,bpo.cancel_order_id)
			when (bco.client_event_type_id_1 = 2 and bco.client_event_type_id_2 = 3) or bco.client_event_type_id_2 = 4 then bco.order_id
			when (bco.client_event_type_id_1 is null and bco.client_event_type_id_2 = 3) and bpo.client_event_type_id_1 = 7
				then coalesce(nullif(bpo.parent_order_id,'00000000-0000-0000-0000-000000000000'),bpo.parent_leg_order_id)
			else coalesce(po.compliance_id,po.alternative_compliance_id,po.client_order_id)
		end||','||
		--coalesce(po.compliance_id,po.alternative_compliance_id,po.client_order_id)||','|| --check how it works
		--
		i.symbol||
		case
			when i.symbol_suffix is not null then ' '||i.symbol_suffix
			else ''
		end||','||
		''||','||--originatingIMID
		to_char(cl.process_time,'YYYYMMDD HH24MISS.MS')||','||--[10]
		'false'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||--electronicTimestamp
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		case
			when cl.exchange_id <> 'C1PAR' then
				coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||----v2
				in_reporter_imid
			else coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = coalesce(fxm.fix_message->>'7933',in_reporter_imid) and (crd_amount = 1 or is_default = 'Y')),'')||----v2
				  coalesce(fxm.fix_message->>'7933',in_reporter_imid)
		end||','||--senderIMID

		case
			when dex.trading_venue_class = 'E' then
				coalesce(dex.cat_exchange_id,'')
			else
				coalesce(dcn.crd_number||':'||dex.cat_exchange_id,'')
		end||','||--destination[15]	--v2

		---------------------------------------------------------------------------------------------------------------------------------------------------------
		case
		  when dex.trading_venue_class = 'E' then 'E'
		  else 'F'
		end||','||--destinationType (F=Industry Member)
		cl.client_order_id||','||--routedOrderID
		case
			when cl.exchange_id = 'C1PAR' then
				coalesce(sfc.fix_comp_id||coalesce(sfc.sender_sub_id,''),ec.session_placeholder,'')
			else coalesce(sfc.fix_comp_id,ec.session_placeholder,'')
		end||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.multileg_reporting_type = '2' then ''
		    when cl.order_type_id in ('2','4') then to_char(abs(cl.price), 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.order_qty||','||
		''||','||--minQty
		case
			when cl.multileg_reporting_type = '2' then 'MKT'
		    when cl.order_type_id in ('2','4') then 'LMT'
			else 'MKT'
		end||','||
		case
			--when tif.tif_short_name in ('GTC','IOC','GTX') then tif.tif_short_name
			when tif.tif_short_name in ('GTC','IOC') then tif.tif_short_name
			when tif.tif_short_name = 'GTX' then 'GTX='||to_char(cl.create_time,'YYYYMMDD')
			when tif.tif_short_name = 'GTD' then 'GTD='||to_char(coalesce(cl.expire_time,cl.create_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_time,'YYYYMMDD')

		end||','||
		compliance.get_eq_sor_trading_session(cl.order_id, cl.create_date_id)||','||--[25]
		'false'||','||--affiliate flag
		case
			when tif.tif_short_name = 'IOC' and cl.exec_instruction = 'f' then 'ISOI'
			when coalesce(tif.tif_short_name,'DAY') = 'DAY' and cl.exec_instruction = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		--compliance.get_sor_handl_inst(cl.order_id,'E', cl.create_date_id)||','||
		compliance.get_sor_handl_inst_sy(cl.order_id, 'E', cl.create_date_id, fxm.fix_message)||','||
		-----------------------
		case
			when rej.cnt > 0 then 'true'
			else 'false'
		end||','||--routeRejectedFlag

		'false'||','||--dupROIDCond[30]
		''--seqNum
	    ||
		compliance.get_custom_field(coalesce(dcom.cat_configuration,''),bco.order_id,bco.leg_number,in_date_id)


		:: varchar

		as ROE

		from client_order cl
		inner join client_order po on cl.parent_order_id = po.order_id
		--left join client_order orig on cl.orig_order_id = orig.order_id and cl.trans_type = 'G' and orig.create_date_id > 20200619 and (orig.create_date_id = in_date_id or orig.time_in_force_id in ('1','6'))
		inner join compliance.blaze_client_order bco on bco.order_id = po.alternative_compliance_id and bco.date_id  = po.create_date_id  --po in SOR is bco in BLAZE
		--
		left join compliance.blaze_client_order bpo on bpo.order_id = bco.parent_order_id and bpo.instrument_type_id = 'E' and bpo.leg_number = bco.leg_number and bpo.date_id > 20200619
		--
		left join compliance.blaze_d_entity_cat dcom on dcom.company_id = coalesce(bco.dest_company_id,bco.company_id)
		left join compliance.blaze_d_route drt on (drt.ex_destination = bco.ex_destination )
		inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
		inner join d_exchange dex on cl.exchange_id = dex.exchange_id and dex.is_active = true
		left join compliance.crd_number_list dcn on (dex.cat_exchange_id = dcn.cat_imid
			 										 and
			 									 	 (dcn.crd_amount = 1 or dcn.is_default = 'Y')
			 									     )
		left join compliance.cat_exchange_config ec on ec.exchange_id = cl.exchange_id
		inner join d_instrument i on cl.instrument_id = i.instrument_id
		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
		--
		left join lateral
	        (select out_orig_order_id order_id, out_date_id date_id
	         from compliance.get_blaze_first_orig(bpo.order_id, bpo.date_id)
	         where bpo.order_id is not null
	         and bpo.client_event_type_id_1 in (1,3,6)
	         and bpo.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
	         limit 1
	        ) orig on true
	    left join lateral
	        (select count(1) as cnt
	         from dwh.execution ex
	         where ex.order_id = cl.order_id
	         and ex.exec_date_id = in_date_id
	         and ex.is_parent_level = false
	         and ex.exec_type = '8'
	         limit 1
	        ) rej on true
	    left join lateral
	        (select j.fix_message
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = cl.fix_message_id
	         and j.date_id = in_date_id
	         limit 1
	        ) fxm on true
	    left join lateral
	        (select j.fix_message->>'10099' as tag_10099
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  =
	         	(select min(ex.fix_message_id) from execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type in ('0','4') limit 1)
	         and j.date_id = in_date_id
	         limit 1
	        ) fxc on true
	    left join d_fix_connection sfc on sfc.fix_connection_id::varchar = fxc.tag_10099 and sfc.is_active = true
		where cl.create_date_id = in_date_id
		and (po.create_date_id = in_date_id or po.time_in_force_id in ('1','6'))
		and po.create_date_id > 20200619
		and bco.date_id > 20200619
		and bco.instrument_type_id = 'E'
		--
		and ((bco.broker_dealer_mpid = in_reporter_imid and bco.client_event_type_id_2 = 3) --electronic market routing
			  or
			 (bco.receiving_broker_mpid = in_reporter_imid and bco.client_event_type_id_2 = 4 and bco.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--
		and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		and (coalesce(drt.cat_route_suppress::varchar, '0' ) = '1' or bco.ex_destination  = 'XCBO')
		--and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','')
		and i.instrument_type_id = 'E'
		and (cl.trans_type = 'D'
			 --or
			--(cl.trans_type = 'G' and cl.parent_order_id <> orig.parent_order_id )
			)
		--and cl.cross_order_id is null
		and tf.cat_imid = in_reporter_imid
		and cl.exchange_id in ('C1PAR','JSEB','PHLXFB','SQHT','TRAFX','WEEDN','CTDLHT')
		and i.symbol not in (select symbol from dwh.d_test_symbol_list)
		--and cl.order_id not in (select ex.order_id from execution ex where ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type = '8')
		--and not exists (select 1 from dwh.execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type = '8' limit 1)

		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_sor2exch_record_2c(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_sor2exch_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_sor2exch_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin

  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Route Collapsed-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               dcom.file_group as FILE_GROUP, -- use from d_entity
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.create_date_id::varchar||'_'||cl.order_id::varchar||'_'||'clp'||coalesce(bco.client_event_type_id_1,0)||coalesce(bco.client_event_type_id_2,0)||'_'||'1'||','||--leg ref id?
		'MEOR'||','||
		in_reporter_imid||','||  -- client's imid here
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when (bco.client_event_type_id_1 = 2 and bco.client_event_type_id_2 = 3) or bco.client_event_type_id_2 = 4 then bco.date_id::varchar||' 000000.000'
		    else coalesce(bpo.date_id::varchar,bco.date_id::varchar)||' 000000.000'
		end||','||
		--parent order
		--use parent_leg_order_id for stitched
		case
			--when bpo.client_event_type_id_1 in (1,3,6) and bpo.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then coalesce(orig.order_id,bpo.cancel_order_id)
			when (bco.client_event_type_id_1 = 2 and bco.client_event_type_id_2 = 3) or bco.client_event_type_id_2 = 4 then bco.order_id
			when (bco.client_event_type_id_1 is null and bco.client_event_type_id_2 = 3) and bpo.client_event_type_id_1 = 7
				then coalesce(nullif(bpo.parent_order_id,'00000000-0000-0000-0000-000000000000'),bpo.parent_leg_order_id)
			else coalesce(po.compliance_id,po.alternative_compliance_id,po.client_order_id)
		end||','||
		--coalesce(po.compliance_id,po.alternative_compliance_id,po.client_order_id)||','|| --check how it works
		--
		i.symbol||
		case
			when i.symbol_suffix is not null then ' '||i.symbol_suffix
			else ''
		end||','||
		''||','||--originatingIMID
		to_char(cl.process_time,'YYYYMMDD HH24MISS.MS')||','||--[10]
		'false'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||--electronicTimestamp
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		case
			when cl.exchange_id <> 'C1PAR' then
				coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||----v2
				in_reporter_imid
			else coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = coalesce(fxm.fix_message->>'7933',in_reporter_imid) and (crd_amount = 1 or is_default = 'Y')),'')||----v2
				  coalesce(fxm.fix_message->>'7933',in_reporter_imid)
		end||','||--senderIMID

		case
			when dex.trading_venue_class = 'E' then
				coalesce(dex.cat_exchange_id,'')
			else
				coalesce(dcn.crd_number||':'||dex.cat_exchange_id,'')
		end||','||--destination[15]	--v2

		---------------------------------------------------------------------------------------------------------------------------------------------------------
		case
		  when dex.trading_venue_class = 'E' then 'E'
		  else 'F'
		end||','||--destinationType (F=Industry Member)
		cl.client_order_id||','||--routedOrderID
		case
			when cl.exchange_id = 'C1PAR' then
				coalesce(sfc.fix_comp_id||coalesce(sfc.sender_sub_id,''),ec.session_placeholder,'')
			else coalesce(sfc.fix_comp_id,ec.session_placeholder,'')
		end||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
			when cl.multileg_reporting_type = '2' then ''
		    when cl.order_type_id in ('2','4') then to_char(abs(cl.price), 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.order_qty||','||
		''||','||--minQty
		case
			when cl.multileg_reporting_type = '2' then 'MKT'
		    when cl.order_type_id in ('2','4') then 'LMT'
			else 'MKT'
		end||','||
		case
			--when tif.tif_short_name in ('GTC','IOC','GTX') then tif.tif_short_name
			when tif.tif_short_name in ('GTC','IOC') then tif.tif_short_name
			when tif.tif_short_name = 'GTX' then 'GTX='||to_char(cl.create_time,'YYYYMMDD')
			when tif.tif_short_name = 'GTD' then 'GTD='||to_char(coalesce(cl.expire_time,cl.create_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_time,'YYYYMMDD')

		end||','||
		compliance.get_eq_sor_trading_session(cl.order_id, cl.create_date_id)||','||--[25]
		'false'||','||--affiliate flag
		case
			when tif.tif_short_name = 'IOC' and cl.exec_instruction = 'f' then 'ISOI'
			when coalesce(tif.tif_short_name,'DAY') = 'DAY' and cl.exec_instruction = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		--compliance.get_sor_handl_inst(cl.order_id,'E', cl.create_date_id)||','||
		compliance.get_sor_handl_inst_sy(cl.order_id, 'E', cl.create_date_id, fxm.fix_message)||','||
		-----------------------
		case
			when rej.cnt > 0 then 'true'
			else 'false'
		end||','||--routeRejectedFlag

		'false'||','||--dupROIDCond[30]
		''||','||--seqNum [31]
		--2d fields
		'false'||','|| --[32]
		''||','|| --[33] pairedOrderID
		''||','||
		''||','||
		''||','||
		''-- [37]
	    ||
		compliance.get_custom_field(coalesce(dcom.cat_configuration,''),bco.order_id,bco.leg_number,in_date_id)


		:: varchar

		as ROE

		from client_order cl
		inner join client_order po on cl.parent_order_id = po.order_id
		--left join client_order orig on cl.orig_order_id = orig.order_id and cl.trans_type = 'G' and orig.create_date_id > 20200619 and (orig.create_date_id = in_date_id or orig.time_in_force_id in ('1','6'))
		inner join compliance.blaze_client_order bco on bco.order_id = po.alternative_compliance_id and bco.date_id  = po.create_date_id  --po in SOR is bco in BLAZE
		--
		left join compliance.blaze_client_order bpo on bpo.order_id = bco.parent_order_id and bpo.instrument_type_id = 'E' and bpo.leg_number = bco.leg_number and bpo.date_id > 20200619
		--
		left join compliance.blaze_d_entity_cat dcom on dcom.company_id = coalesce(bco.dest_company_id,bco.company_id)
		left join compliance.blaze_d_route drt on (drt.ex_destination = bco.ex_destination )
		inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
		inner join d_exchange dex on cl.exchange_id = dex.exchange_id and dex.is_active = true
		left join compliance.crd_number_list dcn on (dex.cat_exchange_id = dcn.cat_imid
			 										 and
			 									 	 (dcn.crd_amount = 1 or dcn.is_default = 'Y')
			 									     )
		left join compliance.cat_exchange_config ec on ec.exchange_id = cl.exchange_id
		inner join d_instrument i on cl.instrument_id = i.instrument_id
		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
		--
		/*
		left join lateral
	        (select out_orig_order_id order_id, out_date_id date_id
	         from compliance.get_blaze_first_orig(bpo.order_id, bpo.date_id)
	         where bpo.order_id is not null
	         and bpo.client_event_type_id_1 in (1,3,6)
	         and bpo.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
	         limit 1
	        ) orig on true
	     */
	    left join lateral
	        (select count(1) as cnt
	         from dwh.execution ex
	         where ex.order_id = cl.order_id
	         and ex.exec_date_id = in_date_id
	         and ex.is_parent_level = false
	         and ex.exec_type = '8'
	         limit 1
	        ) rej on true
	    left join lateral
	        (select j.fix_message
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = cl.fix_message_id
	         and j.date_id = in_date_id
	         limit 1
	        ) fxm on true
	    left join lateral
	        (select j.fix_message->>'10099' as tag_10099
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  =
	         	(select min(ex.fix_message_id) from execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type in ('0','4') limit 1)
	         and j.date_id = in_date_id
	         limit 1
	        ) fxc on true
	    left join d_fix_connection sfc on sfc.fix_connection_id::varchar = fxc.tag_10099 and sfc.is_active = true
		where cl.create_date_id = in_date_id
		and (po.create_date_id = in_date_id or po.time_in_force_id in ('1','6'))
		and po.create_date_id > 20200619
		and bco.date_id > 20200619
		and bco.instrument_type_id = 'E'
		--
		and ((bco.broker_dealer_mpid = in_reporter_imid and bco.client_event_type_id_2 = 3) --electronic market routing
			  or
			 (bco.receiving_broker_mpid = in_reporter_imid and bco.client_event_type_id_2 = 4 and bco.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--
		and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		and (coalesce(drt.cat_route_suppress::varchar, '0' ) = '1' or bco.ex_destination  = 'XCBO')
		--and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','')
		and i.instrument_type_id = 'E'
		and (cl.trans_type = 'D'
			 --or
			--(cl.trans_type = 'G' and cl.parent_order_id <> orig.parent_order_id )
			)
		--and cl.cross_order_id is null
		and tf.cat_imid = in_reporter_imid
		and cl.exchange_id in ('C1PAR','JSEB','PHLXFB','SQHT','TRAFX','WEEDN','CTDLHT')
		and i.symbol not in (select symbol from dwh.d_test_symbol_list)
		--and cl.order_id not in (select ex.order_id from execution ex where ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type = '8')
		--and not exists (select 1 from dwh.execution ex where ex.order_id = cl.order_id and ex.exec_date_id = in_date_id and ex.is_parent_level = false and ex.exec_type = '8' limit 1)

		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_sor2exch_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_synt_record_2c(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_synt_record_2c(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 in (2,7) then com.file_group
                 else coalesce(dcom.file_group, com.file_group)
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||exc.report_id::varchar||'_sr'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		--parent order, child can be suppressed (no 7)
		case
			when cl.client_event_type_id_1 = 7 and po.cancel_order_id = '00000000-0000-0000-0000-000000000000' then po.order_id
			when cl.client_event_type_id_1 = 7 and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
		    else cl.order_id
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS')||','||--[10]
		--
		'true'||','||--manual flag (true for manual route)
		--
		'false'||','||--electronicDupFlag - need to check
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp temp.removed
		--
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--senderIMID
		case
			when in_reporter_imid = 'SGAS'
			 then coalesce(exc.executing_broker,'')
		    --else coalesce(drt.cat_destination_id, exc.ex_destination, '')
		    else
		    	--coalesce(stb.sent_to_broker_imid, '') --v1
		    	coalesce(stb.cat_crd_number||':'||stb.sent_to_broker_imid, '') --v2
		end||','||--destination[15]
		---------------------------------------------------------------------------------------------------------------------------------------------------------
		'F'||','||--destinationType (F=Industry Member)
		--cl.order_id||','||--routedOrderID
		exc.report_id||','||--routedOrderID
		''||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		--cl.order_qty||','||
		exc.last_qty||','||
		coalesce(cl.min_quantity::varchar,'')||','||--minQty
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		---------- 2c -------------
		'false'||','||--routeRejectedFlag--can't be rejected
		---------------------------
		'false'||','||--dupROIDCond[30]
		''--seqNum
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number
		inner join compliance.blaze_execution exc on (cl.order_id = exc.order_id and exc.leg_number = cl.leg_number and exc.report_id = exc.child_report_id and lower(exc.exchange_transaction_id) like '%manual%' and lower(exc.status) like '%fill%')
		--left join compliance.blaze_d_route_tmp drt on (drt.ex_destination = exc.ex_destination )
		left join compliance.blaze_sent_to_broker stb on stb.sent_to_broker = exc.sent_to_broker
		where exc.date_id = in_date_id
		and cl.date_id = in_date_id
		and ((cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and cl.client_event_type_id_1 in (2,7))
			 or
			 (cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.client_event_type_id_2 = 4)
			 or
			 (coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and cl.client_event_type_id_1 in (1,3))
			)

        and cl.child_orders = 0
		and cl.instrument_type_id = 'E'
		and (nullif(exc.sent_to_broker,'') is not null or in_reporter_imid = 'SGAS')
		and exc.sent_to_broker <> 'NOREPORT'
		--and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_synt_record_2c(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_synt_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_synt_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_1 in (2,7) then com.file_group
                 else coalesce(dcom.file_group, com.file_group)
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||exc.report_id::varchar||'_sr'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_'||cl.leg_number::varchar||','||
		'MEOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		--parent order, child can be suppressed (no 7)
		case
			when upper(cl.system_name) <> 'BLAZE7' then
				case
					when cl.client_event_type_id_1 = 7 and po.cancel_order_id = '00000000-0000-0000-0000-000000000000' then po.order_id
					when cl.client_event_type_id_1 = 7 and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
				    else cl.order_id
				end
			else
				case
					when cl.client_event_type_id_1 = 7 and po.cancel_order_id = '00000000-0000-0000-0000-000000000000' then coalesce(po.transaction64_order_id::text,po.order_id)
					when cl.client_event_type_id_1 = 7 and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
				    else coalesce(cl.transaction64_order_id::text,cl.order_id)
				end
		end||','||
		--
		replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		''||','||--originatingIMID
		--to_char(cl.create_date_time,'YYYYMMDD HH24MISS')||','||--[10]
		to_char(coalesce(exc.call_time_report, exc.transaction_date_time),'YYYYMMDD HH24MISS')||','||--[10]
		--
		'true'||','||--manual flag (true for manual route)
		--
		'false'||','||--electronicDupFlag - need to check
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp temp.removed
		--
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--senderIMID
		case
			when in_reporter_imid = 'SGAS'
			 then coalesce(exc.executing_broker,'')
		    --else coalesce(drt.cat_destination_id, exc.ex_destination, '')
		    else
		    	--coalesce(stb.sent_to_broker_imid, '') --v1
		    	coalesce(stb.cat_crd_number||':'||stb.sent_to_broker_imid, '') --v2
		end||','||--destination[15]
		---------------------------------------------------------------------------------------------------------------------------------------------------------
		'F'||','||--destinationType (F=Industry Member)
		--cl.order_id||','||--routedOrderID
		exc.report_id||','||--routedOrderID
		''||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.order_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		--cl.order_qty||','||
		exc.last_qty||','||
		coalesce(cl.min_quantity::varchar,'')||','||--minQty
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		---------- 2c -------------
		'false'||','||--routeRejectedFlag--can't be rejected
		---------------------------
		'false'||','||--dupROIDCond[30]
		''||','||--seqNum [31]
		--2d fields
		'false'||','|| --[32]
		''||','|| --[33] pairedOrderID
		''||','||
		''||','||
		''||','||
		''-- [37]
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'E' and po.leg_number = cl.leg_number
		inner join compliance.blaze_execution exc on (cl.order_id = exc.order_id and exc.leg_number = cl.leg_number and exc.report_id = exc.child_report_id and lower(exc.exchange_transaction_id) like '%manual%' and lower(exc.status) like '%fill%')
		--left join compliance.blaze_d_route_tmp drt on (drt.ex_destination = exc.ex_destination )
		left join compliance.blaze_sent_to_broker stb on stb.sent_to_broker = exc.sent_to_broker
		where exc.date_id = in_date_id
		and cl.date_id = in_date_id
		and ((cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and cl.client_event_type_id_1 in (2,7))
			 or
			 (cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.client_event_type_id_2 = 4)
			 or
			 (coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and cl.client_event_type_id_1 in (1,3))
			)

        and cl.child_orders = 0
		and cl.instrument_type_id = 'E'
		and (nullif(exc.sent_to_broker,'') is not null or in_reporter_imid = 'SGAS')
		and exc.sent_to_broker <> 'NOREPORT'
		--and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_synt_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_tts_record_2c(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_tts_record_2c(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then dcom.file_group
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_r'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_'||(cl.leg_number-1)::varchar||','||
		'MEOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		--parent order, child can be suppressed (no 7)
		case

			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when po.client_event_type_id_1 = 6  and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
			when po.client_event_type_id_1 = 1 and in_reporter_imid <> 'PWJC' and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
		    else coalesce(po.order_id, cl.order_id)
		end||','||
		--
		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||
		''||','||--originatingIMID
		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--[10]
		'true'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp temp.removed
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--senderIMID

		--coalesce(cl.stock_floor_broker, '')||','||--destination[15] --v1
		coalesce(fbcn.crd_number||':'||cl.stock_floor_broker, '')||','||--destination[15] --v2

		'F'||','||--destinationType (F=Industry Member)
		cl.order_id||','||--routedOrderID
		''||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when cl.tied_stock_price > 0 then to_char(cl.tied_stock_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.tied_stock_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
		    when cl.tied_stock_price > 0 then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		----------- 2c -------------
		case
			when coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject') then 'true'
			else 'false'
		end||','||--routeRejectedFlag
		----------------------------
		'false'||','||--dupROIDCond[30]
		''--seqNum
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.crd_number_list fbcn on (cl.stock_floor_broker = fbcn.cat_imid
			 										  and
			 									      (fbcn.crd_amount = 1 or fbcn.is_default = 'Y')
			 									      )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'O' and po.leg_number = cl.leg_number and po.date_id > 20200619
		--left join compliance.blaze_d_route_tmp drt on (drt.ex_destination = cl.ex_destination )
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where cl.date_id = in_date_id
		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --manual order entry
			)

		--and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		and nullif(cl.stock_floor_broker,'') is not null
		and coalesce(cl.stock_floor_broker,'') <> 'AWAY'
		--and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_tts_record_2c(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_meor_tts_record_2d(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_meor_tts_record_2d(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Order Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               case
                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then dcom.file_group
                 else com.file_group
               end as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_r'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_'||(cl.leg_number-1)::varchar||','||
		'MEOR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||
		--parent order, child can be suppressed (no 7)
		case

			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when po.client_event_type_id_1 = 6  and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
			when po.client_event_type_id_1 = 1 and in_reporter_imid <> 'PWJC' and po.cancel_order_id <> '00000000-0000-0000-0000-000000000000' then po.cancel_order_id
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
		    else coalesce(po.order_id, cl.order_id)
		end||','||
		--
		--replace(replace(cl.symbol,'.',' '),'/',' ')||','||
		coalesce(ncs.eq_base, replace(replace(cl.symbol,'.',' '),'/',' ') )||','||
		''||','||--originatingIMID
		to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')||','||--[10]
		'true'||','||--manual flag (true for manual route)
		'false'||','||--electronicDupFlag - need to check
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp temp.removed
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||----v2
		--
		in_reporter_imid||','||--senderIMID

		--coalesce(cl.stock_floor_broker, '')||','||--destination[15] --v1
		coalesce(fbcn.crd_number||':'||cl.stock_floor_broker, '')||','||--destination[15] --v2

		'F'||','||--destinationType (F=Industry Member)
		cl.order_id||','||--routedOrderID
		''||','||--session
		--
		case cl.side
		    when '1' then 'B'
		    when '2' then 'SL'
		    when '5' then 'SS'
		    when '6' then 'SX'
		    else 'B'
		end||','||--side
		case
		    when cl.tied_stock_price > 0 then to_char(cl.tied_stock_price, 'FM9999999990.09999999')
			else ''
		end||','||--[20]
		cl.tied_stock_qty||','||
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		case
		    when cl.tied_stock_price > 0 then 'LMT'
			else 'MKT'
		end||','||
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[25]
		'false'||','||--affiliate flag
		case
			when cl.time_in_force = 'IOC' and cl.exec_inst = 'f' then 'ISOI'
			when cl.time_in_force = 'Day' and cl.exec_inst = 'f' then 'ISOD'
			else 'NA'
		end||','||--isoInd
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		----------- 2c -------------
		case
			when coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject') then 'true'
			else 'false'
		end||','||--routeRejectedFlag
		----------------------------
		'false'||','||--dupROIDCond[30]
		''||','||--seqNum [31]
		--2d fields
		'false'||','|| --[32]
		''||','|| --[33] pairedOrderID
		''||','||
		''||','||
		''||','||
		''-- [37]
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.crd_number_list fbcn on (cl.stock_floor_broker = fbcn.cat_imid
			 										  and
			 									      (fbcn.crd_amount = 1 or fbcn.is_default = 'Y')
			 									      )
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.instrument_type_id = 'O' and po.leg_number = cl.leg_number and po.date_id > 20200619
		--left join compliance.blaze_d_route_tmp drt on (drt.ex_destination = cl.ex_destination )
		left join compliance.blaze_d_non_common_stock ncs on cl.symbol = ncs.root
		where cl.date_id = in_date_id
		and (
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --manual order entry
			)

		--and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and cl.instrument_type_id = 'O'
		and cl.is_tied_to_stock = 'Y'
		and cl.tied_stock_qty > 0
		and cl.leg_number = 1
		and nullif(cl.stock_floor_broker,'') is not null
		and coalesce(cl.stock_floor_broker,'') <> 'AWAY'
		--and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_meor_tts_record_2d(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlcr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlcr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Multi-Leg Order Route-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'ROUTE', in_date_id ) as FILE_GROUP,
        '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_cr'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_00'||','||
		'MLCR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.date_id::varchar||' 000000.000'
		    else coalesce(po.date_id::varchar||' 000000.000', cl.date_id::varchar||' 000000.000')
		end	||','|| --[6]
		--parent order, child can be suppressed (no 7)
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when cl.client_event_type_id_2 = 3 and upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.transaction64_order_id::text,'')
		    else coalesce(po.order_id, cl.order_id)
		end||','|| --[7]
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','||
		''||','||--originatingIMID
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS') --manual route
			else to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')
        end||','||--[10]
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then 'true'
			else 'false'
		end||','||--manual flag[11]

		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp [12]
		(exc.last_qty/cl.ratio)::varchar||','||--cancelled_qty[13]
		''||','||
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||
			coalesce(cd.cat_sender_imid, in_reporter_imid)||','||--senderIMID [15]

		case
			when cl.receiving_broker_mpid = in_reporter_imid or cl.client_event_type_id_2 = 3 then
		  	case

				when coalesce(drt.is_exchange::varchar,'0') = '1' then
					coalesce(drt.cat_destination_id, '')

			    else
			    	--coalesce(drt.cat_crd_number||':'||drt.cat_destination_id, '')--v2
			    	coalesce(drt.crd_number||':'||drt.cat_destination_id, '')--v2
		   	end
			else
				--coalesce(dcom.imid,'') -- broker routing --v1
				coalesce(dccn.crd_number||':'||dcom.imid,'') --v2
		end||','||--destination[16]
		case
		  when coalesce(drt.is_exchange::varchar,'0') = '1' then 'E'
		  else 'F'
		end||','||--destinationType[17]
		case
			when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.fix_cl_ord_id,cl.order_id)
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.routed_onyx_order_id,cl.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||--routedOrderID [18]
		coalesce(drt.cat_session,'')||','||--session [19]

		--
		case
			when 1 = 2 --coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject')
				then 'true'
			else 'false'
		end||','||--routeRejectedFlag [20]
		--

		cl.leg_count||','|| --[21]
		''
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl

	    inner join compliance.blaze_execution exc on exc.order_id = cl.order_id and exc.leg_number = 1

		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.crd_number_list dccn on (dcom.imid = dccn.cat_imid
			 										  and
			 									      (dccn.crd_amount = 1 or dccn.is_default = 'Y')
			 									      )
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.leg_number = cl.leg_number --and ((po.date_id > 20200619 and po.time_in_force in ('GTC','GTD')) or po.date_id = in_date_id)
		left join lateral
			( select p.order_id
			  from dwh.client_order p
			  inner join dwh.client_order str on str.parent_order_id = p.order_id and str.create_date_id = in_date_id
			  where p.client_order_id = cl.routed_onyx_order_id
			  	and cl.leg_number::varchar = coalesce(p.co_client_leg_ref_id,'1')
			  	and p.create_date_id  = in_date_id
			  	and p.ex_destination = 'W'
			  	and str.exchange_id = 'C1PAR'
			  	limit 1) spo on true
		--modification route should be reported
		left join compliance.blaze_d_route drt on (drt.ex_destination = cl.ex_destination )
		left join compliance.blaze_client2destination cd on (cd.ex_destination = cl.ex_destination and cd.client_imid = in_reporter_imid)
		left join compliance.blaze_d_exchange2cust_firm ecf on (ecf.cat_exchange_id  = drt.cat_destination_id and ecf.customer_or_firm  = cl.customer_or_firm)
		--left join compliance.blaze_client_order orcl on orcl.order_id = cl.cancel_order_id and orcl.leg_number = cl.leg_number
		--
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = coalesce(exc.child_report_id, exc.report_id)
		and lower(exc.exchange_transaction_id) not like '%manual%'
		and (cl.date_id = in_date_id
			 or
			 (cl.time_in_force in ('GTC','GTD') and cl.date_id > 20200716)
			 )

		and ((cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name <> 'BLAZE7' and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --electronic market routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			  or
			 (cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_1 = 5 and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --broker routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 4 and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		--suppress manual for configuration = 5
		and ((cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null) is false
				or coalesce(com.cat_configuration,'') not like '%5%')
		and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and coalesce(drt.cat_route_suppress::varchar, '0' ) = '0'
		/*
		and (cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
			 or
			 cl.parent_order_id = '00000000-0000-0000-0000-000000000000'
			 or
			 cl.parent_order_id <> coalesce(orcl.parent_order_id,'00000000-0000-0000-0000-000000000000')
			)
		*/
		and spo.order_id is null
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count > 1
		and cl.leg_number = 1
		and cl.system_order_type <> 'VEGA Order'
		--
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlcr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlic_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlic_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Multi-Leg Internal Route Cancelled-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_c'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_00'||','||
		'MLIC'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','||--[8]

		''||','||--originatingIMID
		to_char(exc.transaction_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp [10]
		'false'||','||--manual flag
		''||','||--electronicTimestamp [12]
		--
		(exc.last_qty/cl.ratio)||','||--cancelled_qty
		'0'||','||--leaves (need to ask)
		'C'||','||--initiator[15]
		--=========--
		--2d fields--
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','|| --[16] requestTimestamp (need to take from 'F' msg)
		cl.leg_count||','|| --[17]
		''
		--=========--
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		inner join compliance.blaze_execution exc on exc.order_id = cl.order_id and exc.leg_number = 1
		where exc.date_id  = in_date_id
		and exc.status in ('Canceled','Ex Rpt Out')
		and cl.leg_number = exc.leg_number
		and exc.report_id  = exc.child_report_id
	    and cl.date_id > 20200619
		and (cl.date_id = in_date_id or cl.time_in_force in ('GTC','GTD'))

		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid  and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																   --and coalesce(dcom.imid,com.imid) = coalesce(cl.user_imid,''))
																																   and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)
		--suppress manual for configuration = 5--
		and (cl.client_event_type_id_1 in (1,3)  or coalesce(dcom.cat_configuration,'') not like '%5%')
		--

		and coalesce(cl.time_in_force,'DAY') <> 'IOC'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count > 1
		and cl.leg_number = 1
		and coalesce(cl.system_order_type,'') <> 'VEGA Order'
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlic_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlim_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlim_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Equity Inernal Route Modified-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_m'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_00'||','||
		'MLIM'||','||
		in_reporter_imid||','||--[5]
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','||
		--===================
		to_char(coalesce(orig.create_date_time, cl.create_date_time),'YYYYMMDD')||' 000000.000'||','||--priorOrderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(orig.transaction64_order_id::text,orig.order_id)
			else orig.order_id
		end||','||--priorOrderID[10]
		--
		--cl.cancel_order_id||','||--priorOrderID[10]
		--===================
		''||','||--originatingIMID

		--2d - timestamp should be taken from 5/5 execution
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp
		--

		'false'||','||--manual flag [13]
		''||','||--electronicTimestamp
		coalesce(dcom.dept_type,'A')||','||--deptType(Agency)[15]
		coalesce(dcom.receiving_desk_type,'A')||','||--receivingDeskType
		--
		'C'||','||--initiator [17]
		''||','|| --[18]
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.complex_price, 'FM9999999990.09999999')
			else ''
		end||','|| -- price [19]
		cl.complex_qty||','|| --[20]
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty
		cl.complex_qty||','||--leavesQty [22]
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','|| -- [23]
		--handling instructions
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, 1, cl.date_id)||','||
		-----------------------
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||--[26]
		--=========--
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','|| --[27] requestTimestamp
		cl.leg_count||','|| --[28]
		'PU'||','|| --priceType[29]
		compliance.get_leg_details(cl.order_id, cl.leg_count, cl.date_id) --[30]
		--=========--
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		--

		from compliance.blaze_client_order cl
		inner join compliance.blaze_client_order orig on cl.cancel_order_id = orig.order_id and orig.leg_number = cl.leg_number
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order pcl on cl.parent_order_id = pcl.order_id and pcl.leg_number = cl.leg_number --and pcl.date_id > 20200719
		--=====================
		--left join dwh.client_order scl on scl.client_order_id = cl.system_order_id and scl.create_date_id = in_date_id and scl.parent_order_id is not null and scl.ex_destination = 'BRKPT' and coalesce(scl.co_client_leg_ref_id,'1')  = cl.leg_number::varchar
		--left join dwh.client_order pscl on pscl.order_id = scl.parent_order_id and pscl.create_date_id = in_date_id
		--=====================
		where cl.date_id = in_date_id
		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid  and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																   --and coalesce(dcom.imid,com.imid) = coalesce(cl.user_imid,''))
																																   and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)

		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject','Ex Reject')
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count > 1
		and cl.leg_number = 1
		and coalesce(cl.system_order_type,'') <> 'VEGA Order'
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlim_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlir_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlir_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;


  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Multi-Leg Order Internal Route Acc.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'INTERNAL', in_date_id ) as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_i'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_00'||','||
		'MLIR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||
		--
		case
			when cl.generation > 0 then to_char(coalesce(pcl.create_date_time, cl.create_date_time),'YYYYMMDD')||' 000000.000'
			else to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'
		end||','||--parentOrderKeyDate[8]
		case
			when cl.generation > 0  and cl.system_name = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.parent_order_id)
			when cl.generation > 0 then cl.parent_order_id
			when cl.client_event_type_id_1 in (1,3) and cl.broker_dealer_mpid = 'SGAS' and position('*' in cl.free_text) > 0 then substring(cl.free_text, 1, position('*' in cl.free_text)-1)
			when cl.client_event_type_id_1 in (1,3) then coalesce(cl.cat_order_id,cl.system_order_id)
			else ''
		end||','||--parentOrderID[9]
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','|| --[10]
		--
		to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--eventTimestamp --[11]
		'false'||','||--manual flag
		''||','||--electronicTimestamp --[13]
		coalesce(dcom.dept_type,'A')||','||--deptType(Agency)[14]
		coalesce(dcom.receiving_desk_type,'A')||','||--receivingDeskType[15]
		--
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.complex_price, 'FM9999999990.09999999')
			else ''
		end||','|| -- price [16]
		cl.complex_qty||','|| --[17]
		--
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty [18]
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||--[19]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','||
		'REG'||','||
		compliance.get_handl_inst_2c(cl.order_Id, 1, cl.date_id)||','||--[22]

		cl.leg_count||','|| --[23]
		'PU'||','|| --priceType[24]
		compliance.get_leg_details(cl.order_id, cl.leg_count, cl.date_id) --[25]
		||
		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3,6) then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.blaze_client_order pcl on cl.parent_order_id = pcl.order_id and pcl.leg_number = cl.leg_number
		left join compliance.blaze_client_order fcl on cl.cat_order_id = fcl.order_id and fcl.leg_number = cl.leg_number --from classic to blaze7

		where cl.date_id = in_date_id
		and ((cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '1'
																																  --and coalesce(dcom.imid,com.imid) = cl.user_imid)
																																  and coalesce(cl.user_imid,com.imid,'') = coalesce(dcom.imid,''))
			 or
			 (cl.client_event_type_id_1 = 6 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			)

		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		and cl.leg_count > 1
		and cl.leg_number = 1
		and coalesce(cl.system_order_type,'') <> 'VEGA Order'
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlir_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlmr_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlmr_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt bigint;
prev_size bigint;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Multi-Leg Order Route-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'ROUTE', in_date_id ) as FILE_GROUP,
        '1'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_mr'||coalesce(cl.client_event_type_id_1,0)||coalesce(cl.client_event_type_id_2,0)||'_00'||','||
		'MLMR'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.date_id::varchar||' 000000.000'
		    else coalesce(po.date_id::varchar||' 000000.000', cl.date_id::varchar||' 000000.000')
		end	||','|| --[6]
		--parent order, child can be suppressed (no 7)
		case
			when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then cl.order_id
			when po.client_event_type_id_1 = 7 then po.parent_order_id
			when cl.client_event_type_id_2 = 3 and upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_parent_order_id::text,cl.transaction64_order_id::text,'')
		    else coalesce(po.order_id, cl.order_id)
		end||','|| --[7]
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','||
		''||','||--originatingIMID
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then to_char(cl.create_date_time,'YYYYMMDD HH24MISS') --manual route
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
        end||','||--[10]
		case
			when cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null then 'true'
			else 'false'
		end||','||--manual flag[11]

		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--electronicTimestamp [12]
		--------------------------------------------------------------------------------------------------------------------------------------------------------
		coalesce((select crd_number||':' from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y')),'')||
			coalesce(cd.cat_sender_imid, in_reporter_imid)||','||--senderIMID [13]

		case
			when cl.receiving_broker_mpid = in_reporter_imid or cl.client_event_type_id_2 = 3 then
		  	case

				when coalesce(drt.is_exchange::varchar,'0') = '1' then
					coalesce(drt.cat_destination_id, '')

			    else
			    	--coalesce(drt.cat_crd_number||':'||drt.cat_destination_id, '')--v2
			    	coalesce(drt.crd_number||':'||drt.cat_destination_id, '')--v2
		   	end
			else
				--coalesce(dcom.imid,'') -- broker routing --v1
				coalesce(dccn.crd_number||':'||dcom.imid,'') --v2
		end||','||--destination[14]
		case
		  when coalesce(drt.is_exchange::varchar,'0') = '1' then 'E'
		  else 'F'
		end||','||--destinationType[15]
		case
			when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.fix_cl_ord_id,cl.order_id)
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (cl.routed_onyx_order_id,cl.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','||--routedOrderID [16]
		case
		    when cl.ex_destination in ('ADIR','PDIR')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (orig.fix_cl_ord_id,orig.order_id)
			when cl.aors_destination in ('AODIR','AOTNT','PODIR','POTNT','ROUTER2')
				and (cl.client_event_type_id_2 = 3 or cl.receiving_broker_mpid = in_reporter_imid) then coalesce (orig.routed_onyx_order_id,orig.order_id)
			---'BLAZPRM', --– Not sure on this path (Dash Prime routes)
			when upper(cl.system_name) = 'BLAZE7' then coalesce(orig.transaction64_order_id::text,orig.order_id)
			else orig.order_id
		end||','||--priorRoutedOrderID [17]
		coalesce(drt.cat_session,'')||','||--session [18]
		''||','||--reserved
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.complex_price, 'FM9999999990.09999999')
			else ''
		end||','|| -- price [20]
		cl.complex_qty||','|| --[21]
		--
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty [22]
		''||','||--retiredFieldPosition
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','||--[24]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','|| --[25]
		'REG'||','||--[26]
		'false'||','||--affiliate flag [27]
		compliance.get_handl_inst_2c(cl.order_Id, 1, cl.date_id)||','|| --[28]

		--
		case
			when coalesce(cl.order_status,'') in ('Reject','Ex Reject','Report Cancel Replace Reject','Ex Rej') then 'true'
			else 'false'
		end||','||--routeRejectedFlag [29]
		'false'||','|| --dupROIDCond [30]
		case
			when coalesce(drt.is_exchange::varchar,'0') = '1' then coalesce(ecf.exch_customer_firm,cl.customer_or_firm,'')
			else ''
		end||','||--exchOriginCode [31]
		cl.leg_count||','|| --[32]
		'PU'||','||--priceType[33]
		compliance.get_leg_details(cl.order_id, cl.leg_count, cl.date_id) --[34]
		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid then coalesce(dcom.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)


		:: varchar

		as ROE

		from compliance.blaze_client_order cl
		inner join compliance.blaze_client_order orig on orig.order_id = cl.cancel_order_id  and orig.leg_number = cl.leg_number

		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)
		left join compliance.crd_number_list dccn on (dcom.imid = dccn.cat_imid
			 										  and
			 									      (dccn.crd_amount = 1 or dccn.is_default = 'Y')
			 									      )
		left join compliance.blaze_client_order po on po.order_id = cl.parent_order_id and po.leg_number = cl.leg_number --and ((po.date_id > 20200619 and po.time_in_force in ('GTC','GTD')) or po.date_id = in_date_id)
		left join lateral
			( select p.order_id
			  from dwh.client_order p
			  inner join dwh.client_order str on str.parent_order_id = p.order_id and str.create_date_id = in_date_id
			  where p.client_order_id = cl.routed_onyx_order_id
			  	and cl.leg_number::varchar = coalesce(p.co_client_leg_ref_id,'1')
			  	and p.create_date_id  = in_date_id
			  	and p.ex_destination = 'W'
			  	and str.exchange_id = 'C1PAR'
			  	limit 1) spo on true
		--modification route should be reported
		left join compliance.blaze_d_route drt on (drt.ex_destination = cl.ex_destination )
		left join compliance.blaze_client2destination cd on (cd.ex_destination = cl.ex_destination and cd.client_imid = in_reporter_imid)
		left join compliance.blaze_d_exchange2cust_firm ecf on (ecf.cat_exchange_id  = drt.cat_destination_id and ecf.customer_or_firm  = cl.customer_or_firm)
		left join compliance.blaze_client_order orcl on orcl.order_id = cl.cancel_order_id  and orcl.leg_number = cl.leg_number
		--
		where cl.date_id = in_date_id
		and ((cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name <> 'BLAZE7' and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --electronic market routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 3 and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE',''))
			  or
			 (cl.broker_dealer_mpid = in_reporter_imid and cl.client_event_type_id_1 = 5 and coalesce(com.cat_submitter_imid,'') not in ('NONE','')) --broker routing
			  or
			 (cl.receiving_broker_mpid = in_reporter_imid and cl.client_event_type_id_2 = 4 and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and cl.aors_destination is not null) --OBO scenario, electronic routing to the market
			)
		--and (in_reporter_imid <> 'DFIN' or coalesce(drt.cat_destination_id,'') <> 'DFIN')
		--suppress manual for configuration = 5
		and ((cl.client_event_type_id_1 = 5 and cl.broker_dealer_mpid = in_reporter_imid and cl.obo_user is not null) is false
				or coalesce(com.cat_configuration,'') not like '%5%')
		and (in_reporter_imid <> coalesce(drt.cat_destination_id,''))
		and coalesce(drt.cat_route_suppress::varchar, '0' ) = '0'

		and cl.cancel_order_id <> '00000000-0000-0000-0000-000000000000'  --add more conditions

		and spo.order_id is null
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count > 1
		and cl.leg_number = 1
		and cl.system_order_type <> 'VEGA Order'
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlmr_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mlno_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

CREATE FUNCTION compliance.insert_mlno_record(in_reporter_imid character varying, in_date_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare

prev_rec_cnt integer;
prev_size integer;


begin


  select count(1) into prev_rec_cnt from COMPLIANCE.CAT_REPORT;
  select coalesce(sum(ROE_SIZE),0) into prev_size from COMPLIANCE.CAT_REPORT;

  insert into COMPLIANCE.CAT_REPORT (CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE, TOTAL_SIZE)
  select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, ROE_NUMBER, ROE_SIZE--, null
		,prev_size + sum(ROE_SIZE) over(order by ROE_NUMBER rows between unbounded preceding and current row)  TOTAL_SIZE
	from
	(
	select CLIENT_MPID, FILE_GROUP, ORDER_IND, ROE, prev_rec_cnt + row_number() OVER () ROE_NUMBER, length(ROE) ROE_SIZE
	from
	    (

	     -------------------Multi-Leg New Order-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
        compliance.get_file_group(dcom.file_group, com.file_group, dcom.cat_configuration, com.cat_configuration, cl.order_id, 'NEW', in_date_id ) as FILE_GROUP,
        	   '1'::varchar as ORDER_IND,

		'NEW'||','||--[1]
		''||','||
		cl.date_id::varchar||'_'||cl.system_order_id::varchar||'_n'||coalesce(cl.client_event_type_id_1,'0')||coalesce(cl.client_event_type_id_2,'0')||'_00'||','||
		'MLNO'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.create_date_time,'YYYYMMDD')||' 000000.000'||','||--[6]orderKeyDate
		--B7 logic
		case cl.system_name
			when 'BLAZE7' then coalesce(cl.transaction64_order_id::text,cl.order_id)
			else cl.order_id
		end||','|| --[7]
		--
		case
			when compliance.get_blaze_underlying_count(cl.order_id, cl.date_id) = 1
				then coalesce(compliance.get_underlying_by_root(trim(substring(cl.osi_symbol, 1, 6))),cl.symbol,'')
			else ''
		end||','|| --[8] Underlying

		case
		    --representative is electronic
		    when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.leg_count > 1
		    	then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--Timestamp for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 in (2,7)
				then to_char(coalesce(cl.receive_time,cl.create_date_time),'YYYYMMDD HH24MISS')
			--Electronic
			else to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
		end||','||--eventTimestamp

		case
		    when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.leg_count > 1 then 'false'
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 in (2,7) then 'true'
			else 'false'
		end||','||--manual flag[10]
		''||','||--to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')||','||--manualOrderKeyDate [11]
		''||','||--cl.order_id||','||--manualOrderID [12]
		--
		'false'||','||--electronicDupFlag [13]
		case
		    when cl.representative = '1' and cl.user_acc_holder_type = 'V'
		    	then ''
			--for manual orders:
			when (cl.client_event_type_id_2 = 4 and cl.obo_user is not null) or cl.client_event_type_id_1 in (2,7)
				then to_char(cl.create_date_time,'YYYYMMDD HH24MISS.MS')
			--electronic
			else ''
		end||','||--electronicTimestamp [14]

		case
			when cl.client_event_type_id_1 in (2,7) then coalesce(com.dept_type,'A')
			else coalesce(dcom.dept_type,'A')
		end||','||--deptType(Agency)[15]
		--complex_price
		case
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then to_char(cl.complex_price, 'FM9999999990.09999999')
			else ''
		end||','|| --[16]
		cl.complex_qty||','|| --[17]
		--
		coalesce(nullif(cl.min_quantity,0)::varchar,'')||','||--minQty [18]
		case
			when cl.is_cabinet = 'Y' then 'CAB'
		    when upper(cl.order_type) in ('LIMIT','STOP LIMIT') then 'LMT'
			else 'MKT'
		end||','|| --[19]
		case
			when cl.time_in_force in ('GTC','IOC') then cl.time_in_force
			when cl.time_in_force = 'GTX' then 'GTX='||to_char(cl.create_date_time,'YYYYMMDD')
			when cl.time_in_force = 'GTD' then 'GTD='||to_char(coalesce(cl.good_till_date, cl.create_date_time),'YYYYMMDD')
			else 'DAY='||to_char(cl.create_date_time,'YYYYMMDD')
		end||','|| --[20]
		'REG'||','|| --[21]
		--handling instructions[22]
		-----------------------
		compliance.get_handl_inst_2c(cl.order_Id, cl.leg_number, cl.date_id)||','||
		-----------------------
		case
			when cl.client_event_type_id_1 in (1,2,3) and cl.obo_user is null then coalesce(nullif(cl.user_fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.fdid,''),nullif(cl.user_fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
		    --
			else coalesce(nullif(com.fdid,''),compliance.get_pending(cl.order_id, cl.date_id, dcom.cat_configuration, com.cat_configuration))
		end||','||--firmDesignatedID (#account) --[23]
		case
			when cl.client_event_type_id_1 in (1,2,3)  and cl.obo_user is null then coalesce(nullif(cl.user_acc_holder_type,''),'A')
			--use company setting for obo
			when (cl.client_event_type_id_1 = 2 or cl.client_event_type_id_2 = 4) and cl.obo_user is not null then coalesce(nullif(com.account_holder_type,''),nullif(cl.user_acc_holder_type,''),'A')
			--
			else coalesce(nullif(com.account_holder_type,''),'A')
		end||','||--accountHolderType --[24]
		case
			when cl.client_event_type_id_1 in (1,3) and dcom.parent = cl.user_parent then 'true'
			when cl.client_event_type_id_1 = 2 and cl.acc_affiliate_flag = '1' then 'true'
			when cl.client_event_type_id_2 = 4 and dcom.parent = com.parent then 'true'
			else 'false'
		end||','||--affiliate flag --[25]
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then compliance.get_represented_orders(cl.order_id, cl.date_id)
			else ''
		end||','||--aggregated orders
		case
			when cl.representative = '1' and cl.user_acc_holder_type = 'V' and cl.has_represented_order = '1'
				then 'O'
			else 'N'
		end||','||--representativeInd  --[27]
		'false'||','|| --solicitationFlag[28]
		--
		''||','|| --RFGID
		cl.leg_count||','||
        'PU'||','|| --[31] price type

		compliance.get_leg_details(cl.order_id, cl.leg_count, cl.date_id) --[32]

		||

		compliance.get_custom_field(case
					                 when cl.client_event_type_id_1 in (1,3) or cl.client_event_type_id_2 = 4 then coalesce(dcom.cat_configuration,com.cat_configuration,'')
					                 else coalesce(com.cat_configuration,'')
               						end,cl.order_Id,cl.leg_number,cl.date_id)

		:: varchar

		as ROE

		from
		/*
			(
			select clo.date_id, clo.system_name, clo.company_id, clo.dest_company_id, clo.receiving_broker_mpid, clo.broker_dealer_mpid, clo.order_id, clo.transaction64_order_id, clo.system_order_id, clo.client_event_type_id_1, clo.client_event_type_id_2,
				   clo.create_date_time, clo.receive_time, clo.symbol, clo.representative, clo.user_acc_holder_type, clo.obo_user, clo.order_type, clo.time_in_force, clo.user_fdid, clo.good_till_date, clo.complex_qty, clo.complex_price, clo.user_parent,
				   clo.acc_affiliate_flag, clo.user_is_broker_dealer, clo.cancel_order_id, clo.order_status, clo.leg_count, clo.min_quantity

			from compliance.blaze_client_order clo
			where clo.date_id = in_date_id
			and clo.leg_count > 1
			and clo.leg_number = 1) cl
		*/
		compliance.blaze_client_order cl
		left join compliance.blaze_d_entity_cat com on (com.company_id = cl.company_id)
		left join compliance.blaze_d_entity_cat dcom on (dcom.company_id = cl.dest_company_id)

		where cl.date_id = in_date_id
		--
		and ((cl.client_event_type_id_2 = 4 and cl.receiving_broker_mpid = in_reporter_imid and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and coalesce(com.is_broker_dealer,'0') = '0') --incoming broker routing
			 or
			 (cl.client_event_type_id_1 = 2 and cl.broker_dealer_mpid = in_reporter_imid and cl.system_name = 'BLAZE' and coalesce(com.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '0') --manual order entry
			 or
			 (cl.client_event_type_id_1 = 2 and cl.receiving_broker_mpid = in_reporter_imid and cl.system_name = 'BLAZE7' and coalesce(dcom.cat_submitter_imid,'') not in ('NONE','') and coalesce(cl.user_is_broker_dealer,'0') = '0') --manual order entry
			 or
			 (cl.client_event_type_id_1 in (1,3) and coalesce(cl.receiving_broker_mpid, cl.broker_dealer_mpid) = in_reporter_imid and coalesce(cl.user_is_broker_dealer,com.is_broker_dealer,'0') = '0' ) --fix staging
			 or
			 (cl.client_event_type_id_1 = 7 and cl.receiving_broker_mpid = in_reporter_imid and cl.system_order_type = 'Stitched Complex')
			 or
			 (cl.client_event_type_id_2 = 3 and cl.receiving_broker_mpid = in_reporter_imid and cl.system_order_type = 'Stitched Complex' and cl.parent_order_id = '00000000-0000-0000-0000-000000000000')
			)
		--
		--suppress manual for configuration = 5--
		--broker routing, obo
		and (coalesce(cl.client_event_type_id_2,0) <> 4 or coalesce(cl.obo_user,'') is null or coalesce(dcom.cat_configuration,'') not like '%5%')
		--manual entry
		and (coalesce(cl.client_event_type_id_1,0) <> 2 or  coalesce(com.cat_configuration,'') not like '%5%')
		--
		and cl.cancel_order_id = '00000000-0000-0000-0000-000000000000'
		and coalesce(cl.order_status,'') not in ('Reject')
		and cl.symbol not in (select symbol from dwh.d_test_symbol_list)
		--
		and cl.leg_count > 1
		and cl.leg_number = 1
		and coalesce(cl.system_order_type,'') <> 'VEGA Order'
		order by CLIENT_MPID, ORDER_IND

		) T_ROE
	)ORP;

  end;
$$;


ALTER FUNCTION compliance.insert_mlno_record(in_reporter_imid character varying, in_date_id integer) OWNER TO dwh;

--
-- Name: insert_mloa_record(character varying, integer); Type: FUNCTION; Schema: compliance; Owner: dwh
--

