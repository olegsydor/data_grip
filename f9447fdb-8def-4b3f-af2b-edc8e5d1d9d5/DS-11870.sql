select * from trash.allocations_snapshot(in_date_id := 20260807);
select * from dash360.allocations_snapshot(in_date_id := 20260807), in_hide_non_customer_bphops := true);
drop FUNCTION trash.allocations_snapshot;

-- DROP FUNCTION trash.allocations_snapshot(_int8, int4, bpchar, bool, _bpchar);

CREATE OR REPLACE FUNCTION trash.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                      in_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
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
                manual_broker_code         character varying,
                lifecycle_order_id         character varying,
                lifecycle_order_state      character
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
    -- SY 20260610 https://dashfinancial.atlassian.net/browse/DS-11651 Reimplement hot fix from 20250305
    -- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
    -- SO 20260612 https://dashfinancial.atlassian.net/browse/DS-11642 Add manual broker
    -- SO 20270720 https://dashfinancial.atlassian.net/browse/DS-11700 Performance improvement
    -- SO 20280810 https://dashfinancial.atlassian.net/browse/DS-11870 Adjust allocation procedures to Lifecycle Order ID and Lifecycle Order Status
    -- SO 20260812 https://dashfinancial.atlassian.net/browse/DS-11887 Implement filtering out values by BlazeIsLinked (FIX 10579) and BlazeIsPartOfStitchedOrder (10585) in allocation snapshot
declare
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int4;
    l_msg_text    text;
    l_sg_accounts int8[];
begin
    l_msg_text := 'admin_allocations_snapshot ' || in_date_id::text || ':';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' STARTED ====', 0, 'O')
    into l_step_id;


    drop table if exists t_trade_record;
    create temp table t_trade_record
    as
    select distinct on (atr.trade_record_id, br.to_report, br.alloc_instr_id) atr.trade_record_id,
                                                                              br.to_report,
                                                                              br.alloc_instr_id,
                                                                              br.db_create_time,
                                                                              'B'     as alloc_rep_type,
                                                                              case
                                                                                  when br.to_report is distinct from 'U'
                                                                                      then br.to_report
                                                                                  when staging.get_fully_reported_trade(br.alloc_instr_id, br.date_id) = 1 -- means that only one value is possible in related trade_records and it can be only R
                                                                                      then 'U'
                                                                                  else 'W'
                                                                                  end as to_report_mod
    from dash_reporting.bofa_allocation_report br
             join genesis2.alloc_instr2trade_record atr
                  on atr.alloc_instr_id = br.alloc_instr_id and atr.date_id = br.date_id
    where br.date_id = in_date_id
    union all
    select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type, to_report
    from dash_reporting.bofa_trade_record btr
    where btr.date_id = in_date_id;

    get diagnostics l_row_cnt = row_count;


    select array_agg(ac.account_id)
    into l_sg_accounts
    from account ac
             join staging.sg_trading_firm using (trading_firm_id)
    where ac.is_deleted = 'N';


    analyze t_trade_record;
    create index on t_trade_record (trade_record_id);
    create index on t_trade_record (alloc_instr_id);

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' t_trade_record created', l_row_cnt, 'O')
    into l_step_id;

    drop table if exists t_alloc_instr2trade_record;
    create temp table t_alloc_instr2trade_record as
    select ai2tr.trade_record_id, a.alloc_instr_id, a.date_id
    from genesis2.allocation_instruction a
             inner join genesis2.alloc_instr2trade_record ai2tr
                        on (a.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = a.date_id)
    where true
      and case when in_account_ids = '{}' then true else a.account_id = any (in_account_ids) end
      and a.date_id = in_date_id
      and a.is_deleted = 'N';
    create index on t_alloc_instr2trade_record (trade_record_id);

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' t_alloc_instr2trade_record created', l_row_cnt, 'O')
    into l_step_id;

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
               coalesce(x.db_create_time,
                        rep.db_create_time)                                                             as reported_time,
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
               case
                   when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                       then (select manual_broker::character varying
                             from staging.trade_record_blaze7 as bl
                             where bl.date_id = tr.date_id
                               and bl.exec_id = tr.exec_id
                               and bl.manual_broker is not null
                             limit 1)
                   when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts)
                       then fmj.manual_broker_code::character varying end,
               -- LIFECYCLE
               case
                   when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                       then lc.lifecycle_orderid::character varying
                   when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts)
                       then fmjo.lifecycleorderid::character varying end                                as lifecycle_order_id,
               case
                   when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                       then lc.lifecycle_orderid_status::char(1)
                   when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts)
                       then (select lifecycle_orderid_status::char(1)
                             from genesis2.blaze_lifecycle_order
                             WHERE parent_order_id = fmjo.lifecycleorderid::int8
                             limit 1)
                   end                                                                                  as lifecycle_order_state
