alter table dash360.risk_management_modification_requests add column if not exists remarks character varying DEFAULT NULL::character varying(255);

-- DROP FUNCTION dash360.risk_management_create_request_v2(text, text, int8, int8, int8, text, text, bpchar, int4, int4, bpchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.risk_management_create_request_v2(in_scope text, in_status text,
                                                                     in_created_by_user_id bigint,
                                                                     in_account_id bigint DEFAULT NULL::bigint,
                                                                     in_trader_id bigint DEFAULT NULL::bigint,
                                                                     in_trading_firm_id text DEFAULT NULL::text,
                                                                     in_change_type text DEFAULT NULL::text,
                                                                     in_change_reason character DEFAULT NULL::text,
                                                                     in_risk_account_group_id integer DEFAULT NULL::integer,
                                                                     in_risk_tf_group_id integer DEFAULT NULL::integer,
                                                                     in_risk_management_config_type character DEFAULT NULL::character(1),
                                                                     in_symbol character varying DEFAULT NULL::character varying(10),
                                                                     in_symbol_sfx character varying DEFAULT NULL::character varying(10),
                                                                     in_symbol_list_id character varying DEFAULT NULL::character varying(6),
in_remarks character varying DEFAULT NULL::character varying(255))
    RETURNS bigint
    LANGUAGE sql
AS
$function$
INSERT INTO dash360.risk_management_modification_requests
(req_id, status, "scope", account_id, trading_firm_id, trader_id, change_type, change_reason, created_date,
 created_by_user_id, risk_account_group_id, risk_tf_group_id, risk_management_config_type, symbol, symbol_sfx,
 symbol_list_id, remarks)
VALUES (nextval('dash360.risk_management_modification_requests_req_id_seq'::regclass), in_status::bpchar,
        in_scope::bpchar, in_account_id, in_trading_firm_id::varchar, in_trader_id, in_change_type::bpchar,
        in_change_reason::bpchar, now(), in_created_by_user_id, in_risk_account_group_id, in_risk_tf_group_id,
        in_risk_management_config_type, in_symbol, in_symbol_sfx, in_symbol_list_id, in_remarks)
RETURNING req_id
$function$
;
