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

alter table dash360.bofa_allocation_report add column if not exists instrument_id int8;
alter table dash360.bofa_allocation_report add column if not exists opt_is_fix_custfirm_processed char;
alter table dash360.bofa_allocation_report add column if not exists opt_penny_commission numeric(12, 4);
alter table dash360.bofa_allocation_report add column if not exists opt_nickel_commission numeric(12, 4);
alter table dash360.bofa_allocation_report add column if not exists root_symbol varchar(10);
alter table dash360.bofa_allocation_report add column if not exists min_tick_increment numeric(12, 4);
alter table dash360.bofa_allocation_report add column if not exists put_call char;
alter table dash360.bofa_allocation_report add column if not exists maturity_year int2;
alter table dash360.bofa_allocation_report add column if not exists maturity_month int2;
alter table dash360.bofa_allocation_report add column if not exists maturity_day int2;
alter table dash360.bofa_allocation_report add column if not exists strike_price  numeric(12, 4);




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

select * from dash360.allocation_report(20241223, 20241223, null)

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
             occ_actionable_id, dataset, instrument_id,
             opt_penny_commission, opt_nickel_commission, root_symbol, min_tick_increment, put_call,
             maturity_year, maturity_month, maturity_day, strike_price,
             to_report)
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
                   alin.instrument_id,
                   acc.opt_penny_commission, -- numeric(12, 4)
                   acc.opt_nickel_commission,-- numeric(12, 4)
                   os.root_symbol,
                   os.min_tick_increment,
                   oc.put_call,
                   oc.maturity_year,
                   oc.maturity_month,
                   oc.maturity_day,
                   oc.strike_price,
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

select dataset, to_report, count(*)
from dash360.bofa_allocation_report
where true
  and dataset = 13390122
group by dataset, to_report;


select * from dash360.bofa_allocation_report
             where dataset = 13390122;


-52942
-52943
2346622521
2346622513

select * from staging.all_orig_trade_record_id_today(2346622521, 20241212) as x(trade_record_ids)
-- 2346622513


select * from trash.get_all_parent_alloc_instr_id(-52943, 20241212)

select * from genesis2.alloc_instr2trade_record
where alloc_instr_id in(-52943, -52942)


create temp table t_reported as
select trade_record_id, atr.alloc_instr_id, dataset
from dash360.bofa_allocation_report bar
         join genesis2.alloc_instr2trade_record atr
              on atr.alloc_instr_id = bar.alloc_instr_id and atr.date_id = bar.date_id
where true
--   and dataset < 810511
  and to_report = 'report'

select * from t_reported

create or replace function trash.so_f_nonreported_trade_record_reason(in_trade_record int8, in_dataset int4,
                                                           in_date_id int4 default to_char(current_date, 'YYYMMDD')::int4)
    returns table
            (
                trade_record_id int8,
                alloc_instr_id  int4,
                dataset         int4
            )
    language plpgsql
as
$fx$
declare

begin

    return query
        with cte_reported as (select atr.trade_record_id, atr.alloc_instr_id, bar.dataset
                              from dash360.bofa_allocation_report bar
                                       join genesis2.alloc_instr2trade_record atr
                                            on atr.alloc_instr_id = bar.alloc_instr_id and atr.date_id = bar.date_id
                              where true
                                and bar.dataset < in_dataset
                                and bar.to_report = 'report'
                                and bar.date_id = in_date_id)
        select tr.trade_record_id, tr.alloc_instr_id, tr.dataset
        from cte_reported tr
        where tr.trade_record_id = any (staging.all_orig_trade_record_id_today(in_trade_record, in_date_id));

end;
$fx$;




select bar.alloc_instr_id, atr.trade_record_id, bar.dataset, atr.date_id, (trash.so_f_nonreported_trade_record_reason(atr.trade_record_id, bar.dataset, atr.date_id)).*
from dash360.bofa_allocation_report bar
join genesis2.alloc_instr2trade_record atr on bar.alloc_instr_id = atr.alloc_instr_id
where atr.alloc_instr_id in (-52942,-52943);

select * from t_reported
where trade_record_id = any(staging.all_orig_trade_record_id_today(2346622521, 20241212))


select * from staging.all_orig_trade_record_id_today(2346622521, 20241212)
2346622521
2346622513
2346622515

         select * from trash.so_f_nonreported_trade_record_reason(2346622521, 13390122, 20241212)

select *
from dash360.bofa_allocation_report bar;


