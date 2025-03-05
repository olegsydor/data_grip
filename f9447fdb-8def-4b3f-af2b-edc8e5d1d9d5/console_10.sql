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
where br.date_id = :in_date_id
union all
select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
from dash_reporting.bofa_trade_record btr
where btr.date_id = :in_date_id;

select ai.date_id,
       null::int8                     as trade_record_id,
       ai.account_id::int4,
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
       null                           as opt_customer_or_firm,
       rep.to_report                  as reported_status,
       rep.db_create_time             as reported_time,
       bas.claimed_by                 as claimed_by,
       bas.claim_status               as claim_status,
       null::boolean,
       ccr.exec_broker
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
                                       end                                                  as blaze_account_alias,
                                   string_agg(distinct tr.exec_broker, ', ')                as exec_broker
                            from genesis2.alloc_instr2trade_record alt
                                     inner join genesis2.trade_record tr
                                                on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                     left join lateral (select rate,
                                                               row_number()
                                                               over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                        from genesis2.trade_level_book_record tl
                                                                 inner join genesis2.book_record_creator cr
                                                                            on tl.book_record_creator_id = cr.book_record_creator_id
                                                        where tl.date_id = :in_date_id
                                                          AND tl.book_record_type_id = 'CCRU'
                                                          and tl.trade_record_id = alt.trade_record_id) l1
                                               on true
                            where alt.alloc_instr_id = ai.alloc_instr_id
                              and tr.is_busted = 'N'
                              and (l1.rn = 1 or l1.rn is null)
    ) ccr on true

where ai.date_id = :in_date_id
--           and case when in_account_ids = '{}' then true else ai.account_id = any (in_account_ids) end
  and ai.is_deleted = 'N'
  and case
          when in_reported_status = 'R' then rep.to_report = 'R'
          when in_reported_status = 'U' then rep.to_report in ('U', 'C') -- C the same as U
          when in_reported_status is null then true end;


select tr.is_billed, atr.alloc_instr_id, atr.trade_record_id, *
from genesis2.alloc_instr2trade_record atr
         join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
where atr.date_id = 20250211
order by atr.alloc_instr_id;


select atr.alloc_instr_id, count(distinct tr.is_billed)
from genesis2.alloc_instr2trade_record atr
         join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
where atr.date_id = 20250211
group by atr.alloc_instr_id;

drop function staging.get_fully_reported_trade;
create function staging.get_fully_reported_trade(in_alloc_instr_id int4, in_date_id int4)
    returns int4
    language plpgsql
as
$fx$
declare
    l_ret_cnt int4;
begin
    select count(distinct tr.is_billed)
    into l_ret_cnt
    from genesis2.alloc_instr2trade_record atr
             join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
    where atr.date_id = in_date_id
      and atr.alloc_instr_id = in_alloc_instr_id;

    return l_ret_cnt;

end;
$fx$;



select *
from dash360.allocations_snapshot(in_date_id := 20250214);
select * from dash360.report_alloc_instr_trade_record(20250211, '733')

drop function dash360.report_alloc_instr_trade_record
create or replace function dash360.report_alloc_instr_trade_record(in_date_id integer, in_exec_broker text)
    returns table
            (
                "Exec Broker"       text,
                "Type"              text,
                "Trading Firm Name" text,
                "Account Name"      text,
                "Alloc Instr ID"    integer,
                "Trade Record ID"   bigint,
                "Symbol"            text,
                "Side"              text,
                "O/C"               text,
                "Exec Qty"          integer,
                "Avg Px"            numeric,
                "CMTA"              text,
                "OCC AID"           text,
                "Capacity"          text,
                "Reported Status"   text,
                "Reported Time"     timestamp without time zone,
                "Trade is busted"   character,
                "Created Time"      timestamp without time zone,
                "Created by User"   text,
                "Alloc is deleted"  character,
                "Deleted Time"      timestamp without time zone,
                "Deleted by User"   text
            )
    language plpgsql
     security definer
