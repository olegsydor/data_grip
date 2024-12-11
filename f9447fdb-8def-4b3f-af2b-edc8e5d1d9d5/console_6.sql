create table if not exists dash360.bofa_allocation_report
(
    last_qty                      int4                                null,
    alloc_instr_id                int4                                null,
    side                          bpchar(1)                           null,
    avg_px                        numeric(14, 6)                      null,
    date_id                       int4                                null,
    open_close                    bpchar(1)                           null,
    alloc_qty                     int4                                null,
    opt_is_fix_clfirm_processed   bpchar(1)                           null,
    ftr_cmta                      varchar(3)                          null,
    ca_cmta                       varchar(3)                          null,
    opt_is_fix_custfirm_processed bpchar(1)                           null,
    opt_customer_firm             bpchar(1)                           null,
    opt_customer_or_firm          bpchar(1)                           null,
    occ_actionable_id             varchar(10)                         null,
    dataset                       int4                                null,
    to_report                     text                                null,
    db_create_time                timestamp default clock_timestamp() not null
);
create index bofa_allocation_report_alloc_instr_id_idx on dash360.bofa_allocation_report (alloc_instr_id);
create index bofa_allocation_report_date_id_idx on dash360.bofa_allocation_report (date_id);

alter table dash360.bofa_allocation_report drop column trade_record_sheep;

drop function staging.get_all_alloc_instr_id_for_orig;
create function staging.get_all_alloc_instr_id_for_orig(in_alloc_instr_id integer, in_date_id integer, in_trade_record_id int8 default null)
    returns integer[]
    language plpgsql
AS
$function$
    -- 1. We have alloc_instr_id
    -- 2. We calculate all trade_record_id inside it
    -- 3. We found all orig of these trade_records
    -- 4. We found all alloc_instr_id that these origs can be found
declare
    l_trade_record_id_in  int8[];
    l_trade_record_id_out int8[];
    ret_alloc_instr_ids   int4[];
begin
    if in_trade_record_id is null then
        select array_agg(distinct trade_record_id)
        into l_trade_record_id_in
        from genesis2.alloc_instr2trade_record
        where alloc_instr_id = in_alloc_instr_id
          and date_id = in_date_id;
    else
        l_trade_record_id_in := array [in_trade_record_id];
    end if;

    with recursive total (trade_record_id, orig_trade_record_id) as
                       (select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                        where true
                          and tr.trade_record_id = any (l_trade_record_id_in)
                          and tr.date_id = in_date_id

                        union all

                        select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                                 join total on tr.trade_record_id = total.orig_trade_record_id
                        where tr.date_id = in_date_id)
    select array_agg(distinct trade_record_id order by trade_record_id)
    into l_trade_record_id_out
    from total;

    select array_agg(distinct alloc_instr_id order by alloc_instr_id)
    into ret_alloc_instr_ids
    from genesis2.alloc_instr2trade_record
    where trade_record_id = any (l_trade_record_id_out);

    return ret_alloc_instr_ids;
end;
$function$
;



create or replace function dash360.allocation_report(in_start_date_id integer, in_end_date_id integer,
                                          in_exec_broker text default '792'::text)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
        l_load_id int;
    l_step_id int;
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id           int4[];
    l_row_cnt                  int4;
    l_msg_text text;

begin
    l_msg_text := 'allocation_report for ' || in_start_date_id::text || '-' || in_end_date_id::text || 'for ' ||
                  case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ' ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' STARTED ====', 0, 'O')
    into l_step_id;

    -- preparing data
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from dash360.bofa_allocation_report
    where date_id between in_start_date_id and in_end_date_id
    and to_report = 'report'; -- this condition looks excessive


    with base_ins as (
        insert into dash360.bofa_allocation_report
            (last_qty, alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed,
             ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
             occ_actionable_id, dataset, to_report)
            select ftr.last_qty,
                   alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta,             -- ftr_cmta,
                   ca.cmta,              -- ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id, -- occ_actionable_id,
                   l_load_id,            -- dataset,
                   case
                       when ar.date_id is not null then 'skip - current alloc_instr_id'
                       when or_ai.alloc_instr_ids && l_alloc_instr_id_reported then 'skip - alloc_instr_id has been reported before'
                       else 'report' end as to_report
            from genesis2.allocation_instruction_entry ae
                     join genesis2.allocation_instruction alin
                          on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
                     left join lateral (select alloc_instr_ids
                                        from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                                     alin.date_id) as x(alloc_instr_ids)
                                        limit 1) or_ai on true
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm,
                                                tr.last_qty
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and case
                                                                         when in_exec_broker is null then true
                                                                         else tr.exec_broker = in_exec_broker end
                                                                 and tr.exec_broker is not null
                                         where aitr.alloc_instr_id = alin.alloc_instr_id
                                           and aitr.date_id = alin.date_id
                                         limit 1
                ) ftr on true
                     join genesis2.clearing_account ca
                          on (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                              and ca.clearing_account_type = '1' and ca.market_type = 'O')
                     join genesis2.account acc ON (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and
                                                   acc.opt_report_to_mpid = 'MLCB' and
                                                   acc.trading_firm_id <> 'cantor')
                     join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
                     join genesis2.option_series os on os.option_series_id = oc.option_series_id
                     join genesis2.instrument i on i.instrument_id = alin.instrument_id
                     left join lateral (select ar.date_id
                                        from dash360.bofa_allocation_report ar
                                        where ar.alloc_instr_id = ae.alloc_instr_id
                                          and to_report = 'report'
                                        limit 1) ar on true
            where alin.date_id between in_start_date_id and in_end_date_id
              and not exists (select null
                              from dash360.bofa_allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' FINISHED ====', l_row_cnt, 'O')
    into l_step_id;

    return query
        select l_row_cnt::text;

end;
$fn$
;

select * from dash360.bofa_allocation_report