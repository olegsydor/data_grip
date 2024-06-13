create schema if not exists genesis2;

-- DROP FUNCTION public.get_message_tag_string(int8, int4, int4, bool);

CREATE FUNCTION public.get_message_tag_string(in_fix_message_id bigint, in_tag_number integer, in_date_id integer,
                                              in_null_when_crash boolean DEFAULT true)
    RETURNS character varying
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
DECLARE

    --  v_char_value varchar DEFAULT NULL;
    v_input      text;
    v_tag_number text;
    v_return     varchar DEFAULT NULL;

BEGIN
    BEGIN

        v_tag_number := in_tag_number::text;

        select fix_message ->> v_tag_number
        into v_input
        from fix_capture.fix_message_json
        where fix_message_id = in_fix_message_id
          and date_id = in_date_id;

--        v_char_value := v_input::varchar;

    EXCEPTION
        WHEN OTHERS then
            RAISE NOTICE 'Invalid varchar value: "%".  Returning NULL.', v_input;

            v_return := case when in_null_when_crash is true then null else v_input::varchar end;
            RETURN v_return;

    END;

    RETURN v_input;

END;
$function$
;


-- DROP FUNCTION public.get_message_tag_string_cross_multileg(int8, int4, int4, text, text, text, bool, bool);

CREATE FUNCTION public.get_message_tag_string_cross_multileg(in_fix_message_id bigint, in_tag_number integer, in_date_id integer, in_client_order_id text, in_account_name text DEFAULT NULL::text, in_legref_id text DEFAULT NULL::text, in_is_cross boolean DEFAULT false, in_null_when_crash boolean DEFAULT true)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- SY: 20230821 https://dashfinancial.atlassian.net/browse/DS-7137 Inital creation (Based on https://dashfinancial.atlassian.net/browse/DS-7032)
-- SY: 20230905 Fixed bug for mulileg non cross.
DECLARE
    l_result     varchar;
    v_return varchar DEFAULT NULL;
    l_tag_number text := in_tag_number::text;
begin
	if (in_is_cross is null or in_is_cross is false) and in_legref_id is null
	then
		 select public.get_message_tag_string(in_fix_message_id, in_tag_number, in_date_id, in_null_when_crash)::varchar key_value
	            into l_result;
		return l_result;
	end if;
    begin
with key_value_fix_message as (
   select key,
      value,
      fix_message
   FROM fix_capture.fix_message_json,
      json_each(fix_message)
   where fix_message_id = in_fix_message_id
      and date_id = in_date_id
),
distinct_keys as (
   select key,
      count(key) key_cnt
   from key_value_fix_message
   group by key
),
singles as (
   select jsonb_object_agg(s.key, s.value) js
   from key_value_fix_message s
      join distinct_keys c on s.key = c.key
   where key_cnt = 1
),
groupe as (
   select btrim(unnest(string_to_array( '{"11": ' || btrim( unnest( string_to_array(json_object_agg(s.key, s.value)::text, '"11" :')), ' {:,}' ) || '}',  '"654"' ) ),' ,}' ) || '}' js
   from key_value_fix_message s,
      distinct_keys c
   where key_cnt >= 2
      and s.key in (c.key) offset 1
),
finale as (
      select case when js like '{"11"%' then 'group'  else 'multileg' end as status,
         case when js like ':%' then ('{"654"' || js)::jsonb else js::jsonb end as js
      from groupe
   ),
 gr as  (select * from finale where status = 'group') ,
 ml as (select * from finale where status = 'multileg'),
super_final as materialized (
select /*greatest(gr.status, ml.status) as status,*/ coalesce (gr.js, '{}'::jsonb)||coalesce (ml.js, '{}'::jsonb) as js
       from gr full outer join ml on true
		   union all
		      select /*'single' status,*/ js
		      from singles
		)
    select /*js ->> '11', js ->> '1' , js ->> '654',  **/
          --status as group_status,
          js ->> l_tag_number as key_value
    into l_result
    from super_final
    where
	case when in_client_order_id 	is not null and in_is_cross then js ->> '11'  = in_client_order_id else true end
	and case when in_account_name 	is not null then js ->> '1'   = in_account_name else true end
	and case when in_legref_id 		is not null then js ->> '654' = in_legref_id else true end;

--    raise info '%', l_result;

    if l_result is null then
    select /*'single' as group_status,*/ fix_message->>l_tag_number as key_value
        into l_result
        from fix_capture.fix_message_json
        where fix_message_id = in_fix_message_id
        and date_id =in_date_id;
    end if;
    --raise info '%', l_result;
    EXCEPTION
        WHEN OTHERS then
            RAISE NOTICE 'Invalid varchar value: "%".  Returning NULL.', l_result;
           -- v_return := case when in_null_when_crash is true then null else l_result::varchar end;
            RETURN  l_result;
    END;
    return  l_result;
    END;
$function$
;


