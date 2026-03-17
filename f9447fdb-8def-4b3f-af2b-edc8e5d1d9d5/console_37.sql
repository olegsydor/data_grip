-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar, bool);

CREATE OR REPLACE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                      in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                      in_reported_status character DEFAULT NULL::character(1),
                                                      in_hide_non_customer_bphops boolean DEFAULT false)
    RETURNS TABLE
            (
                date_id                    integer,
                trade_record_id            bigint,
                account_id                 integer,
                instrument_id              bigint,
                side                       character,
                open_close                 character,
                avg_px                     numeric,
                exec_qty                   integer,
                display_instrument_id      character varying,
                last_trade_date            date,
                instrument_type_id         character,
                alloc_instr_id             integer,
                alloc_time                 timestamp without time zone,
                is_allocated               boolean,
                is_bundle                  boolean,
                cmta                       character varying,
                exec_broker                character varying,
                principal_amount           numeric,
                client_commission_rate     numeric,
                username                   character varying,
                blaze_account_alias        character varying,
                street_exec_time           timestamp without time zone,
                expiration_date            timestamp without time zone,
                opt_customer_firm          character,
                reported_status            character,
                reported_time              timestamp without time zone,
                claimed_by                 integer,
                claim_status               character,
                is_prev_reported           boolean,
                db_create_time             timestamp without time zone,
                drop_message_status        character,
                drop_message_reject_reason text,
                client_commission_amount   numeric,
                client_order_id            character varying,
                client_order_status        character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --in_date_id = 20190301;
    -- VP 20231030 https://dashfinancial.atlassian.net/browse/DS-7465 [ALLOC] Return street_exec_time in dash360.allocations_snapshot()
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters and removed if-else condition for empty in_account_id
    -- OS 20250116 https://dashfinancial.atlassian.net/browse/DS-9337 is_prev_reported will use is_billed
    -- OS 20250212 https://dashfinancial.atlassian.net/browse/DS-9550 Add "GUP" (exec_broker) column to Allocations procedure
    -- OS 20250305 hotfix for empty account_id list returns nothing
    -- OS 20250307 hotfix performance improvement
    -- OS 20251219 https://dashfinancial.atlassian.net/browse/DS-10632
    -- OS 20260107 https://dashfinancial.atlassian.net/browse/D360-16941 Return Total CCRU Amount for Execution Blotter, Change Clearing Pop-up, Allocations
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260313 https://dashfinancial.atlassian.net/browse/DS-11254 Adjust allocation_snapshot procedure to have a capability to filter out non-final BP trades by chain_id vs client_order_id
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
begin

    drop table if exists t_trade_record;
    create temp table t_trade_record
    as
    select distinct on (atr.trade_record_id, br.to_report, br.alloc_instr_id) atr.trade_record_id,
                                                                              br.to_report,
                                                                              br.alloc_instr_id,
                                                                              br.db_create_time,
                                                                              'B' as alloc_rep_type
    from dash_reporting.bofa_allocation_report br
             join genesis2.alloc_instr2trade_record atr
                  on atr.alloc_instr_id = br.alloc_instr_id and atr.date_id = br.date_id
    where br.date_id = in_date_id
    union all
    select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
    from dash_reporting.bofa_trade_record btr
    where btr.date_id = in_date_id;

    /*
    select array_agg(account_id)
    into l_sg_accounts
    from genesis2.account
    where
    */

    analyze t_trade_record;
    create index on t_trade_record (trade_record_id);
    create index on t_trade_record (alloc_instr_id);
--     raise notice '2 - %', clock_timestamp();

    return query
        select tr.date_id::int4,
               tr.trade_record_id::int8,
               tr.account_id::int4,
               tr.instrument_id::int8,
               tr.side::character,
               tr.open_close::character,
               tr.last_px                                                                               as avg_px,
               tr.last_qty::int4                                                                        as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id::character,
               null::int4                                                                               as alloc_instr_id,
               null::timestamp without time zone                                                        as alloc_time,
               false                                                                                    as is_allocated,
               false                                                                                    as is_bundle,
               tr.cmta::character varying,
               tr.exec_broker::character varying,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                                  as principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
                   else CCRU.rate end                                                                   as client_commission_rate,
               null::character varying                                                                  as user_name,
               tr.blaze_account_alias::character varying,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)::timestamp without time zone as street_exec_time,
               ----------------
               i.last_trade_date                                                                        as expiration_date,
               tr.opt_customer_firm::character,
               coalesce(nullif(tr.is_billed, 'N'), rep.to_report)::character                            as reported_status,
               case
                   when coalesce(nullif(tr.is_billed, 'N'), rep.to_report) = 'R' then
                       coalesce((select bar.db_create_time
                                 from dash_reporting.bofa_allocation_report bar
                                          join genesis2.alloc_instr2trade_record aitr
                                               on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                          join genesis2.trade_record tri
                                               on tri.date_id = bar.date_id and
                                                  tri.trade_record_id = aitr.trade_record_id
                                 where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                                   and tri.exec_id = tr.exec_id
                                   and tri.is_billed = 'R'
                                   and tri.date_id = tr.date_id
                                 order by 1
                                 limit 1),
                                rep.db_create_time) end                                                 as reported_time,
               bas.claimed_by::int4                                                                     as claimed_by,
               bas.claim_status::character                                                              as claim_status,
               case when tr.is_billed = 'R' then true end                                               as is_prev_reported,
               msg.db_create_time                                                                       as db_create_time,
               msg.drop_message_status                                                                  as alloc_drop_msg_status,
               msg.drop_message_reject_reason                                                           as alloc_drop_msg_reject_reason,
               CCRU.amount                                                                              as client_commission_amount,
               tr.client_order_id                                                                       as client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = in_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1) end                                                         as client_order_status
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join genesis2.account acc on acc.account_id = tr.account_id
                 left join (select ai2tr.trade_record_id, a.alloc_instr_id, a.date_id
                            from genesis2.allocation_instruction a
                                     inner join genesis2.alloc_instr2trade_record ai2tr
                                                on (a.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = a.date_id)
                            where true
                              and case when in_account_ids = '{}' then true else a.account_id = any (in_account_ids) end
                              and a.date_id = in_date_id
                              and a.is_deleted = 'N') allocated_trades
                           on allocated_trades.trade_record_id = TR.TRADE_RECORD_ID
                 left join lateral (select rep.to_report, rep.db_create_time
                                    from t_trade_record rep
                                    where rep.trade_record_id = tr.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and bas.date_id = allocated_trades.date_id
                                      and 1 = 2
                                    limit 1) bas on true
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = in_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
                 left join lateral (select *
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                    limit 1) msg on true
                 left join lateral (select fix_message ->> '10707' as chain_id
                                    from staging.fix_message_json fmj
                                    where fmj.date_id = tr.date_id
                                      and fmj.fix_message_id = tr.trade_fix_message_id
                                    limit 1) fmj on in_hide_non_customer_bphops
        where tr.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then true else tr.account_id = any (in_account_ids) end
          and tr.is_busted = 'N'
