-- PROD
-- DROP FUNCTION dash360.clearing_select_trades_for_bundle(int4, int8, int8, varchar, varchar, varchar, varchar, varchar, date, varchar, bpchar, varchar, bpchar, date, varchar);

CREATE OR REPLACE FUNCTION dash360.clearing_select_trades_for_bundle(in_date_id integer, in_account_id bigint,
                                                                     in_instrument_id bigint,
                                                                     in_client_id character varying,
                                                                     in_side character varying,
                                                                     in_execbroker character varying,
                                                                     in_cmta character varying,
                                                                     in_capacity character varying, in_trade_date date,
                                                                     in_account_name character varying,
                                                                     in_instrument_type_id character,
                                                                     in_display_instrument_id character varying,
                                                                     in_open_close character, in_last_trade_date date,
                                                                     in_street_mpid character varying)
    RETURNS TABLE
            (
                trade_record_id           bigint,
                orig_trade_record_id      bigint,
                trade_record_reason       character,
                is_busted                 character,
                trade_record_time         timestamp without time zone,
                account_id                bigint,
                side                      character,
                open_close                character,
                instrument_id             bigint,
                instrument_type_id        character,
                display_instrument_id     character varying,
                last_qty                  integer,
                last_px                   numeric,
                exec_broker               character varying,
                opt_customer_firm         character,
                clearing_account_number   character varying,
                sub_account               character varying,
                cmta                      character varying,
                real_exchange_id          character varying,
                remarks                   character varying,
                trade_liquidity_indicator character varying,
                last_trade_date           timestamp without time zone,
                street_exec_broker        character varying,
                street_account_name       character varying,
                client_commission_rate    numeric,
                blaze_account_alias       character varying,
                branch_sequence_number    character varying,
                trade_text                character varying,
                frequent_trader_id        character varying,
                date_id                   integer,
                street_mpid               character varying
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
begin
    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_reason,
               tr.is_busted,
               tr.trade_record_time,
               tr.account_id::bigint,
               tr.side,
               tr.open_close,
               i.instrument_id,
               i.instrument_type_id,
               i.display_instrument_id2 display_instrument_id,
               tr.last_qty,
               tr.last_px,
               tr.exec_broker,
               tr.opt_customer_firm,
               tr.clearing_account_number,
               tr.sub_account,
               tr.cmta,
               e.real_exchange_id,
               tr.remarks,
               tr.trade_liquidity_indicator,
               i.last_trade_date,
               tr.street_exec_broker,
               tr.street_account_name,
               CCRU.rate as             client_commission_rate,
               tr.blaze_account_alias,
               tr.branch_sequence_number,
               tr.trade_text,
               tr.frequent_trader_id,
               tr.date_id,
               tr.street_mpid
        from genesis2.trade_record tr
                 inner join genesis2.instrument i
                            on (tr.instrument_id = i.instrument_id)
                 left join genesis2.exchange e
                           on e.exchange_id = tr.exchange_id and e.is_active = 'Y'
                 left join genesis2.account a
                           on a.account_id = tr.account_id
                 left join lateral
            (
            select L1.rate
            from (SELECT row_number()
                         over (partition by tl.trade_record_id ,book_record_type_id ,billing_entity order by cr.priority) as rn,
                         tl.rate
                  FROM genesis2.trade_level_book_record tl
                           inner join genesis2.book_record_creator cr
                                      on tl.book_record_creator_id = cr.book_record_creator_id
                  WHERE tl.date_id = in_date_id
                    AND book_record_type_id = 'CCRU'
                    and tl.trade_record_id = tr.trade_record_id) L1
            where rn = 1
            ) CCRU on true
        where tr.date_id = in_date_id
          and tr.is_busted = 'N'
          and tr.account_id = in_account_id
          and tr.instrument_id = in_instrument_id
          and case when in_client_id is null then tr.client_id is null else tr.client_id = in_client_id end
          and tr.side = in_side
          and case when in_execbroker is null then tr.exec_broker is null else tr.exec_broker = in_execbroker end
          and case when in_cmta is null then tr.cmta is null else tr.cmta = in_cmta end
          and case
                  when in_capacity is null then tr.opt_customer_firm is null
                  else tr.opt_customer_firm = in_capacity end
          and tr.trade_record_time::date = in_trade_date
          and a.account_name = in_account_name
          and i.instrument_type_id = in_instrument_type_id
          and i.display_instrument_id2 = in_display_instrument_id
          and case when in_open_close is null then tr.open_close is null else tr.open_close = in_open_close end
          and case
                  when in_last_trade_date is null then i.last_trade_date is null
                  else i.last_trade_date::date = in_last_trade_date end
          and case when in_street_mpid is null then tr.street_mpid is null else tr.street_mpid = in_street_mpid end;
end;
$function$
;

-- DROP FUNCTION dash360.clearing_get_trade_by_client_order_id(int4, _varchar);

CREATE OR REPLACE FUNCTION dash360.clearing_get_trade_by_client_order_id(in_date_id integer, in_client_order_id character varying[])
    RETURNS TABLE
            (
                trade_record_id           bigint,
                orig_trade_record_id      bigint,
                trade_record_reason       character,
                is_busted                 character,
                trade_record_time         timestamp without time zone,
                account_id                bigint,
                side                      character,
                open_close                character,
                instrument_type_id        character,
                display_instrument_id     character varying,
                last_qty                  integer,
                last_px                   numeric,
                exec_broker               character varying,
                opt_customer_firm         character,
                clearing_account_number   character varying,
                sub_account               character varying,
                cmta                      character varying,
                real_exchange_id          character varying,
                remarks                   character varying,
                trade_liquidity_indicator character varying,
                last_trade_date           timestamp without time zone,
                street_exec_broker        character varying,
                street_account_name       character varying,
                blzae_account_alias       character varying,
                branch_sequence_number    character varying,
                trade_text                character varying,
                frequent_trader_id        character varying,
                date_id                   integer
            )
    LANGUAGE plpgsql
AS
$function$
-- PD 20211115 https://dashfinancial.atlassian.net/browse/DS-4425
begin

    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_reason,
               tr.is_busted,
               tr.trade_record_time,
               tr.account_id,
               tr.side,
               tr.open_close,
               i.instrument_type_id,
               i.display_instrument_id2 display_instrument_id,
               tr.last_qty,
               tr.last_px,
               tr.exec_broker,
               tr.opt_customer_firm,
               tr.clearing_account_number,
               tr.sub_account,
               tr.cmta,
               e.real_exchange_id,
               tr.remarks,
               tr.trade_liquidity_indicator,
               i.last_trade_date,
               tr.street_exec_broker,
               tr.street_account_name,
               tr.blaze_account_alias,
               tr.branch_sequence_number,
               tr.trade_text,
               tr.frequent_trader_id,
               tr.date_id
        from trade_record tr
                 inner join instrument i on tr.instrument_id = i.instrument_id
                 left join exchange e on e.exchange_id = tr.exchange_id and e.is_active = 'Y'
        where tr.date_id = in_date_id
          and tr.is_busted = 'N'
          and tr.client_order_id = any (in_client_order_id);

end;
$function$
;

-- DROP FUNCTION dash360.clearing_get_trades_by_trade_record_id(int4, _int8);

CREATE OR REPLACE FUNCTION dash360.clearing_get_trades_by_trade_record_id(in_date_id integer, in_trade_record_id bigint[])
    RETURNS TABLE
            (
                trade_record_id            bigint,
                orig_trade_record_id       bigint,
                trade_record_reason        character,
                is_busted                  character,
                trade_record_time          timestamp without time zone,
                account_id                 bigint,
                side                       character,
                open_close                 character,
                instrument_id              bigint,
                instrument_type_id         character,
                display_instrument_id      character varying,
                last_qty                   integer,
                last_px                    numeric,
                exec_broker                character varying,
                opt_customer_firm          character,
                clearing_account_number    character varying,
                sub_account                character varying,
                cmta                       character varying,
                real_exchange_id           character varying,
                remarks                    character varying,
                trade_liquidity_indicator  character varying,
                last_trade_date            timestamp without time zone,
                street_exec_broker         character varying,
                street_account_name        character varying,
                client_commission_rate     numeric,
                blaze_account_alias        character varying,
                branch_sequence_number     character varying,
                trade_text                 character varying,
                frequent_trader_id         character varying,
                date_id                    integer,
                box_additional_firm        character varying,
                cboe_reason_code           character varying,
                box_additional_client_memo character varying,
                alloc_instr_id             integer
            )
    LANGUAGE plpgsql
AS
$function$
begin
    -- VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
    -- AK 20230921 https://dashfinancial.atlassian.net/browse/DS-7299 has been chnaged cie.trade_record_id = tr.trade_record_id to cie.new_trade_record_id = tr.trade_record_id
    -- AK 20231129 https://dashfinancial.atlassian.net/browse/D360-12491 added cboe_reason_code field to return table
    -- PD 20240530 https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo to output
    -- OS 20260325 https://dashfinancial.atlassian.net/browse/DS-11311 add alloc_instr_id to clearing_select_trades_for_validation as return param
    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_reason,
               tr.is_busted,
               tr.trade_record_time,
               tr.account_id::bigint,
               tr.side,
               tr.open_close,
               i.instrument_id,
               i.instrument_type_id,
               i.display_instrument_id2 as display_instrument_id,
               tr.last_qty,
               tr.last_px,
               tr.exec_broker,
               tr.opt_customer_firm,
               tr.clearing_account_number,
               tr.sub_account,
               tr.cmta,
               e.real_exchange_id,
               tr.remarks,
               tr.trade_liquidity_indicator,
               i.last_trade_date,
               tr.street_exec_broker,
               tr.street_account_name,
               CCRU.rate                as client_commission_rate,
               tr.blaze_account_alias,
               tr.branch_sequence_number,
               tr.trade_text,
               tr.frequent_trader_id,
               tr.date_id,
               cie.box_additional_firm,
               cie.cboe_reason_code,
               cie.box_additional_client_memo,
               aitr.alloc_instr_id
        from trade_record tr
                 inner join instrument i on (tr.instrument_id = i.instrument_id)
                 left join exchange e on e.exchange_id = tr.exchange_id and e.is_active = 'Y'
                 left join clearing_instruction_entry cie on cie.new_trade_record_id = tr.trade_record_id and
                                                             cie.opt_customer_firm = tr.opt_customer_firm
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id
                                            and tl.date_id >= in_date_id) l1
                                    where rn = 1
            ) CCRU on true
                 left join lateral (select ar.alloc_instr_id
                                    from genesis2.alloc_instr2trade_record ar
                                    where ar.date_id = in_date_id
                                      and ar.trade_record_id = tr.trade_record_id
                                    limit 1) aitr on true
        where tr.date_id >= in_date_id
          and tr.is_busted = 'N'
          and tr.trade_record_id = any (in_trade_record_id);