drop table if exists dash_reporting.bofa_allocation_instruction_status;
create table if not exists dash_reporting.bofa_allocation_instruction_status
(
    alloc_instr_id int4      not null
        constraint bofa_allocation_instruction_status_pk primary key,                                                   -- link to allocation instruction
    date_id        int4      not null,
    claimed_by     int4      null
        constraint bofa_allocation_instruction_status_user_identifier_fk references genesis2.user_identifier (user_id), -- user id (probably - foreign key to the dictionary of users
    claim_status   bpchar    not null default 'O',                                                                      -- status. 'O' - unclaimed (default & initial), 'C' - claimed, 'R' - resolved
    db_update_time timestamp not null default clock_timestamp()                                                         -- create\last update time
);
comment on table dash_reporting.bofa_allocation_instruction_status is 'Table contains information on the current claim/resolve status on Allocation Instructions that are unreportable in BOFA report. Only Admins can change the satatus';
comment on column dash_reporting.bofa_allocation_instruction_status.alloc_instr_id is 'link to allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.date_id is 'link to date_id of allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.claimed_by is 'user id from genesis2.user_identifier';
comment on column dash_reporting.bofa_allocation_instruction_status.claim_status is $$status. 'O' - unclaimed (default & initial), 'C' - claimed, 'R' - resolved$$;
comment on column dash_reporting.bofa_allocation_instruction_status.db_update_time is 'create\last update time';

-- alter table dash360.bofa_allocation_instruction_status set schema dash_reporting;

select * from genesis2.user_identifier;

drop function if exists dash360.get_status_to_bofa_allocation_instruction;
create or replace function dash360.get_status_to_bofa_allocation_instruction(in_alloc_iinstr_id int4)
    returns table
            (
                alloc_instr_id int4,
                claimed_by     int4,
                user_name      text,
                claim_status   bpchar,
                db_update_time timestamp
            )
    language plpgsql
as
$fx$
    -- 20241230 SO https://dashfinancial.atlassian.net/browse/D360-15023
begin
    return query
        select bas.alloc_instr_id, bas.claimed_by, ui.user_name::text, bas.claim_status, bas.db_update_time
        from dash_reporting.bofa_allocation_instruction_status bas
                 left join genesis2.user_identifier ui on ui.user_id = bas.claimed_by
        where bas.alloc_instr_id = in_alloc_iinstr_id;
end;
$fx$;
comment on function dash360.get_status_to_bofa_allocation_instruction is 'The function gets claim status for an Un-reportable Allocation Instruction';


drop function if exists dash360.set_status_to_bofa_allocation_instruction;
create or replace function dash360.set_status_to_bofa_allocation_instruction(in_alloc_instr_id int4,
                                                                             in_claimed_by int4,
                                                                             in_target_claim_status bpchar)
    returns table
            (
                alloc_instr_id int4,
                claimed_by     int4,
                user_name      text,
                claim_status   bpchar,
                db_update_time timestamp
            )
    language plpgsql
as
$fx$
    -- 20241230 SO https://dashfinancial.atlassian.net/browse/D360-15023

begin

    insert into dash_reporting.bofa_allocation_instruction_status (alloc_instr_id, date_id, claimed_by, claim_status)
    select ai.alloc_instr_id, ai.date_id, in_claimed_by, in_target_claim_status
    from genesis2.allocation_instruction ai
    where ai.alloc_instr_id = in_alloc_instr_id
    on conflict on constraint bofa_allocation_instruction_status_pk
        do update
        set claimed_by     = excluded.claimed_by,
            claim_status   = excluded.claim_status,
            db_update_time = clock_timestamp();

    return query
        select bas.alloc_instr_id, bas.claimed_by, ui.user_name::text, bas.claim_status, bas.db_update_time
        from dash_reporting.bofa_allocation_instruction_status bas
                 left join genesis2.user_identifier ui on ui.user_id = bas.claimed_by
        where bas.alloc_instr_id = in_alloc_instr_id;
end;
$fx$;
comment on function dash360.set_status_to_bofa_allocation_instruction is 'The function sets claim status for an Un-reportable Allocation Instruction';

select * from genesis2.allocation_instruction

select * from dash360.set_status_to_bofa_allocation_instruction(453, 521, 'C');
select * from dash360.get_status_to_bofa_allocation_instruction(453);

select * from dash360.so_allocations_snapshot(in_account_ids := '{}', in_date_id := 20241224, in_reported_status := null);

select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53720);
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -52631);
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53737);