AS
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
    -- 2025-02-12 OS https://dashfinancial.atlassian.net/browse/DS-9572 add new columns
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker"
               'allocation',                                                            -- "Type"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID"
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty"
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"

               'Reported',                                                              -- "Reported Status"
               min(bar.db_create_time),                                                 -- "Reported Time"
               '',                                                                      -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted"
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name)                                                        -- "Deleted by User"

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and ui.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
        group by bar.alloc_instr_id

        union all


        select tr.exec_broker::varchar(32),                                                  -- "Exec Broker"
               'trade',                                                                      -- "Type"
               tf.trading_firm_name,                                                         -- "Trading Firm Name"
               ac.account_name,                                                              -- "Account Name"
               null,                                                                         -- "Alloc Instr ID"
               btr.trade_record_id,                                                          -- "Trade Record ID"
               di.display_instrument_id2,                                                    -- "Symbol"
               case tr.side when '1' then 'Buy' when '2' then 'Sell' end,                    -- "Side"
               case tr.open_close when 'O' then 'Open' when 'C' then 'Close' end,            -- "O/C"
               tr.last_qty,                                                                  -- "Exec Qty"
               tr.last_px,                                                                   -- "Avg Px"
               null,                                                                         -- "CMTA"
               null,                                                                         -- "OCC AID"
               concat_ws(': ', tr.opt_customer_firm, cst.customer_or_firm_name),             -- "Capacity"
               'Reported',                                                                   -- "Reported Status"
               coalesce((select bar.db_create_time
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
                         limit 1), tr.db_create_time),                                         -- "Reported Time"
               tr.is_busted,                                                                   -- "Trade is busted"
               null,                                                                           -- "Created Time"
               null,                                                                           -- "Created by User"
               null,                                                                           -- "Alloc is deleted"
               null,                                                                           -- "Deleted Time"
               null                                                                            -- "Deleted by User"

        from dash_reporting.bofa_trade_record btr
                 join genesis2.trade_record tr using (trade_record_id, date_id)
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = tr.instrument_id
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = tr.opt_customer_firm
        where btr.date_id = in_date_id
          and btr.to_report = 'R'
          and tr.exec_broker = in_exec_broker;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
select * from genesis2.account
    where account_name in ('PIPR_4902', 'PIPR_4918', 'PIPR_6459', 'PIPR_5022', 'PIPR_4072');

