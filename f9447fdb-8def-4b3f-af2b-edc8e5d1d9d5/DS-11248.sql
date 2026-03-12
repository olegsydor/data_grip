-- DROP FUNCTION dash360.allocations_instruction_delete(int4, int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_delete(in_alloc_instr_id integer, in_user_id integer)
    RETURNS TABLE
            (
                date_id                  integer,
                trade_record_id          bigint,
                account_id               integer,
                instrument_id            bigint,
                side                     character,
                open_close               character,
                avg_px                   numeric,
                exec_qty                 bigint,
                display_instrument_id    character varying,
                last_trade_date          date,
                instrument_type_id       character,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                blaze_account_alias      character varying,
                orig_trade_record_id     bigint,
                street_exec_time         timestamp without time zone,
                opt_customer_firm        character,
                reported_status          character,
                reported_time            timestamp without time zone,
                client_commission_amount numeric,
                client_order_id          character varying
            )
    LANGUAGE plpgsql
AS
$function$

    -- SY 20210531 DS-3420 return type has been changed from id into query
-- The logic to modify trade_record has been implemented
-- SY 20210617 https://dashfinancial.atlassian.net/browse/DS-3642 CMTA field has been added to revertion process
-- VP 20231130 https://dashfinancial.atlassian.net/browse/DS-7591 Added field street_exec_time
-- SO 20250116 https://dashfinancial.atlassian.net/browse/DS-9407 Add new fields is_prev_reported, opt_customer_firm
-- SO 20250528 https://dashfinancial.atlassian.net/browse/DS-10041 Added status='U' for deleted instruction
-- SO 20261112 https://dashfinancial.atlassian.net/browse/DS-11248 Support client_order_id in dash360.allocations_instruction_delete()
declare
    l_user_id              int;
    l_system_id            varchar;
    l_revert_vector        jsonb;
    l_new_trade_record_ids bigint[];
    l_date_id              int;
    l_load_batch_id        bigint;
    l_step_id              int;
begin
    l_step_id := 0;

    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete STARTED =====', 0,
                             'S'::char)
    into l_step_id;

    with ct as ( update genesis2.allocation_instruction ai
        set
            is_deleted = 'Y',
            delete_time = 'now'::timestamp,
            deleted_by_user_id = in_user_id,
            status = 'U'
        where alloc_instr_id = in_alloc_instr_id
        returning ai.created_by_user_id, ai.created_by_subsystem_id, ai.date_id)
    select ct.created_by_user_id, ct.created_by_subsystem_id, ct.date_id
    into l_user_id, l_system_id, l_date_id
    from ct;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'genesis2.allocation_instruction updated', 0, 'S'::char)
    into l_step_id;


--  raise info '%: l_user_id=%, l_system_id=%, date_id = %', clock_timestamp(),l_user_id, l_system_id, l_date_id ;

    if l_user_id is null and l_system_id = 'RPS'
    then
        l_new_trade_record_ids := array []::bigint[];
    else
        /* UNALLOCATE MANUAL ALLOCATION with reverting trade_record changes*/
        select ('{' || string_agg('"' || tr.trade_record_id || '":[{"clearing_account_number":"' ||
                                  coalesce(orig_tr.clearing_account_number, 'NULL') || '"
															  , "account_nickname":"' ||
                                  coalesce(orig_tr.account_nickname, 'NULL') || '"
															  , "street_account_name":"' ||
                                  coalesce(orig_tr.street_account_name, 'NULL') || '"
															  , "cmta":"' || coalesce(orig_tr.cmta, 'NULL') || '"
		      												  , "allocation_avg_price":"NULL"
															  , "trade_record_reason":"U"
															  , "user_id":' || in_user_id || '}]', ',') || '}')::jsonb
        into l_revert_vector
        from alloc_instr2trade_record aitr
                 inner join trade_record tr on aitr.trade_record_id = tr.trade_record_id and tr.is_busted = 'N' and
                                               tr.date_id = aitr.date_id and trade_record_reason = 'L'
                 inner join trade_record orig_tr
                            on tr.orig_trade_record_id = orig_tr.trade_record_id and tr.date_id = orig_tr.date_id
        where aitr.alloc_instr_id = in_alloc_instr_id
          and aitr.date_id = l_date_id;

        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_revert_vector defined ', 0, 'S'::char)
        into l_step_id;

        raise info 'Revert vector is %', l_revert_vector;

        if l_revert_vector is not null
        then
            l_new_trade_record_ids := dash360.ptm_process_trades(l_date_id, in_user_id, l_revert_vector);
--        then l_new_trade_record_ids:=trash.so_ptm_process_trades(l_date_id, in_user_id, l_revert_vector);

            select genesis2.load_log(l_load_batch_id::int, l_step_id, 'cardinality(l_new_trade_record_ids): ',
                                     cardinality(l_new_trade_record_ids), 'S'::char)
            into l_step_id;

            perform dash360.trade_record_update_ccru(in_user_id =>in_user_id, in_date_id => l_date_id,
                                                     in_trade_record_id =>l.trade_record_id, in_rate => l.rate,
                                                     in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
            from (select tr.trade_record_id::bigint,
                         tlbr.rate,
                         tr.last_qty * tlbr.rate                                                                                 as amount,
                         row_number()
                         over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
                  from genesis2.trade_record tr
                           inner join genesis2.trade_level_book_record tlbr
                                      on tlbr.date_id = tr.date_id and
                                         tlbr.trade_record_id = tr.orig_trade_record_id and
                                         book_record_type_id = 'CCRU'
                           inner join genesis2.book_record_creator brc
                                      on tlbr.book_record_creator_id = brc.book_record_creator_id
                  where tr.date_id = l_date_id
                    and tr.trade_record_id = any (array [l_new_trade_record_ids])) l
            where rn = 1;

        else
            select array_agg(trade_record_id::bigint)
            into l_new_trade_record_ids
            from alloc_instr2trade_record a
            where a.date_id = l_date_id
              and a.alloc_instr_id = in_alloc_instr_id;
        end if;
        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'After IF ', 0, 'S'::char)
        into l_step_id;

    end if;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete returning query', 0,
                             'S'::char)
    into l_step_id;

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id::bigint,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty::bigint                                         as exec_qty,
               i.display_instrument_id2,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                     as principal_amount,
               CCRU.rate                                                   as client_commission_rate,
               tr.blaze_account_alias,
               tr.orig_trade_record_id::bigint,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               tr.opt_customer_firm,
               case when tr.is_billed = 'R' then 'R'::char end             as reported_status,
               case
                   when true
                       and tr.is_billed = 'R'
                       then (select bar.db_create_time
                             from dash_reporting.bofa_allocation_report bar
                                      join genesis2.alloc_instr2trade_record aitr
                                           on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                      join genesis2.trade_record tri
                                           on tri.date_id = bar.date_id and tri.trade_record_id = aitr.trade_record_id
                             where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                               and tri.exec_id = tr.exec_id
                               and tri.is_billed = 'R'
                             order by 1
                             limit 1) end                                  as reported_time,
               CCRU.amount                                                 as client_commission_amount,
               tr.client_order_id
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
                 left join lateral (select to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and tr.trade_record_id = any (l_new_trade_record_ids);

end;

$function$
;
