-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
and routine_name ilike '%clearing_get_trades_by_trade_record_id%'

select * from genesis2.clearing_instruction_entry;

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