--and false
          and allocated_trades.alloc_instr_id is NULL
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C')
                  when in_reported_status is null then true end
          and case
                  when in_hide_non_customer_bphops and (chain_id is not null and chain_id != tr.client_order_id)
                      then false
                  else true end;

--     raise notice '3 - %', clock_timestamp();

    return query
        select ai.date_id,
               null::int8                                                                                  as trade_record_id,
               ai.account_id::int4,
               ai.instrument_id::int8,
               ai.side::character,
               ai.open_close::character,
               ai.avg_px::numeric,
               ai.total_qty::int4                                                                          as exec_qty,
               i.display_instrument_id::character varying,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id::character,
               ai.alloc_instr_id::int4,
               ai.create_time::timestamp without time zone                                                 as alloc_time,
               true                                                                                        as is_allocated,
               true                                                                                        as is_bundle,
               null::character varying                                                                     as cmta,
               ccr.exec_broker::character varying                                                          as exec_broker,
               case i.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                                                                                        principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end                                                                       as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying                                           as user_name,
               ccr.blaze_account_alias::character varying,
               null::timestamp without time zone                                                           as street_exec_time,
               -------
               i.last_trade_date,
               null::character                                                                             as opt_customer_or_firm,
               rep.to_report::character                                                                    as reported_status,
               rep.db_create_time                                                                          as reported_time,
               bas.claimed_by                                                                              as claimed_by,
               bas.claim_status                                                                            as claim_status,
               null::boolean                                                                               as is_prev_reported,
               msg.db_create_time                                                                          as db_create_time,
               msg.drop_message_status                                                                     as alloc_drop_msg_status,
               msg.drop_message_reject_reason                                                              as alloc_drop_msg_reject_reason,
               ccr.amount                                                                                  as client_commission_amount,
               case
                   when array_length(ccr.client_order_id, 1) > 1 then '-'
                   else ccr.client_order_id[1] end                                                         as client_order_id,
               case
                   when array_length(ccr.order_status, 1) > 1 then '-'
                   else ccr.client_order_id[1] end                                                         as client_order_status
        from genesis2.allocation_instruction ai
                 inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
                 left join lateral (select case
                                               when rep.to_report = 'U' and
                                                    staging.get_fully_reported_trade(rep.alloc_instr_id, in_date_id) =
                                                    1 -- means that only one value is possible in related trade_records and it can be only R
                                                   then 'U'
                                               when rep.to_report = 'U' then 'W'
                                               else rep.to_report end as to_report,
                                           rep.db_create_time
                                    from t_trade_record rep
                                    where rep.alloc_instr_id = ai.alloc_instr_id
                                    limit 1) rep on true
                 left join genesis2.account acc on acc.account_id = ai.account_id
                 left join genesis2.user_identifier ui on ai.created_by_user_id = ui.user_id
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = ai.alloc_instr_id
                                      and bas.date_id = ai.date_id
                                    limit 1) bas on true
                 left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as rate,
                                           case
                                               when count(distinct tr.blaze_account_alias) = 1
                                                   then max(tr.blaze_account_alias)
                                               when count(distinct tr.blaze_account_alias) > 1 then '-'
                                               else null
                                               end                                                  as blaze_account_alias,
                                           string_agg(distinct tr.exec_broker, ', ')                as exec_broker,
                                           sum(amount)                                              as amount,
                                           array_agg(distinct tr.client_order_id)                   as client_order_id,
                                           array_agg(distinct fpo.order_status)                     as order_status
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                             left join lateral (select rate,
                                                                       tl.amount,
                                                                       row_number()
                                                                       over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                                from genesis2.trade_level_book_record tl
                                                                         inner join genesis2.book_record_creator cr
                                                                                    on tl.book_record_creator_id = cr.book_record_creator_id
                                                                where tl.date_id = in_date_id
                                                                  AND tl.book_record_type_id = 'CCRU'
                                                                  and tl.trade_record_id = alt.trade_record_id) l1
                                                       on true
                                             left join lateral (select distinct fpo.order_status
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id) fpo on true
                                    where alt.alloc_instr_id = ai.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and (l1.rn = 1 or l1.rn is null)
                                      and alt.date_id = in_date_id
                                      and tr.date_id = in_date_id
                                    limit 1
            ) ccr on true
                 left join lateral (select *
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = ai.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                    limit 1) msg on true

        where ai.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then true else ai.account_id = any (in_account_ids) end
          and ai.is_deleted = 'N'
