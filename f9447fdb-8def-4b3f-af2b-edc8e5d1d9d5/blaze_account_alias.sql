/*
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
and routine_name ilike '%clearing_post%'

select * from genesis2.clearing_instruction_entry;
*/
alter table genesis2.clearing_instruction_entry
    add column if not exists blaze_account_alias varchar(255) null;
comment on column genesis2.clearing_instruction_entry.blaze_account_alias is 'Base on EDWDilling..TOrder_EDW.AccountAlias. Filled for blaze traffic only';


-- DROP FUNCTION dash360.clearing_instruction_create(int4, bpchar, int4, bpchar, varchar);

CREATE OR REPLACE FUNCTION dash360.clearing_instruction_create(in_date_id integer, in_clearing_status character,
                                                               in_user_id integer, in_modification_type character,
                                                               in_json_values character varying)
    RETURNS TABLE
            (
                trade_json    character varying[],
                clearing_json character varying[]
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
-- AK 20231129 : https://dashfinancial.atlassian.net/browse/D360-12491 added cboe_reason_code field to insert into genesis2.clearing_instruction_entry
-- PD 20240530 : https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo field to insert statement
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
declare

    l_clearing_instr_id       int;
    l_clearing_instr_entry_id int;
    trade_json                varchar[];
    clearing_json             varchar[];

begin
    --VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
--insert into clearing_instruction
    insert into genesis2.clearing_instruction
    (clearing_instr_id, date_id, status, created_by_user_id, modification_type)
    values (nextval('clearing_instruction_clearing_instr_id_seq'::regclass), in_date_id, in_clearing_status, in_user_id,
            in_modification_type)
    returning clearing_instr_id into l_clearing_instr_id;

    /*INSERT INTO genesis2.clearing_instruction_entry
    (clearing_instr_entry_id, date_id, clearing_instr_id, trade_record_id, account_id, opt_customer_firm, open_close, last_qty, last_px, exec_broker, cmta, clearing_account_number, sub_account, remarks, trade_record_time, street_exec_broker, client_commission_rate, branch_sequence_number, trade_text, frequent_trader_id)
    VALUES(nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass), in_date_id, l_clearing_instr_id, @TradeRecordId, @AccountId, @Capacity, @OpenClose, @LastQty, @LastPx, @ExecBroker, @CMTA, @ClearingAccountNumber, @SubAccount, @Remarks, @TradeRecordTime, @StreetExecBroker, @CommissionRate, @BranchSeqNbr, @TradeText, @FrequentTraderId)
    returning clearing_instr_entry_id;*/

--insert into clearing_instruction_entry (most of values are from input param in_json_values)
    with ct as (select in_json_values::json as jsn),
         trd_ids as (select json_object_keys(jsn) as old_trade_record_id
                     from ct),
         tr_values as (select trd_ids.old_trade_record_id,
                              ct.jsn -> trd_ids.old_trade_record_id val_arr
                       from ct,
                            trd_ids)
    insert
    into genesis2.clearing_instruction_entry (clearing_instr_entry_id, date_id, clearing_instr_id, new_trade_record_id,
                                              trade_record_id, account_id, opt_customer_firm, open_close, last_qty,
                                              last_px, exec_broker, cmta, clearing_account_number,
                                              trade_liquidity_indicator, sub_account, remarks, trade_record_time,
                                              electronic_report_status, street_account_name, street_exec_broker,
                                              client_commission_rate, trade_text, branch_sequence_number,
                                              frequent_trader_id, box_additional_firm, electronic_report_error_text,
                                              cboe_reason_code, box_additional_client_memo, blaze_account_alias)
    select nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass),
           in_date_id,
           l_clearing_instr_id,
           (l.value ->> 'new_trade_record_id')::bigint,
           tr_values.old_trade_record_id::bigint,
           (l.value ->> 'account_id')::int,
           (l.value ->> 'opt_customer_firm')::bpchar,
           (l.value ->> 'open_close')::bpchar,
           (l.value ->> 'last_qty')::int,
           (l.value ->> 'last_px')::numeric,
           (l.value ->> 'exec_broker')::varchar,
           (l.value ->> 'cmta')::varchar,
           (l.value ->> 'clearing_account_number')::varchar,
           (l.value ->> 'trade_liquidity_indicator')::varchar,
           (l.value ->> 'sub_account')::varchar,
           (l.value ->> 'remarks')::varchar,
           (l.value ->> 'trade_record_time')::timestamp,
           (l.value ->> 'electronic_report_time')::varchar,
           (l.value ->> 'street_account_name')::varchar,
           (l.value ->> 'street_exec_broker')::varchar,
           (l.value ->> 'client_commission_rate')::numeric,
           (l.value ->> 'trade_text')::varchar,
           (l.value ->> 'branch_sequence_number')::varchar,
           (l.value ->> 'frequent_trader_id')::varchar,
           (l.value ->> 'box_additional_firm')::varchar,
           (l.value ->> 'electronic_report_error_text')::varchar,
           (l.value ->> 'cboe_reason_code')::varchar as r,
           (l.value ->> 'box_additional_client_memo')::varchar,
           l.value ->> 'blaze_account_alias'
    from tr_values,
         json_array_elements(tr_values.val_arr) l;

    select array_agg(row_to_json(cte))
    into trade_json
    from (select l_clearing_instr_id as clearing_instr_id, *
          from dash360.clearing_instruction_modifications(l_clearing_instr_id)) cte;

    select array_agg(row_to_json(cte))
    into clearing_json
    from (select *
          from dash360.clearing_get_change_requests(clearing_instruction_id=>l_clearing_instr_id)) cte;

    return query
        select trade_json, clearing_json;