drop function if exists dash360.bofa_allocation_report(int4, int4, text, bool);
create or replace function dash360.bofa_allocation_report(in_start_date_id int4, in_end_date_id int4,
                                                          in_exec_broker text,-- default '792'::text,
                                                          in_is_eod boolean default false,
                                                          in_removed_account_ids int4[] default '{257165,62810,62887,62923,63787,67949}'::int4[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
    -- 20241224 SO https://dashfinancial.atlassian.net/browse/DS-9237
-- The main function based on dash360.report_rps_ml_options_cmta for aggregating data intraday only (if in_is_eod = false)
-- and both intraday and EOD (if in_is_eod = true) and saving data into the dash_reporting.bofa_allocation_report for intraday
-- and dash_reporting.bofa_trade_record for EOD
    -- 20250116 SO https://dashfinancial.atlassian.net/browse/DS-9313 add subscriptions

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
    l_msg_text := 'allocation_report for ' || in_start_date_id::text || '-' || in_end_date_id::text || ' for ' ||
                  case when in_exec_broker is null then ' all exec brokers' else in_exec_broker end || ':';

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
                     join genesis2.account acc ON (acc.account_id = ca.account_id and acc.is_deleted <> 'Y'
                and acc.opt_report_to_mpid = 'MLCB'
                and acc.trading_firm_id <> 'cantor'
                and case when in_is_eod then true else acc.account_id != all (in_removed_account_ids) end
                )
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

    -- Subscription (for ONLY THESE trade_record_id with  R in alloc_instr_id)
    perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                in_row_cnt=>coalesce(l_row_cnt, 0),
                                in_subscription_name => 'trade_record',
                                in_source_table_name => 'bofa_allocation_report',
                                in_date_id => in_start_date_id);

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data completed', coalesce(l_row_cnt, 0), 'O')
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
        where aitr.alloc_instr_id = any (l_alloc_instr_id_reported);

        drop table if exists t_trade_record_to_exclude;
        create temp table t_trade_record_to_exclude as
        select aitr.trade_record_id, aitr.date_id, aitr.alloc_instr_id
        from genesis2.alloc_instr2trade_record aitr
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
                 join genesis2.trade_record tr
                      on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
        where aitr.date_id between in_start_date_id and in_end_date_id
          and ai.is_deleted = 'N'
          and tr.exec_broker = in_exec_broker;
        create index on t_trade_record_to_exclude (trade_record_id);

        -- find all valid trade_records: all except the records from the prev

        drop table if exists t_trade_record_to_report;
        create temp table t_trade_record_to_report as
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
                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_reported trr
                                                                     where trr.trade_record_id = ftr.trade_record_id)
                       then 'U'
                   when ftr.orig_trade_record_id is null then 'R'
                   when exists (select null
                                from t_trade_record_reported rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'U'
                   else 'R' end      as to_report,
               case

                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_to_exclude tre
                                                                     where tre.trade_record_id = ftr.trade_record_id)
                       then 'D'
                   when ftr.orig_trade_record_id is null then null
                   when exists (select null
                                from t_trade_record_to_exclude rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'D' end  as to_del
        FROM genesis2.trade_record ftr
                 join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
                 JOIN genesis2.account acc ON (acc.account_id = ftr.account_id)
                 left join t_trade_record_to_exclude tex
                           on tex.trade_record_id = ftr.trade_record_id and tex.date_id = ftr.date_id
        WHERE ftr.date_id between in_start_date_id and in_end_date_id
          AND is_busted = 'N'
          AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = in_exec_broker
          and tex.trade_record_id is null
          and acc.is_deleted <> 'Y'
          AND acc.opt_report_to_mpid = 'MLCB'
          AND acc.trading_firm_id <> 'cantor'
        --           and not exists (select null
--                           from t_trade_record_to_exclude rp
--                           where rp.trade_record_id = any
--                                 (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
        ;

        insert into dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report
        from t_trade_record_to_report
        where to_del is null;
        get diagnostics l_row_cnt = row_count;

        -- Subscription
        perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                in_row_cnt=>coalesce(l_row_cnt, 0),
                                in_subscription_name => 'trade_record',
                                in_source_table_name => 'bofa_trade_record',
                                in_date_id => in_start_date_id);

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
        FROM t_trade_record_to_report rtr
        where date_id between in_start_date_id and in_end_date_id
          and to_report = 'R'
          and to_del is null
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
with b as (select *
           from genesis2.account
           where account_id != all ('{}'))
select * from b
where account_id = 16435


select date_id, is_billed, trade_record_id, exec_broker, tr.account_id, ac.opt_report_to_mpid, ac.trading_firm_id, *
from genesis2.trade_record tr
join genesis2.account ac on tr.account_id = ac.account_id
where trade_record_id in (2346726833,2346726834,2346726835,2346726836,2346726837);



        -- list of reported alloc_instr_id
        l_alloc_instr_id_reported := '{}'::int4[];
        select array_agg(ba.alloc_instr_id)
--         into l_alloc_instr_id_reported
        from dash_reporting.bofa_allocation_report ba
        where ba.date_id between :in_start_date_id and :in_end_date_id
          and ba.to_report in ('R');

        -- list of trade records from reported alloc_instr_id
        drop table if exists t_trade_record_reported;
        create temp table t_trade_record_reported as
        select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id
        from genesis2.trade_record tr
                 join genesis2.alloc_instr2trade_record aitr
                      on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
        where aitr.alloc_instr_id = any (:l_alloc_instr_id_reported);

        drop table if exists t_trade_record_to_exclude;
        create temp table t_trade_record_to_exclude as
        select aitr.trade_record_id, aitr.date_id, aitr.alloc_instr_id
        from genesis2.alloc_instr2trade_record aitr
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
                 join genesis2.trade_record tr
                      on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
        where aitr.date_id between :in_start_date_id and :in_end_date_id
          and ai.is_deleted = 'N'
          and tr.exec_broker = :in_exec_broker;
        create index on t_trade_record_to_exclude (trade_record_id);

        -- find all valid trade_records: all except the records from the prev

        drop table if exists t_trade_record_to_report;
        create temp table t_trade_record_to_report as
        SELECT ftr.order_id,
            ftr.date_id           AS date_id,
               ftr.trade_record_id,
               :l_load_id             as dataset,
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
                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_reported trr
                                                                     where trr.trade_record_id = ftr.trade_record_id)
                       then 'U'
                   when ftr.orig_trade_record_id is null then 'R'
                   when exists (select null
                                from t_trade_record_reported rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'U'
                   else 'R' end      as to_report,
               case

                   when ftr.orig_trade_record_id is null and exists (select null
                                                                     from t_trade_record_to_exclude tre
                                                                     where tre.trade_record_id = ftr.trade_record_id)
                       then 'D'
                   when ftr.orig_trade_record_id is null then null
                   when exists (select null
                                from t_trade_record_to_exclude rp
                                where rp.trade_record_id = any
                                      (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
                       then 'D' end  as to_del
        FROM genesis2.trade_record ftr
                 join genesis2.instrument gi on gi.instrument_id = ftr.instrument_id
                 JOIN genesis2.account acc ON (acc.account_id = ftr.account_id)
                 left join t_trade_record_to_exclude tex
                           on tex.trade_record_id = ftr.trade_record_id and tex.date_id = ftr.date_id
        WHERE ftr.trade_record_id in (2346726833,2346726834,2346726835,2346726836,2346726837)
            and ftr.date_id between :in_start_date_id and :in_end_date_id
          AND is_busted = 'N'
--           AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = :in_exec_broker
          and tex.trade_record_id is null
          and acc.is_deleted <> 'Y'
          AND acc.opt_report_to_mpid = 'MLCB'
          AND acc.trading_firm_id <> 'cantor'
        --           and not exists (select null
--                           from t_trade_record_to_exclude rp
--                           where rp.trade_record_id = any
--                                 (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))
        ;

        insert into dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report
        from t_trade_record_to_report
        where to_del is null;
        get diagnostics l_row_cnt = row_count;

        -- Subscription
        perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                in_row_cnt=>coalesce(l_row_cnt, 0),
                                in_subscription_name => 'trade_record',
                                in_source_table_name => 'bofa_trade_record',
                                in_date_id => in_start_date_id);

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
        FROM t_trade_record_to_report rtr
        where date_id between in_start_date_id and in_end_date_id
          and to_report = 'R'
          and to_del is null
        group by rtr.date_id, rtr.cmta, rtr.open_close, rtr.order_id, rtr.instrument_id, rtr.side,
                 rtr.opt_is_fix_clfirm_processed, rtr.opt_customer_or_firm,
                 rtr.opt_nickel_commission, rtr.opt_penny_commission,
                 rtr.opt_is_fix_custfirm_processed;




select *
from staging.get_fully_reported_trade(-57801, 20250214);

drop function if exists dash360.allocations_snapshot(int8[], int4, bpchar);
-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar);
CREATE OR REPLACE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                        in_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                        in_reported_status character DEFAULT NULL::character(1))
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
                opt_customer_firm      character,
                reported_status        character,
                reported_time          timestamp without time zone,
                claimed_by             integer,
                claim_status           character,
                is_prev_reported       boolean
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

    create index on t_trade_record (trade_record_id);

    return query
        select tr.date_id,
               tr.trade_record_id::int8,
               tr.account_id::int4,
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
               coalesce(nullif(tr.is_billed, 'N'), rep.to_report)          as reported_status,
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
                                 order by 1
                                 limit 1), rep.db_create_time) end         as reported_time,
               bas.claimed_by                                              as claimed_by,
               bas.claim_status                                            as claim_status,
               case when tr.is_billed = 'R' then true end                  as is_prev_reported

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
               null::int8                     as trade_record_id,
               ai.account_id::int4,
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
               ccr.exec_broker                as exec_broker,
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
               null                           as opt_customer_or_firm,
               rep.to_report                  as reported_status,
               rep.db_create_time             as reported_time,
               bas.claimed_by                 as claimed_by,
               bas.claim_status               as claim_status,
               null::boolean                  as is_prev_reported
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
                                           string_agg(distinct tr.exec_broker, ', ')                as exec_broker
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
comment on function dash360.allocations_snapshot is 'The report allocations_snapshot temp nsme with the prefix os_ until it is tested';


