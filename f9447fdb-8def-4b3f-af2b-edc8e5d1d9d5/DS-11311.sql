-- https://dashfinancial.atlassian.net/browse/DS-11311
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
    --VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
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
               CCRU.rate as             client_commission_rate,
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

select * from alloc_instr2trade_record