end;
$function$
;


-- compare 1 PROD

DROP FUNCTION dash360.clearing_instruction_modifications(int4);

CREATE OR REPLACE FUNCTION dash360.clearing_instruction_modifications(in_clearing_instr_id integer)
    RETURNS TABLE
            (
                trade_record_id                 bigint,
                parent_order_id                 bigint,
                parent_client_order_id          character varying,
                client_order_id                 character varying,
                symbol                          character varying,
                instrument_type_id              character,
                trade_record_reason             character,
                maturity_date                   timestamp without time zone,
                side                            character,
                last_px                         numeric,
                exec_time                       timestamp without time zone,
                client_id                       character varying,
                exchange_name                   character varying,
                exchange_id                     character varying,
                liquidity_indicator             character varying,
                account_id                      integer,
                orig_account_id                 bigint,
                account_name                    character varying,
                orig_account_name               character varying,
                capacity                        character,
                orig_capacity                   character,
                open_close                      character,
                orig_open_close                 character,
                last_qty                        integer,
                orig_last_qty                   integer,
                gup                             character varying,
                orig_gup                        character varying,
                cmta                            character varying,
                orig_cmta                       character varying,
                clearing_account_number         character varying,
                orig_clearing_account_number    character varying,
                sub_account                     character varying,
                orig_sub_account                character varying,
                remarks                         character varying,
                orig_remarks                    character varying,
                tf_name                         character varying,
                modified_time                   timestamp without time zone,
                alloc_instr_id                  integer,
                report_status                   character,
                street_account_name             character varying,
                orig_street_account_name        character varying,
                street_exec_broker              character varying,
                orig_street_exec_broker         character varying,
                client_commission_rate          numeric,
                orig_client_commission_rate     numeric,
                branch_sequence_number          character varying,
                orig_branch_sequence_number     character varying,
                trade_text                      character varying,
                orig_trade_text                 character varying,
                frequent_trader_id              character varying,
                orig_frequent_trader_id         character varying,
                electronic_report_error_text    character varying,
                box_additional_firm             character varying,
                orig_box_additional_firm        character varying,
                cboe_reason_code                character varying,
                box_additional_client_memo      character varying,
                orig_box_additional_client_memo character varying,
                blaze_account_alias             character varying,
                orig_blaze_account_alias        character varying
            )
    LANGUAGE plpgsql