end;
$function$
;

-- DROP FUNCTION dash360.clearing_select_trades_for_validation(int4, _int8);

CREATE OR REPLACE FUNCTION dash360.clearing_select_trades_for_validation(in_date_id integer, in_trade_ids bigint[])
    RETURNS TABLE
            (
                trade_record_id           bigint,
                orig_trade_record_id      bigint,
                trade_record_reason       character,
                is_busted                 character,
                trade_record_time         timestamp without time zone,
                account_id                bigint,
                side                      character,
                open_close                character,
                display_instrument_id     character varying,
                last_qty                  integer,
                last_px                   numeric,
                exec_broker               character varying,
                opt_customer_firm         character,
                clearing_account_number   character varying,
                sub_account               character varying,
                cmta                      character varying,
                real_exchange_id          character varying,
                remarks                   character varying,
                trade_liquidity_indicator character varying,
                last_trade_date           timestamp without time zone,
                clearing_status           character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
begin
    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_reason,
               tr.is_busted,
               tr.trade_record_time,
               tr.account_id::bigint,
               tr.side,
               tr.open_close,
               i.display_instrument_id2 as display_instrument_id,
               tr.last_qty,
               tr.last_px,
               tr.exec_broker,
               tr.opt_customer_firm,
               tr.clearing_account_number,
               tr.sub_account,
               tr.cmta,
               e.real_exchange_id,
               tr.remarks,
               tr.trade_liquidity_indicator,
               i.last_trade_date,
               ci.status                as clearing_status
        from trade_record tr
                 inner join instrument i
                            on (tr.instrument_id = i.instrument_id)
                 left join exchange e
                           on e.exchange_id = tr.exchange_id and e.is_active = 'Y'
                 left join clearing_instruction_entry cie
                           on cie.trade_record_id = tr.trade_record_id
                 left join clearing_instruction ci
                           on ci.clearing_instr_id = cie.clearing_instr_id and ci.is_deleted = 'N'
        where tr.date_id = in_date_id
          and tr.trade_record_id = any (in_trade_ids);

end;
$function$
;
