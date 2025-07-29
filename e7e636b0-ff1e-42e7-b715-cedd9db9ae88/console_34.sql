
alter table genesis2.clearing_account drop column if exists default_alloc_ratio;

alter table genesis2.clearing_account add column if not exists auto_alloc_ratio numeric DEFAULT 1.00 NULL; -- Ratio used to allocate share of a bundle during auto-allocation. 1 means 100%
alter table genesis2.clearing_account add column if not exists is_auto_alloc_to bpchar NULL;

comment on column genesis2.clearing_account.auto_alloc_ratio is 'Ratio used to allocate share of a bundle during auto-allocation. 1 means 100%';
comment on column genesis2.clearing_account.is_auto_alloc_to is 'clearing_account_id takes in auto_alloc multiple cmta process';

-- staging.bofa_allocation_report_history definition

-- Drop table

-- DROP TABLE staging.bofa_allocation_report_history;


-- Column comments


-- compare 2 UAT

-- dash360.bofa_allocation_report

-- DROP FUNCTION dash360.bofa_allocation_report(int4, int4, text, bool, _int4);

CREATE OR REPLACE FUNCTION dash360.bofa_allocation_report(in_start_date_id integer, in_end_date_id integer, in_exec_broker text, in_is_eod boolean DEFAULT false, in_removed_account_ids integer[] DEFAULT '{62939,263022,62810,62887,62923,63787,67949}'::integer[])
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 20241224 SO https://dashfinancial.atlassian.net/browse/DS-9237
    -- The main function based on dash360.report_rps_ml_options_cmta for aggregating data intraday only (if in_is_eod = false)
    -- and both intraday and EOD (if in_is_eod = true) and saving data into the dash_reporting.bofa_allocation_report for intraday
    -- and dash_reporting.bofa_trade_record for EOD
    -- 20250116 SO https://dashfinancial.atlassian.net/browse/DS-9313 add subscriptions
    -- 20250214 SO https://dashfinancial.atlassian.net/browse/DS-9590 add in_removed_account_ids - list of accounts ignored during intraday
    -- 20250218 SO https://dashfinancial.atlassian.net/browse/D360-15295 removed condition order_id > 0 in the EOD part (about 290 row)
    -- 20250403 SO https://dashfinancial.atlassian.net/browse/D360-15560 account_id 62939 was added to the list of account_ids excluded from the intradey process.
    --          account_id 263022 is for UAT flow and added in all scripts for compatibility
    -- 20250722 SO https://dashfinancial.atlassian.net/browse/DS-10237 saving the reported data into the table to avoid missing report
    -- 20250725 SO hot fix creating account_ids list

declare
    l_load_id                 int;
    l_step_id                 int;
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id          int4[];
    l_row_cnt                 int4;
    l_row_cnt_eod             int4;
    l_msg_text                text;
    l_start_row               int4;
    l_account_ids             int4[];

begin
    l_msg_text := 'bofa_allocation_report ' ||
                  case when in_is_eod then 'EOD ' else 'intraday ' end ||
                  in_start_date_id::text || '-' || in_end_date_id::text ||
                  ' for ' || case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ':';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' preparing data STARTED ====', 0, 'O')
    into l_step_id;
    -- PART 0. Creating account_id list
    select array_agg(account_id)
    into l_account_ids
    from genesis2.account ac
    where true
      and ac.is_deleted <> 'Y'
      and ac.opt_report_to_mpid = 'MLCB'
      and ac.trading_firm_id <> 'cantor';

    -- PART 1. Collecting intraday data
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from dash_reporting.bofa_allocation_report
    where date_id between in_start_date_id and in_end_date_id
      and to_report = 'R';


    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions collected',
                           coalesce(array_length(l_alloc_instr_id_reported, 1), 0), 'O')
    into l_step_id;

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
                     join genesis2.account acc ON (acc.account_id = ca.account_id
--                                                       and acc.is_deleted <> 'Y'
--                 and acc.opt_report_to_mpid = 'MLCB'
--                 and acc.trading_firm_id <> 'cantor'
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
              and ca.account_id = any (l_account_ids)
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
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions added',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

    -- Subscription (for ONLY THESE trade_record_id with  R in alloc_instr_id)
    perform genesis2.etl_subscribe(in_load_batch_id => l_load_id,
                                   in_row_cnt=>coalesce(l_row_cnt, 0),
                                   in_subscription_name => 'trade_record',
                                   in_source_table_name => 'bofa_allocation_report',
                                   in_date_id => in_start_date_id);

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' subscriptions sent', coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

    --  PART 2. Printing the report for intraday

    insert into staging.bofa_allocation_report_history(report_row, dataset, report_part)
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
                                   ], ',', ''),
                   l_load_id, 'A'
        from dash_reporting.bofa_allocation_report gen
        where dataset = l_load_id
          and to_report = 'R';
    get diagnostics l_start_row = row_count;
    return query
        select report_row as ret_row
        from staging.bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'A';

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' intraday reporting completed',
                           coalesce(l_start_row, 0), 'O')
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

        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD instructions calculated',
                               coalesce(array_length(l_alloc_instr_id_reported, 1), 0), 'O')
        into l_step_id;

        -- list of trade records from reported alloc_instr_id
        drop table if exists t_trade_record_reported;
        create temp table t_trade_record_reported as
        select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id
        from genesis2.trade_record tr
                 join genesis2.alloc_instr2trade_record aitr
                      on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
        where aitr.alloc_instr_id = any (l_alloc_instr_id_reported);
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD trade_records calculated', l_row_cnt, 'O')
        into l_step_id;

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
        get diagnostics l_row_cnt = row_count;
        create index on t_trade_record_to_exclude (trade_record_id);
        analyze t_trade_record_to_exclude;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD excluded trade_records calculated', l_row_cnt,
                               'O')
        into l_step_id;
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
          and ftr.is_busted = 'N'
          and ftr.account_id = any(l_account_ids)
          and ftr.is_billed is distinct from 'R'
