drop function if exists dash360.bofa_allocation_entry_history;

create or replace function dash360.bofa_allocation_entry_history(in_date_id integer, in_exec_broker text)
    returns table
            (
                ret_row text
            )
    language plpgsql
    -- OS 20250305 https://dashfinancial.atlassian.net/browse/DS-8204
as
$fx$
declare
    l_load_id  int;
    l_step_id  int;
    l_row_cnt  int4;
    l_msg_text text;

begin
    l_msg_text := 'bofa_allocation_entry_history ' || in_date_id::text ||
                  ' for ' || case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ':';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data STARTED ====', 0, 'O')
    into l_step_id;


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

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data completed ====', 0, 'O')
    into l_step_id;

    return query
        select
            array_to_string(ARRAY [
               tr.exec_broker            , -- as "Exec Broker",     --list of all exec_broker from trades releated to AI. e.g. 333, 733, 792.
               'allocation'              , -- as "Type",            --show `allocation` if we generate line from allocation, `trade` if from trade record
               ac.account_name           , -- as "Account Name",    -- taken from account_id
               ai.alloc_instr_id::text   , -- as "Alloc Instr ID",
               di.display_instrument_id2 , -- as "Symbol",          -- display_instrument_v2
               ai.side                   , -- as "Side",
               ai.open_close             , -- as "O/C",
               aie.alloc_qty::text             , -- as "Exec Qty",
               to_char(ai.avg_px, 'FM999990.009999'), -- as "Avg Px",
               ca.CMTA                   , -- as "CMTA",
               aie.occ_actionable_id     , -- as "OCC AID",
               rep.to_report             , -- as "Reported Status",
               rep.db_create_time::text  , -- as "Reported Time",   --better recursion, but otherwise use our logic.
               ai.is_deleted             , -- as "Alloc is deleted",
               ai.create_time::text      , -- as "Created Time",
               uic.user_name             , -- as "Created by User", -- Taken from Users dictionary
               ui.user_name              , -- as "Deleted by User", -- Taken from Users dicitionary by deleted_user_id
               ai.delete_time::text        -- as "Deleted time"
                ], ',', '')
        from genesis2.allocation_instruction ai
                 join allocation_instruction_entry aie
                      on (aie.alloc_instr_id = ai.alloc_instr_id and aie.date_id = ai.date_id)
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = ai.alloc_instr_id and aitr.date_id = ai.date_id)
                                 and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
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
                 left join genesis2.clearing_account ca
                           on ca.account_id = aie.clearing_account_id and ca.clearing_account_type = '1' and
                              ca.market_type = 'O'
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = ai.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'

                 left join lateral (select max(
                                                   case ca.market_type
                                                       when 'E' then ca.clearing_account_number
                                                       end::text) as eq_clearing_account_number,
                                           ca.account_id
                                    from genesis2.clearing_account ca
                                    where ca.is_default = 'Y'
                                      and ca.is_deleted <> 'Y'
                                    group by ca.account_id, ca.is_visible_for_manual_allocation) cla
                           on cla.account_id = ac.account_id
        where ai.date_id = in_date_id
          and case
                  when ac.opt_report_to_mpid = 'MLCB' then true
                  when ac.eq_report_to_mpid = 'MLCB' and
                       (coalesce(cla.eq_clearing_account_number, 'null alternative'::text) <> all
                        (array ['3Q800806'::text, '3Q800797'::text, '3Q800809'::text])) then true
                  else false
            end;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data completed ====', l_row_cnt, 'O')
    into l_step_id;

end;
$fx$;

select * from dash360.bofa_allocation_entry_history(in_date_id := 20250404, in_exec_broker := '733')