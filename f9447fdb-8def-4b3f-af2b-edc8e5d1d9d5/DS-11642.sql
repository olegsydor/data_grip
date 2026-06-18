drop function dash360.allocations_snapshot;

CREATE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                           in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                           in_reported_status character DEFAULT NULL::character(1),
                                           in_hide_non_customer_bphops boolean DEFAULT false,
                                           in_client_order_states character[] DEFAULT NULL::character(1)[])
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
                client_order_status        character,
                clearing_submitted_away    character,
                broker_commission_rate     numeric,
                broker_commission_amount   numeric
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
    -- OS 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
    -- OS 20260403 https://dashfinancial.atlassian.net/browse/DS-11344 Support a new filtering parameter client_order_state
    -- SO 20260414 https://dashfinancial.atlassian.net/browse/DS-11390 Return client_order_status for Trade Records from OMS (OMS_EDW) as filled (2)
    -- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
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
               CCRU.ccru_rate                                                                           as client_commission_rate,
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
               CCRU.ccru_amount                                                                         as client_commission_amount,
               tr.client_order_id                                                                       as client_order_id,
               (case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end)::character    as client_order_status,
               null::character                                                                          as clearing_submitted_away,
               CCRU.brok_rate                                                                           as broker_commission_rate,
               CCRU.brok_amount                                                                         as broker_commission_amount
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
--                  left join lateral (select L1.rate, l1.amount
--                                     from (SELECT row_number()
--                                                  over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
--                                                  tl.rate,
--                                                  tl.amount
--                                           FROM genesis2.trade_level_book_record tl
--                                                    inner join genesis2.book_record_creator cr
--                                                               on tl.book_record_creator_id = cr.book_record_creator_id
--                                           WHERE tl.date_id = in_date_id
--                                             AND book_record_type_id = 'CCRU'
--                                             and tl.trade_record_id = tr.trade_record_id) L1
--                                     where rn = 1) CCRU_ on true
                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
                                    from (SELECT tl.trade_record_id,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = in_date_id
                                            AND book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) ccru on true
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
                 left join lateral (select fpo.order_status
                                    from staging.f_parent_order fpo
                                    where fpo.status_date_id = in_date_id
                                      and fpo.parent_order_id = tr.order_id
                                    limit 1) fpo on true and tr.subsystem_id is distinct from 'OMS_EDW'
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
                  else true end
          and case
                  when in_client_order_states is null then true
                  else fpo.order_status is not null and fpo.order_status = any (in_client_order_states) end;


--     raise notice '3 - %', clock_timestamp();

    return query