--          AND ftr.order_id > 0
          and gi.instrument_type_id = 'O'
          and ftr.exec_broker = in_exec_broker
          and tex.trade_record_id is null;
--           and acc.is_deleted <> 'Y'
--           AND acc.opt_report_to_mpid = 'MLCB'
--           AND acc.trading_firm_id <> 'cantor'

        --           and not exists (select null
--                           from t_trade_record_to_exclude rp
--                           where rp.trade_record_id = any
--                                 (staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)))

        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD temp table t_trade_record_to_report created',
                               l_row_cnt, 'O')
        into l_step_id;

        insert into dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report
        from t_trade_record_to_report
        where to_del is null;
        get diagnostics l_row_cnt = row_count;
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD inserted into into bofa_trade_record',
                               l_row_cnt, 'O')
        into l_step_id;

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

        insert into staging.bofa_allocation_report_history(report_row, dataset, report_part)

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
                                       ], ',', ''),
                l_load_id, 'T'
            FROM t_ftr AS ftr
                     INNER JOIN genesis2.option_contract oc ON (oc.instrument_id = ftr.instrument_id)
                     INNER JOIN genesis2.option_series os ON (os.option_series_id = oc.option_series_id)
--                      INNER JOIN genesis2.instrument gi ON (gi.instrument_id = ftr.instrument_id)
        ;
    return query
        select report_row as ret_row
        from staging.bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'T';

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


-- genesis2.auto_allocate_unallocated_trade
-- DROP FUNCTION genesis2.auto_allocate_unallocated_trade(bpchar, int4, int4, _int4);

CREATE OR REPLACE FUNCTION genesis2.auto_allocate_unallocated_trade(in_instrument_type_id character, in_allocation_type integer, in_date_id integer DEFAULT get_dateid(CURRENT_DATE), in_account_ids integer[] DEFAULT '{}'::integer[])
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL:  AutoAllocation'
AS $function$
--in_allocation_type = 0: options
--in_allocation_type = 1: equities with ACC.IS_SPECIFIC_ALLOCATED = 'N'
--in_allocation_type = 2: equities with ACC.IS_SPECIFIC_ALLOCATED = 'Y'

--  SY:  20210223  DS-2833.  Subscription  has  been  introduced
--  SY:  20210418  DS-3342.  Migrate  to  is_option_autoallocate  for  options  and  is_autoallocate  for  Equity
--  SY:  20210610  DS-3568.  Introduced  market  Participant  id  and  coalesce(tr.compliance_id,  tr.alternative_compliance_id)  to  group  by  statement  while  bunching  trades
--  SY:  20210715  DS-3811.  The  opt_is_fix_custfirm_processed  field  has  been  added  to  the  logic  to  identify  using  of  mpid  during  bunching.
--  SY:  20230922  https://dashfinancial.atlassian.net/browse/DS-7307  street_account_name  field  has  been  added  to  the  manual  clearing  sub  query
--  SY:  20240901  https://dashfinancial.atlassian.net/browse/DS-7470  application  name  has  been  added  to  be  able  to  track  performance  via  zabbix    -- SY: 20240212 https://dashfinancial.atlassian.net/browse/DS-7931 join to clearing account has been added to be sure manual clearin uses correct attributes.
-- 	SY:  20240221   https://dashfinancial.atlassian.net/browse/DS-7931 join to clearing account has been added to be sure manual clearin uses correct attributes.
-- 																	condition on cmta is not null has been removed from that join.
--  SY:  20240221 https://dashfinancial.atlassian.net/browse/DS-8077	having count(1) has been added
--  SY:  20241114 https://dashfinancial.atlassian.net/browse/DS-9151 tr table has been introduced
--  SO:  20250602 https://dashfinancial.atlassian.net/browse/DS-10060 Added account_id list as an input parameter that is calculated in the wrapper (see https://dashfinancial.atlassian.net/browse/DS-10060)
--  SO:  20250606 https://dashfinancial.atlassian.net/browse/DS-10060 Support multiple default CTMAs in auto-allocation job
--  SO:  20250630 https://dashfinancial.atlassian.net/browse/DS-10060 REMOVING support multiple default CTMAs in auto-allocation job
-- SY\SO: 20250704 performance improvement (add index to temp table with trade_records)
--  SO: 20250721 https://dashfinancial.atlassian.net/browse/DS-10191 add multiple CMTA logic again

DECLARE

    l_date_id       integer;
    l_max_trade_id  int8;
    l_cnt_rows      int;
    l_load_id       int;
    l_step_id       int;
    l_load_batch_id bigint;
begin

  select nextval('load_timing_seq') into l_load_id;
  l_step_id:=1;
  l_cnt_rows := 0;

  l_date_id = in_date_id;

select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

select public.load_log(l_load_id, l_step_id, 'AUTOALLOCATION Started <<<', 0, 'S')
	into l_step_id;

select public.load_log(l_load_id, l_step_id, 'l_load_batch_id: '||l_load_batch_id, 0, 'S')
	into l_step_id;

 select public.load_log(l_load_id, l_step_id, 'in_instrument_type_id='||in_instrument_type_id||' in_allocation_type='||in_allocation_type||' date_id='||l_date_id, 1 , 'O')
	into l_step_id;

