alter table dash360.bofa_allocation_report drop column last_qty;
update dash360.bofa_allocation_report
set to_report = case
                    when to_report = 'report' then 'R'
                    when to_report = 'skip - alloc_instr_id has been reported before' then 'U'
                    else 'C'
    end;

alter table dash360.bofa_trade_record set schema dash_reporting
    alter column to_report type bpchar;
-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4);

select * from dash360.bofa_allocation_report;
drop function dash360.so_allocations_snapshot;
create function dash360.so_allocations_snapshot(in_account_ids bigint[] default '{}'::bigint[],
                                                in_date_id integer default public.get_dateid(current_date),
                                                in_reported_status bpchar(1) default null::bpchar(1))
    returns table
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                alloc_instr_id         integer,
                alloc_time             timestamp without time zone,
                is_allocated           boolean,
                is_bundle              boolean,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                username               character varying,
                blaze_account_alias    character varying,
                street_exec_time       timestamp without time zone,
                expiration_date        timestamp without time zone,
                opt_customer_firm      char,
                reported_status        bpchar,
                reported_time          timestamp,
                claimed_by             int4,
                claim_status           bpchar
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --in_date_id = 20190301;
    -- VP 20231030 https://dashfinancial.atlassian.net/browse/DS-7465 [ALLOC] Return street_exec_time in dash360.allocations_snapshot()
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters and removed if-else condition for empty in_account_id
begin
    drop table if exists t_trade_record;
    create temp table t_trade_record
    as
    select distinct on (atr.trade_record_id, br.to_report, br.alloc_instr_id)
        atr.trade_record_id, br.to_report, br.alloc_instr_id, br.db_create_time
    from dash_reporting.bofa_allocation_report br
             join genesis2.alloc_instr2trade_record atr
                  on atr.alloc_instr_id = br.alloc_instr_id and atr.date_id = br.date_id
    where br.date_id = in_date_id
    union all
    select btr.trade_record_id, 'R', 0, btr.db_create_time
    from dash_reporting.bofa_trade_record btr
    where btr.date_id = in_date_id;

    create index on t_trade_record (trade_record_id);

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               null                                                        as alloc_instr_id,
               null                                                        as alloc_time,
               false                                                       as is_allocated,
               false                                                       as is_bundle,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                        principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
                   else CCRU.rate end                                      as client_commission_rate,
               null::varchar                                               as user_name,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               rep.to_report                                               as reported_status,
               rep.db_create_time                                          as reported_time,
               bas.claimed_by                                              as claimed_by,
               bas.claim_status                                            as claim_status

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
                                    where rep.trade_record_id = allocated_trades.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and bas.date_id = allocated_trades.date_id
                                    limit 1) bas on true
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = in_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.date_id = in_date_id
          and case when in_account_ids = '{}' then true else tr.account_id = any (in_account_ids) end
          and tr.is_busted = 'N'
          and allocated_trades.alloc_instr_id is NULL
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C')
                  when in_reported_status is null then true end
        union all
        select ai.date_id,
               null::bigint                   as trade_record_id,
               ai.account_id::integer,
               ai.instrument_id,
               ai.side,
               ai.open_close,
               ai.avg_px,
               ai.total_qty                   as exec_qty,
               i.display_instrument_id,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               ai.alloc_instr_id,
               ai.create_time                 as alloc_time,
               true                           as is_allocated,
               true                           as is_bundle,
               null                           as cmta,
               null                           as exec_broker,
               case i.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                           principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end          as client_commission_rate,
               coalesce(ui.user_name, 'auto') as user_name,
               ccr.blaze_account_alias,
               null                           as street_exec_time,
               -------
               i.last_trade_date,
               acc.opt_customer_or_firm,
               rep.to_report                  as reported_status,
               rep.db_create_time             as reported_time,
               bas.claimed_by                 as claimed_by,
               bas.claim_status               as claim_status
        from genesis2.allocation_instruction ai
                 inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
                 left join lateral (select rep.to_report, rep.db_create_time
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
                                               end                                                  as blaze_account_alias
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                             left join lateral (select rate,
                                                                       row_number()
                                                                       over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                                from genesis2.trade_level_book_record tl
                                                                         inner join genesis2.book_record_creator cr
                                                                                    on tl.book_record_creator_id = cr.book_record_creator_id
                                                                where tl.date_id = in_date_id
                                                                  AND tl.book_record_type_id = 'CCRU'
                                                                  and tl.trade_record_id = alt.trade_record_id) l1
                                                       on true
                                    where alt.alloc_instr_id = ai.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and (l1.rn = 1 or l1.rn is null)
            ) ccr on true

        where ai.date_id = in_date_id
          and case when in_account_ids = '{}' then true else ai.account_id = any (in_account_ids) end
          and ai.is_deleted = 'N'
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C') -- C the same as U
                  when in_reported_status is null then true end;