select subsystem_id, *
from genesis2.trade_record
where true
--      and order_id is null
and date_id >= 20240101
and exec_id < 0
-- and subsystem_id = 'OMS_EDW'


select * from staging.trade_record_missed_lp
where date_id = 20250214;

select * from genesis2.customer_or_firm;

 EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker"
               'allocation',                                                            -- "Type"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID"
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty"
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"

               'Reported',                                                              -- "Reported Status"
               min(bar.db_create_time),                                                 -- "Reported Time"
               '',                                                                      -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted"
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name)                                                        -- "Deleted by User"
,min(ai.created_by_user_id)
        , min(ai.deleted_by_user_id)
        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                               and tr.exec_broker = :in_exec_broker
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = :in_date_id
          and bar.to_report = 'R'
        group by bar.alloc_instr_id;



-- list of tables with specific column names
select distinct t.table_schema
                , t.table_name
--                 , c.column_name
--                , data_type
from information_schema.tables t
         inner join information_schema.columns c on (c.table_name = t.table_name and c.table_schema = t.table_schema)
where true
and t.table_schema not in
      ('trash', 'information_schema', 'pg_catalog', 'dm_partitions', 'ot_partitions', 'partitions', 'cmp_partitions',
       'md_partitions', 'fc_partitions', 'fc_partitions_tmp_hft', 'external_data_partitions')
  and t.table_name ilike '%customer_or_firm%'
