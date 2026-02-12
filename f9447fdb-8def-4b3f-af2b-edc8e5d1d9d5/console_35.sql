alter table dash360.risk_management_modification_requests add column if not exists remarks character varying DEFAULT NULL::character varying(255);

-- DROP FUNCTION dash360.risk_management_create_request_v2--(text, text, int8, int8, int8, text, text, bpchar, int4, int4, bpchar, varchar, varchar, varchar);

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


-- DROP FUNCTION dash360.risk_management_get_param_history_v2(text, int4, text, int8, text, int8, int4, int4, bpchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.risk_management_get_param_history_v2(in_param_code text, in_size integer,
                                                                        in_scope text,
                                                                        in_acc_id bigint DEFAULT NULL::bigint,
                                                                        in_tf_id text DEFAULT NULL::text,
                                                                        in_tr_id bigint DEFAULT NULL::bigint,
                                                                        in_risk_acc_group_id integer DEFAULT NULL::integer,
                                                                        in_risk_tf_group_id integer DEFAULT NULL::integer,
                                                                        in_risk_management_config_type character DEFAULT NULL::character(1),
                                                                        in_symbol character varying DEFAULT NULL::character varying(10),
                                                                        in_symbol_sfx character varying DEFAULT NULL::character varying(10),
                                                                        in_symbol_list_id character varying DEFAULT NULL::character varying(6))
    RETURNS TABLE
            (
                req_id                      bigint,
                status                      character,
                scope                       character,
                account_id                  bigint,
                trading_firm_id             character varying,
                trader_id                   bigint,
                change_type                 character,
                change_reason               character,
                created_date                timestamp without time zone,
                created_by_user_id          bigint,
                rejected_date               timestamp without time zone,
                rejected_by_user_id         bigint,
                approved_date               timestamp without time zone,
                approved_by_user_id         bigint,
                created_by_user             character varying,
                approved_by_user            character varying,
                rejected_by_user            character varying,
                prm_id                      bigint,
                prm_code                    character varying,
                prm_value                   character varying,
                prm_current_value           character varying,
                prm_type                    character,
                risk_acc_group_id           integer,
                risk_tf_group_id            integer,
                risk_management_config_type character,
                symbol                      character varying,
                symbol_sfx                  character varying,
                symbol_list_id              character varying,
                remarks                     character varying
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- 
--     # variable_conflict use_column
begin
    RETURN QUERY
        select r.req_id,
               r.status,
               r."scope",
               r.account_id,
               r.trading_firm_id,
               r.trader_id,
               r.change_type,
               r.change_reason,
               r.created_date,
               r.created_by_user_id,
               r.rejected_date,
               r.rejected_by_user_id,
               r.approved_date,
               r.approved_by_user_id,
               cu.user_name created_by_user,
               au.user_name approved_by_user,
               ru.user_name rejected_by_user,
               re.prm_id,
               re.prm_code,
               re.prm_value,
               re.prm_current_value,
               re.prm_type,
               r.risk_account_group_id,
               r.risk_tf_group_id,
               r.risk_management_config_type,
               r.symbol,
               r.symbol_sfx,
               r.symbol_list_id,
               r.remarks
        from dash360.risk_management_modification_requests r
                 join dash360.risk_management_modification_requests_entry re on re.req_id = r.req_id
                 join genesis2.user_identifier cu on r.created_by_user_id = cu.user_id
                 left join genesis2.user_identifier au on r.approved_by_user_id = au.user_id
                 left join genesis2.user_identifier ru on r.rejected_by_user_id = ru.user_id
        where true
          and re.prm_code = in_param_code::varchar
          and r."scope" = in_scope::bpchar
          and (in_acc_id is null or r.account_id = in_acc_id)
          and (in_tr_id is null or r.trader_id = in_tr_id)
          and (in_tf_id is null or r.trading_firm_id = in_tf_id::varchar)
          and (in_risk_tf_group_id is null or r.risk_tf_group_id = in_risk_tf_group_id)
          and (in_risk_acc_group_id is null or r.risk_account_group_id = in_risk_acc_group_id)
          and (in_risk_management_config_type is null or r.risk_management_config_type = in_risk_management_config_type)
          and (in_symbol is null or r.symbol = in_symbol)
          and (in_symbol_sfx is null or r.symbol_sfx = in_symbol_sfx)
          and (in_symbol_list_id is null or r.symbol_list_id = in_symbol_list_id)
        order by r.created_date desc -- r.approved_date desc, r.rejected_date desc,
        limit in_size;
end;
$function$
;


-- DROP FUNCTION dash360.risk_management_get_requests_v2(timestamp, timestamp, text, int8, text, int8, text, int4, int4, bpchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.risk_management_get_requests_v2(in_from timestamp without time zone, in_to timestamp without time zone, in_scope text DEFAULT NULL::text, in_acc_id bigint DEFAULT NULL::bigint, in_tf_id text DEFAULT NULL::text, in_tr_id bigint DEFAULT NULL::bigint, in_status text DEFAULT NULL::text, in_risk_acc_group_id integer DEFAULT NULL::integer, in_risk_tf_group_id integer DEFAULT NULL::integer, in_risk_management_config_type character DEFAULT NULL::character(1), in_symbol character varying DEFAULT NULL::character varying(10), in_symbol_sfx character varying DEFAULT NULL::character varying(10), in_symbol_list_id character varying DEFAULT NULL::character varying(6))
 RETURNS TABLE(req_id bigint, status character, scope character, account_id bigint, trading_firm_id character varying, trader_id bigint, change_type character, change_reason character, created_date timestamp without time zone, created_by_user_id bigint, rejected_date timestamp without time zone, rejected_by_user_id bigint, approved_date timestamp without time zone, approved_by_user_id bigint, created_by_user character varying, approved_by_user character varying, rejected_by_user character varying, prm_id bigint, prm_code character varying, prm_value character varying, prm_current_value character varying, prm_type character, risk_acc_group_id integer, risk_tf_group_id integer, risk_management_config_type character, symbol character varying, symbol_sfx character varying, symbol_list_id character varying)
 LANGUAGE plpgsql
 COST 1
AS $function$
#variable_conflict use_column
begin
	 RETURN QUERY
		SELECT r.req_id,
			   r.status,
			   r."scope",
			   r.account_id,
			   r.trading_firm_id,
			   r.trader_id,
			   r.change_type,
			   r.change_reason,
			   r.created_date,
			   r.created_by_user_id,
			   r.rejected_date,
			   r.rejected_by_user_id,
			   r.approved_date,
			   r.approved_by_user_id,
			   cu.user_name created_by_user,
			   au.user_name approved_by_user,
			   ru.user_name rejected_by_user,
			   re.prm_id,
			   re.prm_code,
			   re.prm_value,
			   re.prm_current_value,
			   re.prm_type,
			   r.risk_account_group_id,
			   r.risk_tf_group_id,
			   r.risk_management_config_type,
			   r.symbol,
			   r.symbol_sfx,
			   r.symbol_list_id
		FROM dash360.risk_management_modification_requests r
		join dash360.risk_management_modification_requests_entry re on re.req_id = r.req_id
		join genesis2.user_identifier cu on r.created_by_user_id = cu.user_id
		left join genesis2.user_identifier au on r.approved_by_user_id = au.user_id
		left join genesis2.user_identifier ru on r.rejected_by_user_id = ru.user_id
		where
			(r.created_date between in_from and in_to)
			and (in_scope is null or r."scope" = in_scope::bpchar)
			and (in_acc_id is null or r.account_id = in_acc_id)
			and (in_tr_id is null or r.trader_id = in_tr_id)
			and (in_tf_id is null or r.trading_firm_id = in_tf_id::varchar)
			and (in_status is null or r.status = in_status::bpchar)
			and (in_risk_tf_group_id is null or r.risk_tf_group_id = in_risk_tf_group_id)
			and (in_risk_acc_group_id is null or r.risk_account_group_id = in_risk_acc_group_id )
			and (in_risk_management_config_type is null or r.risk_management_config_type = in_risk_management_config_type )
			and (in_symbol is null or r.symbol = in_symbol )
			and (in_symbol_sfx is null or r.symbol_sfx = in_symbol_sfx )
			and (in_symbol_list_id is null or r.symbol_list_id = in_symbol_list_id );
end;
$function$
;


-- DROP FUNCTION dash360.risk_management_get_request_v2(int8);

CREATE OR REPLACE FUNCTION dash360.risk_management_get_request_v2(in_request_id bigint)
 RETURNS TABLE(req_id bigint, status character, scope character, account_id bigint, trading_firm_id character varying, trader_id bigint, change_type character, change_reason character, created_date timestamp without time zone, created_by_user_id bigint, rejected_date timestamp without time zone, rejected_by_user_id bigint, approved_date timestamp without time zone, approved_by_user_id bigint, created_by_user character varying, approved_by_user character varying, rejected_by_user character varying, prm_id bigint, prm_code character varying, prm_value character varying, prm_current_value character varying, prm_type character, risk_acc_group_id integer, risk_tf_group_id integer, risk_management_config_type character, symbol character varying, symbol_sfx character varying, symbol_list_id character varying)
 LANGUAGE plpgsql
 COST 1
AS $function$
#variable_conflict use_column
begin
	 RETURN QUERY
		SELECT r.req_id,
			   r.status,
			   r."scope",
			   r.account_id,
			   r.trading_firm_id,
			   r.trader_id,
			   r.change_type,
			   r.change_reason,
			   r.created_date,
			   r.created_by_user_id,
			   r.rejected_date,
			   r.rejected_by_user_id,
			   r.approved_date,
			   r.approved_by_user_id,
			   cu.user_name created_by_user,
			   au.user_name approved_by_user,
			   ru.user_name rejected_by_user,
			   re.prm_id,
			   re.prm_code,
			   re.prm_value,
			   re.prm_current_value,
			   re.prm_type,
			   r.risk_account_group_id as risk_acc_group_id,
			   r.risk_tf_group_id,
			   r.risk_management_config_type,
			   r.symbol,
			   r.symbol_sfx,
			   r.symbol_list_id
		FROM dash360.risk_management_modification_requests r
		join dash360.risk_management_modification_requests_entry re on re.req_id = r.req_id
		join genesis2.user_identifier cu on r.created_by_user_id = cu.user_id
		left join genesis2.user_identifier au on r.approved_by_user_id = au.user_id
		left join genesis2.user_identifier ru on r.rejected_by_user_id = ru.user_id
		where r.req_id = in_request_id;
end;
$function$
;