end ;
$function$
;


select * from dash360.so_allocations_snapshot(in_account_ids := '{}', in_date_id := 20241224, in_reported_status := null);



-- DROP FUNCTION dash360.so_allocations_instruction_trades;

create or replace function dash360.so_allocations_instruction_trades(in_alloc_instr_id integer)
    returns table
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                blaze_account_alias    character varying,
                street_exec_time       timestamp without time zone,
                expiration_date        timestamp without time zone,
                opt_customer_firm      char,
                reported_status        bpchar,
                reported_time          timestamp,
                claimed_by             int4,
                claim_status           bpchar,
                reported_aloc_instr_id int4[]
            )
    language plpgsql
    cost 1
AS
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
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
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
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
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               coalesce(bar.to_report, btr.to_report)                      as reported_status,
               coalesce(bar.db_create_time, btr.db_create_time)            as reported_time,
               bas.claimed_by                                              as claimed_by,
               bas.claim_status                                            as claim_status,
               case
                   when bar.to_report in ('U', 'C') then
                       (select array_agg(distinct aitr.alloc_instr_id)
                        from genesis2.alloc_instr2trade_record aitr
                        where aitr.date_id = tr.date_id
                          and aitr.trade_record_id = any
                              (staging.all_orig_trade_record_id_today(tr.trade_record_id, tr.date_id)))
                   end                                                     as reported_aloc_instr_id

        from trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 inner join genesis2.alloc_instr2trade_record ai2tr on (ai2tr.trade_record_id = tr.trade_record_id)
                 inner join genesis2.allocation_instruction a on (a.alloc_instr_id = ai2tr.alloc_instr_id)
                 left join lateral (select 'R' as to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
                 left join lateral (select to_report, bar.db_create_time
                                    from dash_reporting.bofa_allocation_report bar
                                    where bar.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bar.date_id = ai2tr.date_id
                                    limit 1) bar on true
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bas.date_id = ai2tr.date_id
                                    limit 1) bas on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53720);

select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -52631);

select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53737);

select staging.all_orig_trade_record_id_today( 2346619764, 20241210);


    select * from dash360.so_allocations_snapshot (in_date_id:=20250103, in_account_ids:='{257078}');

select * from dash360.allocations_snapshot (in_date_id:=20241223, in_account_ids:='{257078}');

 select * from dash360.so_allocations_snapshot (in_date_id:=20241223, in_account_ids:='{257078}');

select * from dash_reporting.bofa_allocation_report
where alloc_instr_id = -54455
------------------


-- DROP FUNCTION dash360.bofa_allocation_report(int4, int4, text, bool);

CREATE OR REPLACE FUNCTION dash360.bofa_allocation_report(in_start_date_id integer, in_end_date_id integer,
                                                          in_exec_broker text DEFAULT '792'::text,
                                                          in_is_eod boolean DEFAULT false)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
-- 20241224 SO https://dashfinancial.atlassian.net/browse/DS-9237

declare
    l_load_id                 int;
    l_step_id                 int;
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id          int4[];
    l_row_cnt                 int4;
    l_row_cnt_eod             int4;
    l_msg_text                text;
    l_start_row               int4;

begin
    l_msg_text := 'allocation_report for ' || in_start_date_id::text || '-' || in_end_date_id::text || 'for ' ||
                  case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ':';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data STARTED ====', 0, 'O')
    into l_step_id;

    -- PART 1. Collecting intraday data
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from dash_reporting.bofa_allocation_report
    where date_id between in_start_date_id and in_end_date_id
      and to_report = 'R';