AS
$function$
-- 20240130 AK : https://dashfinancial.atlassian.net/browse/DS-7912 added cboe_reason_code to return query
-- PD 20240530: https://dashfinancial.atlassian.net/browse/DS-8362 box_additional_client_memo and orig_box_additional_client_memo added to the output
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
begin
    return query
        select tr.trade_record_id::bigint,
               orig_tr.order_id                              as parent_order_id,
               orig_tr.client_order_id                       as parent_client_order_id,
               orig_tr.street_client_order_id                as client_order_id,
               i.display_instrument_id2                      as symbol,
               i.instrument_type_id,
               orig_tr.trade_record_reason,
               i.last_trade_date                             as maturity_date,
               orig_tr.side,
               tr.last_px,
               tr.trade_record_time                          as exec_time,
               orig_tr.client_id,
               real_exch.exchange_name,
               real_exch.exchange_id,
               orig_tr.trade_liquidity_indicator             as liquidity_indicator,
               tr.account_id                                 as account_id,
               orig_tr.account_id::bigint                    as orig_account_id,
               acc.account_name,
               orig_acc.account_name                         as orig_account_name,
               tr.opt_customer_firm                          as capacity,
               orig_tr.opt_customer_firm                     as orig_capacity,
               tr.open_close,
               orig_tr.open_close                            as orig_open_close,
               tr.last_qty,
               orig_tr.last_qty                              as orig_last_qty,
               tr.exec_broker                                as gup,
               orig_tr.exec_broker                           as orig_gup,
               tr.cmta,
               orig_tr.cmta                                  as orig_cmta,
               tr.clearing_account_number,
               orig_tr.clearing_account_number               as orig_clearing_account_number,
               tr.sub_account,
               orig_tr.sub_account                           as orig_sub_account,
               tr.remarks,
               orig_tr.remarks                               as orig_remarks,
               tf.trading_firm_name                          as tf_name,
               ci.create_time                                as modified_time,
               alc.alloc_instr_id,
               tr.electronic_report_status                      report_status,
               tr.street_account_name,
               orig_tr.street_account_name                   as orig_street_account_name,
               tr.street_exec_broker,
               orig_tr.street_exec_broker                    as orig_street_exec_broker,
               tr.client_commission_rate,
               CCRU.rate                                     as orig_client_commission_rate,
               tr.branch_sequence_number,
               orig_tr.branch_sequence_number                as orig_branch_sequence_number,
               tr.trade_text,
               orig_tr.trade_text                            as orig_trade_text,
               tr.frequent_trader_id,
               orig_tr.frequent_trader_id                    as orig_frequent_trader_id,
               case
                   when tr.electronic_report_status in ('I', 'R')
                       then tr.electronic_report_error_text end as electronic_report_error_text,
               tr.box_additional_firm,
               cie.box_additional_firm						 as orig_box_additional_firm,
               tr.cboe_reason_code,
               tr.box_additional_client_memo,
               cie.box_additional_client_memo as orig_box_additional_client_memo,
               tr.blaze_account_alias,
               orig_tr.blaze_account_alias
        from clearing_instruction_entry tr
                 inner join clearing_instruction ci on ci.clearing_instr_id = tr.clearing_instr_id
                 inner join account acc on acc.account_id = tr.account_id
                 inner join trading_firm as tf on tf.trading_firm_id = acc.trading_firm_id and tf.is_deleted = 'N'
                 left join trade_record orig_tr on orig_tr.trade_record_id = tr.trade_record_id
                 left join clearing_instruction_entry cie on cie.new_trade_record_id = orig_tr.trade_record_id and cie.opt_customer_firm = orig_tr.opt_customer_firm
                 left join account orig_acc on orig_tr.account_id = orig_acc.account_id
                 left join exchange exch on exch.exchange_id = orig_tr.exchange_id
                 left join exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
                 left join instrument i on i.instrument_id = orig_tr.instrument_id
                 left join (select AT.TRADE_RECORD_ID, A.alloc_instr_id
                            from ALLOC_INSTR2TRADE_RECORD AT
                                     inner join ALLOCATION_INSTRUCTION A
                                                on A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID AND A.IS_DELETED = 'N') alc
                           on (alc.trade_record_id = coalesce(tr.new_trade_record_id, tr.trade_record_id))
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = orig_tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where ci.clearing_instr_id = in_clearing_instr_id;

end;
$function$
;


