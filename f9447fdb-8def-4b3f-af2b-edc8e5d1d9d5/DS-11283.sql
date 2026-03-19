
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
                orig_blaze_account_alias        character varying,
                clearing_submitted_away         bpchar
            )
    LANGUAGE plpgsql
AS
$function$
    -- 20240130 AK : https://dashfinancial.atlassian.net/browse/DS-7912 added cboe_reason_code to return query
-- PD 20240530: https://dashfinancial.atlassian.net/browse/DS-8362 box_additional_client_memo and orig_box_additional_client_memo added to the output
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
-- OS 20250128 hotfix replaced 78 row with 79: join to trade_record using lateral instead of join
-- OS 20250328 https://dashfinancial.atlassian.net/browse/DS-9719 added condition date_id = date_id in a few joins
-- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
begin
    return query
        select cin.trade_record_id::bigint,
               tr.order_id                                       as parent_order_id,
               tr.client_order_id                                as parent_client_order_id,
               tr.street_client_order_id                         as client_order_id,
               i.display_instrument_id2                          as symbol,
               i.instrument_type_id,
               tr.trade_record_reason,
               i.last_trade_date                                 as maturity_date,
               tr.side,
               cin.last_px,
               cin.trade_record_time                             as exec_time,
               tr.client_id,
               real_exch.exchange_name,
               real_exch.exchange_id,
               tr.trade_liquidity_indicator                      as liquidity_indicator,
               cin.account_id                                    as account_id,
               tr.account_id::bigint                             as orig_account_id,
               acc.account_name,
               orig_acc.account_name                             as orig_account_name,
               cin.opt_customer_firm                             as capacity,
               tr.opt_customer_firm                              as orig_capacity,
               cin.open_close,
               tr.open_close                                     as orig_open_close,
               cin.last_qty,
               tr.last_qty                                       as orig_last_qty,
               cin.exec_broker                                   as gup,
               tr.exec_broker                                    as orig_gup,
               cin.cmta,
               tr.cmta                                           as orig_cmta,
               cin.clearing_account_number,
               tr.clearing_account_number                        as orig_clearing_account_number,
               cin.sub_account,
               tr.sub_account                                    as orig_sub_account,
               cin.remarks,
               tr.remarks                                        as orig_remarks,
               tf.trading_firm_name                              as tf_name,
               ci.create_time                                    as modified_time,
               alc.alloc_instr_id,
               cin.electronic_report_status                      as report_status,
               cin.street_account_name,
               tr.street_account_name                            as orig_street_account_name,
               cin.street_exec_broker,
               tr.street_exec_broker                             as orig_street_exec_broker,
               cin.client_commission_rate,
               CCRU.rate                                         as orig_client_commission_rate,
               cin.branch_sequence_number,
               tr.branch_sequence_number                         as orig_branch_sequence_number,
               cin.trade_text,
               tr.trade_text                                     as orig_trade_text,
               cin.frequent_trader_id,
               tr.frequent_trader_id                             as orig_frequent_trader_id,
               case
                   when cin.electronic_report_status in ('I', 'R')
                       then cin.electronic_report_error_text end as electronic_report_error_text,
               cin.box_additional_firm,
               cie.box_additional_firm                           as orig_box_additional_firm,
               cin.cboe_reason_code,
               cin.box_additional_client_memo,
               cie.box_additional_client_memo                    as orig_box_additional_client_memo,
               cin.blaze_account_alias,
               tr.blaze_account_alias,
               ci.clearing_submitted_away
        from genesis2.clearing_instruction_entry cin
                 inner join genesis2.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
                                                                    and cin.date_id = ci.date_id -- DS-9719 checked on PROD
                 inner join genesis2.account acc on acc.account_id = cin.account_id
                 inner join genesis2.trading_firm as tf
                            on tf.trading_firm_id = acc.trading_firm_id and tf.is_deleted = 'N'
