-- DROP FUNCTION dash360.clearing_instruction_create(int4, bpchar, int4, bpchar, varchar);

CREATE OR REPLACE FUNCTION dash360.clearing_instruction_create(in_date_id integer, in_clearing_status character,
                                                               in_user_id integer, in_modification_type character,
                                                               in_json_values character varying,
                                                               in_clearing_submitted_away bpchar default 'N')
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
-- OS 20250129 https://dashfinancial.atlassian.net/browse/DS-9502 add logging
declare

    l_clearing_instr_id       int;
    trade_json                varchar[];
    clearing_json             varchar[];
    l_msg_text                text;
    l_load_id                 int;
    l_step_id                 int;
    l_row_cnt                 int4;

begin
    l_msg_text :=
            'clearing_instruction_create for ' || in_date_id::text || ', clearing status: ' || in_clearing_status ||
            ', user_id: ' || in_user_id::text || ', modification_type: ' || in_modification_type ||
            ', clearing_submitted_away: ' || in_clearing_submitted_away::text||'. ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || '  STARTED ====', 0, 'O')
    into l_step_id;

    --VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
--insert into clearing_instruction
    insert into genesis2.clearing_instruction
    (clearing_instr_id, date_id, status, created_by_user_id, modification_type, clearing_submitted_away)
    values (nextval('clearing_instruction_clearing_instr_id_seq'::regclass), in_date_id, in_clearing_status, in_user_id,
            in_modification_type, in_clearing_submitted_away)
    returning clearing_instr_id into l_clearing_instr_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || '  Step 1 - insert into genesis2.clearing_instruction',
                           l_row_cnt, 'I')
    into l_step_id;
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
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_msg_text || '  Step 2 - insert into genesis2.clearing_instruction_entry', l_row_cnt, 'I')
    into l_step_id;

    select array_agg(row_to_json(cte))
    into trade_json
    from (select l_clearing_instr_id as clearing_instr_id, *
          from dash360.clearing_instruction_modifications(l_clearing_instr_id)) cte;

    select public.load_log(l_load_id, l_step_id, l_msg_text || '  Step 3 - clearing_instruction_modifications',
                           l_row_cnt, 'O')
    into l_step_id;

    select array_agg(row_to_json(cte))
    into clearing_json
    from (select *
          from dash360.clearing_get_change_requests(clearing_instruction_id=>l_clearing_instr_id)) cte;

    select public.load_log(l_load_id, l_step_id,
                           l_msg_text || '  Step 4 - clearing_get_change_requests and COMPLETED ========', 0, 'O')
    into l_step_id;

    return query
        select trade_json, clearing_json;


end;
$function$
;