-- DROP FUNCTION dash360.clearing_instruction_entries(timestamp, timestamp, _varchar, _varchar, _varchar, _varchar, _varchar, int4);

CREATE OR REPLACE FUNCTION dash360.clearing_instruction_entries(in_start_date timestamp without time zone, in_end_date timestamp without time zone DEFAULT (now())::timestamp without time zone, in_symbol character varying[] DEFAULT '{}'::character varying[], in_electronic_report_status character varying[] DEFAULT '{}'::character varying[], in_status character varying[] DEFAULT '{}'::character varying[], in_exchange_id character varying[] DEFAULT '{}'::character varying[], in_root_symbol character varying[] DEFAULT '{}'::character varying[], in_limit integer DEFAULT 30)
 RETURNS TABLE(trade_record_id bigint, parent_order_id bigint, parent_client_order_id character varying, client_order_id character varying, symbol character varying, instrument_type_id character, trade_record_reason character, maturity_date timestamp without time zone, side character, last_px numeric, exec_time timestamp without time zone, client_id character varying, exchange_name character varying, exchange_id character varying, liquidity_indicator character varying, account_id integer, orig_account_id bigint, account_name character varying, orig_account_name character varying, capacity character, orig_capacity character, open_close character, orig_open_close character, last_qty integer, orig_last_qty integer, gup character varying, orig_gup character varying, cmta character varying, orig_cmta character varying, clearing_account_number character varying, orig_clearing_account_number character varying, sub_account character varying, orig_sub_account character varying, remarks character varying, orig_remarks character varying, tf_name character varying, modified_time timestamp without time zone, alloc_instr_id integer, report_status character, street_account_name character varying, orig_street_account_name character varying, street_exec_broker character varying, orig_street_exec_broker character varying, client_commission_rate numeric, orig_client_commission_rate numeric, branch_sequence_number character varying, orig_branch_sequence_number character varying, trade_text character varying, orig_trade_text character varying, frequent_trader_id character varying, orig_frequent_trader_id character varying, electronic_report_error_text character varying, box_additional_firm character varying, orig_box_additional_firm character varying, created_by_user_id integer, created_by_user_name character varying, modification_type character, status character, claimed_by_user_id integer, claimed_by_user_name character varying, clearing_instr_id integer, create_time timestamp without time zone, clearing_instr_entry_id integer, box_additional_client_memo character varying, exch_exec_id character varying, secondary_exch_exec_id character varying, blaze_account_alias character varying)
 LANGUAGE plpgsql
AS $function$
begin
--VP 20240125 https://dashfinancial.atlassian.net/browse/DS-7622
--PD 20240530 https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo to the output
--VP 20240703 https://dashfinancial.atlassian.net/browse/DS-8530 filter out by real_exchange_id instead of exchange_id
--VP 20241010 https://dashfinancial.atlassian.net/browse/DS-8688 Add new fields to DB procedure `dash360.clearing_instruction_entries` - exch_exec_id, secondary_exch_exec_id
--OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
    return query