CREATE OR REPLACE VIEW genesis2.trade_record_v_historical
AS
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
--     cl.sub_strategy_desc AS sub_strategy,
    ts.target_strategy_name,
    str.order_id AS street_order_id,
    cl.order_id,
    str.order_qty AS street_order_qty,
    cl.order_qty,
    cl.multileg_reporting_type,
    str.max_floor AS street_max_floor,
        CASE
            WHEN i.instrument_type_id = 'O'::bpchar THEN
            CASE
                WHEN acc.opt_is_fix_execbrok_processed::text = 'Y'::text THEN COALESCE(COALESCE(cl_br.opt_exec_broker, get_message_tag_string_cross_multileg(cl.fix_message_id, 76, cl.create_date_id, cl.client_order_id::text, acc.account_name::text, cl.co_client_leg_ref_id::text,
                CASE
                    WHEN cl.cross_order_id IS NULL THEN false
                    ELSE true
                END)), opx.opt_exec_broker)
                ELSE opx.opt_exec_broker
            END
            ELSE get_message_tag_string_cross_multileg(str.fix_message_id, 76, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
            CASE
                WHEN str.cross_order_id IS NULL THEN false
                ELSE true
            END)
        END AS exec_broker,
    lpad(
        CASE
            WHEN i.instrument_type_id = 'O'::bpchar THEN NULLIF(COALESCE(COALESCE(COALESCE(get_message_tag_string(ex.fix_message_id, 439, ex.exec_date_id), get_message_tag_string(str_ex.fix_message_id, 439, str_ex.exec_date_id)), str.clearing_firm_id::text::character varying), get_message_tag_string_cross_multileg(cl.fix_message_id, 439, cl.create_date_id, cl.client_order_id::text, acc.account_name::text, cl.co_client_leg_ref_id::text,
            CASE
                WHEN cl.cross_order_id IS NULL THEN false
                ELSE true
            END))::text, '949'::text)
            ELSE NULL::text
        END, 3, '0'::text) AS cmta,
    str.time_in_force_id AS street_time_in_force,
    str.order_type_id AS street_order_type,
    cl.customer_or_firm_id AS opt_customer_firm,
    ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) AS str_opt_customer_firm,
    str.market_participant_id AS street_mpid,
        CASE
            WHEN cl.cross_order_id IS NULL THEN 'N'::text
            ELSE 'Y'::text
        END AS is_cross_order,
        CASE
            WHEN str.cross_order_id IS NULL THEN 'N'::text
            ELSE 'Y'::text
        END AS street_is_cross_order,
    ( SELECT c.cross_type
           FROM dwh.cross_order c
          WHERE c.cross_order_id = str.cross_order_id) AS street_cross_type,
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
    get_message_tag_string(ex.fix_message_id, 9090, ex.exec_date_id) AS fee_sensitivity,
    COALESCE(str.strtg_decision_reason_code, cl.strtg_decision_reason_code) AS strategy_decision_reason_code,
    cl.compliance_id,
    get_message_tag_string_cross_multileg(cl.fix_message_id, 143, cl.create_date_id, cl.client_order_id::text, acc.account_name::text, cl.co_client_leg_ref_id::text,
        CASE
            WHEN cl.cross_order_id IS NULL THEN false
            ELSE true
        END) AS floor_broker_id,
    str2au.auction_id,
        CASE
            WHEN ex.exchange_id::text = ANY (ARRAY['AMEX'::character varying::text, 'ARCE'::character varying::text]) THEN
            CASE ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text))
                WHEN '3'::text THEN get_message_tag_string_cross_multileg(str.fix_message_id, 50, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)::text
                ELSE NULL::text
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['ISE'::character varying::text, 'GEMINI'::character varying::text, 'MCRY'::character varying::text, 'MIAX'::character varying::text, 'MPRL'::character varying::text, 'PHLX'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['4'::text, '5'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)::text
                ELSE NULL::text
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['BATO'::character varying::text, 'EDGO'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'N'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)::text
                ELSE NULL::text
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['C2OX'::character varying::text, 'CBOE'::character varying::text, 'CBOEEH'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'N'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 1462, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)::text
                ELSE NULL::text
            END
            WHEN ex.exchange_id::text = 'BOX'::text THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'X'::text]) THEN NULL::text
                ELSE NULL::text
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['NSDQO'::character varying::text, 'NQBXO'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'O'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)::text
                ELSE NULL::text
            END
            ELSE NULL::text
        END AS sub_account,
        CASE
            WHEN ex.exchange_id::text = ANY (ARRAY['AMEX'::character varying::text, 'ARCE'::character varying::text]) THEN
            CASE ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text))
                WHEN '3'::text THEN NULL::character varying
                ELSE cross_acc.account_name
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['BATO'::character varying::text, 'EDGO'::character varying::text]) THEN cross_acc.account_name
            WHEN ex.exchange_id::text = ANY (ARRAY['C2OX'::character varying::text, 'CBOE'::character varying::text, 'CBOEEH'::character varying::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 440, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
            CASE
                WHEN str.cross_order_id IS NULL THEN false
                ELSE true
            END)
            WHEN ex.exchange_id::text = 'BOX'::text THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'X'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['ISE'::character varying::text, 'GEMINI'::character varying::text, 'MCRY'::character varying::text, 'MIAX'::character varying::text, 'MPRL'::character varying::text, 'PHLX'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['4'::text, '5'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
                    ELSE true
                END)
                ELSE cross_acc.account_name
            END
            WHEN ex.exchange_id::text = ANY (ARRAY['NSDQO'::character varying::text, 'NQBXO'::character varying::text]) THEN
            CASE
                WHEN ltrim(rtrim(COALESCE(str.eq_order_capacity, str.customer_or_firm_id)::text)) = ANY (ARRAY['M'::text, 'O'::text]) THEN get_message_tag_string_cross_multileg(str.fix_message_id, 58, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
                CASE
                    WHEN str.cross_order_id IS NULL THEN false
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
    get_message_tag_string(str_ex.fix_message_id, 5049, str_ex.exec_date_id) AS str_cls_comp_id,
    COALESCE(get_message_tag_string(str_ex.fix_message_id, 1, str_ex.exec_date_id), get_message_tag_string_cross_multileg(str.fix_message_id, 1, str.create_date_id, str.client_order_id::text, acc.account_name::text, str.co_client_leg_ref_id::text,
        CASE
            WHEN str.cross_order_id IS NULL THEN false
            ELSE true
        END)) AS street_account_name,
    get_message_tag_string(str_ex.fix_message_id, 9861, str_ex.exec_date_id) AS branch_seq_num,
    str_ex.exec_text AS trade_text,
    get_message_tag_string(str_ex.fix_message_id, 21097, str_ex.exec_date_id) AS frequent_trader_id,
    cl.time_in_force_id AS time_in_force,
        CASE
            WHEN str2au.auction_id IS NULL THEN NULL::text
            ELSE
            CASE
                WHEN (( SELECT count(1) AS count
                   FROM data_marts.f_rfq_details r
                  WHERE r.auction_id = str2au.auction_id AND r.auction_date_id = str2au.create_date_id)) > 0 THEN 'A'::text
                ELSE 'C'::text
            END
        END AS is_ats_or_cons,
    cl.market_participant_id AS mpid,
    cl.alternative_compliance_id,
    str_ex.exec_time AS street_trade_record_time,
    str.process_time AS street_order_process_time,
    cl.co_client_leg_ref_id,
    get_message_tag_string_cross_multileg(cl.fix_message_id, 10445, cl.create_date_id, cl.client_order_id::text, acc.account_name::text, cl.co_client_leg_ref_id::text,
        CASE
            WHEN cl.cross_order_id IS NULL THEN false
            ELSE true
        END) AS blaze_account_alias
   FROM dwh.execution ex
     JOIN dwh.client_order cl ON ex.order_id = cl.order_id AND (cl.multileg_reporting_type = ANY (ARRAY['1'::bpchar, '2'::bpchar])) AND cl.parent_order_id IS NULL AND cl.trans_type <> 'F'::bpchar
     JOIN dwh.d_account acc ON cl.account_id = acc.account_id
     JOIN dwh.d_instrument i ON cl.instrument_id = i.instrument_id
     LEFT JOIN dwh.d_sub_system dss ON cl.sub_system_unq_id = dss.sub_system_unq_id
     LEFT JOIN dwh.client_order str ON ex.secondary_order_id::text = str.client_order_id::text AND str.parent_order_id = cl.order_id
     LEFT JOIN dwh.client_order2auction str2au ON str.order_id = str2au.order_id AND str.create_date_id = str2au.create_date_id
     LEFT JOIN dwh.d_account cross_acc ON str.cross_account_id = cross_acc.account_id
     LEFT JOIN dwh.execution str_ex ON ex.secondary_exch_exec_id::text = str_ex.exch_exec_id::text AND str_ex.order_id = str.order_id AND ex.exec_date_id = str_ex.exec_date_id
     LEFT JOIN dwh.d_opt_exec_broker opx ON cl.account_id = opx.account_id AND opx.is_active AND opx.is_default::text = 'Y'::text
     LEFT JOIN dwh.d_opt_exec_broker cl_br ON cl.opt_exec_broker_id = cl_br.opt_exec_broker_id
     LEFT JOIN dwh.d_opt_exec_broker str_br ON str_br.opt_exec_broker_id = opx.opt_exec_broker_id
     LEFT JOIN dwh.d_fix_connection fc ON fc.fix_connection_id = cl.fix_connection_id
   left join dwh.d_target_strategy ts on ts.target_strategy_id = cl.sub_strategy_id
  WHERE ex.is_busted <> 'Y'::bpchar AND ex.exec_type = 'F'::bpchar;



--drop table if exists dwh.trade_record;

create table if not exists genesis2.trade_record
(
    trade_record_id               bigserial NOT NULL,
    trade_record_time             timestamp,
    db_create_time                timestamp DEFAULT now(),
    date_id                       int4      NOT NULL,
    is_busted                     bpchar(1),
    orig_trade_record_id          int8,
    trade_record_trans_type       bpchar(1),
    trade_record_reason           bpchar(1),
    subsystem_id                  varchar(20),
    user_id                       int4,
    account_id                    int4,
    client_order_id               varchar(256),
    instrument_id                 int4,
    side                          bpchar(1),
    open_close                    bpchar(1),
    fix_connection_id             int2,
    exec_id                       int8,
    exchange_id                   varchar(6),
    trade_liquidity_indicator     varchar(256),
    secondary_order_id            varchar(256),
    exch_exec_id                  varchar(128),
    secondary_exch_exec_id        varchar(128),
    last_mkt                      varchar(5),
    last_qty                      int4,
    last_px                       numeric(16, 8),
    ex_destination                varchar(5),
    sub_strategy                  varchar(128),
    street_order_id               int8,
    order_id                      int8,
    street_order_qty              int4,
    order_qty                     int4,
    multileg_reporting_type       bpchar(1),
    is_largest_leg                bpchar(1),
    street_max_floor              int4,
    exec_broker                   varchar(32),
    cmta                          varchar(3),
    street_time_in_force          bpchar(1),
    street_order_type             bpchar(1),
    opt_customer_firm             bpchar(1),
    street_mpid                   varchar(18),
    is_cross_order                bpchar(1),
    street_is_cross_order         bpchar(1),
    street_cross_type             bpchar(1),
    cross_is_originator           bpchar(1),
    street_cross_is_originator    bpchar(1),
    contra_account                bpchar(1),
    contra_broker                 varchar(256),
    trade_exec_broker             varchar(32),
    order_fix_message_id          int8,
    trade_fix_message_id          int8,
    street_order_fix_message_id   int8,
    client_id                     varchar(255),
    street_transaction_id         int8,
    transaction_id                int8,
    order_price                   numeric(12, 4),
    order_process_time            timestamp,
    clearing_account_number       varchar(25),
    sub_account                   varchar(30),
    remarks                       varchar(100),
    optional_data                 varchar(25),
    street_client_order_id        varchar(256),
    fix_comp_id                   varchar(30),
    leaves_qty                    int4,
    is_billed                     bpchar(1) DEFAULT 'N'::bpchar,
    street_exec_inst              varchar(128),
    fee_sensitivity               int2,
    street_order_price            numeric(12, 4),
    leg_ref_id_old                int2,
    load_batch_id                 int4,
    strategy_decision_reason_code int2,
    compliance_id                 varchar(256),
    floor_broker_id               varchar(255),
    auction_id                    int8,
    street_opt_customer_firm      varchar(1),
    multileg_order_id             int8,
    internal_component_type       varchar(1),
    street_trade_fix_message_id   int8,
    pt_basket_id                  varchar(100),
    pt_order_id                   int8,
    blaze_account_alias           varchar(255),
    customer_review_status        bpchar(1) DEFAULT NULL::bpchar,
    street_client_sender_compid   varchar(30),
    street_account_name           varchar(255),
    street_exec_broker            varchar(32),
    branch_sequence_number        varchar(256),
    trade_text                    varchar(100),
    frequent_trader_id            varchar(6),
    time_in_force                 varchar(3),
    int_liq_source_type           varchar(1),
    allocation_avg_price          numeric(12, 6),
    account_nickname              varchar(40),
    clearing_account_id           int4,
    market_participant_id         varchar(18),
    alternative_compliance_id     varchar(256),
    street_trade_record_time      timestamp,
    street_order_process_time     timestamp,
    leg_ref_id                    varchar(60),
    constraint pk_trade_record primary key (trade_record_id)
);
create index trade_record_date_id_idx on genesis2.trade_record using btree (date_id);
create index trade_record_etl_idx on genesis2.trade_record using btree (load_batch_id);
create index trade_record_exec_id_idx on genesis2.trade_record using btree (exec_id);
create unique index trade_record_nk on genesis2.trade_record using btree (date_id,
                                                                     coalesce(exch_exec_id, (exec_id)::character varying),
                                                                     client_order_id, (
                                                                         case
                                                                             when (orig_trade_record_id is not null)
                                                                                 then trade_record_id
                                                                             else (1)::bigint
                                                                             end));
create index trade_record_order_id_date_id_idx on genesis2.trade_record using btree (order_id, date_id);
create index trade_record_orig_trade_record_id_idx on genesis2.trade_record using btree (orig_trade_record_id);
create index trade_record_secondary_order_idx on genesis2.trade_record using btree (secondary_order_id);
create index trade_record_street_order_id_date_id_idx on genesis2.trade_record using btree (street_order_id, date_id);

-- genesis2.trade_record foreign keys

alter table genesis2.trade_record
    add constraint fk_trade_record_exchange foreign key (exchange_id) references dwh.d_exchange (exchange_unq_id);
alter table genesis2.trade_record
    add constraint fk_trade_record_instrument foreign key (instrument_id) references dwh.d_instrument (instrument_id);
alter table genesis2.trade_record
    add constraint trade_record_account_id_fkey foreign key (account_id) references dwh.d_account (account_id);
alter table genesis2.trade_record
    add constraint trade_record_instrument_id_fkey foreign key (instrument_id) references dwh.d_instrument (instrument_id);


comment on column genesis2.trade_record.trade_record_time IS 'Exec time from PARENT level EXECUTION';
comment on column genesis2.trade_record.date_id IS 'based on exec_time of the parent level order';
comment on column genesis2.trade_record.orig_trade_record_id IS 'If we split trade we bust the old one and create two or more new trades with old_trade_record_if in the orig_trade_record_id field';
comment on column genesis2.trade_record.trade_record_trans_type IS 'Based on client_order.trans_type of the parent level order';
comment on column genesis2.trade_record.trade_record_reason IS 'Initially based on STRATEGY_DECISION_REASON_CODE field of the parent level of client_order record
- ''P'': post-trade modification/correction (all splits, clearing changes)
- ''A'': manual (away) trade
- ''B'': trade bust/cancel (electronic or manual)
- ''L'': manual allocation
- ''U'': Manual unallocation';
comment on column genesis2.trade_record.subsystem_id IS 'Based on client_order.SUB_SYSTEM_ID of the parent order level. We use PG_DASH for empty subsystem_id of DASH trafic';
comment on column genesis2.trade_record.user_id IS 'Based on client_order.user_id of the parent order level';
comment on column genesis2.trade_record.account_id IS 'Based on client_order.account_id of the parent order level';
comment on column genesis2.trade_record.client_order_id IS 'client_order_id of the parent level record';
comment on column genesis2.trade_record.instrument_id IS 'Based on client_order.instrument_id of the parent order level';
comment on column genesis2.trade_record.side IS 'Side of the parent level order';
comment on column genesis2.trade_record.open_close IS 'Based on client_order.open_close of the parent order level';
comment on column genesis2.trade_record.fix_connection_id IS 'Fix_connection_id of the parent level order. Base on cl.fix_connection_id';
comment on column genesis2.trade_record.exec_id IS 'Exec ID of the parent level trade';
comment on column genesis2.trade_record.exchange_id IS 'Base on execution.EXCHANGE_ID of the parent order level';
comment on column genesis2.trade_record.trade_liquidity_indicator IS 'Based on execution.TRADE_LIQUIDITY_INDICATOR of the parent order trade';
comment on column genesis2.trade_record.secondary_order_id IS 'Based on execution.SECONDARY_ORDER_ID of the parent order trade. Means street client_order_id???';
comment on column genesis2.trade_record.exch_exec_id IS 'Based on execution.exch_exec_id of the parent order trade. Means exec_id that arrives form the exchange';
comment on column genesis2.trade_record.secondary_exch_exec_id IS 'Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange';
comment on column genesis2.trade_record.last_mkt IS 'Based on execution.last_mkt of the parent order trade.';
comment on column genesis2.trade_record.last_qty IS 'Based on execution.last_qty of the parent order trade. Means quantity';
comment on column genesis2.trade_record.last_px IS 'Based on execution.last_px of the parent order trade. Means price';
comment on column genesis2.trade_record.ex_destination IS 'Based on client_order.ex_destination of the parent order level';
comment on column genesis2.trade_record.sub_strategy IS 'Based on client_order.sub_strategy of the parent order level';
comment on column genesis2.trade_record.street_order_id IS 'street order_id str.order_id';
comment on column genesis2.trade_record.order_id IS 'parent order ID cl.order_id';
comment on column genesis2.trade_record.street_order_qty IS 'order_qty arrives from STREET level of client_order table';
comment on column genesis2.trade_record.order_qty IS 'order_qty arrives from PARENT level of client_order table';
comment on column genesis2.trade_record.multileg_reporting_type IS 'MULTILEG_REPORTING_TYPE arrives from PARENT level of client_order table';
comment on column genesis2.trade_record.is_largest_leg IS 'by default ''N'' ';
comment on column genesis2.trade_record.street_max_floor IS 'MAX_FLOOR field of the STREET level client order';
comment on column genesis2.trade_record.exec_broker IS 'based on  street client_order.opt_exec_broker ';
comment on column genesis2.trade_record.cmta IS 'Based on client_order.Clearing_firm_id of he parent level order. if it is empty we use 439 fix message if still empty we use  clearing_account.CMTA';
comment on column genesis2.trade_record.street_time_in_force IS 'Based on client_order.TIME_IN_FORCE of the strret level order';
comment on column genesis2.trade_record.street_order_type IS 'Based on client_order.ORDER_TYPE of the strret level order';
comment on column genesis2.trade_record.opt_customer_firm IS 'Based on client_order.OPT_CUSTOMER_FIRM of the parent level order';
comment on column genesis2.trade_record.street_mpid IS 'Based on client_order.MPID of the strret level order';
comment on column genesis2.trade_record.is_cross_order IS 'N if cross_order_id of the parent level order is null and Y in other case';
comment on column genesis2.trade_record.street_is_cross_order IS 'N if cross_order_id of the street level order is null and Y in other case';
comment on column genesis2.trade_record.street_cross_type IS 'CROSS_TYPE of the street level order';
comment on column genesis2.trade_record.cross_is_originator IS 'Based on the IS_ORIGINATOR of the PARENT level client_order';
comment on column genesis2.trade_record.street_cross_is_originator IS 'Based on the IS_ORIGINATOR of the STREET level client_order';
comment on column genesis2.trade_record.contra_account IS 'Based on the CONTRA_ACCOUNT_CAPACITY field of the PARENT level exection';
comment on column genesis2.trade_record.contra_broker IS 'Based on the CONTRA_BROKER field of the PARENT level exection';
comment on column genesis2.trade_record.trade_exec_broker IS 'based on execution.exec_broker';
comment on column genesis2.trade_record.order_fix_message_id IS 'Based on the fix_message_id field of the PARENT level client_order';
comment on column genesis2.trade_record.trade_fix_message_id IS 'Based on the fix_message_id field of the PARENT level EXECUTION';
comment on column genesis2.trade_record.street_order_fix_message_id IS 'Based on the fix_message_id field of the STREET level of client_order table';
comment on column genesis2.trade_record.client_id IS 'Based on the client_id field of the PARENT level client_order';
comment on column genesis2.trade_record.street_transaction_id IS 'client_order.transaction_id of the street level';
comment on column genesis2.trade_record.transaction_id IS 'client_order.transaction_id of the parent order level';
comment on column genesis2.trade_record.leaves_qty IS 'Based on the LEAVES_QTY field of the PARENT level EXECUTION';
comment on column genesis2.trade_record.is_billed IS 'Value indicates if trade is billed, not billed or prepared for recalculation. ''Y'', ''N'', ''R'', ''D''. ''E'' - TCCE error. ''M''- Manual trade. Should be renamed to Billing_status to avoid misunderstanding with boolean type';
comment on column genesis2.trade_record.street_exec_inst IS 'based on EXEC_INST of the street level order';
comment on column genesis2.trade_record.street_order_price IS 'arrives from client_order.price of street order level';
comment on column genesis2.trade_record.strategy_decision_reason_code IS 'Routing reason. Based on strategy_decision_reason_code of the strret order. Parent order field is used in case street order value is null';
comment on column genesis2.trade_record.compliance_id IS 'Based on compliance_id of the parent level order.';
comment on column genesis2.trade_record.floor_broker_id IS 'Tag 143 of the customer order. Assigned value used to identify specific message destination''s location (i.e. geographic location and/or desk, trader)';
comment on column genesis2.trade_record.auction_id IS 'AUCTION_ID based on execution.AUCTION_ID of the parent order level';
comment on column genesis2.trade_record.multileg_order_id IS 'The vaule is based on CO_MULTILEG_ORDER_ID of the parent order';
comment on column genesis2.trade_record.internal_component_type IS 'INTERNAL_COMPONENT_TYPE of the parent execution level';
comment on column genesis2.trade_record.street_trade_fix_message_id IS 'Fix message_id of the street level trade';
comment on column genesis2.trade_record.pt_basket_id IS 'Basket_id of the parent order. Base on 9047 tag of parent order fix message';
comment on column genesis2.trade_record.blaze_account_alias IS 'Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only';
comment on column genesis2.trade_record.street_client_sender_compid IS 'Street_Client_Sender_CompID base on 5049 tag of stree trade fix message';
comment on column genesis2.trade_record.street_account_name IS 'street_account_name based on Tag 1 of of street trade fix message';
comment on column genesis2.trade_record.street_exec_broker IS 'street_exec_broker for Options only base on get_street_exec_broker function';
comment on column genesis2.trade_record.branch_sequence_number IS 'Based on 9861 tag of parent execution ';
comment on column genesis2.trade_record.trade_text IS 'Based on 58 tag of parent execution ';
comment on column genesis2.trade_record.frequent_trader_id IS 'CBOE-specific field "FrequentTraderID" based on tag 21097 of the street trade message';
comment on column genesis2.trade_record.time_in_force IS 'Based on parent level time_in_force from client_order';
comment on column genesis2.trade_record.int_liq_source_type IS 'INTernal LIQuidity SOURCE TYOE.  ''A'' - ATS, ''C'' - Consolidator';
comment on column genesis2.trade_record.allocation_avg_price IS 'Avarenge price of allocated trades';
comment on column genesis2.trade_record.account_nickname IS 'account_nickname. should be populated from the dash360 as free text during allocation';
comment on column genesis2.trade_record.clearing_account_id IS 'FK to clearing_account';
comment on column genesis2.trade_record.market_participant_id IS 'Tag 115 of the parent order. Based on client_order.MPID field of the parent order level';
comment on column genesis2.trade_record.alternative_compliance_id IS 'Tag 6376 of the parent order. Based on client_order.ALTERNATIVE_COMPLIANCE_ID field of the parent order level';
comment on column genesis2.trade_record.street_trade_record_time IS 'Exec time from street level EXECUTION';
-- Table Triggers
create or replace function genesis2.trade_record_del_protection_fnc()
    returns trigger
    language plpgsql
as
$function$
declare
begin
    raise exception ' You are not allowed to delete rows from the % table', tg_table_name;
    return null;
end;
$function$
;


CREATE TABLE public.etl_rejects (
	etl_rejects bigserial NOT NULL,
	etl_process_name varchar(100) NULL,
	constraint_name varchar(100) NULL,
	error_mesage varchar(4000) NULL,
	load_batch_id int4 NULL,
	pgdb_create_time timestamp null DEFAULT clock_timestamp(),
	CONSTRAINT pk_etl_rejects2 PRIMARY KEY (etl_rejects)
);


CREATE FUNCTION public.f_insert_etl_reject(in_etl_process_name character varying,
                                                      in_constraint_name character varying,
                                                      in_err_message character varying,
                                                      in_load_batch_id integer DEFAULT NULL::integer)
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
declare
-- l_mail_list varchar;
    --l_mail_res int;
begin

    insert into public.etl_rejects (etl_process_name, constraint_name, error_mesage, load_batch_id)
    values (in_etl_process_name, in_constraint_name, in_err_message, in_load_batch_id);

    return null; /* MUST!!!!! return null. Because it is used in the ON CONFLIC statements */

end;
$function$
;


CREATE OR REPLACE FUNCTION genesis2.trade_record_partition_trigger()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$function$
DECLARE
    table_master varchar(255) := 'trade_record';
    start_date   varchar(255) := '';
    table_part   varchar(255) := '';
    end_date     varchar(255) := '';
    scheme       varchar(255) := 'dm_partitions.';
    check_prefix varchar(255) := 'chk_';
    a            varchar(255) := '';
BEGIN
    table_part := scheme || table_master || '_' || substring(NEW.DATE_ID::TEXT, 1, 6);
    start_date := substring(NEW.DATE_ID::TEXT, 1, 6);
    end_date :=
            substring(to_char(to_date(substring(NEW.DATE_ID::TEXT, 1, 6), 'YYYYMM') + interval '1 month', 'YYYYMM'), 1,
                      6);
    a := table_master || '_' || substring(NEW.DATE_ID::TEXT, 1, 6);

    PERFORM 1
    FROM pg_class
    WHERE relname = a
    limit 1;

    IF NOT FOUND
    THEN
        EXECUTE 'CREATE TABLE ' || scheme || table_master || '_' || start_date || '
	(
	  CONSTRAINT trade_record_account_id_fkey FOREIGN KEY (account_id)
		REFERENCES dwh.d_account (account_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	  CONSTRAINT trade_record_exchange_id_fkey FOREIGN KEY (exchange_id)
		REFERENCES dwh.d_exchange (exchange_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	  CONSTRAINT trade_record_instrument_id_fkey FOREIGN KEY (instrument_id)
		REFERENCES dwh.instrument (instrument_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	  CONSTRAINT ' || check_prefix || table_master || '_' || start_date || ' CHECK( date_id >= ' || start_date ||
                '01 and date_id < ' || end_date || '01 )
	)
	INHERITS ( genesis2.' || table_master || ' )
	WITH (
	    OIDS=FALSE
	);';


        EXECUTE 'ALTER TABLE ' || table_part || ' OWNER TO dwh;';

        EXECUTE 'GRANT ALL ON TABLE ' || table_part || ' TO dwh;';

        -- EXECUTE 'GRANT SELECT ON TABLE ' || table_part || ' TO ben_locke;';

        EXECUTE ' CREATE UNIQUE INDEX ' || a || '_id_idx ON ' || table_part || ' USING btree (trade_record_id);';

--	EXECUTE ' CREATE UNIQUE INDEX ' || a || '_nk ON ' || table_part || ' USING btree ( date_id, exch_exec_id, client_order_id, (coalesce(orig_trade_record_id,1)) );';
        EXECUTE ' CREATE UNIQUE INDEX ' || a || '_nk ON ' || table_part ||
                ' USING btree ( date_id, COALESCE(exch_exec_id, exec_id::varchar), client_order_id, (case when orig_trade_record_id is not null then trade_record_id else 1::integer end) );';

        EXECUTE ' CREATE INDEX ' || a || '_date_id_idx ON ' || table_part || ' USING btree (date_id);';


        EXECUTE ' CREATE INDEX ' || a || '_exec_id_idx ON ' || table_part || ' USING btree (exec_id);';


        EXECUTE ' CREATE INDEX ' || a || '_secondary_order_idx ON ' || table_part ||
                '  USING btree (secondary_order_id COLLATE pg_catalog."default");';
        EXECUTE ' CREATE INDEX ' || a || '_secondary_exch_exec_idx ON ' || table_part ||
                '  USING btree (date_id, secondary_exch_exec_id);';


        EXECUTE ' CREATE INDEX ' || a || '_order_id_date_id_idx ON ' || table_part ||
                ' USING btree (order_id, date_id);';
        EXECUTE ' CREATE INDEX ' || a || 'street_order_id_date_id_idx ON ' || table_part ||
                ' USING btree (street_order_id, date_id);';
        EXECUTE ' CREATE INDEX  if not exists ' || a || '_etl_idx on ' || table_part ||
                ' USING btree (load_batch_id ASC NULLS LAST);';


    END IF;

    EXECUTE 'INSERT INTO ' || table_part || ' SELECT ( (' || QUOTE_LITERAL(NEW) || ')::genesis2.' || TG_TABLE_NAME || ' ).*
             /* on conflict  (date_id, exch_exec_id, client_order_id, coalesce(orig_trade_record_id,1)) do update */
            on conflict  (date_id, COALESCE(exch_exec_id, exec_id::varchar), client_order_id, (case when orig_trade_record_id is not null then trade_record_id else 1::integer end) ) do update
          set 	date_id	= coalesce(public.f_insert_etl_reject(''trade_record_inc''::varchar, ''' || a || '_nk'', ''(date_id = ''||EXCLUDED.date_id||'' , exch_exec_id=''||EXCLUDED.exch_exec_id||'', client_order_id = ''||EXCLUDED.client_order_id||'')''::varchar),
                                   EXCLUDED.date_id)';

    RETURN NULL;
END;
$function$
;



create trigger trade_record_del_protection_trg
    before
        delete
    on
        genesis2.trade_record
    for each statement
execute function genesis2.trade_record_del_protection_fnc();


create trigger trade_record_partition_trigger
    before
        insert
    on
        genesis2.trade_record
    for each row
execute function genesis2.trade_record_partition_trigger();

-- DROP TABLE public.etl_subscriptions;

CREATE TABLE public.etl_subscriptions (
	subscription_id bigserial NOT NULL,
	subscription_name varchar(255) NOT NULL,
	source_table_name varchar(255) NOT NULL,
	load_batch_id int8 NOT NULL,
	is_processed bool DEFAULT false NULL,
	subscribe_time timestamp(1) DEFAULT clock_timestamp() NOT NULL,
	process_time timestamp(1) NULL,
	date_id int4 NULL
);
CREATE INDEX etl_subscriptions_load_batch_id_idx ON public.etl_subscriptions USING btree (load_batch_id, subscription_name, source_table_name);
CREATE UNIQUE INDEX etl_subscriptions_pk ON public.etl_subscriptions USING btree (subscription_id);
CREATE INDEX etl_subscriptions_subscribe_idx ON public.etl_subscriptions USING btree (subscription_name, source_table_name, is_processed, load_batch_id, date_id);
CREATE INDEX etl_subscriptions_subscribe_time_idx_active ON public.etl_subscriptions USING btree (subscribe_time, is_processed);


CREATE  FUNCTION staging.get_trade_liquidity_indicator(in_str text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
declare
    f_length int := length(in_str);
    f_ret    text;
begin
    if f_length = 29 and substr(in_str, 7, 1) = 'R' and substr(in_str, 16, 6) = '000000' then
        f_ret = 'R';
    elsif f_length = 29 and substr(in_str, 7, 1) = 'R' then
        f_ret = 'X';
    elsif f_length = 29 then
        f_ret = substr(in_str, 7, 1);
    elsif f_length = 14 then
        f_ret = substr(in_str, 4, 1);
    elsif in_str like '%/%' then
        f_ret = (regexp_split_to_array(in_str, '/'))[1];
    else
        f_ret = in_str;
    end if;
    return f_ret;
end ;
$function$
;


-- DROP FUNCTION genesis2.f_get_street_account_name(int8, int4, varchar, int2, bpchar);

CREATE FUNCTION genesis2.f_get_street_account_name(in_street_order_fix_message_id bigint, in_date_id integer,
                                              in_exchange_id character varying, in_mleg_type smallint,
                                              in_is_cross character)
    RETURNS character varying
    LANGUAGE plpgsql
 COST 10
AS $function$DECLARE
   l_fix_message_id bigint;
   l_exchange_id varchar;
   l_result varchar;
   l_rep_group_count smallint;
   l_shor_json_text text;
   l_json_arr jsonb[];
   l_str jsonb;
   l_mleg_type smallint;
   i int;
   l_rep_tag text;
   l_rep_start_tag text;

BEGIN

--select street_order_fix_message_id, exchange_id, street_client_order_id, multileg_reporting_type::smallint
l_fix_message_id:=in_street_order_fix_message_id;
l_exchange_id:=in_exchange_id;
l_mleg_type:=in_mleg_type;

if l_fix_message_id is null then
    return null;
end if;
 if in_is_cross ='N'
  then select (jsn.fix_message->>'1')::text
       into l_result
       from fix_capture.fix_message_json jsn
       where jsn.fix_message_id = l_fix_message_id
       and jsn.date_id = in_date_id
      limit 1;
       return l_result;
  else
--  raise INFO '%: fix_messgae_id = %, exchange_id = %', clock_timestamp(), l_fix_message_id, l_exchange_id;

 if l_exchange_id = 'MIAX' and  l_mleg_type=2
    then l_rep_tag:='73';

   elsif l_exchange_id in ('PHLX', 'NQBXO')
    then l_rep_tag:='73';

   elsif l_exchange_id in ('BOX')
    then l_rep_tag:='7904';

   elsif l_exchange_id in ('XCHI')
    then l_rep_tag:='10552';

   else l_rep_tag:='552';
 end if;


-- raise INFO '%: l_rep_tag = %', clock_timestamp(), l_rep_tag;

 select (fix_message->>l_rep_tag)::smallint, right(fix_message::text, strpos(fix_message::text, '"'||l_rep_tag||'":')*(-1) -length(l_rep_tag)-6)
 into l_rep_group_count, l_shor_json_text
 from fix_capture.fix_message_json
 where fix_message_id = l_fix_message_id
 and date_id = in_date_id;

--  raise INFO '%: l_rep_group_count = %', clock_timestamp(), l_rep_group_count;

if coalesce(l_rep_group_count,0) > 0
 then
--	raise INFO '%: l_shor_json_text = %', clock_timestamp(), l_shor_json_text;

	l_rep_start_tag:=replace(left(l_shor_json_text, strpos(l_shor_json_text, ':'::char)-1 ), '"', '');
--	 raise INFO '%: l_rep_start_tag = %', clock_timestamp(), l_rep_start_tag;


	l_str:=('[{'||replace(l_shor_json_text,',"'||l_rep_start_tag||'"', '},{"'||l_rep_start_tag||'"')||']')::jsonb;
--	 raise INFO '%: l_shor_json_text = %', clock_timestamp(), l_shor_json_text;


--	l_str:=l_shor_json_text::jsonb;

	 select str_acc_name
	  into l_result
	   from (select msg->>'10009' as orig_cont, msg->>'1'::text as str_acc_name
	         from jsonb_array_elements(l_str) msg ) dt
	   where orig_cont = 'O'
	   limit 1;
	  RETURN l_result;
	else -- There is no reperating groups part
	 return null;
--	 raise INFO '%: l_rep_group_count = %', clock_timestamp(), 0;
--
--	select  fix_message->>'1'
--	 into l_result
--	 from staging.fix_message_json
--    where fix_message_id = l_fix_message_id
--    and date_id = in_date_id;
--    return l_result;

 end if;
end if;

END;

$function$
;

CREATE TABLE public.log_mail_groups (
	mail_group_name varchar(25) NULL,
	email_list varchar(255) NULL,
	mail_group_id serial4 NOT NULL,
	CONSTRAINT "mail_groups_PK" PRIMARY KEY (mail_group_id)
);
-- DROP FUNCTION public.load_error_log(varchar, bpchar, varchar, int8, varchar);

CREATE OR REPLACE FUNCTION public.load_error_log(in_table_name character varying, in_operation character,
                                                 in_err_message character varying, in_load_timing_id bigint,
                                                 in_mail_group character varying DEFAULT 'DEV_ERROR'::character varying)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
declare
    l_mail_list   varchar;
    l_server_addr varchar;
    --l_mail_res int;
    l_program_str varchar;
    l_str         varchar;
begin

    perform public.dblink_connect_u('err_pragma', 'dbname=big_data');
    perform public.dblink_exec('err_pragma', 'insert into public.error_log (table_name, operation, err_message, load_timing_id, err_time)
                                  values (''' || in_table_name || ''', ''' || in_operation || ''', ''' ||
                                             in_err_message || ''', ''' || in_load_timing_id || ''', now());', false);
    perform public.dblink_exec('err_pragma', 'commit;');
    perform public.dblink_disconnect('err_pragma');

    select email_list
    into l_mail_list
    from public.log_mail_groups
    where mail_group_name = in_mail_group
    LIMIT 1;
    raise info '%', l_mail_list;

    l_server_addr := inet_server_addr()::varchar;
    raise info '%', l_server_addr;

--    l_program_str:= 'mail -s "PostgreSQL ERROR !!! ('||l_server_addr||') PROD(genesis2)" '||l_mail_list;
    l_program_str := 'mail -s "PostgreSQL ERROR !!!  PROD(big_data)" ' || l_mail_list;
    raise info '%', l_program_str;

    l_str := format('copy ( select %L ) to program %L  with ( format text)', in_table_name || ': ' || in_err_message,
                    l_program_str);

    raise WARNING '%', l_str;
    execute l_str;
exception
    when others then
        if (SELECT 'err_pragma' = ANY (public.dblink_get_connections()))
        then
            perform public.dblink_disconnect('err_pragma');
        end if;

end;
$function$
;


CREATE TABLE if not exists staging.psql_execution (
	"operation$" bpchar(2) NULL,
	"cscn$" numeric NULL,
	"commit_timestamp$" timestamp(0) NULL,
	"xidusn$" numeric NULL,
	"xidslt$" numeric NULL,
	"xidseq$" numeric NULL,
	"ddldesc$" text NULL,
	"ddloper$" numeric NULL,
	"ddlpdobjn$" numeric NULL,
	"rsid$" numeric NULL,
	"target_colmap$" bytea NULL,
	exec_id int8 NULL,
	is_busted bpchar(1) NULL
);

CREATE SEQUENCE genesis2.load_batch_load_batch_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;


CREATE TABLE if not exists genesis2.etl_load_batch
(
    load_batch_id         int4 DEFAULT nextval('genesis2.load_batch_load_batch_id_seq'::regclass) NOT NULL,
    file_name             varchar(255)                                                       NULL,
    file_provider         varchar                                                            NULL,
    process_date_time     timestamp                                                          NULL,
    status                varchar(2)                                                         NULL,
    rows_processed        int4                                                               NULL,
    ftp_file_path         varchar(255)                                                       NULL,
    process_end_date_time timestamp                                                          NULL,
    CONSTRAINT load_batch_pk PRIMARY KEY (load_batch_id)
);
CREATE INDEX etl_load_batch_file_name_idx ON genesis2.etl_load_batch USING btree (file_name, status, process_end_date_time, load_batch_id);


CREATE TABLE staging.trade_record_missed_lp (
	trade_record_time timestamp NULL,
	db_create_time timestamp NULL DEFAULT now(),
	date_id int4 NOT NULL,
	is_busted bpchar(1) NULL,
	orig_trade_record_id int8 NULL,
	trade_record_trans_type bpchar(1) NULL,
	trade_record_reason bpchar(1) NULL,
	subsystem_id varchar(20) NULL,
	user_id int4 NULL,
	account_id int4 NULL,
	client_order_id varchar(256) NULL,
	instrument_id int4 NULL,
	side bpchar(1) NULL,
	open_close bpchar(1) NULL,
	fix_connection_id int2 NULL,
	exec_id int8 NULL,
	exchange_id varchar(20) NULL,
	trade_liquidity_indicator varchar(256) NULL,
	secondary_order_id varchar(256) NULL,
	exch_exec_id varchar(128) NULL,
	secondary_exch_exec_id varchar(128) NULL,
	last_mkt varchar(20) NULL,
	last_qty int4 NULL,
	last_px numeric NULL,
	ex_destination varchar(20) NULL,
	sub_strategy varchar(128) NULL,
	street_order_id int4 NULL,
	order_id int4 NULL,
	street_order_qty int4 NULL,
	order_qty int4 NULL,
	multileg_reporting_type bpchar(1) NULL,
	is_largest_leg bpchar(1) NULL,
	street_max_floor int4 NULL,
	exec_broker varchar(32) NULL,
	cmta varchar(5) NULL,
	street_time_in_force bpchar(1) NULL,
	street_order_type bpchar(1) NULL,
	opt_customer_firm bpchar(1) NULL,
	street_mpid varchar(18) NULL,
	is_cross_order bpchar(1) NULL,
	street_is_cross_order bpchar(1) NULL,
	street_cross_type bpchar(1) NULL,
	cross_is_originator bpchar(1) NULL,
	street_cross_is_originator bpchar(1) NULL,
	contra_account bpchar(1) NULL,
	contra_broker varchar(256) NULL,
	trade_exec_broker varchar(32) NULL,
	order_fix_message_id int8 NULL,
	trade_fix_message_id int8 NULL,
	street_order_fix_message_id int8 NULL,
	client_id varchar(255) NULL,
	street_transaction_id int8 NULL,
	transaction_id int8 NULL,
	order_price numeric(12, 4) NULL,
	order_process_time timestamp NULL,
	clearing_account_number varchar(25) NULL,
	sub_account varchar(50) NULL,
	remarks varchar(100) NULL,
	optional_data varchar(25) NULL,
	street_client_order_id varchar(256) NULL,
	fix_comp_id varchar(30) NULL,
	leaves_qty int4 NULL,
	is_billed bpchar(1) DEFAULT 'N'::bpchar NULL,
	street_exec_inst varchar(128) NULL,
	fee_sensitivity int2 NULL,
	street_order_price numeric(12, 4) NULL,
	leg_ref_id int2 NULL,
	load_batch_id int4 NULL,
	strategy_decision_reason_code int2 NULL,
	compliance_id varchar(256) NULL,
	floor_broker_id varchar(255) NULL,
	order_id_guid varchar(256) NULL,
	is_parent bpchar(1) NULL,
	symbol varchar(256) NULL,
	symbol_sfx varchar(256) NULL,
	strike_price numeric(12, 4) NULL,
	put_or_call varchar(256) NULL,
	maturity_year int2 NULL,
	maturity_month int2 NULL,
	maturity_day int2 NULL,
	security_type varchar(256) NULL,
	child_orders int4 NULL,
	handling_id int4 NULL,
	secondary_order_id2 varchar(256) NULL,
	ex_destination_for_order_guid varchar(128) NULL,
	sub_strategy_for_ordg varchar(128) NULL,
	display_instrument_id varchar(100) NULL,
	trade_record_id int8 NULL,
	instrument_type_id varchar(1) NULL,
	activ_symbol varchar(255) NULL,
	mapping_logic int2 NULL,
	commision_rate_unit numeric(16, 6) NULL, -- Commission rate per unit for balze originated trades. Based on [LiquidPoint_EDW].[dbo].[AcctComm] field
	blaze_account_alias varchar(255) NULL,
	is_sor_routed bool NULL, -- true if order was routd to sor, false - not routed or manula fill
	report_id varchar NULL,
	is_company_name_changed int4 NULL,
	companyname varchar NULL,
	generation int4 NULL,
	mx_gen int4 NULL,
	num_firms int4 NULL,
	"orderId" varchar NULL,
	"parentOrderId" varchar NULL,
	is_flex_order bool NULL,
	last_px_temp numeric(16, 8) NULL
);
CREATE INDEX trade_record_missed_lp_date_id_idx ON staging.trade_record_missed_lp USING btree (date_id, trade_record_id);
CREATE UNIQUE INDEX trade_record_missed_lp_exec_id_idx ON staging.trade_record_missed_lp USING btree (exec_id, date_id);

-- Column comments

COMMENT ON COLUMN staging.trade_record_missed_lp.commision_rate_unit IS 'Commission rate per unit for balze originated trades. Based on [LiquidPoint_EDW].[dbo].[AcctComm] field';
COMMENT ON COLUMN staging.trade_record_missed_lp.is_sor_routed IS 'true if order was routd to sor, false - not routed or manula fill';

create table genesis2.fact_last_load_id
(
    value_name text
        constraint fact_last_load_id_table_name_pk primary key,
    last_id    int8
);
comment on table genesis2.fact_last_load_id is 'the table the last values for etl-s can be stored in';
comment on column genesis2.fact_last_load_id.value_name is 'the unique value we use the table for';
comment on column genesis2.fact_last_load_id.last_id is 'the value';

CREATE FUNCTION genesis2.load_trade_record_inc(in_exec_id numeric DEFAULT NULL::numeric,
                                               in_orig_trade_record_id bigint DEFAULT NULL::bigint,
                                               in_trade_record_reason character DEFAULT NULL::character(1))
    RETURNS integer
    LANGUAGE plpgsql
    SET application_name TO 'ETL_FAST: TRADE_RECORD incremental'
AS
$function$
-- OS: 20240429 https://dashfinancial.atlassian.net/browse/DS-8134 init

DECLARE
   l_max_exec_id bigint;
   l_arch_max_exec_id int;
   l_ret	int;
   some_var     varchar;
   l_step_id	int;
   l_load_id	int;
   l_foreign_max_exec_id bigint;
   l_arch_foreign_max_exec_id bigint;
   l_status_message varchar;
   l_scr record;
   l_busted_jsn jsonb;
   l_cnt int;
   l_date_id int;
   l_away_load_batch int;

BEGIN

if in_exec_id is null
 then
	select nextval('load_timing_seq') into l_load_id;
	l_step_id:=1;
	--l_foreign_max_exec_id:=0;

	l_status_message:='Trade_Record_inc STARTED===';
	select public.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
	into l_step_id;

   l_status_message:='l_max_exec_id';
	select COALESCE(max(exec_id),0)
	into l_max_exec_id from genesis2.trade_record;

	select load_log(l_load_id, l_step_id, 'l_max_exec_id = '||l_max_exec_id, 0 , 'S')
	into l_step_id;

--	RAISE INFO 'MAX exec_id is    %', l_max_exec_id;


	l_status_message:='l_foreign_max_exec_id = ';
--  SELECT COALESCE(max(exec_id),0) FROM staging.psql_execution where OPERATION$ <> 'D' into l_foreign_max_exec_id;
	SELECT COALESCE(max(exec_id),0) FROM dwh.execution where exec_id>=l_max_exec_id into l_foreign_max_exec_id;
-- DISASTER
-- In case of CDC not return data then just uncomment next line
--l_foreign_max_exec_id:=999999999999;

select load_log(l_load_id, l_step_id, l_status_message||l_foreign_max_exec_id, 0, 'S')
	into l_step_id;

-- SO removed
/*	perform public.oracle_close_connections();
	perform pg_sleep(3);

	select load_log(l_load_id, l_step_id, 'Oracle connection closed', 0, 'S')
	into l_step_id;
*/

-- SO removed
/* select dimension_etl(true) into some_var;

   l_status_message:='dimension_etl';
	select genesis2.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
	into l_step_id;
perform public.oracle_close_connections();

--	select load_trade_facts_etl() into some_var;
--
--   l_status_message:='load_trade_facts_etl';
--	select genesis2.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
--	into l_step_id;
*/

    for l_scr in (select load_batch_id, subscription_id
                  from public.etl_subscriptions
                  where subscription_name = 'missed_fix_trade'
                    and source_table_name = 'orcl_execution'
                    and not is_processed)
        loop
            l_status_message := 'FIX TRADE GAP processing: ' || l_scr.load_batch_id;

            select public.load_log(l_load_id, l_step_id, l_status_message, 1, 'O')
            into l_step_id;

            perform genesis2.load_trade_record_inc(l_scr.load_batch_id);

            update public.etl_subscriptions
            set is_processed = true,
                process_time = clock_timestamp()
            where subscription_id = l_scr.subscription_id;

        end loop;

--   l_status_message:='============FIX TRADE GAP =======';

 else 	 l_foreign_max_exec_id:=in_exec_id ;
	 l_max_exec_id := in_exec_id -1;
end if;


IF l_foreign_max_exec_id> l_max_exec_id /* 1=1*/ THEN

	insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, clearing_account_number, sub_account,  multileg_order_id,
		    INTERNAL_COMPONENT_TYPE, street_trade_fix_message_id, pt_basket_id, pt_order_id, Street_Client_Sender_CompID,
		    street_account_name, street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, time_in_force, int_liq_source_type,
		    market_participant_id, ALTERNATIVE_COMPLIANCE_ID, street_trade_record_time, street_order_process_time,leg_ref_id, blaze_account_alias


		    )
	select TRADE_RECORD_TIME
	, now()
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, coalesce(in_trade_record_reason,TRADE_RECORD_REASON::char ) as TRADE_RECORD_REASON
	, COALESCE(SUB_SYSTEM_ID,'PG_DASH') as SUB_SYSTEM_ID
	, -1 as USER_ID  -- SO hotfix
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, v.INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, staging.get_trade_liquidity_indicator(TRADE_LIQUIDITY_INDICATOR) as TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
-- 	, SUB_STRATEGY
    , target_strategy_name	-- SO hotfix
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY

	, MULTILEG_REPORTING_TYPE
	, 'Y' as IS_LARGEST_LEG -- SO hotfix
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, left(CMTA,3)
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
	, clearing_account
    , left(sub_account,30) as sub_account
    ,  multileg_order_id
    , INTERNAL_COMPONENT_TYPE
    , str_trade_fix_message_id
    , pt_basket_id
    , pt_order_id
    , str_cls_comp_ID
    , coalesce(street_account_name, dwh.f_get_street_account_name(street_order_fix_message_id, date_id::int, exchange_id , multileg_reporting_type::smallint, street_is_cross_order::char))
    , case i.instrument_type_id
        when 'O' then dwh.get_street_exec_broker(v.street_order_fix_message_id, v.date_id::int, v.exchange_id, v.street_client_order_id, v.multileg_reporting_type::smallint, v.street_is_cross_order::char)
        else null
      end as street_exec_broker
    , trade_text
    , branch_seq_num
    , left (frequent_trader_id,6) as frequent_trader_id
    , time_in_force
    , is_ats_or_cons
    , mpid
    , ALTERNATIVE_COMPLIANCE_ID
    , street_trade_record_time
    , street_order_process_time
    , co_client_leg_ref_id as leg_ref_id
    --, v.blaze_account_alias
	, case when v.is_cross_order='Y'
             then  public.get_message_tag_string_cross_multileg(v.order_fix_message_id, 10445, v.date_id::int,v.client_order_id, NULL, v.co_client_leg_ref_id, v.is_cross_order::boolean)
             else v.blaze_account_alias
      end
from genesis2.trade_record_v_historical v
	left join dwh.d_instrument i on v.instrument_id =i.instrument_id
--	where exec_id between l_max_exec_id+1 and l_max_exec_id+100001;
	where exec_id between l_max_exec_id+1 and l_foreign_max_exec_id /*-50*/;

select load_log(l_load_id, l_step_id, 'trade_record l_foreign_max_exec_id='||l_foreign_max_exec_id, 0, 'I')
into l_step_id;



ELSE
  select load_log(l_load_id, l_step_id,'Nothing to insert ', 0, 'E')
        into l_step_id;
    RAISE notice 'Nothing to insert';

-- SO removed
  /*
if 1=2 and current_time < '06:30'::time
 then
    l_status_message:='l_arch_max_exec_id';
	select COALESCE(max(exec_id),0)
	into l_arch_max_exec_id from genesis2.trade_record
	where date_id < 20160101;

	select load_log(l_load_id, l_step_id, 'l_arch_max_exec_id = '||l_arch_max_exec_id,0, 'S')
	into l_step_id;

	RAISE INFO 'ARCH MAX exec_id is    %', l_max_exec_id;


/*	l_status_message:='l_arch_foreign_max_exec_id = ';
	--SELECT COALESCE(max(exec_id),0) FROM staging.psql_execution into l_foreign_max_exec_id;
	SELECT  COALESCE(max(exec_id),0) into l_arch_foreign_max_exec_id
    FROM staging.trade_record_varch  ;*/
	insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, multileg_order_id, int_liq_source_type

		    )
	select TRADE_RECORD_TIME
	, now()
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, TRADE_RECORD_REASON
	, SUB_SYSTEM_ID
	, USER_ID
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
	, SUB_STRATEGY
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY

	, MULTILEG_REPORTING_TYPE
	, IS_LARGEST_LEG
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, CMTA
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
    , multileg_order_id
    , is_ats_or_cons


	from staging.trade_record_varch
	/*where exec_id between l_max_exec_id+1 and l_max_exec_id+100001;*/
	where exec_id between l_arch_max_exec_id+1 and l_arch_max_exec_id+550000 /*-50*/;

	select load_log(l_load_id, l_step_id, 'trade_record arch insert', 0, 'I')
	into l_step_id;

 end if;
*/
END IF;

select load_log(l_load_id, l_step_id, 'AFTER IF', 0, 'I')
into l_step_id;
/* where exec_id > l_max_exec_id */

-- GET DIAGNOSTICS does not work on partitioned tables since version 8.4 at lest !!!!
 --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;



 /*select count(1) into l_ret
 from trade_record
 where date_id = to_number(to_char(current_date, 'YYYYMMDD'),'99999999');*/

 if in_exec_id is null
  then
   /* replicate busted trades without recalculation.
     1. Must be inside in_exec_id is null
     2. MUST be before recalculated */


 /*update trade_record tr
 set is_busted = 'Y'
 where tr.exec_id in (select exec_id from staging.psql_execution psq where psq.is_busted='Y')
   and tr.is_busted='N';*/

 /*======================*/

 -- DISASTER
  select load_log(l_load_id, l_step_id, 'INSIDE in_exec_id is null', 0, 'I')
into l_step_id;

  if (select count(1) from staging.psql_execution psq where psq.is_busted='Y' and OPERATION$ <> 'D')>0
   then
     select load_log(l_load_id, l_step_id, 'is_busted=Y', 0, 'I')
     into l_step_id;

	WITH upd AS (update genesis2.trade_record tr
			 set is_busted = 'Y'
			 where tr.exec_id in (select exec_id from staging.psql_execution psq where psq.is_busted='Y' and OPERATION$ <> 'D')
			   and tr.is_busted='N'
			   and date_id > 20210701
       RETURNING trade_record_id, tr.date_id)
    insert into public.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id)
	Select 'big_data.flat_trade_record', 'TRADE_RECORD.BUSTED_TRADES', trade_record_id, date_id FROM upd;


  	GET DIAGNOSTICS l_ret = ROW_COUNT;

	select load_log(l_load_id, l_step_id, 'Update to BUSTED ', l_ret, 'U')
	into l_step_id;
	end if;


 /*        RECALCULATED TRADES */

  /* =======================================*/

--     select load_log(l_load_id, l_step_id, 'Before RECALCULATED TRADES', 0, 'I')
--     into l_step_id;
--
-- ============ We do not use billing on the Oracle side anymore
--  -- DISASTER
--  for l_scr in (select TRADE_RECORD_RECALC_ID, EXEC_ID from staging.PSQL_TRADE_RECORD_RECALC where is_processed=0) loop
--
--   with upd as (update trade_record
--			set is_busted='Y'
--			where exec_id = l_scr.exec_id
--			and is_busted='N'
--			and coalesce (trade_record_reason , 'O') <> 'P'
--		      RETURNING trade_record_id, date_id)
--        select array_to_json(array(select row(trade_record_id, date_id)  FROM upd)) into l_busted_jsn;
--
--  	GET DIAGNOSTICS l_ret = ROW_COUNT;
--
--	if l_busted_jsn is not null and jsonb_array_length(l_busted_jsn)>0
--      then
--        perform load_trade_record_inc(l_scr.exec_id, (l_busted_jsn->0->>'f1')::int, 'R');
--
--		update staging.PSQL_TRADE_RECORD_RECALC
--		set process_time = statement_timestamp(),
--		    is_processed=1
--		where TRADE_RECORD_RECALC_id = l_scr.TRADE_RECORD_RECALC_id;
--
--	    insert into genesis2.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id )
--		Select 'big_data.flat_trade_record', 'TRADE_RECORD.BUSTED_TRADES', (tr_id->'f1')::int, (tr_id->>'f2')::int
--	   from jsonb_array_elements (l_busted_jsn) tr_id;
--	end if;
--
--end loop;

end if;

/* =============================================================================================================== */
/* ========================================= AWAY TRADE=========================================================== */
/* =============================================================================================================== */

if in_exec_id is null
 then
	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES processing started', 0, 'I')
	into l_step_id;

   l_date_id:=to_char(current_date ,'YYYYMMDD')::int ;

/* We take into account last but one completed Missed trade job
 * Missed job has delay 12 minutes to be sure we are not ahead Oracle traffic
 * We can't use last completed ID bacuse aftre completion we have matching process. It update all load_batchIds to -1 to avoid picking up trade too early
 * */

  select max(load_batch_id)
	  into l_away_load_batch
	from genesis2.etl_load_batch
	where file_name ='Load_Missed_Trades_MSSQL'
	and process_end_date_time < now()
	and status ='C';

  INSERT INTO genesis2.trade_record
	(trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,trade_record_reason
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id
			,load_batch_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias )

select trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,'A' as trade_record_reason
--			,subsystem_id
			,case when (generation>0  or (is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ))
			            and subsystem_id = 'LPEDW'
				  then 'LPEDW_DUPE'
			 else subsystem_id
			 end as subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,e.exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,e.last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,nullif(left(cmta,3), '') as cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,nullif(street_client_order_id,'') as street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id::varchar
			,l_load_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias
	from staging.trade_record_missed_lp trml
	join dwh.d_exchange e on  e.exchange_id=trml.exchange_id
					and e.is_active
					and e.exchange_id=e.real_exchange_id
    where trade_record_id is null
    and instrument_id is not null
--    and subsystem_id not in ('OMS_EDW')
    and (  (subsystem_id not in ('OMS_EDW') and  generation = 0 and not is_sor_routed )/* ordinar case non sor routed trades */
		    or (subsystem_id not in ('OMS_EDW') and  generation = 0 and is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* routed to sor with company name changes*/
		    or (subsystem_id not in ('OMS_EDW') and  generation>0 and is_company_name_changed =1 and not is_sor_routed and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* non-routed to SOR company name chaned in firther generation*/
		    or (subsystem_id not in ('OMS_EDW') and generation>0 and is_company_name_changed =1 and is_sor_routed and mx_gen>generation and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' )
		    or (subsystem_id in ('OMS_EDW') and generation=0 and secondary_exch_exec_id = 'Manual Report' and not is_sor_routed and trml.instrument_type_id not in ('E') )
		)
    and date_id = l_date_id
    and trml.load_batch_id <> -1
    and trml.load_batch_id < l_away_load_batch
    and last_qty<=order_qty
    and trml.is_busted ='N'
    --and not trml.is_flex_order
    ;

	update staging.trade_record_missed_lp trml
	set trade_record_id = tr.trade_record_id ,
		mapping_logic = 20
	from genesis2.trade_record tr
	where tr.date_id = l_date_id
	 and tr.load_batch_id = l_load_id
	 and tr.subsystem_id in ('LPEDW', 'LPEDW_DUPE', 'OMS_EDW')
	 and trml.trade_record_id is null
	 and trml.date_id =tr.date_id
	 and trml.exec_id = tr.exec_id
	 and trml.load_batch_id <> -1
	 and trml.load_batch_id < l_away_load_batch;


   	GET DIAGNOSTICS l_cnt = ROW_COUNT;


--	select count(1)
--   	from genesis2.trade_record trml
--    where date_id = l_date_id
--    and load_batch_id=l_load_id
--    into l_cnt;

	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES INSERT INSERTED load_batch_id='||l_load_id, l_cnt, 'I')
	into l_step_id;
end if;


/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   AWAY TRADES ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/

select load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
into l_step_id;

 l_ret:=1;

 return l_ret;

 exception when others then
   select public.load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select public.load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
  into l_step_id;

  PERFORM public.load_error_log('trade_record',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
  RAISE;



END;
$function$
;


CREATE VIEW public.last_fact_success
AS
SELECT 'TRADE_RECORD'::text AS table_name,
       load_timing.log_date
FROM public.load_timing
WHERE load_timing.load_timing_id = ((SELECT max(load_timing_1.load_timing_id) AS max
                                     FROM public.load_timing load_timing_1
                                     WHERE load_timing_1.table_name::text =
                                           'Trade_Record_inc COMPLETED ==='::character varying::text
                                       AND load_timing_1.log_date >= (now() - '1 day'::interval)))
  AND load_timing.step = 1;

CREATE SEQUENCE genesis2.tradelevel_book_record_book_record_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 5178869
	CACHE 1
	NO CYCLE;

CREATE TABLE genesis2.trade_level_book_record (
	book_record_id int8 DEFAULT nextval('dwh.tradelevel_book_record_book_record_id_seq'::regclass) NOT NULL,
	trade_record_id int8 NOT NULL,
	book_record_type_id varchar(10) NOT NULL,
	amount numeric(20, 8) NULL,
	book_record_creator_id varchar(4) NOT NULL, -- tcce, bcm, man
	create_time timestamp NULL,
	is_deleted int2 DEFAULT 0 NULL, -- 0  - record active¶1 - record deleted
	date_id int4 NOT NULL,
	rate numeric(14, 8) NULL,
	load_batch_id int4 NULL,
	schedule_rate_type varchar(1) NULL,
	user_id int4 NULL,
	billing_entity varchar(255) NULL
)
PARTITION BY RANGE (date_id);
CREATE INDEX book_record ON ONLY genesis2.trade_level_book_record USING btree (book_record_id);
CREATE UNIQUE INDEX nk_trade_level_book_record_idx ON ONLY genesis2.trade_level_book_record USING btree (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id);
CREATE INDEX pk_book_record ON ONLY genesis2.trade_level_book_record USING btree (book_record_id);
CREATE UNIQUE INDEX trade_level_book_record_idx ON ONLY genesis2.trade_level_book_record USING btree (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id);
CREATE INDEX trade_level_book_record_load_batch ON ONLY genesis2.trade_level_book_record USING btree (load_batch_id, book_record_type_id);
CREATE INDEX trade_level_book_record_load_batch_brt ON ONLY genesis2.trade_level_book_record USING btree (load_batch_id, book_record_type_id);

-- Column comments

COMMENT ON COLUMN genesis2.trade_level_book_record.book_record_creator_id IS 'tcce, bcm, man';
COMMENT ON COLUMN genesis2.trade_level_book_record.is_deleted IS '0  - record active
1 - record deleted';


CREATE TABLE genesis2.book_record_creator (
	book_record_creator_id varchar(4) NOT NULL, -- tcce, bcm, man
	description varchar(255) NULL,
	priority int2 NULL,
	CONSTRAINT pk_book_record_creator PRIMARY KEY (book_record_creator_id)
);

-- Column comments

COMMENT ON COLUMN genesis2.book_record_creator.book_record_creator_id IS 'tcce, bcm, man';

--====================================== FTR PART

CREATE or replace FUNCTION public.etl_subscribe(in_load_batch_id bigint, in_subscription_name character varying DEFAULT NULL::character varying, in_source_table_name character varying DEFAULT NULL::character varying, in_date_ids character varying DEFAULT NULL::character varying, in_row_count integer DEFAULT '-1'::integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare

l_pk_value bigint;
begin

    if in_row_count <> 0
    then
        if in_date_ids is null
        then
            insert into public.etl_subscriptions (subscription_name, source_table_name, load_batch_id)
            select in_subscription_name, in_source_table_name, in_load_batch_id
            where not exists(select 1
                             from public.etl_subscriptions sb2
                             where sb2.subscription_name = in_subscription_name
                               and source_table_name = in_source_table_name
                               and is_processed = false
                               and load_batch_id = in_load_batch_id
                )
            returning subscription_id into l_pk_value;
        else
            insert into public.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id)
            select in_subscription_name, in_source_table_name, in_load_batch_id, dtid::int
            from unnest(string_to_array(in_date_ids, ',')) as dtid
            where not exists (select 1
                             from public.etl_subscriptions sb2
                             where sb2.subscription_name = in_subscription_name
                               and source_table_name = in_source_table_name
                               and is_processed = false
                               and date_id = dtid::int
                               and load_batch_id = in_load_batch_id)  ;
            get diagnostics l_pk_value = row_count;
        end if;
    end if;

 return l_pk_value;

end;
$function$
;

CREATE or replace PROCEDURE dwh.load_trade_commissions(IN in_load_batch_id integer, IN in_date_id integer,
                                                       IN in_load_id integer DEFAULT NULL::integer,
                                                       IN in_step_id integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
AS
$procedure$
-- SY 20211018 'ATPF' , 'ARTY' logic has been introduced https://dashfinancial.atlassian.net/browse/DS-4277
-- SY 20211028 Doubling MIRA and GOAT commissions in case MIRA and GOAT they have different billing enttity
-- OS: 20211104 DS-4333 removing dynamic sql
-- SY: 20211220 DS-4567 Deduplicatyion logic implemented
-- SY: 20220203 DS-4797 deduplication during subscriptions for biling engines
-- SY&AK: 20220208 Subcription logic moved to inside in "if" scope  to avoid generating dummy subcriptions
-- SY: 20220210 https://dashfinancial.atlassian.net/browse/DS-4826. We do not need to create historical subscriptions for mira/goat because there are no any processes to pickup that data
-- AK: 20230825 changed amount type to numeric(20,8) in genesis2_commissions_tmp table creation
-- AK: 20240425 https://dashfinancial.atlassian.net/browse/DS-8256 added new commissions 'SPTF','QCCR','CATF'
declare
    l_date_id int;
    row_cnt   int;
    l_step_id int;
    l_pr_time timestamp;
begin
    l_date_id := in_date_id;
    l_step_id := in_step_id;

   create temp table if not exists genesis2_commissions_tmp (
			trade_record_id int8 null,
			book_record_type_id varchar(4) null,
			amount numeric(20,8) null,
			schedule_rate_type varchar(1) null,
            rate numeric (10,4),
			date_id int
		 )  on commit drop;

    if in_load_id is not null
    then
		select    public.load_log(in_load_id,    l_step_id,    'CREATE    TEMP    TABLE    if    not    exists    genesis2_commissions_tmp',    0,    'I')
        into l_step_id;
	            else                    RAISE    INFO    '%    %:    %        %    ',    clock_timestamp(),        'CREATE    TEMP    TABLE    if    not    exists    genesis2_commissions_tmp',    0,    'C';

    end if;

	 insert into genesis2_commissions_tmp(trade_record_id, book_record_type_id, amount, schedule_rate_type, rate, date_id)
	  select  trade_record_id::int8,  book_record_type_id,  amount,  schedule_rate_type,  rate,  date_id  --,  priority
	 from ( select t.trade_record_id, t.book_record_type_id, t.amount, t.schedule_rate_type, null::smallint as priority ,t.rate, t.date_id,
--	       row_number() over (partition by t.trade_record_id, t.book_record_type_id, t.billing_entity order by priority asc) drank
	        dense_rank() over (partition by t.trade_record_id, t.book_record_type_id order by cr.priority asc) as drank,
	          row_number () over (partition by t.book_record_id order by null) dedpulication
	        from genesis2.trade_level_book_record tlbr
	               inner join genesis2.trade_level_book_record t on (tlbr.trade_record_id = t.trade_record_id and tlbr.book_record_type_id = t.book_record_type_id and t.date_id = tlbr.date_id)
	               inner join genesis2.book_record_creator cr ON (t.book_record_creator_id = cr.book_record_creator_id)
	              where tlbr.load_batch_id = in_load_batch_id -- subs_cursor.load_batch_id
	                and tlbr.date_id = l_date_id
	                --and cr.book_record_creator_id <> 'MIR1'
	                and tlbr.book_record_type_id in ('TADC'/*,'TAEC'*/,'TFDC'/*,'TFEC'*/,'TMSS','TMTK','TOCF','TORF','TRTY','TSEC','TTF','TTPF','AMTK','ATF', 'ASRT', 'FSRT', 'CCRU', 'CLRF', 'ATPF' , 'ARTY','SPTF','QCCR','CATF') ) L1
	 where drank=1
	and dedpulication=1;

     GET DIAGNOSTICS row_cnt = ROW_COUNT;

     if in_load_id is not null
	  then
	 	select public.load_log(in_load_id, l_step_id, 'insert into genesis2_commissions_tmp', row_cnt, 'I')
	    into l_step_id;
	   else     RAISE INFO '% %: %  % ', clock_timestamp(),  'insert into genesis2_commissions_tmp', row_cnt, 'I';
 	 end if;

    update dwh.flat_trade_record trg
     set
         TCCE_Account_Dash_Commission_Amount = case when commission_data.TADC_cnt > 0 then commission_data.TCCE_Account_Dash_Commission_Amount else trg.TCCE_Account_Dash_Commission_Amount end,


        TCCE_Account_Execution_Cost =  case when commission_data.TADC_cnt > 0 then coalesce(commission_data.TCCE_Account_Dash_Commission_Amount,0) else coalesce(trg.TCCE_Account_Dash_Commission_Amount,0) end +
                                    case when commission_data.TMTK_cnt > 0 then coalesce(commission_data.TCCE_Maker_Taker_Fee_Amount,0)         else coalesce(trg.TCCE_Maker_Taker_Fee_Amount,0) end +
                                    case when commission_data.TRTY_cnt > 0 then coalesce(commission_data.TCCE_Royalty_Fee_Amount,0)             else coalesce(trg.TCCE_Royalty_Fee_Amount,0) end +
                                    case when commission_data.TTPF_cnt > 0 then coalesce(commission_data.TCCE_Trade_Processing_Fee_Amount,0)    else coalesce(trg.TCCE_Trade_Processing_Fee_Amount,0) end +
                                    case when commission_data.TTF_cnt  > 0 then coalesce(commission_data.TCCE_Transaction_Fee_Amount,0)         else coalesce(trg.TCCE_Transaction_Fee_Amount,0) end,

        TCCE_Firm_Dash_Commission_Amount    = case when commission_data.TFDC_cnt > 0 then commission_data.TCCE_Firm_Dash_Commission_Amount    else trg.TCCE_Firm_Dash_Commission_Amount end,


        TCCE_Firm_Execution_Cost =  case when commission_data.TFDC_cnt > 0 then coalesce(commission_data.TCCE_Firm_Dash_Commission_Amount,0)    else coalesce(trg.TCCE_Firm_Dash_Commission_Amount,0) end +
                                    case when commission_data.TMTK_cnt > 0 then coalesce(commission_data.TCCE_Maker_Taker_Fee_Amount,0)         else coalesce(trg.TCCE_Maker_Taker_Fee_Amount,0) end +
                                    case when commission_data.TRTY_cnt > 0 then coalesce(commission_data.TCCE_Royalty_Fee_Amount,0)             else coalesce(trg.TCCE_Royalty_Fee_Amount,0) end +
                                    case when commission_data.TTPF_cnt > 0 then coalesce(commission_data.TCCE_Trade_Processing_Fee_Amount,0)    else coalesce(trg.TCCE_Trade_Processing_Fee_Amount,0) end +
                                     case when commission_data.TTF_cnt  > 0 then coalesce(commission_data.TCCE_Transaction_Fee_Amount,0)         else coalesce(trg.TCCE_Transaction_Fee_Amount,0) end,


        TCCE_MSS_Fee_Amount                 = case when commission_data.TMSS_cnt > 0 then commission_data.TCCE_MSS_Fee_Amount                 else trg.TCCE_MSS_Fee_Amount end,
        TCCE_Maker_Taker_Fee_Amount         = case when commission_data.TMTK_cnt > 0 then commission_data.TCCE_Maker_Taker_Fee_Amount         else trg.TCCE_Maker_Taker_Fee_Amount end,
        TCCE_OCC_Fee_Amount                 = case when commission_data.TOCF_cnt > 0 then commission_data.TCCE_OCC_Fee_Amount                 else trg.TCCE_OCC_Fee_Amount end,
        TCCE_Option_Regulatory_Fee_Amount   = case when commission_data.TORF_cnt > 0 then commission_data.TCCE_Option_Regulatory_Fee_Amount   else trg.TCCE_Option_Regulatory_Fee_Amount end,
        TCCE_Royalty_Fee_Amount             = case when commission_data.TRTY_cnt > 0 then commission_data.TCCE_Royalty_Fee_Amount             else trg.TCCE_Royalty_Fee_Amount end,
        TCCE_SEC_Fee_Amount                 = case when commission_data.TSEC_cnt > 0 then commission_data.TCCE_SEC_Fee_Amount                 else trg.TCCE_SEC_Fee_Amount end,
        TCCE_Transaction_Fee_Amount         = case when commission_data.TTF_cnt  > 0 then commission_data.TCCE_Transaction_Fee_Amount         else trg.TCCE_Transaction_Fee_Amount end,
        TCCE_Trade_Processing_Fee_Amount    = case when commission_data.TTPF_cnt > 0 then commission_data.TCCE_Trade_Processing_Fee_Amount    else trg.TCCE_Trade_Processing_Fee_Amount end,
        TCCE_Admin_Maker_Taker_Fee_Amount   = case when commission_data.AMTK_cnt > 0 then commission_data.TCCE_Admin_Maker_Taker_Fee_Amount   else trg.TCCE_Admin_Maker_Taker_Fee_Amount end,
        TCCE_Admin_Transaction_Fee_Amount   = case when commission_data.ATF_cnt  > 0 then commission_data.TCCE_Admin_Transaction_Fee_Amount   else trg.TCCE_Admin_Transaction_Fee_Amount end,
        account_schedule_rate_type 			= case when commission_data.ASRT_cnt > 0 then commission_data.account_schedule_rate_type		  else trg.account_schedule_rate_type end,
        trading_firm_schedule_rate_type		= case when commission_data.FSRT_cnt > 0 then commission_data.trading_firm_schedule_rate_type	  else trg.trading_firm_schedule_rate_type end,
        client_commission_rate				= case when commission_data.CCRU_cnt > 0 then commission_data.CCRU	  							  else trg.client_commission_rate end,
        clearing_fee_amout					= case when commission_data.CLRF_cnt > 0 then commission_data.CLRF	  							  else trg.clearing_fee_amout end,

        Tcce_admin_trade_processing_fee		= case when commission_data.ATPF_cnt > 0 then commission_data.ATPF	  							  else trg.Tcce_admin_trade_processing_fee end,
        Tcce_admin_royalty_fee				= case when commission_data.ARTY_cnt > 0 then commission_data.ARTY	  							  else trg.Tcce_admin_royalty_fee end,

        spread_transaction_fee_amount		= case when commission_data.SPTF_cnt > 0 then commission_data.SPTF	  							  else trg.spread_transaction_fee_amount end,
        qcc_Rebate_amount					= case when commission_data.QCCR_cnt > 0 then commission_data.QCCR	  							  else trg.qcc_Rebate_amount end,
        cat_fee_amount						= case when commission_data.CATF_cnt > 0 then commission_data.CATF	  							  else trg.cat_fee_amount end
     from ( select trade_record_id, sum(case when book_record_type_id = 'TADC' then amount else null end) as TCCE_Account_Dash_Commission_Amount,
                                count (case when book_record_type_id = 'TADC' then 1 else null end) as TADC_cnt,
                                sum(case when book_record_type_id = 'TFDC' then amount else null end) as TCCE_Firm_Dash_Commission_Amount,
                                count (case when book_record_type_id = 'TFDC' then 1 else null end) as TFDC_cnt,
                                sum(case when book_record_type_id = 'TMSS' then amount else null end) 	as TCCE_MSS_Fee_Amount,
                                count (case when book_record_type_id = 'TMSS' then 1 else null end) 	as TMSS_cnt,
                                sum(case when book_record_type_id = 'TMTK' then amount else null end) 	as TCCE_Maker_Taker_Fee_Amount,
                                count (case when book_record_type_id = 'TMTK' then 1 else null end) 	as TMTK_cnt,
                                sum(case when book_record_type_id = 'TOCF' then amount else null end) 	as TCCE_OCC_Fee_Amount,
                                count (case when book_record_type_id = 'TOCF' then 1 else null end) 	as TOCF_cnt,
                                sum(case when book_record_type_id = 'TORF' then amount else null end) 	as TCCE_Option_Regulatory_Fee_Amount,
                                count (case when book_record_type_id = 'TORF' then 1 else null end) 	as TORF_cnt,
                                sum(case when book_record_type_id = 'TRTY' then amount else null end) 	as TCCE_Royalty_Fee_Amount,
                                count (case when book_record_type_id = 'TRTY' then 1 else null end) 	as TRTY_cnt,
                                sum(case when book_record_type_id = 'TSEC' then amount else null end) 	as TCCE_SEC_Fee_Amount,
                                count (case when book_record_type_id = 'TSEC' then 1 else null end) 	as TSEC_cnt,
                                sum(case when book_record_type_id = 'TTF' then amount else null end) 	as TCCE_Transaction_Fee_Amount,
                                count (case when book_record_type_id = 'TTF'  then 1 else null end) 	as TTF_cnt,
                                sum(case when book_record_type_id = 'TTPF' then amount else null end) 	as TCCE_Trade_Processing_Fee_Amount,
                                count (case when book_record_type_id = 'TTPF' then 1 else null end) 	as TTPF_cnt,

                                sum(case when book_record_type_id = 'AMTK' then amount else null end) 	as TCCE_Admin_Maker_Taker_Fee_Amount,
                                count (case when book_record_type_id = 'AMTK' then 1 else null end) 	as AMTK_cnt,
                                sum(case when book_record_type_id = 'ATF' then amount else null end) 	as TCCE_Admin_Transaction_Fee_Amount,
                                count (case when book_record_type_id = 'ATF' then 1 else null end) 		as ATF_cnt,

                                max(case when book_record_type_id = 'ASRT' then schedule_rate_type else null end) as account_schedule_rate_type,
                                count (case when book_record_type_id = 'ASRT' then 1 else null end) 		as ASRT_cnt,
                                max(case when book_record_type_id = 'FSRT' then schedule_rate_type else null end) as trading_firm_schedule_rate_type,
                                count (case when book_record_type_id = 'FSRT' then 1 else null end) 		as FSRT_cnt,
                                max(case when book_record_type_id = 'CCRU' then rate else null end) 	as CCRU,
                                count (case when book_record_type_id = 'CCRU' then 1 else null end) 	as CCRU_cnt,
                                max(case when book_record_type_id = 'CLRF' then amount else null end) 	as CLRF,
                                count (case when book_record_type_id = 'CLRF' then 1 else null end) 	as CLRF_cnt
                                																					,
                                max(case when book_record_type_id = 'ATPF' then amount else null end) 	as ATPF,
                                count (case when book_record_type_id = 'ATPF' then 1 else null end) 	as ATPF_cnt,
                                max(case when book_record_type_id = 'ARTY' then amount else null end) 	as ARTY,
                                count (case when book_record_type_id = 'ARTY' then 1 else null end) 	as ARTY_cnt,

                                sum(case when book_record_type_id = 'SPTF' then rate else null end) 	as SPTF,
                                count (case when book_record_type_id = 'SPTF' then 1 else null end) 	as SPTF_cnt,
                                sum(case when book_record_type_id = 'QCCR' then rate else null end) 	as QCCR,
                                count (case when book_record_type_id = 'QCCR' then 1 else null end) 	as QCCR_cnt,
                                sum(case when book_record_type_id = 'CATF' then rate else null end) 	as CATF,
                                count (case when book_record_type_id = 'CATF' then 1 else null end) 	as CATF_cnt

          from genesis2_commissions_tmp dist
          group by dist.trade_record_id ) commission_data
     where trg.trade_record_id = commission_data.trade_record_id
       and trg.date_id = l_date_id;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;

    if in_load_id is not null
	  then
	 	select public.load_log(in_load_id, l_step_id, 'FTR Commissions updated', row_cnt, 'I')
	    into l_step_id;
	   else     RAISE INFO '% %: %  % ', clock_timestamp(),  'update dwh.flat_trade_record trg', row_cnt, 'I';
	 end if;

	if    row_cnt>0
	    then    update    public.etl_subscriptions
			set is_processed = true,
			    process_time = clock_timestamp()
			where load_batch_id = in_load_batch_id --subs_cursor.load_batch_id
			  and not is_processed
			        and    date_id    =    in_date_id
	                        and    subscription_name    in    (    'goat.big_data.flat_trade_record','big_data.flat_trade_record',    'bdark.big_data.flat_trade_record',    'goat.big_data.flat_trade_commissions'    )
			  and source_table_name ='trade_level_book_record' ;

			 GET DIAGNOSTICS row_cnt = ROW_COUNT;

     if in_load_id is not null
	  then
	  select public.load_log(in_load_id, l_step_id, 'load_batches to close subscriptions : '||in_load_batch_id , row_cnt , 'U')
	   into l_step_id;
	   else     RAISE INFO '% %: %  % ', clock_timestamp(),  'load_batches to close subscriptions : '||in_load_batch_id, row_cnt, 'U';
	  end if;

	  if in_date_id >= dwh.get_dateid(current_date-5)
	   then
		  with  ins as (select --public.etl_subscribe(in_load_batch_id=>trade_record_id, in_subscription_name=>'dash_trade_record_comm_edw'::varchar, in_source_table_name=>'flat_trade_record'::varchar, in_row_count=>1, in_date_ids=>date_id::varchar),
		                       public.etl_subscribe(in_load_batch_id=>trade_record_id, in_subscription_name=>'dash_trade_record_comm_mira'::varchar, in_source_table_name=>'flat_trade_record'::varchar, in_row_count=>1, in_date_ids=>date_id::varchar)
	                    from (select distinct trade_record_id, date_id from genesis2_commissions_tmp ) l )
	      select count(1) into row_cnt
	      from ins;
       end if;

    end    if;




    if in_load_id is not null
	  then
	     select public.load_log(in_load_id, l_step_id, 'subscribed commissions for EDW ', row_cnt , 'I')
	     into l_step_id;
	   else
	     RAISE INFO '% %: %  % ', clock_timestamp(),  'subscribed commissions for EDW  : '||in_load_batch_id, row_cnt, 'U';
    end if;

    if in_load_id is not null
	  then
	  select public.load_log(in_load_id, l_step_id, 'dwh.load_trade_commissions COMPLETED ======= : ' , row_cnt , 'E')
	   into l_step_id;
	   else     RAISE INFO '% %: %  % ', clock_timestamp(),  'dwh.load_trade_commissions COMPLETED ======= :'||in_load_batch_id, row_cnt, 'U';
	 end if;

	  RETURN ;

		exception when others then
		 select public.load_log(in_load_id, l_step_id, sqlerrm , 0, 'E')
		 into l_step_id;
	   	PERFORM public.load_error_log(' dwh.load_trade_commissions ERROR!!!',  'I', sqlerrm, in_load_id);

  		RAISE;
end;
$procedure$
;



-- DROP FUNCTION dwh.load_flat_trade_record_inc(bool, _int8, int4);

CREATE OR REPLACE FUNCTION dwh.load_flat_trade_record_inc(in_manual_run boolean DEFAULT false, in_tarde_record_ids bigint[] DEFAULT NULL::bigint[], in_load_batch_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL_FAST: FLat_trade_Record incremental'
AS $function$
-- SY: DS-3269 few fileds have been introduced (allocation_avg_price, occ_actionable_id,account_nickname)
--  SY:  DS-3444  Remove    occ_actionable_id  field
--  AK:  DS-3687  Added  new  condition    subscribe_time  <  now()  in  the  l1_snapshot  subscription  logic  processing
--  AK:  DS-3687  Added  new  condition  "and  coalesce(nullif(st.instrument_id,-1),  trade_record.instrument_id)    =  trade_record.instrument_id"  during  insert  to  FTL  in  join  to  l1_snapshoti
--  AK:  DS-3782  added  input  parameter  to    public.etl_subscribe  function    -->  in_date_ids=>tr_date_id_cursor.date_id::varchar
--  AK:  DS-3427  Added  new  field  penny_nickel  to  FTR
-- OS: DS-2624 Migration ftr into native partitioning (2021-08-23)
--  AK:  DS-4135    20210910  join  to  l1_snapshot  has  been  fixed  as  in  DS-3782  ticket(looks  like  it  was  overwrited)
/* Changes log
   1. on conflict added
   2. unused variables have been removed
   3. the very slow statement with row_number and market_data.trade order by trade_time was replaced by lateral
   4. and as a result, the select has been simplified.
   5. dynamic SQL was replaced by the usual one.
   6. materialized in cte has been removed
   7. prepare-execute statement has been moved inside the loop
 */
--  SY:  DS-4118  join  to  d_exchange  using  last_market  field  was  refactored  to  use  lateral  and  limit  1  due  to  fail  of  on  conflict
--  PD:  DS-4158  added  input  parameter  in_load_batch_id,  so  we  can  create  street  level  fix  subscriptions  for  mira
--  SY:  DS-4069 migration to bigint https://dashfinancial.atlassian.net/browse/DS-4069
--  OS:  DS-4218  added market_data_trade_time populated from market_data.trade trade_time
--  SY:  20211116. MIra subscription for PTM purposes has been added https://dashfinancial.atlassian.net/browse/DS-2734
--  SY:  20211202. TCCE processing has been limited by not more then 10 subscriptions during one run
--  AK:  20211202. Conditions for NBBO has been modified to coalesce(nullif(nullif(st.instrument_id,-1),1), tr.instrument_id) = tr.instrument_id  and in another statement to nullif(nullif(st.instrument_id,-1), 1 )
--  SY:  20220128. https://dashfinancial.atlassian.net/browse/DS-4763
--                 Line 694 If statement has been added to do not process market_data fix during manual sync for todays traffic

-- AK: 20220211 added coalesce function to on conflict in insert into flat_trade_record
-- AK: 20220419 added public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
-- SY: 20220816 Manual bust processing. Cursor based on subscriptions has been improved to use two field in IN statement (date_id, load_batch_id) in (select ...)
-- AK: 20220912 Added to processing street level subscriptions new subscription 'trade_record_away_lvl_info' to process changes related to blaze_account_alias
-- SY: 20230330 https://dashfinancial.atlassian.net/browse/DS-6522. Following cindition has been added to prevent closing subscription before time. and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id )
-- SY: 20230405 https://dashfinancial.atlassian.net/browse/DS-6509. PFOF section has been commented
-- SY: 20230405 https://dashfinancial.atlassian.net/browse/DS-4917 Subscription for GOAT DTR has been commented like this one public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
-- SY: 20231113 https://dashfinancial.atlassian.net/browse/DS-7355 We need to create bust subscritpions for FYC and both billing engines whyle simple manual bust (caused by Oracle or Manual bust of DB side)

declare
    l_max_trade_record_id       int8;
    l_max_instrument_id         int;
    l_foreign_max_instrument_id int;
    date_cursor                 record;
    subs_cursor                 record;
    lp_cursor                   record;
    row_cnt                     integer;
    l_row_cnt                   integer;
    l_tarde_record_ids          bigint[];
    l_load_id                   int;
    l_step_id                   int;
--    l_max_trade_time            timestamp;
    l_sql                       varchar;
    l_trade_id_to_reprint       bigint[];
    l_subs_list_jsn             jsonb;
    tr_date_id_cursor           record;
    l_last_tr_success_time		timestamp;
begin
    select nextval('public.load_timing_seq') into l_load_id;

    l_step_id:=1;
    if in_manual_run then
       /* ============================  POST TRADE MODIFICATION  =================================================  */
        select public.load_log(l_load_id, l_step_id, 'FLAT_TRADE_RECORD STARTED (manual run) ===', cardinality(in_tarde_record_ids), 'O')
        into l_step_id;

         if in_tarde_record_ids is null then
                        select  coalesce(max(trade_record_id),  0)
                        into  l_max_trade_record_id
            from dwh.flat_trade_record
            where coalesce(trade_fix_message_id, 1) > 0  /*we look for dash traffic only */
                 and trade_record_reason in ('P', 'B', 'L', 'U');

                        l_tarde_record_ids  =  array(select  trade_record_id
                                                     from  genesis2.trade_record
                                                     where  trade_record_id  >  l_max_trade_record_id
                                                       and  trade_record_reason  in  ('P',  'B',  'L',  'U')
                                                       and  db_create_time  <=  now()::timestamp);
        else
            l_tarde_record_ids := in_tarde_record_ids;
        end if;

        select public.load_log(l_load_id, l_step_id, 'l_tarde_record_ids size is ='||cardinality(l_tarde_record_ids), 0, 'O')
        into l_step_id;

    else
    /* ============================  GENERAL CASE =================================================  */
        select public.load_log(l_load_id, l_step_id, 'FLAT_TRADE_RECORD STARTED ===', 0, 'O')
        into l_step_id;

                if  in_tarde_record_ids  is  null
                then
                        select  coalesce(max(trade_record_id),  0)
                        into  l_max_trade_record_id
            from dwh.flat_trade_record
            where /*order_id is not null / *We look for Dash traffic only */
            /* coalesce(subsystem_id,' ') not in ('LPDROP', 'LPEDW')
                                and*/  coalesce(trade_record_reason,  'A')  not  in  ('P',  'B',  'L',  'U');

             select log_date  /*- interval '60 minute' */
            into l_last_tr_success_time
			from public.last_fact_success
			where table_name ='TRADE_RECORD';

		l_tarde_record_ids = array(select trade_record_id
                                       from genesis2.trade_record
                                       where trade_record_id > l_max_trade_record_id
                                         and coalesce(trade_record_reason, 'A') not in ('P', 'B', 'L', 'U')
                                         and db_create_time <= l_last_tr_success_time );
--                                         and db_create_time <= now()::timestamp - interval '10 seconds'
 --               /*and coalesce(subsystem_id,' ') not in ('LPDROP', 'LPEDW')*/);
        else
            l_tarde_record_ids := in_tarde_record_ids;
        end if;
        select public.load_log(l_load_id, l_step_id, 'l_tarde_record_ids size is ='||cardinality(l_tarde_record_ids), 0, 'O')
        into l_step_id;

	end if;
-- SO removed
    /*
        if  not  in_manual_run
        then
        select coalesce(max(instrument_id),0) into l_max_instrument_id from dwh.d_instrument;
                select  coalesce(max(instrument_id),  0)
                into  l_foreign_max_instrument_id
                from  staging.instrument
                where  instrument_id  >  l_max_instrument_id;

        select public.load_log(l_load_id, l_step_id, format('l_max_instrument_id is %s, l_foreign_max_instrument_id, %s', l_max_instrument_id, l_foreign_max_instrument_id), 0, 'O')
        into l_step_id;


        if l_foreign_max_instrument_id> l_max_instrument_id then
            perform public.dblink_connect('ftr_instr_sync','dbname=big_data user=dwh');
            perform public.dblink_exec('ftr_instr_sync','call dwh.load_trade_instruments('||l_max_instrument_id +1||','||l_foreign_max_instrument_id||','||l_load_id||','||l_step_id||')');
            perform public.dblink_exec('ftr_instr_sync','commit;');
            perform public.dblink_disconnect('ftr_instr_sync');
            l_step_id:=l_step_id + 2;
        end if;
    end if;
    */

--    l_max_trade_time:=current_timestamp - interval '10 days'; /* to avoid commission being ahead of trade_record */

    select public.load_log(l_load_id, l_step_id, 'Dimensions done', 0, 'I')
            into l_step_id;


    if cardinality(l_tarde_record_ids) > 0 then

       for date_cursor in (select date_id from genesis2.trade_record where trade_record_id = any(l_tarde_record_ids) group by date_id )
           loop

    select public.load_log(l_load_id, l_step_id, 'Processing date', date_cursor.date_id, 'I')
            into l_step_id;

            insert into dwh.flat_trade_record (
        trade_record_id, trade_record_time, db_create_time, date_id, is_busted, trade_record_trans_type,
        trade_record_reason, subsystem_id, user_id, account_id, client_order_id, instrument_id, side, open_close,
        fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator, secondary_order_id, exch_exec_id,
        secondary_exch_exec_id, last_mkt, last_qty, last_px, ex_destination, sub_strategy, street_order_id,
        order_id, street_order_qty, order_qty, multileg_reporting_type, is_largest_leg, street_max_floor,
        exec_broker, cmta, street_time_in_force, street_order_type, opt_customer_firm, street_mpid, is_cross_order,
        street_is_cross_order, street_cross_type, cross_is_originator, street_cross_is_originator, contra_account,
        contra_broker, trade_exec_broker, order_fix_message_id, trade_fix_message_id, street_order_fix_message_id,
        order_price, street_order_price, order_process_time, ask_price, bid_price, trade_id, client_id,
        street_transaction_id, transaction_id, clearing_account_number, sub_account, remarks, optional_data,
        street_client_order_id, fix_comp_id, ask_qty, bid_qty, leaves_qty, is_billed, street_exec_inst,
        orig_trade_record_id, principal_amount, trading_firm_id, trading_firm_unq_id, fee_sensitivity,
        routing_time_bid_price, routing_time_bid_qty, routing_time_ask_price, routing_time_ask_qty,
        strategy_decision_reason_code, compliance_id, floor_broker_id, auction_id, street_opt_customer_firm,
        multileg_order_id, internal_component_type, instrument_type_id, street_trade_fix_message_id, pt_basket_id,
        pt_order_id, transact_time, trade_exchange_id, blaze_account_alias, customer_review_status, street_account_name,
        street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, int_liq_source_type,
        allocation_avg_price, account_nickname, clearing_account_id, market_participant_id,
        alternative_compliance_id, street_trade_record_time, penny_nickel, load_batch_id, market_data_trade_time, street_order_process_time,leg_ref_id)

            select
        tr.trade_record_id, tr.trade_record_time, tr.db_create_time, tr.date_id, tr.is_busted, tr.trade_record_trans_type,
        tr.trade_record_reason, tr.subsystem_id, tr.user_id, tr.account_id, tr.client_order_id, tr.instrument_id, tr.side, tr.open_close,
        tr.fix_connection_id, tr.exec_id, tr.exchange_id, tr.trade_liquidity_indicator, tr.secondary_order_id, tr.exch_exec_id,
        tr.secondary_exch_exec_id, tr.last_mkt, tr.last_qty, tr.last_px, tr.ex_destination, tr.sub_strategy, tr.street_order_id,
        tr.order_id, tr.street_order_qty, tr.order_qty, tr.multileg_reporting_type, tr.is_largest_leg, tr.street_max_floor,
        tr.exec_broker, tr.cmta, tr.street_time_in_force, tr.street_order_type, tr.opt_customer_firm, tr.street_mpid, tr.is_cross_order,
        tr.street_is_cross_order, tr.street_cross_type, tr.cross_is_originator, tr.street_cross_is_originator, tr.contra_account,
        tr.contra_broker, tr.trade_exec_broker, tr.order_fix_message_id, tr.trade_fix_message_id, tr.street_order_fix_message_id,
        tr.order_price, tr.street_order_price, tr.order_process_time, trade.ask_price, trade.bid_price, trade.trade_id, tr.client_id,
        tr.street_transaction_id, tr.transaction_id, tr.clearing_account_number, tr.sub_account, tr.remarks, tr.optional_data,
        tr.street_client_order_id, tr.fix_comp_id, trade.ask_qty, trade.bid_qty, tr.leaves_qty, tr.is_billed, tr.street_exec_inst,
        tr.orig_trade_record_id,
        case
            when case i.instrument_type_id
                     when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                     else tr.last_qty * tr.last_px end > 9999999999999999.9999::numeric(20, 4)
                then null
            else case i.instrument_type_id
                     when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                     else tr.last_qty * tr.last_px end
            end principal_amount,
		    ac.trading_firm_id, ac.trading_firm_unq_id, tr.fee_sensitivity,
			md.l1_bid_price, md.l1_bid_qty, md.l1_ask_price, md.l1_ask_qty,
			tr.strategy_decision_reason_code, tr.compliance_id, tr.floor_broker_id, tr.auction_id, tr.street_opt_customer_firm,
            tr.multileg_order_id, tr.internal_component_type, i.instrument_type_id, tr.street_trade_fix_message_id, tr.pt_basket_id,
            pt_order_id, to_timestamp(j.fix_message->>'60', 'yyyymmdd-hh24:mi:ss.us')::timestamp at time zone 'UTC' as transact_time,
            lm.exchange_id as trade_exchange_id, tr.blaze_account_alias, tr.customer_review_status, tr.street_account_name,
			tr.street_exec_broker, tr.trade_text, tr.branch_sequence_number, tr.frequent_trader_id, tr.int_liq_source_type,
			tr.allocation_avg_price, tr.account_nickname, tr.clearing_account_id, tr.market_participant_id,
			tr.alternative_compliance_id, tr.street_trade_record_time,
            case os.min_tick_increment when 0.05 then 'N' when 0.01 then 'P' end as penny_nickel,
                        in_load_batch_id  as  load_batch_id,
                        trade.trade_time as market_data_trade_time,
            tr.street_order_process_time , tr.leg_ref_id
            from genesis2.trade_record tr
                   inner join dwh.d_instrument i on (tr.instrument_id = i.instrument_id)
                                      left  join  lateral  (select  exchange_id  from  dwh.d_exchange  lmm  where  tr.last_mkt  =  lmm.last_mkt  and  lmm.is_active  and  lmm.exchange_id  =  lmm.real_exchange_id  limit  1)  lm  on  true
                   left join lateral (select t.ask_price, t.bid_price, t.trade_id, t.ask_quantity as ask_qty, t.bid_quantity as bid_qty, t.trade_time
                                      from market_data.trade t
                                      where t.date_id = date_cursor.date_id
                                        and t.activ_symbol = i.activ_symbol
                                        and t.price = tr.last_px
                                        and t.quantity = tr.last_qty
                                        and t.trade_time between
                                              tr.trade_record_time::timestamp without time zone - interval '00:00:00.9'
                                          and tr.trade_record_time::timestamp without time zone + interval '00:00:00.9'
                                      order by abs(extract(epoch from (tr.trade_record_time - t.trade_time)))
                                      limit 1) trade on true
                   left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                   left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   left join dwh.d_account ac on (ac.account_id = tr.account_id)
                   left join lateral (select sum(bid_price)    as l1_bid_price,
                                             sum(ask_price)    as l1_ask_price,
                                             sum(bid_quantity) as l1_bid_qty,
                                             sum(ask_quantity) as l1_ask_qty
                                      from dwh.l1_snapshot st
                                      where exchange_id = 'NBBO'
                                        and num_nonnulls(bid_price, ask_price, bid_quantity, ask_quantity) > 0
                                        and st.transaction_id = tr.street_transaction_id
                                        --and coalesce(st.instrument_id, tr.instrument_id) = tr.instrument_id
                                        and coalesce(nullif(nullif(st.instrument_id,-1),1), tr.instrument_id) = tr.instrument_id
                                        and st.start_date_id = date_cursor.date_id) md on true
                   left join fix_capture.fix_message_json j
                             on (trade_fix_message_id = j.fix_message_id and j.date_id = date_cursor.date_id)
          where tr.trade_record_id = any(l_tarde_record_ids)
            and tr.date_id = date_cursor.date_id
        on conflict (trade_record_id, date_id) do update
                set trade_record_time             = excluded.trade_record_time,
                    is_busted                     = excluded.is_busted,
                    trade_record_trans_type       = excluded.trade_record_trans_type,
                    trade_record_reason           = excluded.trade_record_reason,
                    subsystem_id                  = excluded.subsystem_id,
                    user_id                       = excluded.user_id,
                    account_id                    = excluded.account_id,
                    client_order_id               = excluded.client_order_id,
                    instrument_id                 = excluded.instrument_id,
                    side                          = excluded.side,
                    open_close                    = excluded.open_close,
                    fix_connection_id             = excluded.fix_connection_id,
                    exec_id                       = excluded.exec_id,
                    exchange_id                   = excluded.exchange_id,
                    trade_liquidity_indicator     = excluded.trade_liquidity_indicator,
                    secondary_order_id            = excluded.secondary_order_id,
                    exch_exec_id                  = excluded.exch_exec_id,
                    secondary_exch_exec_id        = excluded.secondary_exch_exec_id,
                    last_mkt                      = excluded.last_mkt,
                    last_qty                      = excluded.last_qty,
                    last_px                       = excluded.last_px,
                    ex_destination                = excluded.ex_destination,
                    sub_strategy                  = excluded.sub_strategy,
                    street_order_id               = excluded.street_order_id,
                    order_id                      = excluded.order_id,
                    street_order_qty              = excluded.street_order_qty,
                    order_qty                     = excluded.order_qty,
                    multileg_reporting_type       = excluded.multileg_reporting_type,
                    is_largest_leg                = excluded.is_largest_leg,
                    street_max_floor              = excluded.street_max_floor,
                    exec_broker                   = excluded.exec_broker,
                    cmta                          = excluded.cmta,
                    street_time_in_force          = excluded.street_time_in_force,
                    street_order_type             = excluded.street_order_type,
                    opt_customer_firm             = excluded.opt_customer_firm,
                    street_mpid                   = excluded.street_mpid,
                    is_cross_order                = excluded.is_cross_order,
                    street_is_cross_order         = excluded.street_is_cross_order,
                    street_cross_type             = excluded.street_cross_type,
                    cross_is_originator           = excluded.cross_is_originator,
                    street_cross_is_originator    = excluded.street_cross_is_originator,
                    contra_account                = excluded.contra_account,
                    contra_broker                 = excluded.contra_broker,
                    trade_exec_broker             = excluded.trade_exec_broker,
                    order_fix_message_id          = excluded.order_fix_message_id,
                    trade_fix_message_id          = excluded.trade_fix_message_id,
                    street_order_fix_message_id   = excluded.street_order_fix_message_id,
                    order_price                   = excluded.order_price,
                    order_process_time            = excluded.order_process_time,
                    --ask_price                     = excluded.ask_price,
                    ask_price                     = coalesce(excluded.ask_price,flat_trade_record.ask_price),
                    --bid_price                     = excluded.bid_price,
                    bid_price                     = coalesce(excluded.bid_price,flat_trade_record.bid_price),
                    --trade_id                      = excluded.trade_id,
                    trade_id                      = coalesce(excluded.trade_id,flat_trade_record.trade_id),
                    client_id                     = excluded.client_id,
                    street_transaction_id         = excluded.street_transaction_id,
                    transaction_id                = excluded.transaction_id,
                    clearing_account_number       = excluded.clearing_account_number,
                    sub_account                   = excluded.sub_account,
                    remarks                       = excluded.remarks,
                    optional_data                 = excluded.optional_data,
                    street_client_order_id        = excluded.street_client_order_id,
                    fix_comp_id                   = excluded.fix_comp_id,
                    --ask_qty                       = excluded.ask_qty,
                    ask_qty                       = coalesce(excluded.ask_qty,flat_trade_record.ask_qty),
                    --bid_qty                       = excluded.bid_qty,
                    bid_qty                       = coalesce(excluded.bid_qty,flat_trade_record.bid_qty),
                    leaves_qty                    = excluded.leaves_qty,
                    is_billed                     = excluded.is_billed,
                    street_exec_inst              = excluded.street_exec_inst,
                    orig_trade_record_id          = excluded.orig_trade_record_id,
                    principal_amount              = excluded.principal_amount,
                    trading_firm_id               = excluded.trading_firm_id,
                    strategy_decision_reason_code = excluded.strategy_decision_reason_code,
                    compliance_id                 = excluded.compliance_id,
                   -- routing_time_bid_price        = excluded.routing_time_bid_price,
                    routing_time_bid_price        = coalesce(excluded.routing_time_bid_price,flat_trade_record.routing_time_bid_price),
                    --routing_time_bid_qty          = excluded.routing_time_bid_qty,
                    routing_time_bid_qty          = coalesce(excluded.routing_time_bid_qty,flat_trade_record.routing_time_bid_qty),
                    --routing_time_ask_price        = excluded.routing_time_ask_price,
                    routing_time_ask_price        = coalesce(excluded.routing_time_ask_price,flat_trade_record.routing_time_ask_price),
                    --routing_time_ask_qty          = excluded.routing_time_ask_qty,
                    routing_time_ask_qty          = coalesce(excluded.routing_time_ask_qty,flat_trade_record.routing_time_ask_qty),
                    floor_broker_id               = excluded.floor_broker_id,
                    auction_id                    = excluded.auction_id,
                    street_opt_customer_firm      = excluded.street_opt_customer_firm,
                    multileg_order_id             = excluded.multileg_order_id,
                    internal_component_type       = excluded.internal_component_type,
                    street_exec_broker            = excluded.street_exec_broker,
                    trading_firm_unq_id           = excluded.trading_firm_unq_id,
                    instrument_type_id            = excluded.instrument_type_id,
                    street_trade_fix_message_id   = excluded.street_trade_fix_message_id,
                    pt_basket_id                  = excluded.pt_basket_id,
                    pt_order_id                   = excluded.pt_order_id,
                    transact_time                 = excluded.transact_time,
                    trade_exchange_id             = excluded.trade_exchange_id,
                    blaze_account_alias           = excluded.blaze_account_alias,
                    customer_review_status        = excluded.customer_review_status,
                    street_account_name           = excluded.street_account_name,
                    trade_text                    = excluded.trade_text,
                    branch_sequence_number        = excluded.branch_sequence_number,
                    frequent_trader_id            = excluded.frequent_trader_id,
                    int_liq_source_type           = excluded.int_liq_source_type,
                    --load_batch_id  				  = excluded.load_batch_id,
                    load_batch_id  				  = coalesce(excluded.load_batch_id,flat_trade_record.load_batch_id),
					market_data_trade_time        = excluded.market_data_trade_time,
                    allocation_avg_price          = excluded.allocation_avg_price,
                    account_nickname              = excluded.account_nickname,
                    clearing_account_id           = excluded.clearing_account_id,
                    market_participant_id         = excluded.market_participant_id,
                    alternative_compliance_id     = excluded.alternative_compliance_id,
                    street_trade_record_time      = excluded.street_trade_record_time,
                    penny_nickel                  = excluded.penny_nickel,
                    street_order_process_time	  = excluded.street_order_process_time,
                    street_order_price			  = excluded.street_order_price,
                   	leg_ref_id					  = excluded.leg_ref_id;

            select public.load_log(l_load_id, l_step_id, 'insert into dwh.flat_trade_record date_id='||date_cursor.date_id::text, 0, 'I')
            into l_step_id;
        end loop;
    end if;

if not in_manual_run then
/*    ================================================================================================*/
/*    =====================================        TCCE    ====================================================*/
/*    ================================================================================================*/
                select  array_to_json(array(select  row  (load_batch_id,  date_id)
                                                                      FROM  public.etl_subscriptions
                                                                      where  subscription_name  in
                                                                                  ('goat.big_data.flat_trade_commissions',  'big_data.flat_trade_record',
                                                                                    'bdark.big_data.flat_trade_record')
                                                                          and  source_table_name  =  'trade_level_book_record'
                                                                          and  not  is_processed
                                                                          and  subscribe_time  <  now()  -  interval  '60    seconds'
                                                                          and  subscribe_time  >  now()  -  interval  '4    day'
                                                                          order by load_batch_id desc
                                                                          limit 15))
                into  l_subs_list_jsn;

                IF  l_subs_list_jsn  is  not  null  and  jsonb_array_length(l_subs_list_jsn)  >  0
                then
                        for  date_cursor  in  (Select  (tr_id  ->  'f1')::int  as  load_batch_id,  coalesce((tr_id  ->>  'f2')::int,  dwh.get_dateid(current_date))  as  date_id
                                from  jsonb_array_elements(l_subs_list_jsn)  tr_id)
                                Loop
                                        select  public.load_log(l_load_id,  l_step_id,  'TCCE    date_id,    load_batch_id    cursor    opened    :    '||date_cursor.load_batch_id||'    -    '||date_cursor.date_id,  0,  'I')
                                        into  l_step_id;

                                        perform  public.dblink_connect('ftr_comm_upd',  'dbname=big_data    user=dwh');
                                        perform  public.dblink_exec('ftr_comm_upd',  'call    dwh.load_trade_commissions('||date_cursor.load_batch_id||','||date_cursor.date_id||','||l_load_id||','||l_step_id||')');
                                        perform  public.dblink_exec('ftr_comm_upd',  'commit;');
                                        perform  public.dblink_disconnect('ftr_comm_upd');
                                        l_step_id  :=  l_step_id  +  10;
                                end  loop;
                        /*date_cursor*/

/* ================================================================================================*/
/* =====================================  LP Traffic ==============================================*/
/* ================================================================================================*/

            select public.load_log(l_load_id, l_step_id, 'Start LP traffic ', 0, 'I')
            into l_step_id;
   for lp_cursor in (select subs.load_batch_id, array_agg(trade_record_id) as trade_record_ids
                      from genesis2.trade_record st_tr
                       inner  join  public.etl_subscriptions  subs on  (subs.load_batch_id  =  st_tr.load_batch_id)
                       where  subscription_name  in  ('goat.big_data.flat_trade_record',  'big_data.flat_trade_record')
                        and source_table_name in ('liquid_point_trade_record', 'liquid_point_trade_record.u')
                        and not is_processed
                        and st_tr.subsystem_id in ('LPDROP', 'LPEDW')
                        and st_tr.trade_record_id < l_max_trade_record_id
                          and  1=2  /*  Deprectaed since middle of 2020 */
                      group by subs.load_batch_id
                      order by load_batch_id desc
                      limit 1)
        loop

            select public.load_log(l_load_id, l_step_id, 'LP Traffic for  load_batch_id='||lp_cursor.load_batch_id, 0, 'I')
            into l_step_id;

            select dwh.load_flat_trade_record_inc(true, lp_cursor.trade_record_ids) into l_row_cnt;

            update public.etl_subscriptions
            set is_processed = true,
                process_time = clock_timestamp()
                                        where  load_batch_id  =  lp_cursor.load_batch_id
                                            and  subscription_name  in  ('goat.big_data.flat_trade_record',  'big_data.flat_trade_record')
                                            and  source_table_name  in  ('liquid_point_trade_record',  'liquid_point_trade_record.u')
                                            and  not  is_processed;

        end loop;

        select public.load_log(l_load_id, l_step_id, 'After LP Traffic', 0, 'I')
        into l_step_id;

        end if;
--
--/* ================================================================================================*/
--/* ====================================  PFOF =====================================================*/
--/* ================================================================================================*/
--            select public.load_log(l_load_id, l_step_id, 'START PFOF Traffic', 0, 'I')
--            into l_step_id;
--               for  subs_cursor  in  (select  distinct  date_id,  load_batch_id
--                        from staging.etl_subscriptions
--                        where subscription_name = 'big_data.flat_trade_record'
--                          and source_table_name = 'trade_level_book_record_pfof'
--                          and not is_processed)
--    loop
--        update dwh.flat_trade_record
--        set (pfof_exchange_marketing_fee, pfof_maker_taker_fee, pfof_royalty_fee, pfof_complex_rebates,
--             pfof_break_up_rebates, pfof_crossing_rebates) =
--                (commission_data.pfof_exchange_marketing_fee, commission_data.pfof_maker_taker_fee,
--                 commission_data.pfof_royalty_fee, commission_data.pfof_complex_rebates,
--                 commission_data.pfof_break_up_rebates, commission_data.pfof_crossing_rebates)
--        from (select trade_record_id,
--                     sum(case when book_record_type_id = 'EMF' then amount end)  as pfof_exchange_marketing_fee,
--                     sum(case when book_record_type_id = 'MKTK' then amount end) as pfof_maker_taker_fee,
--                     sum(case when book_record_type_id = 'RYTF' then amount end) as pfof_royalty_fee,
--                     sum(case when book_record_type_id = 'CPRB' then amount end) as pfof_complex_rebates,
--                     sum(case when book_record_type_id = 'BURB' then amount end) as pfof_break_up_rebates,
--                     sum(case when book_record_type_id = 'CRRB' then amount end) as pfof_crossing_rebates
--              from staging.trade_level_book_record
--              where load_batch_id = subs_cursor.load_batch_id
--                                                and  date_id  =  subs_cursor.date_id
--              group by trade_record_id) commission_data
--                                where  flat_trade_record.trade_record_id  =  commission_data.trade_record_id
--                                    and  flat_trade_record.date_id  =  subs_cursor.date_id;
--
--        get diagnostics row_cnt = row_count;
--
--        select public.load_log(l_load_id, l_step_id, 'PFOF Commission Updated load_batch_id = '||subs_cursor.load_batch_id , row_cnt , 'U')
--        into l_step_id;
--
--        if row_cnt > 0
--        then
--            update staging.etl_subscriptions
--            set is_processed = true,
--                process_time = clock_timestamp()
--            where load_batch_id = subs_cursor.load_batch_id
--                                            and  date_id  =  subs_cursor.date_id
--              and subscription_name = 'big_data.flat_trade_record'
--              and source_table_name = 'trade_level_book_record_pfof';
--        end if;
--    end loop;

/* ==================================================================================================*/
/* =================================  Busted Trades =================================================*/
/* ==================================================================================================*/
 --    with upd as (update staging.etl_subscriptions s
--        set is_processed = true,
--            process_time = clock_timestamp()
--        where is_processed = false
--            and subscription_name = 'big_data.flat_trade_record'
--            and source_table_name = 'TRADE_RECORD.BUSTED_TRADES'
--            and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id ) /* We need to be sure trade to bust already there */
--                        RETURNING  load_batch_id,  date_id  /*it  contains  trade_record_id  for  that  specific  source  'TRADE_RECORD.BUSTED_TRADES'*/)
--    update dwh.flat_trade_record
--    set is_busted = 'Y'
--    where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)
--      and is_busted = 'N';
--     get diagnostics row_cnt = row_count;

 with upd as (update public.etl_subscriptions s
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
            and subscription_name = 'big_data.flat_trade_record'
            and source_table_name = 'TRADE_RECORD.BUSTED_TRADES'
            and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id ) /* We need to be sure trade to bust already there */
                        RETURNING  load_batch_id,  date_id  ),
  ftr_upd as (update dwh.flat_trade_record
    set is_busted = 'Y'
    where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)
      and is_busted = 'N'),
   fyc_subs as (select count(1) as cn
   				from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,  date_id::varchar, 1)
			          from (select distinct order_id, date_id
			                from flat_trade_record
			                where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)) l ) L2 )
  select count(1)
  from (select  	public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_mira'::varchar, 'flat_trade_record'::varchar, date_id::varchar,1) ,
	    	public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_ptm'::varchar, 'flat_trade_record'::varchar, date_id::varchar,1)
 	    from 	upd  ) L1,
 	 fyc_subs
  into 	row_cnt   ;



    select public.load_log(l_load_id, l_step_id, 'Busted trades updated ', row_cnt , 'U')
    into l_step_id;


/* ==================================================================================================*/
/* =================================  NBBO based on strategy_in_l1_snapshopt ========================*/
/* ==================================================================================================*/

                if  (select  count(*)  from  pg_prepared_statements  where  name  ilike  'update_nbbo')  >  0  then
                        deallocate  update_nbbo;
                end  if;

                prepare  update_nbbo(int,  int)  as  with  md  as  (
                        select
                                nullif(nullif(st.instrument_id,-1), 1 )  as  instrument_id,
                                transaction_id,
                                start_date_id,
			                                          	sum (bid_price) as bid_price,
			                                      		sum (ask_price) as ask_price,
			                                      		sum (bid_quantity) as bid_qty,
			                                      		sum (ask_quantity ) as ask_qty
		                                         from dwh.l1_snapshot st
                  where  exchange_id  =  'NBBO'
                      and  (bid_price  is  not  null  or  ask_price  is  not  null  or
                                bid_quantity  is  not  null  or  ask_quantity  is  not  null)
		                                         and st.dataset_id = $1
		                                         and st.start_date_id = $2
		                                         group by nullif(nullif(st.instrument_id,-1), 1 ),transaction_id, start_date_id),

                         upd as (      update dwh.flat_trade_record ft
                               set routing_time_bid_price 	= coalesce(md.bid_price, routing_time_bid_price)
                                 , routing_time_bid_qty 	= coalesce(md.bid_qty, routing_time_bid_qty)
                                 , routing_time_ask_price 	= coalesce(md.ask_price, routing_time_ask_price)
                                 , routing_time_ask_qty 	= coalesce(md.ask_qty, routing_time_ask_qty)
                                 , is_street_order_marketable = null

                               from md
                               where md.transaction_id = ft.street_transaction_id
                                and (ft.multileg_reporting_type = '1' or  coalesce(md.instrument_id, ft.instrument_id) = ft.instrument_id)
                                and ft.date_id = $2
                                and (ft.routing_time_ask_price is null or routing_time_bid_price is null)
                               returning trade_record_id )
                          select count(1) from upd ;

                for  subs_cursor  in  (select  load_batch_id,  date_id
                                                        from  public.etl_subscriptions
                        where is_processed = false
		 					and subscription_name = 'flat_trade_record'
                 			and source_table_name = 'strategy_in'
                                                            and  subscribe_time  <  now()
                 			group by load_batch_id, date_id
                 			order by load_batch_id desc
                                                        limit  15)  loop

    execute 'execute update_nbbo('||subs_cursor.load_batch_id||', '||subs_cursor.date_id||')' into row_cnt;
        select public.load_log(l_load_id, l_step_id,
                               'NBBO updated load_batch_id = ' || subs_cursor.load_batch_id || ', date_id=' ||
                               subs_cursor.date_id, row_cnt, 'U')
        into l_step_id;
        /*  if row_cnt>0
           then*/
        update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
          and subscription_name = 'flat_trade_record'
          and source_table_name = 'strategy_in'
          and load_batch_id = subs_cursor.load_batch_id
          and date_id = subs_cursor.date_id;
        /*	end if;*/
    end loop;



     if  (select  extract(minute  from  now()))  in  (0,  10,  20,  30,  40,  50)  and    now()::time  between  '09:45:00.0'::time  and  '19:05:00.0'::time
       then row_cnt := dwh.fix_ftr_market_data(to_char(now(), 'YYYYMMDD')::int, l_load_id);

        select public.load_log(l_load_id, l_step_id, 'Fix Market Matching ', row_cnt, 'U')
        into l_step_id;
      end if;

/* ================================================================================================*/
/* ==================================  Street level fix  =======================================*/
/* ================================================================================================*/
    l_trade_id_to_reprint := array(select distinct load_batch_id
                                    from    (select  load_batch_id
	                                           	from  public.etl_subscriptions  es
                                   				where is_processed = false
                                     				and subscription_name = 'big_data.flat_trade_record'
		                                            and  source_table_name  in  ('trade_record_street_lvl_info','trade_record_away_lvl_info')
		                                            and  subscribe_time  <=  now()  -  interval  '1  minute'
                                                    /*for  update  skip  locked*/
		                                            order by subscribe_time desc
                                                    limit  5000)  L  );
                if  cardinality(l_trade_id_to_reprint)  >  0
                then
        select public.load_log(l_load_id, l_step_id, 'Street fix processing ', cardinality(l_trade_id_to_reprint), 'U')
        into l_step_id;

	    select dwh.load_flat_trade_record_inc(true, l_trade_id_to_reprint) into l_row_cnt;

                        select  public.load_log(l_load_id,  l_step_id,
                                                                      'Processed  '  ||  left(array_to_string(l_trade_id_to_reprint,  ',',  '*'),  235),
                                                                      cardinality(l_trade_id_to_reprint),  'U')
        into l_step_id;

	    select count(1)
        into l_row_cnt
        from (select public.etl_subscribe(trade_record_id::bigint, 'mira_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
        			--,public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
       	  	  from (select distinct trade_record_id, date_id
       	  	  		from flat_trade_record ftr
       	 			where ftr.trade_record_id = any(l_trade_id_to_reprint))l) l2;

--              		select  count(1)
--                	into  l_row_cnt
--                	from  (select  public.etl_subscribe(l_load_id::bigint,  'mira_street_lvl_fix'::varchar,  'flat_trade_record'::varchar,  date_id::varchar,  1)
--              		    	    from  (select  distinct  date_id  from  flat_trade_record  ftr
--              		  			where  ftr.trade_record_id  =  any(l_trade_id_to_reprint))l)  l2;


                        select  public.load_log(l_load_id,  l_step_id,  'Mira  subscriptions  created    ',  l_row_cnt,  'U')
                        into  l_step_id;

        update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
          and subscription_name = 'big_data.flat_trade_record'
          and source_table_name in ('trade_record_street_lvl_info','trade_record_away_lvl_info')
          and load_batch_id = any (l_trade_id_to_reprint);

	 	  get diagnostics row_cnt = row_count;

        select public.load_log(l_load_id, l_step_id, 'update staging.etl_subscriptions  ', row_cnt, 'U')
        into l_step_id;

--        select count(1)
--        into l_row_cnt
--        from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,
--                                          date_id::varchar, 1)
--              from (select distinct order_id, to_char(order_process_time, 'YYYYMMDD')::int as date_id
--                    from dwh.flat_trade_record
--                    where trade_record_id = any (l_trade_id_to_reprint)
--                                                    and  order_id  >  0
--                                                    and  order_fix_message_id  >  0
--                                                    and order_process_time::date>=current_date -3  )  L)  l2;
--
--        select public.load_log(l_load_id, l_step_id, 'subscribed  ', l_row_cnt , 'U')
--        into l_step_id;

      select count(1)
        into l_row_cnt
        from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,  date_id::varchar, 1)
                    from dwh.flat_trade_record
                    where trade_record_id = any (l_trade_id_to_reprint)
                     and  order_id  >  0
                     and  order_fix_message_id  >  0) l;

        select public.load_log(l_load_id, l_step_id, 'subscribed  ', l_row_cnt , 'U')
        into l_step_id;

       end if; /* cardinality(l_trade_id_to_reprint)>0  */

/* ================================================================================================*/
/* ==================================  Street exec_broker   =======================================*/
/* ================================================================================================*/
--		                    with  subs  as  (select  s.load_batch_id,  s.date_id
--						      from  public.etl_subscriptions  s
--							where  source_table_name  ='insert_street_exec_broker'
--			        		              and  subscription_name='big_data.flat_trade_record'
--						              and  not  is_processed),
--			              upd  as  (update  flat_trade_record  ft
--			                              set  street_exec_broker  =  lt.street_exec_broker
--						      from  subs,  staging.trade_record_late_metrics  lt
--						      where  lt.load_batch_id=subs.load_batch_id
--						          and  lt.date_id=subs.date_id
--						          and  ft.date_id  =  subs.date_id
--						          and  ft.trade_record_id  =  lt.trade_record_id
--						          returning  ft.trade_record_id)
--				  update  public.etl_subscriptions  ss
--				  set  is_processed  =  true,
--				          process_time  =  clock_timestamp()
--				    from  subs
--				  where    ss.load_batch_id=subs.load_batch_id
--				        and  ss.date_id  =  subs.date_id
--				        and  source_table_name  ='insert_street_exec_broker'
--			        	and  subscription_name='big_data.flat_trade_record'
--					and  not  is_processed;
--
--
--			      GET  DIAGNOSTICS  row_cnt  =  ROW_COUNT;
--
--		        select  public.load_log(l_load_id,  l_step_id,  'update  street_exec_broker    ',  row_cnt  ,  'U')
--	                into  l_step_id;

 else /* Manual sync */
/* ================================================================================================*/
/* ==================================  Manual Busted Trades =======================================*/
/* ================================================================================================*/

    select public.load_log(l_load_id, l_step_id, 'Processing manual busts', 1 , 'U')
    into l_step_id;

    for tr_date_id_cursor in (select date_id, array_agg(load_batch_id) as trade_to_process
                              from public.etl_subscriptions
                              where is_processed = false
                                and subscription_name = 'big_data.flat_trade_record'
                                and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
                                and (date_id, load_batch_id) in (select date_id, orig_trade_record_id
			                                                      from dwh.flat_trade_record
			                                                      where trade_record_id = any (l_tarde_record_ids)
			                                                        and orig_trade_record_id is not null
			                                                         /* for update skip locked*/)
                              group by date_id)
 --==================== Probably better query for cursor

--   for tr_date_id_cursor in ( with ct as materialized (select orig_trade_record_id
--                         								from dwh.flat_trade_record
--                          							where trade_record_id = any (l_tarde_record_ids)
--                            							and orig_trade_record_id is not null )
--								select date_id, array_agg(load_batch_id) as trade_to_process
--                              from ct
--							  inner join lateral (select date_id, load_batch_id
--												  from staging.etl_subscriptions
--                              				where is_processed = true
--                               				 	and subscription_name = 'big_data.flat_trade_record'
--                                					and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
--                                					and load_batch_id =ct.orig_trade_record_id
--												 limit 1) l on true
--                              				group by date_id)

        loop
            if cardinality(tr_date_id_cursor.trade_to_process) > 0
            then
                select public.load_log(l_load_id, l_step_id, 'Manual Bust processing ', cardinality (tr_date_id_cursor.trade_to_process) , 'U')
                into l_step_id;

                with tr as materialized (select trade_record_reason, user_id, trade_record_id
                            from genesis2.trade_record
                            where trade_record_id = any (tr_date_id_cursor.trade_to_process)
                              and date_id = tr_date_id_cursor.date_id)
                update dwh.flat_trade_record ftr
                set is_busted = 'Y',
                    trade_record_reason = tr.trade_record_reason,
                    user_id = tr.user_id
                from tr
                where ftr.is_busted = 'N'
                  and ftr.trade_record_id = tr.trade_record_id
                  and ftr.date_id = tr_date_id_cursor.date_id;

            get diagnostics row_cnt = row_count;
            select  public.load_log(l_load_id,  l_step_id,  'Processed  '  ||  left(array_to_string(tr_date_id_cursor.trade_to_process,  ',',  '*'),  200),
                                                                                row_cnt,  'U')
            into l_step_id;

             if tr_date_id_cursor.date_id::int < public.get_dateid(current_date)
              then  row_cnt  :=  dwh.fix_ftr_market_data(tr_date_id_cursor.date_id::int,  l_load_id,  l_tarde_record_ids::bigint[]);

		            select public.load_log(l_load_id, l_step_id, 'Fix Market Matching Manual for = '||tr_date_id_cursor.date_id::text , row_cnt , 'U')
		            into l_step_id;
              end if;

            -- TO REVIEW: IF we need process clearing changes there or it is already processed by some Talend job

            select public.load_log(l_load_id, l_step_id, 'updating clearing_instruction_entry... ', cardinality(tr_date_id_cursor.trade_to_process) , 'U')
            into l_step_id;

            with dt as (select clearing_instr_entry_id, new_trade_record_id
                        from dwh.clearing_instruction_entry cie
                        where new_trade_record_id = any (in_tarde_record_ids)
                          and new_trade_record_id is not null
            )
            update dwh.clearing_instruction_entry i
            set new_trade_record_id = dt.new_trade_record_id
            from dt
            where dt.clearing_instr_entry_id = i.clearing_instr_entry_id;


           select public.load_log(l_load_id, l_step_id, 'updating clearing_instructiony... ', cardinality(tr_date_id_cursor.trade_to_process) , 'U')
           into l_step_id;

            update dwh.clearing_instruction i
            set status = s.status
            from dwh.clearing_instruction s,
                 dwh.clearing_instruction_entry ie
            where ie.new_trade_record_id = any (in_tarde_record_ids)
              and ie.clearing_instr_id = s.clearing_instr_id
              and ie.new_trade_record_id is not null
              and i.clearing_instr_id = s.clearing_instr_id;

                                  select  public.load_log(l_load_id,  l_step_id,  'closing  TRADE_RECORD.MANUAL_BUST  subscriptions',
                                                                                cardinality(tr_date_id_cursor.trade_to_process),  'U')
            into l_step_id;

            declare
            begin
                update public.etl_subscriptions
                set is_processed = true,
                    process_time = clock_timestamp()
                where is_processed = false
                  and subscription_name = 'big_data.flat_trade_record'
                  and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
                  and load_batch_id = any (tr_date_id_cursor.trade_to_process);

            exception
                when others then
                    select public.load_log(l_load_id, l_step_id, sqlerrm, 0, 'E')
                    into l_step_id;
                    perform public.load_error_log('load_flat_trade_record_inc', 'I', sqlerrm, l_load_id);
            end;

            get diagnostics row_cnt = row_count;

            select public.load_log(l_load_id, l_step_id, 'update staging.etl_subscriptions  ', row_cnt, 'U')
            into l_step_id;

            with ins as (select /*public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_edw'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1),*/
                                public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_mira'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1)
                         from unnest(tr_date_id_cursor.trade_to_process) as load_batch_id)
            select count(1)
            into row_cnt
            from ins;

        select public.load_log(l_load_id, l_step_id, 'subscribed for EDW & MIRA ', row_cnt , 'I')
        into l_step_id;

       with subs as (select public.etl_subscribe(ftr.trade_record_id, 'dash_trade_record_bust_ptm'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1)
				        from   flat_trade_record ftr
				        where ftr.date_id = tr_date_id_cursor.date_id
				        and ftr.trade_record_id = any (l_tarde_record_ids)
				        and trade_record_reason is not null)
			select count(1)
            into row_cnt
            from subs;

        select public.load_log(l_load_id, l_step_id, 'subscribed for MIRA PTM', row_cnt , 'I')
        into l_step_id;
    end if;
end loop;

end if;

/*    if  in_manual_run  then
    	  update  public.flat_trade_record_mng
	  set  status=false
	  where  oparation='MANUAL_RUN';
    end  if;                                      */

        if  not  in_manual_run    then
        perform dwh.p_upd_fact_last_load_time('flat_trade_record');
        select public.load_log(l_load_id, l_step_id, 'p_upd_fact_last_load_time ', 0, 'O')
        into l_step_id;
    end if;

    select public.load_log(l_load_id, l_step_id, 'dwh.flat_trade_record COMPLETE ========= ', 0, 'O')
    into l_step_id;
    return 1;

exception
    when others then
        select public.load_log(l_load_id, l_step_id, sqlerrm, 0, 'E')
        into l_step_id;

        if (select 'ftr_comm_upd' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('ftr_comm_upd');
        end if;

        if (select 'ftr_instr_sync' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('ftr_instr_sync');
        end if;

        if (select 'ftr_comm_upd' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('err_pragma');
        end if;

        perform public.load_error_log('load_flat_trade_record_inc', 'I', sqlerrm, l_load_id);
        raise;

end;
$function$
;

























/*
not succesful install
alter table dwh.trade_record
    add constraint fk_trade_record_exchange foreign key (exchange_id) references dwh.d_exchange (exchange_unq_id);

in trade_record
is_larget_leg
user_id
*/