--and false
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C', 'W') -- C the same as U
                  when in_reported_status is null then true end;
--     raise notice '4 - %', clock_timestamp();

end ;
$function$
;


-- DROP FUNCTION dash360.allocations_instruction_trades(int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_trades(in_alloc_instr_id integer)
    RETURNS TABLE
            (
                date_id                  integer,
                trade_record_id          bigint,
                account_id               integer,
                instrument_id            bigint,
                side                     character,
                open_close               character,
                avg_px                   numeric,
                exec_qty                 integer,
                display_instrument_id    character varying,
                last_trade_date          date,
                instrument_type_id       character,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                blaze_account_alias      character varying,
                street_exec_time         timestamp without time zone,
                expiration_date          timestamp without time zone,
                opt_customer_firm        character,
                reported_status          character,
                reported_time            timestamp without time zone,
                claimed_by               integer,
                claim_status             character,
                is_prev_reported         boolean,
                client_commission_amount numeric,
                client_order_id          character varying,
                client_order_status      character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
    -- OS 20250116 https://dashfinancial.atlassian.net/browse/DS-9337 changes in report_time using is_billed in trade_record
    -- OS 20260123 no ticket yet added client_commission_amount
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
declare
    l_date_id integer;
begin

    select ai.date_id
    from genesis2.allocation_instruction ai
    where ai.alloc_instr_id = in_alloc_instr_id
    into l_date_id;

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id::int8,
               tr.side,
               tr.open_close,
               tr.last_px                                                                   as avg_px,
               tr.last_qty                                                                  as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                      as principal_amount,
               CCRU.rate                                                                    as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                  as street_exec_time,
               ----------------
               i.last_trade_date                                                            as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                              as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
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
                        limit 1)) end                                                       as reported_time,
               null::int4                                                                   as claimed_by,
               null::character                                                              as claim_status,
               case when tr.is_billed = 'R' then true else false end                        as is_prev_reported,
               CCRU.amount                                                                  as client_commission_amount,
               tr.client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = l_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1) end                                             as client_order_status
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 inner join genesis2.alloc_instr2trade_record ai2tr on (ai2tr.trade_record_id = tr.trade_record_id)
                 inner join genesis2.allocation_instruction a on (a.alloc_instr_id = ai2tr.alloc_instr_id)
                 left join lateral (select to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
                 left join lateral (select to_report, bar.db_create_time
                                    from dash_reporting.bofa_allocation_report bar
                                    where bar.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bar.date_id = ai2tr.date_id
                                    limit 1) bar on true
--                  left join lateral (select bas.claimed_by, bas.claim_status
--                                     from dash_reporting.bofa_allocation_instruction_status bas
--                                     where bas.alloc_instr_id = ai2tr.alloc_instr_id
--                                       and bas.date_id = ai2tr.date_id
--                                     limit 1) bas on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , tl.book_record_type_id , tl.billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND tl.book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;


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
                client_order_id          character varying,
                client_order_status      character
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
-- SO 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
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
               tr.client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = l_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1) end                            as client_order_status
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