execute 'select max(TRADE_RECORD_ID)  from TRADE_RECORD where is_busted=''N'' and date_id = '||l_date_id
  into l_max_trade_id ;

 select public.load_log(l_load_id, l_step_id, 'l_max_trade_id='||l_max_trade_id, 1 , 'S')
	into l_step_id;

  drop table if exists t_tr;
  create temp table t_tr on commit drop
  as
  select TR.ACCOUNT_ID,
         TR.INSTRUMENT_ID,
         TR.SIDE,
         TR.OPEN_CLOSE,
         tr.cmta,
         acc.opt_is_fix_custfirm_processed,
         tr.market_participant_id,
         tr.compliance_id,
         tr.alternative_compliance_id,
         TR.LAST_PX,
         TR.LAST_QTY,
         tr.trade_record_id
  from genesis2.trade_record tr
           inner join genesis2.account acc on (acc.account_id = tr.account_id)
           inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
  where TR.DATE_ID = l_date_id
    and TR.IS_BUSTED = 'N'
    and case in_instrument_type_id
            when 'E' then ACC.IS_AUTO_ALLOCATE
            else ACC.IS_OPTION_AUTO_ALLOCATE
            end = 'Y'
    and I.INSTRUMENT_TYPE_ID = in_instrument_type_id
    and ((in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
         (in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
    and TR.TRADE_RECORD_ID <= l_max_trade_id
    and TR.TRADE_RECORD_ID <= l_max_trade_id
    and tr.order_id > 0 /* excluding Blaze originated Away trades */
    and (in_allocation_type = 0
      or (in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
      or (in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
      OR (in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
    and case  -- added DS-10061
            when in_account_ids = '{}' then true
            when in_account_ids is null then false
            else acc.account_id = any (in_account_ids) end;

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

    	select public.load_log(l_load_id, l_step_id, 'create temp table TR', l_cnt_rows, 'I')
		into l_step_id;



  drop table if exists trade_for_allocations;
  create temp table trade_for_allocations on commit drop
  as
  select L1.ACCOUNT_ID,
         L1.INSTRUMENT_ID,
         L1.SIDE,
         L1.OPEN_CLOSE,
         L1.cmta,
         L1.mpid,
         eq_grp,
         L1.AVG_PX,
         L1.TOTAL_QTY,
         L1.trade_ids,
         nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
  from (select TR.ACCOUNT_ID,
               TR.INSTRUMENT_ID,
               TR.SIDE,
               TR.OPEN_CLOSE,
               tr.cmta,
               case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end as mpid,
               case in_allocation_type
                   when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                   else null end                                                                          as eq_grp,
               round(sum(TR.LAST_PX * TR.LAST_QTY) / sum(TR.LAST_QTY), 6)                                 as AVG_PX,
               sum(TR.LAST_QTY)                                                                           as TOTAL_QTY,
               array_agg(tr.trade_record_id)                                                              as trade_ids --, nextval('allocation_instruction_alloc_instr_id_seq'::regclass) as alloc_instr_id
       from t_tr tr
                 /* SY: Just to be sure clearing account already configured */
                 inner join genesis2.CLEARING_ACCOUNT CA on (CA.ACCOUNT_ID = TR.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                                             CA.MARKET_TYPE = in_instrument_type_id and
                                                             CA.IS_DEFAULT = 'Y')
--                 inner join t_clearing_account_aa caa on caa.clearing_account_id = ca.clearing_account_id
            /* We need to exclude manual allocations */
                 left join lateral (select A.ALLOC_INSTR_ID
                                    from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                             inner join genesis2.ALLOCATION_INSTRUCTION A
                                                        on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                    where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID) AA on true
            /* We need to exclude manual clearing */
                 left join lateral (select count(1) cn --coalesce(cie.new_trade_record_id, cie.trade_record_id) as trade_RECORD_ID /*, cie.clearing_instr_entry_id */
                                    from genesis2.clearing_instruction_entry cie
                                             inner join genesis2.clearing_instruction ci
                                                        on cie.clearing_instr_id = ci.clearing_instr_id and
                                                           ci.status = 'D' and ci.is_deleted = 'N'
                                             inner join genesis2.clearing_account inner_ca
                                                        on cie.clearing_account_number =
                                                           inner_ca.clearing_account_number
                                                            and cie.account_id = inner_ca.account_id
                                                            and inner_ca.is_deleted = 'N'
                                                            and inner_ca.market_type =
                                                                in_instrument_type_id /* to avoid attempt to allocate wrong clearing accounts*/
                                                            and
                                                           nullif(cie.street_account_name, '') is not distinct from nullif(inner_ca.occ_actionable_id, '')
                                    --and inner_ca.clearing_account_name = ''
                                    where cie.date_id = l_date_id
                                      and nullif(cie.clearing_account_number, '') is not null
                                      and nullif(cie.cmta, '') is not null
                                      and coalesce(cie.new_trade_record_id, cie.trade_record_id) = TR.TRADE_RECORD_ID
                                    group by TR.TRADE_RECORD_ID
                                    having count(1) = 1 /*We just need to be sure we have one clearing account for that manual allocation */
            ) man_clear on true

        where AA.ALLOC_INSTR_ID is null
          and man_clear.cn is null
        --and TR.TRADE_RECORD_ID <= l_max_trade_id
        group by TR.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, TR.OPEN_CLOSE, tr.cmta,
                 case tr.opt_is_fix_custfirm_processed when 'Y' then tr.market_participant_id else null end,
                 case in_allocation_type
                     when 3 then coalesce(tr.compliance_id, tr.alternative_compliance_id)
                     else null end) L1;

    	GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;


    	select public.load_log(l_load_id, l_step_id, 'create temp table trade_for_allocations', l_cnt_rows, 'I')
		into l_step_id;

        create index on trade_for_allocations (alloc_instr_id);

    	select public.load_log(l_load_id, l_step_id, 'create index on table trade_for_allocations', 0, 'I')
		into l_step_id;

  insert into genesis2.ALLOCATION_INSTRUCTION(alloc_instr_id, DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID, SIDE,
                                              OPEN_CLOSE, AVG_PX, TOTAL_QTY, CREATED_BY_SUBSYSTEM_ID, dataset_id)
  select tr.alloc_instr_id,
         l_date_id,
         clock_timestamp(),
         TR.ACCOUNT_ID,
         TR.INSTRUMENT_ID,
         TR.SIDE,
         TR.OPEN_CLOSE,
         tr.AVG_PX,
         tr.TOTAL_QTY,
         'RPS',
         l_load_batch_id
  from trade_for_allocations TR;

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION', l_cnt_rows, 'I')
  into l_step_id;
  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job (removed default_ratio feature)
  -------------- DS-10191 Support multiple CMTA in auto-allocation and Options Allocation Configuration

    -- creating temp table for account_id with sum(allocatin_ratio) = 1 only
  create temp table t_clearing_account_aa on commit drop as
  with base as (select ca.account_id,
                       coalesce(aa.clearing_account_id, ca.clearing_account_id)         as clearing_account_id,
                       coalesce(aa.occ_actionable_id, ca.occ_actionable_id)             as occ_actionable_id,
                       coalesce(aa.clearing_account_number, ca.clearing_account_number) as clearing_account_number,
                       coalesce(aa.cmta, ca.cmta)                                       as cmta,
                       coalesce(aa.auto_alloc_ratio, 1)                                 as auto_alloc_ratio
                from genesis2.clearing_account ca
                         left join genesis2.clearing_account aa
                                   on ca.account_id = aa.account_id and aa.is_auto_alloc_to = 'Y'
                                       and aa.is_deleted = 'N'
                                       and aa.market_type = in_instrument_type_id
                where true
                  and ca.is_deleted = 'N'
                  and ca.market_type = in_instrument_type_id
                  and ca.is_default = 'Y')
     , check_sum_ratio as (select account_id, sum(auto_alloc_ratio) as sum_ratio
                           from base
                           group by account_id
                           having sum(auto_alloc_ratio) = 1)
  select account_id, clearing_account_id, occ_actionable_id, clearing_account_number, cmta, auto_alloc_ratio
  from base
           join check_sum_ratio using (account_id);




-- 2. insert into allocation_instruction_entry
  /*
  drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       max(clearing_account_id)                              as clearing_account_id,
                       ai.total_qty                                          as qty,
                       ca.occ_actionable_id
                from genesis2.allocation_instruction ai
                         inner join genesis2.clearing_account ca
                                    on (ca.account_id = ai.account_id and ca.is_deleted = 'N' and
                                        ca.market_type = in_instrument_type_id and ca.is_default = 'Y')
                where ai.date_id = l_date_id
                  and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id
                )
  select alloc_instr_id,
         clearing_account_id,
         qty as alloc_qty,
         occ_actionable_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;
  */

    drop table if exists t_aie;
  create temp table t_aie on commit drop as
  with base as (select ai.alloc_instr_id,
                       ca.clearing_account_id,
                       ai.account_id,
                       ca.auto_alloc_ratio,
                       ai.total_qty                                          as qty,
                       ai.total_qty * auto_alloc_ratio                    as pre_sum,
                       floor(ai.total_qty * auto_alloc_ratio)             as rnd_sum,
                       sum(floor(ai.total_qty * auto_alloc_ratio)) over w as acc_rnd_sum,
                       row_number() over w                                   as rn,
                       ca.occ_actionable_id
                from genesis2.allocation_instruction ai
                         inner join t_clearing_account_aa ca on (ca.account_id = ai.account_id)
                where ai.date_id = l_date_id
                  and ai.dataset_id = l_load_batch_id
                  and ai.is_deleted = 'N'
                group by ai.date_id, ai.alloc_instr_id, ai.total_qty, ca.occ_actionable_id, ca.clearing_account_id,
                         ai.account_id, ca.auto_alloc_ratio, ca.clearing_account_number
                window w as ( partition by ai.alloc_instr_id, ai.account_id
                        order by ca.auto_alloc_ratio, ca.clearing_account_number desc, ca.clearing_account_id)
                )
  select alloc_instr_id,
         clearing_account_id,
         case
             when rn != (select max(rn) from base b where b.alloc_instr_id = base.alloc_instr_id) then rnd_sum
             else qty - coalesce(lag(base.acc_rnd_sum)
                        over (partition by alloc_instr_id order by auto_alloc_ratio), 0) end  as alloc_qty,
--          rn,
--          qty as alloc_qty,
         occ_actionable_id,
--         l_date_id,
         nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as allocation_instruction_entry_id,
         ta.trade_ids
  from base
  join lateral (select trade_ids from trade_for_allocations ta where ta.alloc_instr_id = base.alloc_instr_id limit 1) ta on true;


  -------------------------------------------------------------------------------------
  select public.load_log(l_load_id, l_step_id, 'created temp table', l_cnt_rows, 'I')
  into l_step_id;

  insert into genesis2.allocation_instruction_entry (alloc_instr_id, clearing_account_id, alloc_qty, date_id,
                                                     occ_actionable_id, allocation_instruction_entry_id)
  select alloc_instr_id,
         clearing_account_id,
         alloc_qty,
         l_date_id,
         occ_actionable_id,
         allocation_instruction_entry_id
  from t_aie
where alloc_qty > 0;


  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;

  select public.load_log(l_load_id, l_step_id, 'insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
  into l_step_id;


  insert into genesis2.alloc_instr2trade_record(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,
                                                allocation_instruction_entry_id)
  with base as (select unnest(trade_ids) as id,
                       ALLOC_INSTR_ID
--                       l_date_id as date_id,
--                       l_load_batch_id as batch_id
                from trade_for_allocations)
  select tr.id, tr.ALLOC_INSTR_ID, l_date_id, l_load_batch_id, aie.allocation_instruction_entry_id
  from base tr
           left join lateral ( select max(allocation_instruction_entry_id) as allocation_instruction_entry_id
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                            and aie.date_id = l_date_id
                          group by alloc_instr_id
                          having count(*) = 1 -- SO: to prevent adding multiple alloc_instr_entry_id
               ) aie on true
           where exists ( select null
                          from genesis2.allocation_instruction_entry aie
                          where aie.alloc_instr_id = tr.alloc_instr_id
                            and aie.date_id = l_date_id
                          limit 1
               );


  -------------- DS-10060 Support multiple default CTMAs in auto-allocation job
  -- End of the insertion into genesis2.allocation_instruction_entry


       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
       select public.load_log(l_load_id, l_step_id, 'insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
	   into l_step_id;


	  /* ===================================================================================================================== */
	  /* Logic for Manual cleared trades */
	  /* ===================================================================================================================== */
  with main_source as (select l_date_id                                                                       as date_id,
                              clock_timestamp()                                                               as CREATE_TIME,
                              man_clear.ACCOUNT_ID,
                              TR.INSTRUMENT_ID,
                              TR.SIDE,
                              man_clear.OPEN_CLOSE,
                              round(sum(man_clear.LAST_PX * man_clear.LAST_QTY) / sum(man_clear.LAST_QTY), 6) as AVG_PX,
                              sum(man_clear.LAST_QTY)                                                         as TOTAL_QTY,
                              man_clear.clearing_account_id,
                              l_load_batch_id                                                                 as load_batch_id
                       from genesis2.TRADE_RECORD TR
                                inner join genesis2.ACCOUNT ACC on (ACC.ACCOUNT_ID = TR.ACCOUNT_ID)
                           /* SY: Just to be sure clearing account already configured */
                                inner join genesis2.CLEARING_ACCOUNT CA
                                           on (CA.ACCOUNT_ID = ACC.ACCOUNT_ID and CA.IS_DELETED = 'N' and
                                               CA.MARKET_TYPE = in_instrument_type_id and CA.IS_DEFAULT = 'Y')
                                inner join genesis2.INSTRUMENT I on (TR.INSTRUMENT_ID = I.INSTRUMENT_ID)
                           /* We need to exclude manual allocations and already autoallocated trades */
                                left join lateral (select A.ALLOC_INSTR_ID
                                                   from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                                            inner join genesis2.ALLOCATION_INSTRUCTION A
                                                                       on (A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID and A.IS_DELETED = 'N')
                                                   where AT.TRADE_RECORD_ID = TR.TRADE_RECORD_ID
                                                  limit 1) AA on true
                           /* Manual clearing */
                                inner join lateral (select cie.last_qty,
                                                           cie.last_px,
                                                           cie.clearing_account_number,
                                                           cie.open_close,
                                                           cie.account_id,
                                                           inner_ca.clearing_account_id
                                                    from genesis2.clearing_instruction_entry cie
                                                             inner join genesis2.clearing_instruction ci
                                                                        on cie.clearing_instr_id =
                                                                           ci.clearing_instr_id and ci.status = 'D' and
                                                                           ci.is_deleted = 'N'
                                                             inner join genesis2.clearing_account inner_ca
                                                                        on cie.clearing_account_number =
                                                                           inner_ca.clearing_account_number
                                                                            and cie.account_id = inner_ca.account_id
                                                                            and inner_ca.is_deleted = 'N'
                                                                            and
                                                                           inner_ca.market_type = in_instrument_type_id
                                                                            and
                                                                           nullif(cie.street_account_name, '') is not distinct from nullif(inner_ca.occ_actionable_id, '')
                                                    --and inner_ca.clearing_account_name = ''
                                                    where cie.new_trade_record_id = TR.TRADE_RECORD_ID
                                                      and cie.date_id = tr.date_id
                                                      and nullif(cie.cmta, '') is not null
                                                      and nullif(cie.clearing_account_number, '') is not null
                                                    order by nullif(inner_ca.clearing_account_name, '') nulls first
                                                    limit 1
                           ) man_clear on true
                       where TR.DATE_ID = l_date_id
                         and TR.IS_BUSTED = 'N'
--        and ACC.IS_AUTO_ALLOCATE = 'Y'
                         and case in_instrument_type_id
                                 when 'E' then ACC.IS_AUTO_ALLOCATE
                                 else ACC.IS_OPTION_AUTO_ALLOCATE
                                 end = 'Y'
                         and I.INSTRUMENT_TYPE_ID = in_instrument_type_id
                         and tr.order_id > 0 /* excluding Blaze originated Away trades */
                         and ((in_instrument_type_id = 'O' and coalesce(ACC.OPT_REPORT_TO_MPID, 'NONE') <> 'NONE') or
                              (in_instrument_type_id = 'E' and coalesce(ACC.EQ_REPORT_TO_MPID, 'NONE') <> 'NONE'))
                         and AA.ALLOC_INSTR_ID is null
                         and TR.TRADE_RECORD_ID <= l_max_trade_id
                         and (in_allocation_type = 0
                           or (in_allocation_type = 1 AND ACC.IS_SPECIFIC_ALLOCATED = 'N')
                           or (in_allocation_type = 2 AND ACC.IS_SPECIFIC_ALLOCATED = 'Y')
                           OR (in_allocation_type = 3 AND ACC.IS_SPECIFIC_ALLOCATED = 'T'))
                         and case -- added DS-10061
                                 when coalesce(in_account_ids, '{}') = '{}' then true
                                 else acc.account_id = any (in_account_ids) end
                       group by man_clear.ACCOUNT_ID, TR.INSTRUMENT_ID, TR.SIDE, man_clear.OPEN_CLOSE,
                                man_clear.clearing_account_id),

       ins_all_in as ( insert into genesis2.ALLOCATION_INSTRUCTION (DATE_ID, CREATE_TIME, ACCOUNT_ID, INSTRUMENT_ID,
                                                                    SIDE, OPEN_CLOSE, AVG_PX, TOTAL_QTY,
                                                                    CREATED_BY_SUBSYSTEM_ID, dataset_id)
           select DATE_ID
                , CREATE_TIME
                , ACCOUNT_ID
                , INSTRUMENT_ID
                , SIDE
                , OPEN_CLOSE
                , AVG_PX
                , TOTAL_QTY
                , main_source.clearing_account_id /*we insert there not subsystem. it will be updated later. We need one more field into ALLOCATION_INSTRUCTION table */
                , load_batch_id
           from main_source
           returning ALLOC_INSTR_ID, CREATED_BY_SUBSYSTEM_ID, TOTAL_QTY, account_id)

  insert
  into genesis2.ALLOCATION_INSTRUCTION_ENTRY (ALLOC_INSTR_ID, CLEARING_ACCOUNT_ID, ALLOC_QTY, DATE_ID,
                                              occ_actionable_id)
  select ALLOC_INSTR_ID, CLEARING_ACCOUNT_ID, TOTAL_QTY, l_date_id, ca.occ_actionable_id
  from ins_all_in
           inner join genesis2.clearing_account ca on ca.clearing_account_id = ins_all_in.CREATED_BY_SUBSYSTEM_ID::int;

	       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
	       select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared insert into ALLOCATION_INSTRUCTION_ENTRY', l_cnt_rows, 'I')
		   into l_step_id;


  insert into genesis2.ALLOC_INSTR2TRADE_RECORD(TRADE_RECORD_ID, ALLOC_INSTR_ID, DATE_ID, dataset_id,allocation_instruction_entry_id)
  select coalesce(cie.new_trade_record_id, cie.trade_record_id), aie.ALLOC_INSTR_ID, l_date_id, l_load_batch_id, aie.allocation_instruction_entry_id
  from genesis2.ALLOCATION_INSTRUCTION ai
           inner join genesis2.ALLOCATION_INSTRUCTION_ENTRY aie
                      on ai.alloc_instr_id = aie.alloc_instr_id and is_deleted = 'N' and ai.date_id = aie.date_id
           inner join genesis2.clearing_account ca
                      on aie.clearing_account_id = ca.clearing_account_id and ca.is_deleted = 'N'
           inner join genesis2.clearing_instruction_entry cie
                      on cie.account_id = ca.account_id /*and cie.cmta = ca.cmta*/ and
                         cie.date_id = aie.date_id --- ?????
                          and cie.clearing_account_number = ca.clearing_account_number
                          --and cie.street_account_name = ca.occ_actionable_id
                          and nullif(cie.street_account_name, '') is not distinct from nullif(ca.occ_actionable_id, '')
                          and nullif(cie.cmta, '') is not null
           inner join genesis2.clearing_instruction ci
                      on cie.clearing_instr_id = ci.clearing_instr_id and ci.status = 'D' and ci.date_id = cie.date_id
           inner join genesis2.trade_record tr
                      on (coalesce(cie.new_trade_record_id, cie.trade_record_id) = tr.trade_record_id
                          and cie.date_id = tr.date_id
                          and tr.is_busted = 'N'
                          and ai.side = tr.side
                          and ai.instrument_id = tr.instrument_id
                          and ai.open_close = tr.open_close)
  where dataset_id = l_load_batch_id
    and ai.date_id = l_date_id
    and coalesce(ai.CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS'
    and not exists (select null
                    from ALLOC_INSTR2TRADE_RECORD in_ai
                    where in_ai.trade_record_id = coalesce(cie.new_trade_record_id, cie.trade_record_id)
--                      and in_ai.alloc_instr_id = ai.alloc_instr_id
                      and in_ai.date_id = ai.date_id);

  GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
  select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared insert into ALLOC_INSTR2TRADE_RECORD', l_cnt_rows, 'I')
  into l_step_id;

  update genesis2.ALLOCATION_INSTRUCTION
  set CREATED_BY_SUBSYSTEM_ID = 'RPS'
  where dataset_id = l_load_batch_id
    and date_id = l_date_id
    and coalesce(CREATED_BY_SUBSYSTEM_ID, 'RPS') <> 'RPS';

 		       GET DIAGNOSTICS l_cnt_rows = ROW_COUNT;
		       select public.load_log(l_load_id, l_step_id, 'MANUAL Cleared CREATED_BY_SUBSYSTEM_ID restored', l_cnt_rows, 'I')
			   into l_step_id;


/* We need that part because GET DIAGNOSTIC still doesn't work with partitioned tables */
  select count(1)
  from genesis2.alloc_instr2trade_record aitr
  where date_id = l_date_id
    and dataset_id = l_load_batch_id
  into l_cnt_rows;

  Perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id,
                                 in_row_cnt => l_cnt_rows,
                                 in_subscription_name => 'allocation_to_big_data',
                                 in_source_table_name => 'genesis2.allocation_instruction',
                                 in_date_id => l_date_id);

select public.load_log(l_load_id, l_step_id, 'AUTOALLOCATION COMPLETED >>>', 0, 'E')
	into l_step_id;


  return l_cnt_rows;

 exception when others then
   select load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select load_log(l_load_id, l_step_id, 'AUTOALLOCATION COMPLETED !!!', 0, 'E')
  into l_step_id;

  PERFORM load_error_log('AUTOALLOCATION',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
  RAISE;
end
$function$
;


-- dash360.bofa_allocation_report_wrapper
-- no changes


-- dash360.allocations_get_accounts_config
-- DROP FUNCTION dash360.allocations_get_accounts_config(bpchar, _int8);

CREATE OR REPLACE FUNCTION dash360.allocations_get_accounts_config(in_market_type character DEFAULT 'O'::character(1), in_account_ids bigint[] DEFAULT '{}'::bigint[])
 RETURNS TABLE(account_id bigint, is_auto_allocate character, clearing_accounts jsonb, is_intraday_auto_allocate character)
 LANGUAGE plpgsql
 COST 1
AS $function$

    -- MG: 20210413 -- add is_option_auto_allocate field to output
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208   The is_visible_for_manual_allocation field has been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20250626 without ticket added new input parameter in_account_ids (back-end will call this procedure per account instead of cache)
begin
    return query
        select acc.account_id::bigint,
               (case
                    when in_market_type = 'E' then acc.is_auto_allocate
                    when in_market_type = 'O' then acc.is_option_auto_allocate
                    else acc.is_auto_allocate
                   end) as is_auto_allocate,
               jsonb_agg(jsonb_object(array ['ca_number', 'def' , 'ca_name', 'oaid', 'visible', 'alloc_ratio', 'auto_alloc_to'],
                                      array [ca.clearing_account_number, ca.is_default , ca.clearing_account_name, ca.occ_actionable_id, ca.is_visible_for_manual_allocation::text, ca.auto_alloc_ratio::text, ca.is_auto_alloc_to ])),
               acc.is_intraday_auto_allocate
        from genesis2.account acc
                 inner join genesis2.clearing_account ca
                            on acc.account_id = ca.account_id
                                and ca.is_deleted = 'N'
                                and ca.market_type = in_market_type
        where acc.is_deleted = 'N'
        and case when coalesce(in_account_ids, '{}') = '{}' then true else acc.account_id = any(in_account_ids) end
        group by acc.account_id,
                 (case
                      when in_market_type = 'E' then acc.is_auto_allocate
                      when in_market_type = 'O' then acc.is_option_auto_allocate
                      else acc.is_auto_allocate
                     end)
--limit 10
    ;

end;
$function$
;

-- dash360.allocations_set_account_config
-- DROP FUNCTION dash360.allocations_set_account_config(int8, text, bpchar, bpchar, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_set_account_config(in_account_id bigint, in_clearing_accounts text, in_is_auto_allocate character DEFAULT NULL::character(1), in_instrumnt_type_id character DEFAULT 'O'::bpchar, in_user_id integer DEFAULT NULL::integer, in_is_intraday_auto_allocate character DEFAULT NULL::bpchar)
 RETURNS integer
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- MG: 20210413 add support to is_option_auto_allocate field
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208 is_visible_for_manual_allocation  and user_id fields have been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable


declare
    l_clearing_account_type smallint;
    l_row_cnt               int;
    l_clearing_accounts jsonb;

begin
    l_clearing_accounts := in_clearing_accounts::jsonb;
    if in_instrumnt_type_id = 'E' and in_is_auto_allocate is not null
    then
-- set is_autoallocate value
        update account acc
        set is_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_instrumnt_type_id = 'O' and in_is_auto_allocate is not null
    then
-- set is_option_auto_allocate value
        update account acc
        set is_option_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_option_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_is_intraday_auto_allocate is not null then
        update account acc
        set is_intraday_auto_allocate = in_is_intraday_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
--           and acc.is_option_auto_allocate <> in_is_auto_allocate
        ;
    end if;


-- close all current configuration for the account if any

    update genesis2.clearing_account
    set is_deleted  = 'Y',
        delete_time = clock_timestamp(),
        user_id     = in_user_id
    where account_id = in_account_id
      and market_type = in_instrumnt_type_id
      and is_deleted = 'N';

    -- get  clearing_account_type

--  select case sum(case instrument_type_id when in_instrumnt_type_id then 1 else 0 end)
--          when 1 then count(1)
--          else 2 -- Temporary solution. For some reason account_id could be missed in account2instrument_type
--          end  as  clearing_account_type
--  into l_clearing_account_type
--  from staging.account2instrument_type ait
--  where account_id = in_account_id
--    and instrument_type_id  in ('E', 'O');

    -- Temporary logc SY:20201215 as per chat with Tim Miller
    l_clearing_account_type := 1;


    insert into genesis2.clearing_account (account_id, clearing_account_type, clearing_account_number, is_default,
                                           market_type, is_deleted, cmta, clearing_account_name, occ_actionable_id,
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio, is_auto_alloc_to)
    select in_account_id,
           l_clearing_account_type::varchar,
           sj ->> 'ca_number'             as clearing_account_number,
           sj ->> 'def'                   as is_default,
           in_instrumnt_type_id           as market_type,
           --clock_timestamp() as  create_time,
           'N'                            as is_deleted,
           sj ->> 'ca_number'             as cmta,
           coalesce(sj ->> 'ca_name', '') as clearing_account_name,
           sj ->> 'oaid'                  as occ_actionable_id,
           in_user_id,
           (sj ->> 'visible')::bool       as is_visible_for_manual_allocation,
           coalesce((sj -> 'alloc_ratio')::numeric, 1),
           sj ->> 'auto_alloc_to'
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;

-- dash360.allocations_clearing_accounts_by_account_id
-- DROP FUNCTION dash360.allocations_clearing_accounts_by_account_id(int8, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_clearing_accounts_by_account_id(in_account_id bigint, in_market_type character)
 RETURNS TABLE(clearing_account_id integer, clearing_account_number character varying, clearing_account_name character varying, is_default character, clearing_account_type character, market_type character, cmta character varying, occ_actionable_id character varying, account_id integer, is_visible_for_manual_allocation boolean, auto_alloc_ratio numeric, is_auto_alloc_to character)
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208
-- SO: 20250610 https://dashfinancial.atlassian.net/browse/D360-15839
begin

    return query
        select ca.clearing_account_id::integer,
               ca.clearing_account_number,
               ca.clearing_account_name,
               ca.is_default::character,
               ca.clearing_account_type::character,
               ca.market_type::character,
               ca.cmta,
               ca.occ_actionable_id,
               ca.account_id,
               ca.is_visible_for_manual_allocation,
               ca.auto_alloc_ratio,
               ca.is_auto_alloc_to
        from genesis2.clearing_account ca
        where ca.account_id = in_account_id
          and ca.market_type = in_market_type
          and ca.is_deleted = 'N'
        order by ca.is_default desc, ca.clearing_account_number;

end;
$function$
;

-- dash360.allocations_clone_account_config
-- no changes

-- dash360.allocations_create
-- DROP FUNCTION dash360.allocations_create(int4, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.allocations_create(in_date_id integer, in_user_id integer, in_change_vector character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
 -- SY 20210319 Initial creation
 -- SY 20210420 DS-3363 Fix CCRU has been added
-- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
-- SY 20240813 https://dashfinancial.atlassian.net/browse/DS-8581 Reverted
-- SY 20240816 https://dashfinancial.atlassian.net/browse/DS-8208 in_user_id has been propagated to f_get_clearing_account_id to make possible user_id autocreation save
-- SY\SO 20250704 https://dashfinancial.atlassian.net/browse/DS-10177 providing alloc_instr_entry_id into alloc_instr2trade_record
declare
 l_change_vector jsonb;
 l_new_trade_record_ids bigint[];
 scr record;
 l_alloc_instr int;
 l_load_batch_id bigint;
 l_step_id int;
 l_row_cnt int;

begin
  l_step_id:=0;
  select nextval('genesis2.allocation_instruction_alloc_instr_id_seq'::regclass) into l_alloc_instr;
  select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create STARTED =====', 0, 'S'::char)
	into l_step_id;


 l_change_vector:=in_change_vector::jsonb;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_change_vector converted to jsonb', 1, 'I'::char)
  into l_step_id;

  for scr in (select e.clearing_instr_id
                 from  clearing_instruction_entry e
                 inner join clearing_instruction ca on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
                 where e.date_id = in_date_id
                 and ca.status in ('P', 'C')
                 and e.trade_record_id in (select jsonb_object_keys (l_change_vector)::bigint )
                 limit 1) loop
--   raise exception using message = 'S 167', detail = 'D 167', hint = 'H 167', errcode = 'P3333';

     raise exception 'Error: Clearing change request is in progress. Please wait till it is processed' using errcode='CLRIP', /*message='Can''t be allocated due to pending clearing',*/ hint='Please finish or reject clearing request before allocating it' ;
     end loop;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Before PTM', 1, 'I'::char)
  into l_step_id;

    l_new_trade_record_ids:=dash360.ptm_process_trades(in_date_id, in_user_id, l_change_vector);

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'PTM DONE', cardinality (l_new_trade_record_ids), 'I'::char)
  into l_step_id;


 with tr as materialized
            (select tr.trade_record_id, tr.account_id , tr.instrument_id,  tr.last_qty, tr.allocation_avg_price, tr.open_close , tr.side, tr.street_account_name , tr.account_nickname, tr.cmta, tr.clearing_account_number, i.instrument_type_id
              from genesis2.trade_record tr
              inner join genesis2.instrument i on tr.instrument_id =i.instrument_id
              where date_id = in_date_id
    			and trade_record_id = any(l_new_trade_record_ids)
    			and is_busted ='N'
    		 ),
     pre_aie as (select --l_alloc_instr,
                       -- in_date_id,
                       dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number,
                                                          tr.account_nickname, tr.street_account_name,
                                                          tr.instrument_type_id, in_user_id)                as clearing_account_id
                      , tr.street_account_name
                      , tr.account_nickname
                      , sum(last_qty) as last_qty
                      , nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as alloc_instr_entry_id,
                        array_agg(trade_record_id) as trade_record_ids
                 from tr
                 group by clearing_account_id, street_account_name, account_nickname
)
 ,      aie as( INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id, occ_actionable_id, account_nickname, alloc_qty, allocation_instruction_entry_id)
			   select l_alloc_instr, in_date_id, clearing_account_id, street_account_name, account_nickname,  last_qty, alloc_instr_entry_id
			   from pre_aie
               returning *),
        a2tr as (INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id, allocation_instruction_entry_id)
                 select unnest(trade_record_ids), l_alloc_instr, in_date_id, l_load_batch_id, alloc_instr_entry_id
                 from pre_aie
                /* inner join aie on aie.clearing_account_id = tr.clearing_account_id and
                                   coalesce(tr.occ_actionable_id, '---') = coalesce(aie.occ_actionable_id, '---') and
                                   coalesce(tr.account_nickname, '---') = coalesce(aie.account_nickname, '---') */ )
   INSERT INTO allocation_instruction
	(alloc_instr_id, date_id, create_time, account_id, instrument_id, total_qty, avg_px, open_close, side, created_by_user_id,  dataset_id)
	select l_alloc_instr, in_date_id, clock_timestamp(), account_id , instrument_id,  sum(last_qty), allocation_avg_price, open_close , side, in_user_id, l_load_batch_id
    from tr
    group by account_id , instrument_id, allocation_avg_price, open_close, side;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocation tables popultaed', l_row_cnt, 'I'::char)
  into l_step_id;


   -- Fix CCRU
--    select count(1)
   -- into l_cnt;
--	from (
		perform dash360.trade_record_update_ccru(in_user_id =>in_user_id , in_date_id => in_date_id, in_trade_record_id =>l.trade_record_id, in_rate => l.rate, in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
		from (select tr.trade_record_id::bigint, tlbr.rate ,  tr.last_qty*tlbr.rate as amount  , row_number () over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
					from genesis2.trade_record tr
					inner join genesis2.trade_level_book_record tlbr on tlbr.date_id = tr.date_id  and tlbr.trade_record_id = tr.orig_trade_record_id and book_record_type_id ='CCRU'
					inner join genesis2.book_record_creator brc on tlbr.book_record_creator_id = brc.book_record_creator_id
					where tr.date_id = in_date_id
					and tr.trade_record_id = any(array[l_new_trade_record_ids]) ) l
		where rn=1
--				) L2
			;
  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'CCRU subscribed', 0, 'I'::char)
  into l_step_id;


  Perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id,
			  					 in_row_cnt => 1,
			  					 in_subscription_name => 'allocation_to_big_data',
			  					 in_source_table_name => 'genesis2.allocation_instruction',
			  					 in_date_id => in_date_id);

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocations subscribed', 0, 'I'::char)
  into l_step_id;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'DONE', 0, 'E'::char)
  into l_step_id;

   return l_alloc_instr;

 exception when others then
   select genesis2.load_log(l_load_batch_id::int, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E'::char)
   into l_step_id;
 -- RAISE notice '% %', sqlstate, sqlerrm;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create DONE ====', 0, 'E'::char)
  into l_step_id;

  PERFORM genesis2.load_error_log('allocations_create'::varchar,  'I'::char, REPLACE(sqlerrm, ''::text, ''::text)::varchar, l_load_batch_id::int);
  RAISE;

end;
 $function$
;