select ai.date_id,
       null::int8                                        as trade_record_id,
       ai.account_id::int4,
       ai.instrument_id::int8,
       ai.side::character,
       ai.open_close::character,
       ai.avg_px::numeric,
       ai.total_qty::int4                                as exec_qty,
       i.display_instrument_id::character varying,
       --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
       i.last_trade_date::date,
       i.instrument_type_id::character,
       ai.alloc_instr_id::int4,
       ai.create_time::timestamp without time zone       as alloc_time,
       true                                              as is_allocated,
       true                                              as is_bundle,
       null::character varying                           as cmta,
       ccr.exec_broker::character varying                as exec_broker,
       case i.instrument_type_id
           when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
           else ai.total_qty * ai.avg_px
           end                                              principal_amount,
       ccr.ccru_rate                                     as client_commission_rate,
       coalesce(ui.user_name, 'auto')::character varying as user_name,
       ccr.blaze_account_alias::character varying,
       null::timestamp without time zone                 as street_exec_time,
       -------
       i.last_trade_date,
       null::character                                   as opt_customer_or_firm,
       rep.to_report::character                          as reported_status,
       rep.db_create_time                                as reported_time,
       bas.claimed_by                                    as claimed_by,
       bas.claim_status                                  as claim_status,
       null::boolean                                     as is_prev_reported,
       msg.db_create_time                                as db_create_time,
       msg.drop_message_status                           as alloc_drop_msg_status,
       msg.drop_message_reject_reason                    as alloc_drop_msg_reject_reason,
       ccr.ccru_amount                                   as client_commission_amount,
       case
           when array_length(ccr.client_order_id, 1) > 1 then '-'
           else ccr.client_order_id[1] end               as client_order_id,
       case
           when array_length(ccr.order_status, 1) > 1 then '-'
           else ccr.order_status[1] end ::char           as client_order_status,
       ai.clearing_submitted_away                        as clearing_submitted_away,
       ccr.brok_rate                                     as broker_commission_rate,
       ccr.brok_amount                                   as broker_commission_rate
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

         left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as ccru_rate,
                                   case
                                       when count(distinct tr.blaze_account_alias) = 1
                                           then max(tr.blaze_account_alias)
                                       when count(distinct tr.blaze_account_alias) > 1 then '-'
                                       end                                                       as blaze_account_alias,
                                   string_agg(distinct tr.exec_broker, ', ')                     as exec_broker,
                                   sum(ccru_amount)                                              as ccru_amount,
                                   array_agg(distinct tr.client_order_id)                        as client_order_id,
                                   array_agg(distinct fpo.order_status)                          as order_status,
                                   sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as brok_rate,
                                   sum(brok_amount)                                              as brok_amount
                            from genesis2.alloc_instr2trade_record alt
                                     inner join genesis2.trade_record tr
                                                on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id

                                     left join lateral (
                                select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                       max(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                       max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                       max(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                from (select rate,
                                             tl.amount,
                                             book_record_type_id,
                                             row_number()
                                             over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                      from genesis2.trade_level_book_record tl
                                               inner join genesis2.book_record_creator cr
                                                          on tl.book_record_creator_id = cr.book_record_creator_id
                                      where tl.date_id = in_date_id
                                        AND tl.book_record_type_id in ('CCRU', 'BROK')
                                        and tl.trade_record_id = alt.trade_record_id) l0
                                where true
                                  and (l0.rn = 1 or l0.rn is null)
                                ) l1 on true
                                     left join lateral (select distinct case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end
                                                        from staging.f_parent_order fpo
                                                        where fpo.status_date_id = in_date_id
                                                          and fpo.parent_order_id = tr.order_id) fpo on true
                            where alt.alloc_instr_id = ai.alloc_instr_id
                              and tr.is_busted = 'N'
--                               and (l1.rn = 1 or l1.rn is null)
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

select *
from dash360.allocations_snapshot(in_date_id := 20260608, in_account_ids := '{263743, 11448}',
                                in_hide_non_customer_bphops := 'False', in_client_order_states := '{2}');

drop function dash360.allocations_instruction_trades;
CREATE FUNCTION dash360.allocations_instruction_trades(in_alloc_instr_id integer)
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
                client_order_status      character,
                broker_commission_rate   numeric,
                broker_commission_amount numeric
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
    -- SO 20260414 https://dashfinancial.atlassian.net/browse/DS-11390 Return client_order_status for Trade Records from OMS (OMS_EDW) as filled (2)
    -- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
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
               tr.last_px                                                                       as avg_px,
               tr.last_qty                                                                      as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                          as principal_amount,
               CCRU.ccru_rate                                                                   as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                      as street_exec_time,
               ----------------
               i.last_trade_date                                                                as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                                  as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
                                                                                  from dash_reporting.bofa_allocation_report bar
                                                                                           join genesis2.alloc_instr2trade_record aitr
                                                                                                on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                                                                           join genesis2.trade_record tri
                                                                                                on tri.date_id =
                                                                                                   bar.date_id and
                                                                                                   tri.trade_record_id =
                                                                                                   aitr.trade_record_id
                                                                                  where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                                                                                    and tri.exec_id = tr.exec_id
                                                                                    and tri.is_billed = 'R'
                                                                                  order by 1
                                                                                  limit 1)) end as reported_time,
               null::int4                                                                       as claimed_by,
               null::character                                                                  as claim_status,
               case when tr.is_billed = 'R' then true else false end                            as is_prev_reported,
               CCRU.ccru_amount                                                                 as client_commission_amount,
               tr.client_order_id,
               case
                   when tr.subsystem_id is distinct from 'OMS_EDW' then
                       (select fpo.order_status
                        from staging.f_parent_order fpo
                        where fpo.status_date_id = l_date_id
                          and fpo.parent_order_id = tr.order_id
                        limit 1)
                   else '2' end::character                                                      as client_order_status,
               CCRU.brok_rate                                                                   as broker_commission_rate,
               CCRU.brok_amount                                                                 as broker_commission_amount
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

                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id


                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
                                    from (SELECT tl.trade_record_id,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) ccru on true

        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;
select * from dash360.allocations_instruction_trades(-125858);
SELECT * FROM dash360.allocations_instruction_trades(-126562)


CREATE FUNCTION dash360.trade_record_update_brok(in_user_id integer, in_date_id integer,
                                                 in_trade_record_id bigint, in_rate numeric,
                                                 in_amount numeric,
                                                 in_load_batch_id integer DEFAULT NULL::integer,
                                                 in_book_record_creator_id character varying DEFAULT 'MAN'::character varying)
    RETURNS integer
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY DS-2914 On conflich has been implemented due to miration to native parititoning
-- AK DS-10934 Add new parameter to procedure dash360.trade_record_update_ccru to add new param to se book_record_creator_id (SGDD or other)
-- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
declare
    l_date_id       int;
    l_load_batch_id int;
