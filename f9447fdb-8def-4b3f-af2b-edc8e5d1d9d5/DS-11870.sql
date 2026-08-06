-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar, bool, _bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_snapshot___(in_account_ids bigint[] DEFAULT '{}'::bigint[],
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
                manual_broker_code         character varying,
                lifecycle_order_id int8,
                lifecycle_order_state char(1)
            )
    LANGUAGE plpgsql
 COST 1
AS $function$
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
                   when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts) then fmj.manual_broker_code::character varying end,
            -- LIFECYCLE
               case
                   when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                       then lc.lifecycle_orderid
                   when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts)
                       then fmjo.lifecycleorderid::int8 end               as lifecycle_order_id,
               case
                   when tr.subsystem_id = 'OMS_EDW' and tr.account_id = any (l_sg_accounts)
                       then lc.lifecycle_orderid_status
--                    when not (tr.subsystem_id = 'OMS_EDW') and tr.account_id = any (l_sg_accounts)
--                        then fmj.manual_broker_code::character varying
                   end as lifecycle_order_id
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
                                           fix_message ->> '10568' as manual_broker_code
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
        left join lateral(select fix_message ->> '10609' as lifecycleorderid
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
                   else ccr.manual_broker[1] end                 as manual_broker_code
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
                                                                          in_fix_message_id := tr.trade_fix_message_id) end) as manual_broker
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

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instruction part finished', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;