create or replace function dash360.allocation_trade_record_monitor(in_date_id integer, in_account_ids bigint[] default '{}'::bigint[])
    returns table
            (
                account_id                      bigint,
                trading_firm_id                 character varying,
                trades_cnt                      bigint,
                trades_qty                      bigint,
                trades_principal                numeric,
                trades_qty_expiring             bigint,
                unallocated_trades_cnt          bigint,
                unallocated_trades_qty          bigint,
                unallocated_trades_principal    numeric,
                unallocated_trades_qty_expiring bigint,
                allocated_trades_cnt            bigint,
                allocated_trades_qty            bigint,
                allocated_trades_principal      numeric,
                allocated_trades_qty_expiring   bigint,
                unable_trades_cnt               bigint,
                unable_trades_qty               bigint,
                unable_trades_principal         numeric,
                unresolved                      int4,
                resolved                        int4
            )
    LANGUAGE plpgsql
AS
$function$
declare

begin

    drop table if exists tmp_trade_record_monitor;
    create temp table tmp_trade_record_monitor as
    select ac.account_id,
           ac.trading_firm_id,
           tr.trade_record_id,
           tr.last_qty,
           tr.last_px,
           tr.instrument_id,
           case
               when to_char(di.last_trade_date, 'YYYYMMDD')::int4 = in_date_id then true
               else false end         as expiring_today,
           case
               when al.alloc_instr_id is not null then 'allocated'
               else 'unallocated' end as is_alloc,
           case
               when un.alloc_instr_id is not null then true
               end                    as is_unable,
           bas.claim_status
    from genesis2.trade_record tr
             join genesis2.instrument di on di.instrument_id = tr.instrument_id
             join genesis2.account ac on tr.account_id = ac.account_id
             left join genesis2.alloc_instr2trade_record atr
                       on atr.trade_record_id = tr.trade_record_id and atr.date_id = in_date_id
             left join lateral (select atr.alloc_instr_id
                                from genesis2.allocation_instruction ai
                                where ai.alloc_instr_id = atr.alloc_instr_id
                                  and ai.is_deleted = 'N'
                                limit 1) al on true
             left join lateral ( select bar.alloc_instr_id
                                 from dash_reporting.bofa_allocation_report bar
                                 where bar.alloc_instr_id = atr.alloc_instr_id
                                   and bar.date_id = atr.date_id
                                   and bar.to_report <> 'report'
                                 limit 1) un on true
             left join dash_reporting.bofa_allocation_instruction_status bas
                       on bas.date_id = atr.date_id and bas.alloc_instr_id = atr.alloc_instr_id
    where true
      and tr.is_busted <> 'Y'
      and tr.date_id = in_date_id
      and di.instrument_type_id = 'O'
      and case when in_account_ids = '{}' then true else ac.account_id = any (in_account_ids) end;


    return query
        select trm.account_id,
               trm.trading_firm_id,
               --
               count(trm.trade_record_id)                                                       as trades_cnt,
               sum(trm.last_qty)                                                                as trades_qty,
               sum(trm.last_qty * trm.last_px)                                                  as trades_principal,
               sum(case when trm.expiring_today then 1 else 0 end)                              as trades_qty_expiring,
               -- unallocated
               sum(case when trm.is_alloc = 'unallocated' then 1 else 0 end)                    as unallocated_trades_cnt,
               sum(case when trm.is_alloc = 'unallocated' then last_qty else 0 end)             as unallocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'unallocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as unallocated_trades_principal,
               sum(case when trm.is_alloc = 'unallocated' and expiring_today then 1 else 0 end) as unallocated_trades_qty_expiring,
               -- allocated
               sum(case when trm.is_alloc = 'allocated' then 1 else 0 end)                      as allocated_trades_cnt,
               sum(case when trm.is_alloc = 'allocated' then last_qty else 0 end)               as allocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'allocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as allocated_trades_principal,
               sum(case when trm.is_alloc = 'allocated' and expiring_today then 1 else 0 end)   as allocated_trades_qty_expiring,
               -- unable
               sum(case when trm.is_unable then 1 else 0 end)                                   as unable_trades_cnt,
               sum(case when trm.is_unable then last_qty else 0 end)                            as unable_trades_qty,
               sum(case
                       when trm.is_unable then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as unable_trades_principal,
               sum(case when trm.claim_status != 'R' then 1 else 0 end)::int4                   as unresolved,
               sum(case when trm.claim_status = 'R' then 1 else 0 end)::int4                    as resolved
-- select *
        from tmp_trade_record_monitor trm
                 left join genesis2.option_contract oc on oc.instrument_id = trm.instrument_id
                 left join genesis2.option_series os on os.option_series_id = oc.option_series_id
        group by trm.account_id, trm.trading_firm_id;
end;
$function$
;

select * from dash360.allocation_trade_record_monitor(20241217);
select * from tmp_trade_record_monitor;