begin

    l_date_id := in_date_id;
    if in_load_batch_id is null
    then
        select nextval('load_batch_load_batch_id_seq'::regclass) into l_load_batch_id;
    else
        l_load_batch_id := in_load_batch_id;
    end if;


    insert into trade_level_book_record (trade_record_id, book_record_type_id, amount, book_record_creator_id, date_id,
                                         rate, load_batch_id, user_id, create_time, billing_entity)
    values (in_trade_record_id, 'BROK', in_amount, in_book_record_creator_id, l_date_id, in_rate, l_load_batch_id,
            in_user_id, clock_timestamp(), '-1')
    on conflict (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id)
        do update set amount        = EXCLUDED.amount,
                      rate          = EXCLUDED.rate,
                      load_batch_id = EXCLUDED.load_batch_id,
                      user_id       = EXCLUDED.user_id,
                      create_time   = EXCLUDED.create_time;

    perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id, in_row_cnt => 1,
                                   in_subscription_name => 'big_data.flat_trade_record',
                                   in_source_table_name => 'trade_level_book_record', in_date_id => l_date_id);

    return l_load_batch_id;


exception
    when others then
        RAISE notice '% %', sqlstate, sqlerrm;
        raise;
        return -2;
end;
$function$
;

drop function if exists genesis2.get_manual_broker;
create or replace function genesis2.get_manual_broker(in_subsystem_id character varying(20), in_date_id int4,
                                                      in_trade_record_id int8 default null,
                                                      in_fix_message_id int8 default null)
    returns character varying
    language plpgsql
as
$$
declare
    l_manual_broker character varying;
begin
    if in_subsystem_id = 'OMS_EDW' then
        select manual_broker
        into l_manual_broker
        from staging.trade_record_blaze7
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id
          and manual_broker is not null
        limit 1;
    else
        select fmj.fix_message ->> '10568'
        into l_manual_broker
        from staging.fix_message_json fmj
        where fmj.date_id = in_date_id
          and fmj.fix_message_id = in_fix_message_id;
    end if;
    return l_manual_broker;
end;
$$

select manual_broker from staging.trade_record_blaze7
where date_id = :in_date_id
and trade_record_id = :in_trade_record_id;

select * from staging.fix_message_json fmj
where fmj.date_id = :in_date_id
--     and fmj.fix_message_id = :in_fix_message
and fmj.fix_message ->> '10658' is not null;


;

-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar, bool, _bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                        in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                        in_reported_status character DEFAULT NULL::character(1),
                                                        in_hide_non_customer_bphops boolean DEFAULT false,
                                                        in_client_order_states character[] DEFAULT NULL::character(1)[])
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
                client_order_status        character,
                clearing_submitted_away    character,
                broker_commission_rate     numeric,
                broker_commission_amount   numeric,
                manual_broker              character varying
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
    -- OS 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
    -- OS 20260403 https://dashfinancial.atlassian.net/browse/DS-11344 Support a new filtering parameter client_order_state
    -- SO 20260414 https://dashfinancial.atlassian.net/browse/DS-11390 Return client_order_status for Trade Records from OMS (OMS_EDW) as filled (2)
    -- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
    -- SO 20260612 https://dashfinancial.atlassian.net/browse/DS-11642 Add manual broker
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
               CCRU.ccru_rate                                                                           as client_commission_rate,
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
               CCRU.ccru_amount                                                                         as client_commission_amount,
               tr.client_order_id                                                                       as client_order_id,
               (case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end)::character    as client_order_status,
               null::character                                                                          as clearing_submitted_away,
               CCRU.brok_rate                                                                           as broker_commission_rate,
               CCRU.brok_amount                                                                         as broker_commission_amount,
               genesis2.get_manual_broker(in_subsystem_id := tr.subsystem_id, in_date_id := tr.date_id,
                                          in_trade_record_id := tr.trade_record_id,
                                          in_fix_message_id := tr.trade_fix_message_id)                 as manual_broker
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
                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
                                    from (SELECT tl.trade_record_id,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = in_date_id
                                            AND book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) ccru on true
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
                 left join lateral (select fpo.order_status
                                    from staging.f_parent_order fpo
                                    where fpo.status_date_id = in_date_id
                                      and fpo.parent_order_id = tr.order_id
                                    limit 1) fpo on true and tr.subsystem_id is distinct from 'OMS_EDW'
        where tr.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then false else tr.account_id = any (in_account_ids) end
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
                  else true end
          and case
                  when in_client_order_states is null then true
                  else fpo.order_status is not null and fpo.order_status = any (in_client_order_states) end;