select tr.trade_record_id::bigint,
               orig_tr.order_id                              as parent_order_id,
               orig_tr.client_order_id                       as parent_client_order_id,
               orig_tr.street_client_order_id                as client_order_id,
               i.display_instrument_id2                      as symbol,
               i.instrument_type_id,
               orig_tr.trade_record_reason,
               i.last_trade_date                             as maturity_date,
               orig_tr.side,
               tr.last_px,
               tr.trade_record_time                          as exec_time,
               orig_tr.client_id,
               real_exch.exchange_name,
               real_exch.exchange_id,
               orig_tr.trade_liquidity_indicator             as liquidity_indicator,
               tr.account_id                                 as account_id,
               orig_tr.account_id::bigint                    as orig_account_id,
               acc.account_name,
               orig_acc.account_name                         as orig_account_name,
               tr.opt_customer_firm                          as capacity,
               orig_tr.opt_customer_firm                     as orig_capacity,
               tr.open_close,
               orig_tr.open_close                            as orig_open_close,
               tr.last_qty,
               orig_tr.last_qty                              as orig_last_qty,
               tr.exec_broker                                as gup,
               orig_tr.exec_broker                           as orig_gup,
               tr.cmta,
               orig_tr.cmta                                  as orig_cmta,
               tr.clearing_account_number,
               orig_tr.clearing_account_number               as orig_clearing_account_number,
               tr.sub_account,
               orig_tr.sub_account                           as orig_sub_account,
               tr.remarks,
               orig_tr.remarks                               as orig_remarks,
               tf.trading_firm_name                          as tf_name,
               ci.create_time                                as modified_time,
               alc.alloc_instr_id,
               tr.electronic_report_status                      report_status,
               tr.street_account_name,
               orig_tr.street_account_name                   as orig_street_account_name,
               tr.street_exec_broker,
               orig_tr.street_exec_broker                    as orig_street_exec_broker,
               tr.client_commission_rate,
               CCRU.rate                                     as orig_client_commission_rate,
               tr.branch_sequence_number,
               orig_tr.branch_sequence_number                as orig_branch_sequence_number,
               tr.trade_text,
               orig_tr.trade_text                            as orig_trade_text,
               tr.frequent_trader_id,
               orig_tr.frequent_trader_id                    as orig_frequent_trader_id,
               case
                   when tr.electronic_report_status in ('I', 'R')
                       then tr.electronic_report_error_text end as electronic_report_error_text,
               tr.box_additional_firm,
               cie.box_additional_firm						 as orig_box_additional_firm,
               ci.created_by_user_id,
               ui_created.user_name created_by_user_name,
               ci.modification_type,
               ci.status,
               ci.claimed_by_user_id,
               ui_claimed.user_name claimed_by_user_name,
               tr.clearing_instr_id,
               ci.create_time,
               tr.clearing_instr_entry_id,
               tr.box_additional_client_memo,
			   orig_tr.exch_exec_id,
			   orig_tr.secondary_exch_exec_id,
			   tr.blaze_account_alias
        from genesis2.clearing_instruction_entry tr
                 inner join genesis2.clearing_instruction ci on ci.clearing_instr_id = tr.clearing_instr_id
                 inner join genesis2.account acc on acc.account_id = tr.account_id
                 inner join genesis2.trading_firm as tf on tf.trading_firm_id = acc.trading_firm_id and tf.is_deleted = 'N'
                 left join genesis2.trade_record orig_tr on orig_tr.trade_record_id = tr.trade_record_id
                 left join genesis2.clearing_instruction_entry cie on cie.new_trade_record_id = orig_tr.trade_record_id and cie.opt_customer_firm = orig_tr.opt_customer_firm
                 left join genesis2.account orig_acc on orig_tr.account_id = orig_acc.account_id
                 left join genesis2.exchange exch on exch.exchange_id = orig_tr.exchange_id
                 left join genesis2.exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
                 left join genesis2.instrument i on i.instrument_id = orig_tr.instrument_id
				 left join genesis2.user_identifier ui_created on ci.created_by_user_id =ui_created.user_id
				 left join genesis2.user_identifier ui_claimed on ci.claimed_by_user_id =ui_claimed.user_id
                 left join (select AT.TRADE_RECORD_ID, A.alloc_instr_id
                            from ALLOC_INSTR2TRADE_RECORD AT
                                     inner join ALLOCATION_INSTRUCTION A
                                                on A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID AND A.IS_DELETED = 'N') alc
                           on (alc.trade_record_id = coalesce(tr.new_trade_record_id, tr.trade_record_id))
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = orig_tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where ci.create_time between in_start_date and in_end_date
        and case when in_symbol = '{}' then true else i.display_instrument_id2 = any(in_symbol) end
        and case when in_electronic_report_status = '{}' then true else tr.electronic_report_status = any(in_electronic_report_status)end
        and case when in_status = '{}' then true else ci.status = any(in_status) end
        and case when in_exchange_id = '{}' then true else real_exch.real_exchange_id = any(in_exchange_id) end
        and case when in_root_symbol = '{}' then true else i.symbol = any(in_root_symbol) end
        limit(in_limit);
end;
$function$
;

select * from dash360.clearing_instruction_modifications(in_clearing_instr_id := -1);
select * from dash360.clearing_instruction_entries('2024-11-28', '2023-11-29')