-- insert into the table
    with base_ins as (
        insert into dash_reporting.bofa_allocation_report
            (alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed,
             ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
             occ_actionable_id, dataset, instrument_id, opt_penny_commission, opt_nickel_commission, root_symbol,
             min_tick_increment, put_call, maturity_year, maturity_month, maturity_day, strike_price, to_report)
            select alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta,                 -- ftr_cmta,
                   ca.cmta,                  -- ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id,     -- occ_actionable_id,
                   l_load_id,                -- dataset,
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
                       when ar.date_id is not null then 'C' --'skip - current alloc_instr_id'
                       when or_ai.alloc_instr_ids && l_alloc_instr_id_reported
                           then 'U' -- 'unable to report - alloc_instr_id has been reported before'
                       else 'R' end as to_report
            from genesis2.allocation_instruction_entry ae
                     join genesis2.allocation_instruction alin
                          on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
                     left join lateral (select alloc_instr_ids
                                        from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                                     alin.date_id) as x(alloc_instr_ids)
                                        limit 1) or_ai on true
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and tr.exec_broker = in_exec_broker
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
                                        from dash_reporting.bofa_allocation_report ar
                                        where ar.alloc_instr_id = ae.alloc_instr_id
                                          and to_report = 'R'
                                        limit 1) ar on true
            where alin.date_id between in_start_date_id and in_end_date_id
              and not exists (select null
                              from dash_reporting.bofa_allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data completed', l_row_cnt, 'O')
    into l_step_id;

    --  PART 2. Printing the report for intraday
    return query
        select array_to_string(ARRAY [
                                   'DAS' , ----Branch
                                   CASE
                                       WHEN gen.side = '1' THEN 'B'
                                       WHEN gen.side in ('2', '5', '6') THEN 'S'
                                       ELSE 'S'
                                       END , ----Action
                                   '' , ----Symbol
                                   '?' , ----Destination
                                   gen.alloc_qty::text , ----Quantity
                                   to_char(gen.avg_px, 'FM99990D009999') , --
                                   CASE
                                       WHEN gen.opt_is_fix_clfirm_processed = 'Y' THEN lpad(ftr_cmta, 5, '0')
                                       WHEN gen.opt_is_fix_clfirm_processed = 'N' THEN lpad(ca_cmta, 5, '0')
                                       END, --
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 5, 2) || '/' ||
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 7, 2) || '/' ||
                                   SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 3, 2) || '/' ||
                                   '00/00' , --
                                   'DASH' , ----Execution Venue