--     raise notice '3 - %', clock_timestamp();

    return query
        select ai.date_id,
               null::int8                                        as trade_record_id,
               ai.account_id::int4,
               ai.instrument_id::int8,
               ai.side::character,
               ai.open_close::character,
               ai.avg_px::numeric,
               ai.total_qty::int4                                as exec_qty,
               i.display_instrument_id::character varying,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id::character,
               ai.alloc_instr_id::int4,
               ai.create_time::timestamp without time zone       as alloc_time,
               true                                              as is_allocated,
               true                                              as is_bundle,
               null::character varying                           as cmta,
               ccr.exec_broker::character varying                as exec_broker,
               case i.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                                              principal_amount,
               ccr.ccru_rate                                     as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying as user_name,
               ccr.blaze_account_alias::character varying,
               null::timestamp without time zone                 as street_exec_time,
               -------
               i.last_trade_date,
               null::character                                   as opt_customer_or_firm,
               rep.to_report::character                          as reported_status,
               rep.db_create_time                                as reported_time,
               bas.claimed_by                                    as claimed_by,
               bas.claim_status                                  as claim_status,
               null::boolean                                     as is_prev_reported,
               msg.db_create_time                                as db_create_time,
               msg.drop_message_status                           as alloc_drop_msg_status,
               msg.drop_message_reject_reason                    as alloc_drop_msg_reject_reason,
               ccr.ccru_amount                                   as client_commission_amount,
               case
                   when array_length(ccr.client_order_id, 1) > 1 then '-'
                   else ccr.client_order_id[1] end               as client_order_id,
               case
                   when array_length(ccr.order_status, 1) > 1 then '-'
                   else ccr.order_status[1] end ::char           as client_order_status,
               ai.clearing_submitted_away                        as clearing_submitted_away,
               ccr.brok_rate                                     as broker_commission_rate,
               ccr.brok_amount                                   as broker_commission_rate,
               case
                   when array_length(ccr.manual_broker, 1) > 1 then '-'
                   else ccr.client_order_id[1] end               as manual_broker
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

                 left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                       as ccru_rate,
                                           case
                                               when count(distinct tr.blaze_account_alias) = 1
                                                   then max(tr.blaze_account_alias)
                                               when count(distinct tr.blaze_account_alias) > 1 then '-'
                                               end                                                                             as blaze_account_alias,
                                           string_agg(distinct tr.exec_broker, ', ')                                           as exec_broker,
                                           sum(ccru_amount)                                                                    as ccru_amount,
                                           array_agg(distinct tr.client_order_id)                                              as client_order_id,
                                           array_agg(distinct fpo.order_status)                                                as order_status,
                                           sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                       as brok_rate,
                                           sum(brok_amount)                                                                    as brok_amount,
                                           array_agg(distinct
                                                     genesis2.get_manual_broker(in_subsystem_id := tr.subsystem_id,
                                                                                in_date_id := tr.date_id,
                                                                                in_trade_record_id := tr.trade_record_id,
                                                                                in_fix_message_id := tr.trade_fix_message_id)) as manual_broker
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id

                                             left join lateral (
                                        select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                               max(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                               max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                               max(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                        from (select rate,
                                                     tl.amount,
                                                     book_record_type_id,
                                                     row_number()
                                                     over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                              from genesis2.trade_level_book_record tl
                                                       inner join genesis2.book_record_creator cr
                                                                  on tl.book_record_creator_id = cr.book_record_creator_id
                                              where tl.date_id = in_date_id
                                                AND tl.book_record_type_id in ('CCRU', 'BROK')
                                                and tl.trade_record_id = alt.trade_record_id) l0
                                        where true
                                          and (l0.rn = 1 or l0.rn is null)
                                        ) l1 on true
                                             left join lateral (select distinct case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id) fpo on true
                                    where alt.alloc_instr_id = ai.alloc_instr_id
                                      and tr.is_busted = 'N'
--                               and (l1.rn = 1 or l1.rn is null)
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
          and case when coalesce(in_account_ids, '{}') = '{}' then false else ai.account_id = any (in_account_ids) end
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



-- DROP FUNCTION dash360.get_data_for_allocation_drop(int8, int4);

CREATE OR REPLACE FUNCTION dash360.get_data_for_allocation_drop(in_alloc_instr_id bigint, in_date_id integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
    -- 20251205 SO https://dashfinancial.atlassian.net/browse/DS-10739 New atrributes in the result json were added
    -- 20260217 SO https://dashfinancial.atlassian.net/browse/DS-11116 v2
    -- 20260223 SO https://dashfinancial.atlassian.net/browse/DS-11134 applied filter for is_busted for cancels only
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11173 Add new output param
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11289 Add new output param Add `ClearingSumbittedAway` to get_data_for_allocation_drop_v2
    -- 20260410 SO https://dashfinancial.atlassian.net/browse/DS-11384 Add NO_ORDER repeating group with CLIENT_ORDER_ID to response
    -- 20260609 SO https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'CS' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay', case
                                                                     when di.instrument_type_id = 'O'
                                                                         then to_char(oc.maturity_day, 'FM00') end,
                                                  'maturityMonthYear', case
                                                                           when di.instrument_type_id = 'O' then
                                                                               to_char(oc.maturity_year, 'FM0000') ||
                                                                               to_char(oc.maturity_month, 'FM00') end,
                                                  'totalQty', ai.total_qty,
                                                  'avgPx', ai.avg_px,
                                                  'noExecs', aitr.trade_cnt,
                                                  'trades', aitr.trades,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries,
                                                  'CCRURate', ccr.ccru_rate,
                                                  'CCRUTotalAmount', ccr.ccru_amount,
                                                  'AllocInstrId', ai.alloc_instr_id,
                                                  'instrumentTypeId', di.instrument_type_id,
                                                  'clearingSumbittedAway', ai.clearing_submitted_away,
												  'noOrders', jsonb_array_length(cl_ords),
                                                  'orders', cl_ords,
                                                  'BROKRate', ccr.brok_rate,
                                                  'BROKTotalAmount', ccr.brok_amount
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as ccru_rate,
                                       sum(ccru_amount)                                              as ccru_amount,
                                       sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as brok_rate,
                                       sum(brok_amount)                                              as brok_amount
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (
                                    select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                    from (select rate,
                                                 tl.amount,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                          from genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          where tl.date_id = in_date_id
                                            AND tl.book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tl.trade_record_id) l0
                                    where true
                                      and (l0.rn = 1 or l0.rn is null)
                                    ) l1 on true
                                where alt.alloc_instr_id = ai.alloc_instr_id
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
--                                   and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'AllocEntryCCRURate', ccr.ccru_rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.ccru_amount * 1.0 * aie.alloc_qty / total_qty,
                                                               'AllocEntryBROKRate', ccr.brok_rate,
                                                               'AllocEntryBROKTotalAmount',
                                                               ccr.brok_amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
                                                  )
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             join lateral (select count(*)                                                              as trade_cnt,
                                  jsonb_agg(distinct jsonb_build_object('clOrdId', tr.client_order_id)) as cl_ords,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )                                                                     as trades
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                                    left join lateral (select fix_message ->> '10710' as chain_exec_id
                                                       from staging.fix_message_json fmj
                                                       where fmj.date_id = aitr.date_id
                                                         and fmj.fix_message_id = tr.trade_fix_message_id
                                                       limit 1) fmj on true
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
--                             and is_busted = 'N'
                           limit 1) aitr on true

             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end ;
$function$
;


select * from genesis2.allocation_instruction
where date_id = 20260612;

select *
from dash360.get_data_for_allocation_drop(-126289, 20260612);



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
                client_order_status      character,
                broker_commission_rate   numeric,
                broker_commission_amount numeric,
                manual_broker_code       character varying
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
    -- SO 20260414 https://dashfinancial.atlassian.net/browse/DS-11390 Return client_order_status for Trade Records from OMS (OMS_EDW) as filled (2)
    -- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
    -- SO 20260616 https://dashfinancial.atlassian.net/browse/DS-11642 Add manual_broker_code
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
               tr.last_px                                                                       as avg_px,
               tr.last_qty                                                                      as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                          as principal_amount,
               CCRU.ccru_rate                                                                   as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                      as street_exec_time,
               ----------------
               i.last_trade_date                                                                as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                                  as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
                                                                                  from dash_reporting.bofa_allocation_report bar
                                                                                           join genesis2.alloc_instr2trade_record aitr
                                                                                                on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                                                                           join genesis2.trade_record tri
                                                                                                on tri.date_id =
                                                                                                   bar.date_id and
                                                                                                   tri.trade_record_id =
                                                                                                   aitr.trade_record_id
                                                                                  where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                                                                                    and tri.exec_id = tr.exec_id
                                                                                    and tri.is_billed = 'R'
                                                                                  order by 1
                                                                                  limit 1)) end as reported_time,
               null::int4                                                                       as claimed_by,
               null::character                                                                  as claim_status,
               case when tr.is_billed = 'R' then true else false end                            as is_prev_reported,
               CCRU.ccru_amount                                                                 as client_commission_amount,
               tr.client_order_id,
               case
                   when tr.subsystem_id is distinct from 'OMS_EDW' then
                       (select fpo.order_status
                        from staging.f_parent_order fpo
                        where fpo.status_date_id = l_date_id
                          and fpo.parent_order_id = tr.order_id
                        limit 1)
                   else '2' end::character                                                      as client_order_status,
               CCRU.brok_rate                                                                   as broker_commission_rate,
               CCRU.brok_amount                                                                 as broker_commission_amount,
               genesis2.get_manual_broker(in_subsystem_id := tr.subsystem_id, in_date_id := tr.date_id,
                                          in_trade_record_id := tr.trade_record_id,
                                          in_fix_message_id := tr.trade_fix_message_id)         as manual_broker_code
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

                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
                                    from (SELECT tl.trade_record_id,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) ccru on true

        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;