--                 left join trade_record orig_tr on orig_tr.trade_record_id = tr.trade_record_id
                 left join lateral (select *
                                    from genesis2.trade_record orig_tr
                                    where orig_tr.trade_record_id = cin.trade_record_id
                                      and cin.date_id = orig_tr.date_id -- DS-9719
                                    limit 1) tr on true
                 left join genesis2.clearing_instruction_entry cie on cie.new_trade_record_id = tr.trade_record_id and
                                                                      cie.opt_customer_firm = tr.opt_customer_firm
                                                                          and cie.date_id = cin.date_id -- DS-9719 checked on prod
                 left join genesis2.account orig_acc on tr.account_id = orig_acc.account_id
                 left join genesis2.exchange exch on exch.exchange_id = tr.exchange_id
                 left join genesis2.exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
                 left join genesis2.instrument i on i.instrument_id = tr.instrument_id
                 left join (select AT.TRADE_RECORD_ID, A.alloc_instr_id, at.date_id
                            from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                     inner join genesis2.ALLOCATION_INSTRUCTION A
                                                on A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID AND A.IS_DELETED = 'N'
                                                    and a.date_id = at.date_id -- DS-9719 checked on PROD
        ) alc
                           on (alc.trade_record_id = coalesce(cin.new_trade_record_id, cin.trade_record_id)
                               and alc.date_id = cin.date_id)
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where ci.clearing_instr_id = in_clearing_instr_id;

end;
$function$
;


DROP FUNCTION dash360.clearing_get_change_requests(timestamp, timestamp, int8, int4);
CREATE OR REPLACE FUNCTION dash360.clearing_get_change_requests(start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                user_id bigint DEFAULT NULL::bigint,
                                                                clearing_instruction_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                clearing_instr_id                integer,
                date_id                          integer,
                status                           character,
                remarks                          character varying,
                trading_firm_names               character varying[],
                display_instrument_ids           character varying[],
                create_time                      timestamp without time zone,
                created_by_user_id               integer,
                claim_time                       timestamp without time zone,
                claimed_by_user_id               integer,
                process_time                     timestamp without time zone,
                claimed_by_user_name             character varying,
                created_by_user_name             character varying,
                modification_type                character,
                alloc_instrument_ids             integer[],
                new_trading_firm_ids             character varying[],
                account_ids                      bigint[],
                cie_agg_electronic_report_status integer,
                cie_sent_count                   integer,
                cie_rejected_count               integer,
                cie_pending_count                integer,
                cie_total_count                  integer,
                cie_accepted_count               integer,
                cie_invalid_count                integer,
                cie_not_supported_count          integer,
                clearing_submitted_away          bpchar
            )
    LANGUAGE plpgsql
    COST 1
AS $function$
    -- SY 20211112 Performance improvement https://dashfinancial.atlassian.net/browse/DS-4402
    -- SY 20211115 GTH related bug fixed https://dashfinancial.atlassian.net/browse/DS-4431
    -- SY 20220305 Joind condition by date_id has been added inside lateral join
    -- SO 20230920 removed dynamic sql
    -- SO 20230920 Add returned parameters for dash360.clearing_get_change_requests https://dashfinancial.atlassian.net/browse/DS-7287
    -- SO 20231019 cie_status -> cie_agg_electronic_report_status, cie_sent -> cie_sent_count, cie_rejected -> cie_rejected_count, cie_pending -> cie_pending_count
    -- SO 20231115 DS-7287 add cie_total_count, cie_accepted_count, count only Accepted, cie_invalid_count, count only Invalid. change counting logic for cie_rejected_count
    -- SO 20231120 DS-7287 add cie_not_supported_count
	-- MB 20260225 DS-11150 Replaced trading_firm_admin with trading_firm_admin2firm table due to Oracle DDL changes
-- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
DECLARE
--    l_clearing_instruction_id int4   := clearing_get_change_requests.clearing_instruction_id ;
--    l_user_id                 bigint := clearing_get_change_requests.user_id;
    l_clearing_instruction_id int4   := $4;
    l_user_id                 bigint := $3;
begin


    /*
=================== RUN this is performance is too pure
analyse genesis2.clearing_instruction;
analyse genesis2.user_identifier;
analyse genesis2.clearing_instruction_entry;
do $$ begin  execute 'analyse daily_partitions.trade_record_'||to_char(current_date, 'YYYYMM'); end $$;
analyse genesis2.instrument;
analyse genesis2.account;
analyse genesis2.trading_firm;
analyse clearing_instruction_entry;
analyse genesis2.alloc_instr2trade_record;
analyse genesis2.allocation_instruction;

     * */

    raise info '%: start_status_date = %', clock_timestamp(), start_status_date::text;
    raise info '%: end_status_date = %', clock_timestamp(), end_status_date::text;
    raise info '%: user_id = %', clock_timestamp(), l_user_id::text;
    raise info '%: clearing_instruction_id = %', clock_timestamp(), l_clearing_instruction_id::text;

    drop table if exists ci;
    create temp table ci on commit drop as
    select ci.clearing_instr_id,
           ci.date_id,
           ci.status,
           ci.remarks,
           ci.create_time,
           ci.created_by_user_id,
           ci.claim_time,
           ci.claimed_by_user_id,
           ci.process_time,
           claim_user.user_name  claimed_by_user_name,
           create_user.user_name created_by_user_name,
           ci.modification_type,
           ci.clearing_submitted_away
    from genesis2.clearing_instruction ci
             inner join genesis2.user_identifier create_user on create_user.user_id = ci.created_by_user_id
             left join genesis2.user_identifier claim_user on claim_user.user_id = ci.claimed_by_user_id
        -->> add
             left join lateral (select --ce.clearing_instr_id,
                                       count(*)::int                                                                as total_cnt,
                                       sum(case when electronic_report_status is not null then 1 else 0 end)::int   as status_sent,
                                       sum(case when electronic_report_status in ('I', 'R') then 1 else 0 end)::int as status_rejected,
                                       sum(case when electronic_report_status = 'P' then 1 else 0 end)::int         as status_pending,
                                       sum(case when electronic_report_status = 'A' then 1 else 0 end)::int         as status_accepted,
                                       sum(case when electronic_report_status is null then 1 else 0 end)::int       as status_null
                                from genesis2.clearing_instruction_entry ce
                                where true
                                  and ce.clearing_instr_id = ci.clearing_instr_id
                                limit 1) ce on true
    --<<
    where ci.is_deleted = 'N'
      and case
              when start_status_date is not null and end_status_date is not null
                  then ci.create_time between start_status_date and end_status_date
              else true end
      and case
              when clearing_instruction_id is not null then ci.clearing_instr_id = l_clearing_instruction_id
              else true end
      and case
              when l_user_id is not null then exists (select null
                                                      from genesis2.user_identifier ua
                                                      where ua.user_id = l_user_id
                                                        and ua.user_role = 'A'
                                                        and ua.is_deleted = 'N')
                  or (ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join staging.user2account ua
                                                                  on e.account_id = ua.account_id and
                                                                     ua.user_id = l_user_id and ua.user_role = 'P'
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(ua.account_id))
                      or
                      ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join (select acc.account_id
                                                                   from staging.trading_firm_admin2firm tf
                                                                            inner join genesis2.account acc
                                                                                       on tf.trading_firm_id = acc.trading_firm_id and acc.is_deleted = 'N'
                                                                            inner join genesis2.user_identifier ui
                                                                                       on ui.user_id = tf.user_id and ui.is_deleted = 'N'
                                                                   where ui.user_role = 'T'
                                                                     and tf.user_id = l_user_id) l
                                                                  on e.account_id = l.account_id
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(l.account_id))
                                                  )
              else true end;

    raise info '%: create temp  table ci on commit drop as', clock_timestamp();


    RETURN QUERY
        SELECT ci.clearing_instr_id,
               ci.date_id,
               ci.status,
               ci.remarks,
               o.trading_firm_names,
               o.display_instrument_ids,
               ci.create_time,
               ci.created_by_user_id,
               ci.claim_time,
               ci.claimed_by_user_id,
               ci.process_time,
               ci.claimed_by_user_name,
               ci.created_by_user_name,
               ci.modification_type,
               alc.alloc_instrument_ids,
               o.trading_firm_ids as new_trading_firm_ids,
               o.account_ids,
               case
                   when o.status_pending + o.status_rejected + o.status_invalid > 0 then 1
                   when status_accepted > 0 and total_cnt - status_accepted - not_supported = 0 then 2
                   else null end  as cie_agg_electronic_report_status,
               o.status_sent        as cie_sent_count,
               o.status_rejected    as cie_rejected_count,
               o.status_pending     as cie_pending_count,
               o.total_cnt          as cie_total_count,
               o.status_accepted    as cie_accepted_count,
               o.status_invalid     as cie_invalid_count,
               o.not_supported      as cie_not_supported_count,
               ci.clearing_submitted_away
        FROM ci
                 left join lateral (select array_agg(distinct orig_tf.trading_firm_name) trading_firm_names,
                                           array_agg(distinct ce.account_id::int8)       account_ids,
                                           array_agg(distinct acc.trading_firm_id)       trading_firm_ids,
                                           array_agg(distinct i.display_instrument_id2)  display_instrument_ids,
                                       count(*)::int                                                                as total_cnt,
                                       sum(case when electronic_report_status is not null then 1 else 0 end)::int   as status_sent,
                                       sum(case when electronic_report_status in ('R') then 1 else 0 end)::int      as status_rejected,
                                       sum(case when electronic_report_status = 'P' then 1 else 0 end)::int         as status_pending,
                                       sum(case when electronic_report_status = 'A' then 1 else 0 end)::int         as status_accepted,
                                       sum(case when electronic_report_status is null then 1 else 0 end)::int       as status_null,
                                       sum(case when electronic_report_status in ('I') then 1 else 0 end)::int      as status_invalid,
                                       sum(case when electronic_report_status in ('N') then 1 else 0 end)::int      as not_supported
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.trade_record tr on tr.trade_record_id =
                                                                                    coalesce(ce.new_trade_record_id, ce.trade_record_id) and
                                                                                    tr.date_id = ce.date_id
                                             inner join genesis2.instrument i
                                                        on i.instrument_id = tr.instrument_id and i.is_deleted = 'N'
                                             inner join genesis2.account acc
                                                        on acc.account_id = ce.account_id and acc.is_deleted = 'N'
                                             inner join genesis2.account orig_acc
                                                        on orig_acc.account_id = tr.account_id and orig_acc.is_deleted = 'N'
                                             inner join genesis2.trading_firm orig_tf
                                                        on orig_tf.trading_firm_id = orig_acc.trading_firm_id and
                                                           orig_tf.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
            ) o on 1 = 1
                 left join lateral (select ce.clearing_instr_id,
                                           array_agg(distinct a.alloc_instr_id) alloc_instrument_ids
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.alloc_instr2trade_record ai2tr
                                                        on ai2tr.trade_record_id =
                                                           coalesce(ce.new_trade_record_id, ce.trade_record_id)
                                             inner join genesis2.allocation_instruction a
                                                        on a.alloc_instr_id = ai2tr.alloc_instr_id and a.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
                                    group by ce.clearing_instr_id
                                    limit 1 ) alc on true
        order by ci.clearing_instr_id desc;

    raise info '%: DONE', clock_timestamp();

end;
$function$
;


DROP FUNCTION dash360.clearing_instruction_create;
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
-- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
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