--		street_account_name ||','||--Client Identifier
                                   gen.occ_actionable_id , ----Client Identifier
                                   to_char(row_number() OVER (), 'FM0000') , --
                                   to_char(((CASE coalesce(gen.min_tick_increment, 0.01)
                                                 WHEN 0.01 THEN gen.opt_penny_commission
                                                 WHEN 0.05 THEN gen.opt_nickel_commission END) * gen.alloc_qty),
                                           'FM99990D0') , ----13
                                   '' , ----Liquidity
                                   'S' , ----Single/Basket
                                   '' , ----Pass Through Fees
                                   gen.root_symbol, ----Symbol
                                   CASE
                                       WHEN gen.put_call = '0' THEN 'P'
                                       WHEN gen.put_call = '1' THEN 'C'
                                       END , ----Put/Call
                                   gen.maturity_year::text , --
                                   to_char(gen.maturity_month, 'FM00') , --
                                   to_char(gen.MATURITY_DAY, 'FM00') , --
                                   to_char(gen.strike_price, 'FM999990D0099') , ----Strike
                                   gen.open_close , --
                                   CASE (CASE gen.opt_is_fix_custfirm_processed
                                             WHEN 'Y' THEN coalesce(gen.opt_customer_firm, gen.opt_customer_or_firm)
                                             ELSE gen.opt_customer_or_firm END)
                                       WHEN '0' THEN 'C'
                                       WHEN '1' THEN 'F'
                                       WHEN '2' THEN 'F'
                                       WHEN '3' THEN 'C'
                                       WHEN '4' THEN 'M'
                                       WHEN '5' THEN 'M'
                                       WHEN '7' THEN 'F'
                                       WHEN '8' THEN 'C'
                                       END,
                                   null,
                                   null
                                   ], ',', '')
                   AS rec
        from dash_reporting.bofa_allocation_report gen
        where dataset = l_load_id
          and to_report = 'R';
    get diagnostics l_start_row = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' intraday reporting completed', l_start_row, 'O')
    into l_step_id;


    -- PART 3. Printing the report for EOD
    if in_is_eod then
        -- list of reported alloc_instr_id
        l_alloc_instr_id_reported := '{}'::int4[];
        select array_agg(ba.alloc_instr_id)
        into l_alloc_instr_id_reported
        from dash_reporting.bofa_allocation_report ba
        where ba.date_id between in_start_date_id and in_end_date_id
          and ba.to_report in ('R');

        -- list of trade records from reported alloc_instr_id
        drop table if exists t_trade_record_reported;
        create temp table t_trade_record_reported as
        select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id
        from genesis2.trade_record tr
                 join genesis2.alloc_instr2trade_record aitr
                      on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
        where aitr.alloc_instr_id = any (l_alloc_instr_id_reported)
        union
        select aitr.trade_record_id, aitr.date_id, aitr.alloc_instr_id
        from genesis2.alloc_instr2trade_record aitr
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
        where aitr.date_id between in_start_date_id and in_end_date_id
          and ai.is_deleted = 'N';

        -- find all valid trade_records: all except the records from the prev

        drop table if exists t_reported_trade_record;
        create temp table t_reported_trade_record as
        SELECT ftr.date_id           AS date_id,
               ftr.trade_record_id,
               l_load_id             as dataset,
               CASE
                   WHEN acc.opt_is_fix_clfirm_processed = 'Y' THEN ftr.cmta
                   ELSE NULL END     AS cmta,
               ftr.open_close,
               ftr.order_id          AS order_id,
               ftr.instrument_id,
               ftr.account_id,
               ftr.side,
               ftr.last_qty          AS last_qty,
               ftr.last_px           AS last_px,
               ftr.opt_customer_firm as opt_customer_firm,
               0                     AS is_cleared,
               acc.opt_is_fix_clfirm_processed,
               acc.opt_customer_or_firm,
               acc.opt_nickel_commission,
               acc.opt_penny_commission,
               acc.opt_is_fix_custfirm_processed,
               case
                   when exists (select null
                                from t_trade_record_reported rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'U'
                   else 'R' end      as to_report
        FROM genesis2.trade_record ftr
                 join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
                 JOIN genesis2.account acc ON (acc.account_id = ftr.account_id AND
                                               acc.is_deleted <> 'Y' AND
                                               acc.opt_report_to_mpid = 'MLCB' AND
                                               acc.trading_firm_id <> 'cantor')

        WHERE ftr.date_id between in_start_date_id and in_end_date_id
          AND is_busted = 'N'
          AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = in_exec_broker
        --           and not exists (select null
--                           from t_trade_record_reported rp
--                           where rp.trade_record_id = any
--                                 (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
        ;

        insert into dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report
        from t_reported_trade_record;

        drop table if exists t_ftr;
        create temp table t_ftr as
        SELECT rtr.date_id,
               rtr.cmta,
               rtr.open_close,
               rtr.order_id,
               rtr.instrument_id,
               rtr.side,
               sum(rtr.last_qty)                                                AS day_cum_qty,
               CASE sum(rtr.last_qty)
                   WHEN 0 THEN NULL
                   ELSE sum(rtr.last_qty * rtr.last_px) / sum(rtr.last_qty) END AS avg_px,
               max(rtr.opt_customer_firm)                                       AS customer_or_firm_id,
               rtr.opt_is_fix_clfirm_processed,
               rtr.opt_customer_or_firm,
               rtr.opt_nickel_commission,
               rtr.opt_penny_commission,
               rtr.opt_is_fix_custfirm_processed
/*,
       max(street_account_name) as street_account_name*/
        FROM t_reported_trade_record rtr
        where date_id between in_start_date_id and in_end_date_id
          and to_report = 'R'
        group by rtr.date_id, rtr.cmta, rtr.open_close, rtr.order_id, rtr.instrument_id, rtr.side,
                 rtr.opt_is_fix_clfirm_processed, rtr.opt_customer_or_firm,
                 rtr.opt_nickel_commission, rtr.opt_penny_commission,
                 rtr.opt_is_fix_custfirm_processed;
        get diagnostics l_row_cnt_eod = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD reporting table for trade_record created',
                               l_row_cnt_eod,
                               'O')
        into l_step_id;

        return query
            SELECT array_to_string(ARRAY [
                                       'DAS' , ----Branch
                                       CASE
                                           WHEN ftr.SIDE = '1' THEN 'B'
                                           WHEN ftr.SIDE in ('2', '5', '6') THEN 'S'
                                           ELSE 'S' END , ----Action
                                       '' , ----Symbol
                                       '?' , ----Destination
                                       ftr.day_cum_qty::text , ----Quantity
                                       to_char(ftr.avg_px, 'FM99990D009999') , ----Avg. Price
                                       COALESCE(lpad(ftr.cmta, 5, '0'), '') , -- -- CMTA
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 5, 2) || '/' ||
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 7, 2) || '/' ||
                                       SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 3, 2) || '/' ||
                                       '00/00' , --
                                       'DASH' , ----Execution Venue
--		ftr.street_account_name ||','||--Client Identifier
                                       '' , ----Client Identifier
                                       to_char(row_number() OVER () + l_start_row, 'FM0000') , --
                                       to_char(((CASE coalesce(OS.MIN_TICK_INCREMENT, 0.01)
                                                     WHEN 0.01 THEN ftr.OPT_PENNY_COMMISSION
                                                     WHEN 0.05 THEN ftr.OPT_NICKEL_COMMISSION END) * ftr.day_cum_qty),
                                               'FM99990D0') , ----13
                                       '' , ----Liquidity
                                       'S' , ----Single/BASket
                                       '' , ----PASs Through Fees
                                       COALESCE(OS.ROOT_SYMBOL, '') , ----Symbol
                                       CASE WHEN OC.PUT_CALL = '0' THEN 'P' WHEN OC.PUT_CALL = '1' THEN 'C' END , ----Put/Call
                                       OC.MATURITY_YEAR::text , --
                                       to_char(OC.maturity_month, 'FM00') , --
                                       to_char(OC.MATURITY_DAY, 'FM00') , --
                                       to_char(OC.STRIKE_PRICE, 'FM999990D0099') , ----Strike
                                       ftr.open_close , --
                                       CASE (CASE ftr.OPT_IS_FIX_CUSTFIRM_PROCESSED
                                                 WHEN 'Y'
                                                     THEN coalesce(ftr.CUSTOMER_OR_FIRM_ID, ftr.OPT_CUSTOMER_OR_FIRM)
                                                 ELSE ftr.OPT_CUSTOMER_OR_FIRM END)
                                           WHEN '0' THEN 'C'
                                           WHEN '1' THEN 'F'
                                           WHEN '2' THEN 'F'
                                           WHEN '3' THEN 'C'
                                           WHEN '4' THEN 'M'
                                           WHEN '5' THEN 'M'
                                           WHEN '7' THEN 'F'
                                           WHEN '8' THEN 'C'
                                           END,
                                       null,
                                       null
                                       ], ',', '')
            FROM t_ftr AS ftr
                     INNER JOIN genesis2.option_contract oc ON (oc.instrument_id = ftr.instrument_id)
                     INNER JOIN genesis2.option_series os ON (os.option_series_id = oc.option_series_id)