--         select *
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join t_alloc_instr2trade_record as allocated_trades
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
                                      and false
                                    limit 1) bas on true

                 left join lateral (select max(case when book_record_type_id = 'CCRU' then L1.rate end)   as ccru_rate,
                                           sum(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           sum(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
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
                 left join lateral (select msg.db_create_time, msg.drop_message_status, msg.drop_message_reject_reason
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                      and false
                                    limit 1) msg on true
                 left join lateral (select fix_message ->> '10707' as chain_id,
                                           fix_message ->> '10568' as manual_broker_code,
                                           fix_message ->> '10579' as blaze_is_linked,
                                           fix_message ->> '10585' as blaze_is_part_of_stitched_order
                                    from staging.fix_message_json fmj
                                    where fmj.date_id = tr.date_id
                                      and fmj.fix_message_id = tr.trade_fix_message_id
                                    limit 1) fmj on true

                 left join lateral (select fpo.order_status
                                    from staging.f_parent_order fpo
                                    where fpo.status_date_id = in_date_id
                                      and fpo.parent_order_id = tr.order_id
                                    limit 1) fpo on true and tr.subsystem_id is distinct from 'OMS_EDW'
                 left join lateral (select min(ttr.db_create_time) as db_create_time
                                    from t_trade_record ttr
                                    where true
                                      and ttr.trade_record_id = tr.trade_record_id
--                                  order by db_create_time
                                    limit 1) x on true and coalesce(nullif(tr.is_billed, 'N'), rep.to_report) = 'R'
                 left join lateral (select lifecycle_orderid, lifecycle_orderid_status
                                    from genesis2.blaze_lifecycle_order bl
                                    where bl.parent_order_id = tr.order_id
                                    limit 1) lc on true
                 left join lateral (select fix_message ->> '10609' as lifecycleorderid
                                    from staging.fix_message_json fmj
                                    where fmj.date_id = tr.date_id
                                      and fmj.fix_message_id = tr.order_fix_message_id
                                    limit 1) fmjo on true

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
                  when in_hide_non_customer_bphops and (blaze_is_linked is not distinct from 'Y' or
                                                        blaze_is_part_of_stitched_order is not distinct from 'Y')
                      then false
                  else true end
          and case
                  when in_client_order_states is null then true
                  else fpo.order_status is not null and fpo.order_status = any (in_client_order_states) end;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' trade_record part finished', l_row_cnt, 'O')
    into l_step_id;

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
                   end                                           as principal_amount,
               ccr.ccru_rate                                     as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying as user_name,
               ccr.blaze_account_alias::character varying,
               null::timestamp without time zone                 as street_exec_time,
               -------
               i.last_trade_date,
               null::character                                   as opt_customer_or_firm,
               rep.to_report_mod::character                      as reported_status,
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
                   else ccr.manual_broker[1] end                 as manual_broker_code,
               case
                   when array_length(ccr.lifecycle_order_id, 1) > 1 then '-'
                   else ccr.lifecycle_order_id[1] end            as lifecycle_order_id,
               case
                   when array_length(ccr.lifecycle_order_state, 1) > 1 then '-'::char(1)
                   else ccr.lifecycle_order_state[1] end         as lifecycle_order_state
        from genesis2.allocation_instruction ai
                 inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
                 left join lateral (select to_report_mod,
                                           to_report,
                                           rep.db_create_time
                                    from t_trade_record rep
                                    where rep.alloc_instr_id = ai.alloc_instr_id
                                    order by rep.db_create_time
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

                 left join lateral (select sum(l1.ccru_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                     as ccru_rate,
                                           case
                                               when count(distinct tr.blaze_account_alias) = 1
                                                   then max(tr.blaze_account_alias)
                                               when count(distinct tr.blaze_account_alias) > 1 then '-'
                                               end                                                                           as blaze_account_alias,
                                           string_agg(distinct tr.exec_broker, ', ')                                         as exec_broker,
                                           sum(ccru_amount)                                                                  as ccru_amount,
                                           array_agg(distinct tr.client_order_id)                                            as client_order_id,
                                           array_agg(distinct fpo.order_status)                                              as order_status,
                                           sum(l1.brok_rate * tr.last_qty) / nullif(sum(tr.last_qty), 0)                     as brok_rate,
                                           sum(brok_amount)                                                                  as brok_amount,
                                           array_agg(distinct case
                                                                  when tr.account_id = any (l_sg_accounts)
                                                                      then genesis2.get_manual_broker(
                                                                          in_subsystem_id := tr.subsystem_id,
                                                                          in_date_id := tr.date_id,
                                                                          in_exec_id := tr.exec_id,
                                                                          in_fix_message_id := tr.trade_fix_message_id) end) as manual_broker,
                                           array_agg(distinct case
                                                                  when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                                                                      then lc.lifecycle_orderid::character varying
                                                                  when not (tr.subsystem_id = 'OMS_EDW') and
                                                                       tr.account_id = any (l_sg_accounts)
                                                                      then fmjo.lifecycleorderid end)                        as lifecycle_order_id,
                                           array_agg(distinct case
                                                                  when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                                                                      then lc.lifecycle_orderid_status::char(1)
                                                                  when not (tr.subsystem_id = 'OMS_EDW') and
                                                                       tr.account_id = any (l_sg_accounts)
                                                                      then (select lifecycle_orderid_status::char(1)
                                                                            from genesis2.blaze_lifecycle_order
                                                                            WHERE parent_order_id = fmjo.lifecycleorderid::int8
                                                                            limit 1)
                                               end)                                                                          as lifecycle_order_state
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
                                              where tl.date_id = in_date_id
                                                AND tl.book_record_type_id in ('CCRU', 'BROK')
                                                and tl.trade_record_id = alt.trade_record_id) l0
                                        where true
                                          and (l0.rn = 1 or l0.rn is null)
                                        ) l1 on true
                                             left join lateral (select distinct case when tr.subsystem_id = 'OMS_EDW' then '2' else fpo.order_status end as order_status
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id) fpo on true
                                             left join lateral (select lifecycle_orderid, lifecycle_orderid_status
                                                                from genesis2.blaze_lifecycle_order bl
                                                                where bl.parent_order_id = tr.order_id
                                                                limit 1) lc on true
                                             left join lateral (select fix_message ->> '10609' as lifecycleorderid
                                                                from staging.fix_message_json fmj
                                                                where fmj.date_id = tr.date_id
                                                                  and fmj.fix_message_id = tr.order_fix_message_id
                                                                limit 1) fmjo on true
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

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instruction part finished', l_row_cnt, 'O')
    into l_step_id;

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
                client_order_status      character,
                broker_commission_rate   numeric,
                broker_commission_amount numeric,
                manual_broker_code       character varying,
                lifecycle_order_id         character varying,
                lifecycle_order_state      character
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
                   --SY  in_trade_record_id := tr.trade_record_id,
                                          in_exec_id := tr.exec_id,
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
                                           sum(case when book_record_type_id = 'CCRU' then l1.amount end) as ccru_amount,
                                           max(case when book_record_type_id = 'BROK' then L1.rate end)   as brok_rate,
                                           sum(case when book_record_type_id = 'BROK' then l1.amount end) as brok_amount
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