select
    tr.subsystem_id,
    tr.date_id,
    tr.trade_record_id,
    tr.trade_fix_message_id,
genesis2.get_manual_broker(in_subsystem_id := tr.subsystem_id, in_date_id := tr.date_id,
                                          in_trade_record_id := tr.trade_record_id,
                                          in_fix_message_id := tr.trade_fix_message_id)         as manual_broker_code
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

                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           max(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           max(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
                                    from (SELECT tl.trade_record_id,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = :l_date_id
                                            AND book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) ccru on true

        where true
--             tr.is_busted = 'N'
          and tr.date_id = :l_date_id
          and a.alloc_instr_id = :in_alloc_instr_id;

SELECT * FROM dash360.allocations_instruction_trades(-126562);

select * from staging.fix_message_json
where fix_message_id in (468106720364724266,468106814854004781,468128809381527929)

select manual_broker

        from staging.trade_record_blaze7
        where date_id = 20260615
          and trade_record_id = 2348069241
          and manual_broker is not null;

SELECT * FROM dash360.allocations_instruction_trades(-126572)
select * from dash360.allocations_instruction_commission_rate(-126289, 20260612)
-- DROP FUNCTION dash360.allocations_instruction_commission_rate(int4, int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_commission_rate(in_alloc_instr_id integer,
                                                                           in_date_id integer DEFAULT get_dateid(CURRENT_DATE))
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
                alloc_instr_id           integer,
                alloc_time               timestamp without time zone,
                is_allocated             boolean,
                is_bundle                boolean,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                username                 character varying,
                client_commission_amount numeric,
                client_order_id          character varying,
                clearing_submitted_away  character,
                client_order_status      character,
                broker_commission_rate   numeric,
                broker_commission_amount numeric,
                manual_broker_code       character varying
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SO 20260319 https://dashfinancial.atlassian.net/browse/DS-11284 Support client_order_id in dash360.allocations_instruction_commission_rate
    -- SO 20260323 https://dashfinancial.atlassian.net/browse/DS-11290 Support client_order_status in dash360.allocations_instruction_commission_rate
    -- SO 20260414 https://dashfinancial.atlassian.net/browse/DS-11390 Return client_order_status for Trade Records from OMS (OMS_EDW) as filled (2)
    -- SO 20260616 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
    -- SO 20260616 https://dashfinancial.atlassian.net/browse/DS-11642 Add manual_broker_code
declare
    l_sg_accounts int8[];
begin

    /*
select array_agg(account_id)
--     into l_sg_accounts
from genesis2.account
where false
*/
    return query
        select a.date_id,
               null::bigint                                                  as trade_record_id,
               a.account_id,
               a.instrument_id,
               a.side,
               a.open_close,
               a.avg_px,
               a.total_qty                                                   as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               a.alloc_instr_id,
               a.create_time                                                 as alloc_time,
               true                                                          as is_allocated,
               true                                                          as is_bundle,
               null::character varying                                       as cmta,
               null::character varying                                       as exec_broker,
               case i.instrument_type_id
                   when 'O' then a.total_qty * a.avg_px * os.contract_multiplier
                   else a.total_qty * a.avg_px
                   end                                                       as principal_amount,
               ccr.ccru_rate                                                 as client_commission_rate,
               ui.user_name,
               ccru_amount                                                   as client_commission_amount,
               (case
                    when array_length(ccr.client_order_id, 1) > 1 then '-'
                    else ccr.client_order_id[1] end)::character varying(256) as client_order_id,
               a.clearing_submitted_away::character,
               (case
                    when array_length(ccr.client_order_status, 1) > 1 then '-'
                    else ccr.client_order_status[1] end)::character          as client_order_status,
               ccr.brok_rate                                                 as broker_commission_rate,
               ccr.brok_amount                                               as broker_commission_rate,
               case
                   when array_length(ccr.manual_broker, 1) > 1 then '-'
                   else ccr.manual_broker[1] end                           as manual_broker_code

        from allocation_instruction a
                 inner join instrument i on (a.instrument_id = i.instrument_id)
                 left join user_identifier ui on a.created_by_user_id = ui.user_id
                 left join option_contract oc on i.instrument_id = oc.instrument_id
                 left join option_series os on oc.option_series_id = os.option_series_id


                 left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                       as ccru_rate,
                                           sum(ccru_amount)                                                                    as ccru_amount,
                                           string_agg(distinct tr.exec_broker, ', ')                                           as exec_broker,
                                           array_agg(distinct tr.client_order_id)                                              as client_order_id,
                                           array_agg(distinct fpo.order_status)                                                as client_order_status,
                                           sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                       as brok_rate,
                                           sum(brok_amount)                                                                    as brok_amount,
                                           array_agg(distinct
                                                     genesis2.get_manual_broker(in_subsystem_id := tr.subsystem_id,
                                                                                in_date_id := tr.date_id,
                                                                                in_trade_record_id := tr.trade_record_id,
                                                                                in_fix_message_id := tr.trade_fix_message_id)) as manual_broker
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id

                                             left join lateral (
                                        select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                               max(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                               max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                               max(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                        from (select rate,
                                                     tl.amount,
                                                     book_record_type_id,
                                                     row_number()
                                                     over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                              from genesis2.trade_level_book_record tl
                                                       inner join genesis2.book_record_creator cr
                                                                  on tl.book_record_creator_id = cr.book_record_creator_id
                                              where tl.date_id = in_date_id
                                                AND tl.book_record_type_id in ('CCRU', 'BROK')
                                                and tl.trade_record_id = alt.trade_record_id) l0
                                        where true
                                          and (l0.rn = 1 or l0.rn is null)
                                        ) l1 on true
                                             left join lateral (select distinct case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id) fpo on true
                                    where alt.alloc_instr_id = a.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and alt.date_id = in_date_id
                                      and tr.date_id = in_date_id
                                    limit 1
            ) ccr on true


        where a.alloc_instr_id = in_alloc_instr_id
          and a.is_deleted = 'N';

end;
$function$
;


SELECT *
FROM dash360.allocations_instruction_commission_rate(
    in_alloc_instr_id := -126572,
    in_date_id := 20260615
);


select '{"side": "2", "avgPx": 7.250000, "orders": [{"clOrdId": "1_6260617"}, {"clOrdId": "1_a260617"}], "symbol": "TSLA", "trades": [{"lastQty": 3, "legRefId": "1", "dashExecId": "pikroetg0g00", "chainExecId": null, "secondaryExchExecId": "Manual Report"}, {"lastQty": 2, "legRefId": "1", "dashExecId": "pikroetg0g00", "chainExecId": null, "secondaryExchExecId": "Manual Report"}, {"lastQty": 6, "legRefId": "1", "dashExecId": "piks8rhk0g00", "chainExecId": null, "secondaryExchExecId": "Manual Report"}], "noExecs": 3, "secType": "OPT", "BROKRate": 1.1022600000000000, "CCRURate": 1.3334700000000000, "noAllocs": 2, "noOrders": 2, "strikePx": 402.5000, "totalQty": 11, "putOrCall": "1", "tradeDate": 20260617, "maturityDay": "18", "processTime": "2026-06-17T07:45:59.301", "AllocInstrId": -126782, "BROKTotalAmount": 12.12486000, "CCRUTotalAmount": 14.66817000, "instrumentTypeId": "O", "allocationEntries": [{"clrFirm": "333", "allocQty": 8, "actionableId": "OCCID_SAB", "allocAccount": "TESTOCC", "individualAllocID": 613121, "AllocEntryBROKRate": 1.1022600000000000, "AllocEntryCCRURate": 1.3334700000000000, "AllocEntryBROKTotalAmount": 8.8180800000000000, "AllocEntryCCRUTotalAmount": 10.6677600000000000}, {"clrFirm": "333", "allocQty": 3, "actionableId": "OCCID_SAB", "allocAccount": "TESTOCC", "individualAllocID": 613120, "AllocEntryBROKRate": 1.1022600000000000, "AllocEntryCCRURate": 1.3334700000000000, "AllocEntryBROKTotalAmount": 3.3067800000000000, "AllocEntryCCRUTotalAmount": 4.0004100000000000}], "maturityMonthYear": "202606", "clearingSumbittedAway": "N"}'::jsonb;



select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as ccru_rate,
       sum(ccru_amount)                                              as ccru_amount,
       sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as brok_rate,
       sum(brok_amount)                                              as brok_amount
from genesis2.alloc_instr2trade_record alt
         inner join genesis2.trade_record tr
                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
         left join lateral (
    select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
           sum(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
           max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
           sum(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
    from (select rate,
                 tl.amount,
                 book_record_type_id,
                 row_number()
                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
          from genesis2.trade_level_book_record tl
                   inner join genesis2.book_record_creator cr
                              on tl.book_record_creator_id = cr.book_record_creator_id
          where tl.date_id = :in_date_id
            AND tl.book_record_type_id in ('BROK', 'CCRU')
            and tl.trade_record_id = tl.trade_record_id
          and tl.trade_record_id in (2348108028,2348108029,2348108030)
          ) l0
    where true
      and (l0.rn = 1 or l0.rn is null)
    ) l1 on true
where alt.alloc_instr_id = -126782;
--                                  and tr.is_busted = 'N'
--                                   and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end


select sum(/*coalesce(*/ l1.rate /*,0)*/ * tr.last_qty) /
       nullif(sum(tr.last_qty), 0)            as rate,
       sum(amount)                            as amount,
       array_agg(distinct tr.client_order_id) as client_order_id,
       array_agg(distinct tr.trade_record_id)
from alloc_instr2trade_record alt
         inner join trade_record tr
                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
         left join lateral (select rate,
                                   tl.amount,
                                   row_number()
                                   over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                            from trade_level_book_record tl
                                     inner join book_record_creator cr
                                                on tl.book_record_creator_id = cr.book_record_creator_id
                            where tl.date_id = :in_date_id
                              AND tl.book_record_type_id = 'CCRU'
                              and tl.trade_record_id = alt.trade_record_id) l1
                   on true
where alt.alloc_instr_id = -126782
  and (l1.rn = 1 or l1.rn is null);


select
    array_agg(tr.trade_record_id),

    sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as ccru_rate,
                                       max(ccru_amount)                                              as ccru_amount,
                                       sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as brok_rate,
                                       max(brok_amount)                                              as brok_amount
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (
                                    select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                           sum(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                           sum(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                    from (select rate,
                                                 tl.amount,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                          from genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          where tl.date_id = :in_date_id
                                            AND tl.book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id in (2348108029,2348108028,2348108030)--= tl.trade_record_id
                                          ) l0
                                    where true
                                      and (l0.rn = 1 or l0.rn is null)
                                    ) l1 on true
                                where alt.alloc_instr_id = -126782
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end;


select ai.is_deleted, ccr.*
from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as ccru_rate,
                                       max(ccru_amount)                                              as ccru_amount,
                                       sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as brok_rate,
                                       max(brok_amount)                                              as brok_amount
                                select *
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (
                                    select max(case when book_record_type_id = 'CCRU' then l0.rate end)   as ccru_rate,
                                           sum(case when book_record_type_id = 'CCRU' then l0.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then l0.rate end)   as brok_rate,
                                           sum(case when book_record_type_id = 'BROK' then l0.amount end) as brok_amount
                                    from (select rate,
                                                 tl.amount,
                                                 book_record_type_id,
                                                 row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                          from genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          where tl.date_id = :in_date_id
                                            AND tl.book_record_type_id in ('CCRU', 'BROK')
                                            and tl.trade_record_id = alt.trade_record_id
--                                           and tl.trade_record_id in (2348108028,2348108029,2348108030)
                                          ) l0
                                    where true
                                      and (l0.rn = 1 or l0.rn is null)
                                    ) l1 on true
                                where alt.alloc_instr_id = -126782
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
--                                   and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'AllocEntryCCRURate', ccr.ccru_rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.ccru_amount * 1.0 * aie.alloc_qty / total_qty,
                                                               'AllocEntryBROKRate', ccr.brok_rate,
                                                               'AllocEntryBROKTotalAmount',
                                                               ccr.brok_amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
                                                  )
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id =-126782
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             join lateral (select count(*)                                                              as trade_cnt,
                                  jsonb_agg(distinct jsonb_build_object('clOrdId', tr.client_order_id)) as cl_ords,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )                                                                     as trades
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                                    left join lateral (select fix_message ->> '10710' as chain_exec_id
                                                       from staging.fix_message_json fmj
                                                       where fmj.date_id = aitr.date_id
                                                         and fmj.fix_message_id = tr.trade_fix_message_id
                                                       limit 1) fmj on true
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
--                             and is_busted = 'N'
                           limit 1) aitr on true

--              left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
--              left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = -126782