select order_id, *
from genesis2.trade_record tr
where true
  and tr.date_id >= 20260801
  and tr.account_id = any
      ('{265273,264817,263290,263297,263298,263300,263303,263301,263743,263289,263296,263299,263815,264145,263330,264228,263346,263347,263732,263718,263368,263873,263378,263382,263395,263744,263288,263354,263376,263408,263409,263410,263411,263412,263426,263427,263428,263430,263471,263472,263489,263490,263492,263493,263433,263434,263403,263404,263405,263494,263495,263496,263500,263501,263563,263565,263566,263567,263568,263571,263572,263598,263597,263599,263600,263601,263606,263607,263618,263619,263620,263621,263629,263632,263633,263672,263684,263714,263715,263716,263717,263719,263720,263721,263722,263725,263727,263728,263729,263730,263731,263747,263765,263766,263767,263792,263803,263804,263805,263806,263807,263808,263810,263819,263822,263823,263824,263825,263826,263827,263828,263848,263851,263852,263855,263857,263859,263860,263861,263863,263866,263867,263868,263870,263878,263885,263895,263896,263898,263902,263903,263904,263905,263915,263916,263917,263918,263919,263959,263964,263965,263992,264024,264084,264105,264106,264108,264109,264110,264111,264121,264123,264129,264140,264141,264144,264148,264149,264150,264169,264171,264172,264178,264179,264180,264207,264221,264222,264224,264225,263963,264227,264229,264230,264273,264274,264275,264276,264277,264283,264284,264373,264374,264375,264376,264533,264534,264556,264557,264558,264573,264574,264575,264593,264594,264595,264596,264597,264604,264608,264818,264879,264896,264894,264897,265065,265073,265074,265075,265093,265113,265115,265117,265118,263397,263399,265481,265513,265491,265492,265493,265494,265495,265496,265497,265498,265499,265500,265501,265502,265503,265504,265505,265506,265507,265508,265509,265510,265511,265512,265514,265515,265516,265517,265518,265519,265520,265521,265522,265523,265524,265525,265526,265527,265528,265529,265530,265531,265533,265534,265535,265536,265537,265538,265539,265540,265541,265542,265543,265544,265545,265547,265548,265549,265550,265551,265552,265546,265532,265553,265554,265555,265556,265557,265558,265559,265560,265561,265562,265563,265564,265565,265566,265567,265568,265569,265570,265571,265572,265573,265574,265575,265576,265577,265578,265579,265580,265581,265582,265583,265584,265585,265586,265587,265588,265589,265590,265591,265592,265593,265594,265595,265596,265597,265598,265599,265600,265601,265602,265603,265604,265605,265606,265607,265608,265609,265610,265611,265612,265613,265614,265615,265616,265617,265618,265619,265620,265621,265622,265623,265624,265625,265626,265627,265628,265629,265630,265631,265632,265633,265634,265635,265636,265637,265638,265639,265640,265641,265642,265643,265644,265645,265646,265647,265648,265649,265650,265651,265652,265653,265654,265655,265656,265657,265658,265659,265660,265661,265662,265663,265664,265665,265666,265667,265668,265669,265670,265671,265672,265673,265674,265675,265676,265677,265678,265679,265680,265681,265682,265683,265684,265685,265686,265687,265693,263435,263406,264793,264813,266093,266094,266095,264814,266293,266294,266296,266314,266317,266333,263832,266395,263302,266473,263774,263809,266393,266733,266753,266754,266756,266755,266759,266760,263776,263961,263980,264062,264107,264124,264196,264255,264280,264281,264282,264576,265114,266313,266315,266394,266433,266434,266793,263761,263762,264127,264216,263677,263680,263756,263757,263758,263760,263763,263752,263754,263764,263772,263681,264218,264633,265193,264158,264012,264013,264773,264774,264754,264755,265201,265214,265216,265694,265695,265696,265697,265698,265699,265700,265701,265702,265703,265704,265705,265706,265707,265708,265709,265710,265711,265712,265713,265714,265715,265716,265717,265718,265719,265720,265721,265722,265723,265724,265725,265726,265727,265728,265729,265730,265731,265732,265733,265734,265735,265736,265737,265738,265739,265740,265741,265742,265743,265744,265745,265746,265747,265748,265749,265750,265751,265752,265753,265754,265755,265756,265757,265758,265759,265760,265761,265762,265763,265764,265765,265766,265767,265768,265769,265770,265771,265772,265773,265774,265775,265776,265777,265778,265779,265780,265781,265782,265783,265784,265785,265786,265787,265788,265789,265790,265791,265792,265793,265794,265795,265796,265797,265798,265799,265800,265801,265802,265803,265804,265805,265806,265807,265808,265809,265810,265811,265812,265813,265814,265815,265816,265817,265818,265819,265820,265821,265822,265823,265824,265825,265826,265827,265828,265829,265830,265831,265832,265833,265834,265835,265836,265837,265838,265839,265840,265841,265842,265843,265844,265845,265846,265847,265848,265849,265850,265851,265852,265853,265854,265855,265856,265857,265858,265859,265860,265861,265862,265863,265864,265865,265866,265867,265868,265869,265870,265871,265872,265873,265874,265875,265876,265877,265878,265879,265880,265881,265882,265883,265884,265885,265886,265887,265888,265889,265890,265891,264120,264254,263957,264513,264514,264515,264733,263000,263001,263420,263674,263784,263785,263786,263787,263816,264023,264101,264253,264287,264673,264713,263817,264116,263627,264609,266097,266098,266099,266100,266101,266102,266103,266104,266105,266106,266107,266096,266108,266109,266110,266111,266112,266113,266114,266115,266116,266117,266118,266119,266120,266121,266122,266123,266124,266125,266126,266127,266128,266129,266130,266131,266132,266133,266134,266135,266136,266137,266138,266139,266140,266141,266142,266143,266144,266145,266146,266147,266148,266149,266150,266151,266152,266153,266154,266155,266156,266157,266158,266159,266160,266161,266162,266163,266164,266165,266166,266167,266168,266169,266170,266171,266172,266173,266174,266175,266176,266177,266178,266179,266180,266181,266182,266183,266184,266185,266186,266187,266188,266189,266190,266191,266192,266193,266194,266195,266196,266197,266198,266199,266200,266201,266202,266203,266204,266205,266206,266207,266208,266209,266210,266211,266212,266213,266214,266215,266216,266217,266218,266219,266220,266221,266222,266223,266224,266225,266226,266227,266228,266229,266230,266231,266232,266233,266234,266235,266236,266237,266238,266239,266240,266241,266242,266243,266244,266245,266246,266247,266248,266249,266250,266251,266262,266261,266260,266259,266258,266256,266255,266254,266252,266264,266265,266266,266267,266268,266269,266270,266271,266272,266273,266274,266275,266276,266277,266278,266279,266280,266263,266257,266253,264089,263768,263421,263015,263002,264151,264152,264153,263203,263270,263271,263358,263202,263201,263281,263294,263204,263205,263206,263207,263208,263209,263359,263360,263379,263396,263402,263564,263401,263361,263363,263645,263643,263644,263789,263795,263796,263797,263813,263814,263830,263831,264293,264294,264295,264296,264297,264413,264414,264433,264434,264654,264653,263362,264855,264016,264017,264018,264115,263700,263701,264098,266813,266853,266873,266874,266913}')
  and tr.subsystem_id = 'OMS_EDW'
  and is_busted = 'N';