--                      INNER JOIN genesis2.instrument gi ON (gi.instrument_id = ftr.instrument_id)
        ;

        get diagnostics l_row_cnt_eod = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD reporting for TR completed', l_row_cnt_eod,
                               'O')
        into l_step_id;
    end if;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' FINISHED ========', l_row_cnt + l_row_cnt_eod, 'O')
    into l_step_id;


end;
$function$
;



-- DROP FUNCTION dash360.so_allocations_instruction_trades(int4);

CREATE OR REPLACE FUNCTION dash360.so_allocations_instruction_trades(in_alloc_instr_id integer)
    RETURNS TABLE
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                blaze_account_alias    character varying,
                street_exec_time       timestamp without time zone,
                expiration_date        timestamp without time zone,
                opt_customer_firm      character,
                reported_status        character,
                reported_time          timestamp without time zone,
                claimed_by             integer,
                claim_status           character,
                is_prev_reported       boolean
--                 reported_aloc_instr_id integer[]
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
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
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
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
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               coalesce(bar.to_report, btr.to_report)                      as reported_status,
               coalesce(bar.db_create_time, btr.db_create_time)            as reported_time,
               bas.claimed_by                                              as claimed_by,
               bas.claim_status                                            as claim_status,
               case
                   when bar.to_report in ('U', 'C') and
                        exists
                            (select null
                             from genesis2.alloc_instr2trade_record aitr
                                      join dash_reporting.bofa_allocation_report br
                                           on br.alloc_instr_id = aitr.alloc_instr_id and
                                              br.date_id = aitr.date_id and br.to_report = 'R'
                             where aitr.date_id = tr.date_id
                               and aitr.trade_record_id = any
                                   (staging.all_orig_trade_record_id_today(
                                           tr.trade_record_id,
                                           tr.date_id))) then true
                   else false
                   end                                                     as is_prev_reported
        from trade_record tr
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
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bas.date_id = ai2tr.date_id
                                    limit 1) bas on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;
select * from dash360.so_allocations_instruction_trades(-54536);


select *
from genesis2.alloc_instr2trade_record aitr
  join dash_reporting.bofa_allocation_report br
                                           on br.alloc_instr_id = aitr.alloc_instr_id and
                                              br.date_id = aitr.alloc_instr_id
                                                  and br.to_report = 'R'
  and aitr.trade_record_id = any
      (staging.all_orig_trade_record_id_today(2346652154, 20250109))
where aitr.date_id = 20250109
2346652153
2346652154

select *
from staging.all_orig_trade_record_id_today(2346652153, 20250109)