--  and t.table_schema in ('dwh', 'staging', 'public')
  and c.column_name ilike '%billing_type%'
  or c.column_name ilike '%max\_%')
  and c.column_name ilike '%royalty%'
  and t.table_type = 'BASE TABLE';
select * from genesis2.cust_or_firm

select * from genesis2.customer_or_firm;

get_reported_allocation_data_by_ids
-- DROP FUNCTION dash360.report_alloc_instr_trade_record(int4, text);

drop function dash360.get_reported_allocation_data_by_ids
create or replace function dash360.get_reported_allocation_data_by_ids(in_date_id integer, in_alloc_instr_ids int4[])
    returns table
            (
                "Exec Broker"       text, -- 1
                "Type"              text,
                "Trading Firm Name" text,
                "Account Name"      text,
                "Alloc Instr ID"    integer, -- 5
                "Trade Record ID"   bigint,
                "Symbol"            text,
                "Side"              text,
                "O/C"               text,
                "Exec Qty"          integer, -- 10
                "Avg Px"            numeric,
                "CMTA"              text,
                "OCC AID"           text,
                "Capacity"          text,
                "Reported Status"   text, -- 15
                "Reported Time"     timestamp without time zone,
                "Trade is busted"   character,
                "Created Time"      timestamp without time zone,
                "Created by User"   text,
                "Alloc is deleted"  character, -- 20
                "Deleted Time"      timestamp without time zone,
                "Deleted by User"   text
            )
    language plpgsql
    security definer
as
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
    -- 2025-02-12 OS https://dashfinancial.atlassian.net/browse/DS-9572 add new columns
    -- 2025-02-20 OS https://dashfinancial.atlassian.net/browse/DS-9607 inherited from the old report
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'get_reported_allocation_data_by_ids for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker" -- 1
               'allocation',                                                            -- "Type"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID" -- 5
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty" -- 10
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"

               'Reported',                                                              -- "Reported Status" -- 15
               min(bar.db_create_time),                                                 -- "Reported Time"
               ''::character,                                                           -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted" -- 20
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name)                                                        -- "Deleted by User"

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
--                                and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
        and bar.alloc_instr_id = any(in_alloc_instr_ids)
        group by bar.alloc_instr_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_reported_allocation_data_by_ids for ' || in_date_id::text ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;

select bar.alloc_instr_id,
       tr.exec_broker
from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
--                                and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = :in_date_id
          and bar.to_report = 'R'
        and bar.alloc_instr_id = any(in_alloc_instr_ids)
        group by bar.alloc_instr_id;

select * from dash360.get_reported_allocation_data_by_ids(20250218, '{-57808,-57809,-57810,-57811,-57812}')


drop function dash360.get_reported_allocation_data_by_ids
create or replace function dash360.get_reported_allocation_data_by_ids(in_date_id integer, in_alloc_instr_ids int4[])
    returns table
            (
                exec_broker            text,      -- 1
                type                   text,
                trading_firm_name      text,
                account_name           text,
                alloc_instr_id         integer,   -- 5
                trade_record_id        bigint,
                display_instrument_id2 text,
                side                   text,
                open_close             text,
                total_qty              integer,   -- 10
                avg_px                 numeric,
                cmta                   text,
                occ_actionable_id      text,
                capacity               text,
                reported_status        text,      -- 15
                reported_time          timestamp without time zone,
                is_busted              character,
                create_time            timestamp without time zone,
                created_by_user_name   text,
                is_deleted             character, -- 20
                delete_time            timestamp without time zone,
                deleted_by_user_name   text
            )
    language plpgsql
    security definer
as
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
    -- 2025-02-12 OS https://dashfinancial.atlassian.net/browse/DS-9572 add new columns
    -- 2025-02-20 OS https://dashfinancial.atlassian.net/browse/DS-9607 inherited from the old report
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'get_reported_allocation_data_by_ids for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker" -- 1
               'allocation',                                                            -- "Type"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID" -- 5
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty" -- 10
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"

               'Reported',                                                              -- "Reported Status" -- 15
               min(bar.db_create_time),                                                 -- "Reported Time"
               ''::character,                                                           -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted" -- 20
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name)                                                        -- "Deleted by User"

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
--                                and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
          and bar.alloc_instr_id = any (in_alloc_instr_ids)
        group by bar.alloc_instr_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_reported_allocation_data_by_ids for ' || in_date_id::text ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;