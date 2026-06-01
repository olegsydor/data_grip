-- DROP FUNCTION dash360.bofa_allocation_report_v2_safe(int4, int4, text, bool, _int4);

select * from dash360.bofa_allocation_report_v2_safe(20260601, 20260601, '733')

CREATE FUNCTION dash360.bofa_allocation_report_v2_safe(in_start_date_id integer, in_end_date_id integer,
                                                       in_exec_broker text, in_is_eod boolean DEFAULT false,
                                                       in_removed_account_ids integer[] DEFAULT '{62939,263022,62810,62887,62923,63787,67949}'::integer[])
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
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
    -- 20251215 SO Unabled to report -> Reportes. And the part for bust was added. V2 was created keeping in mind that both versions can be run
    -- 20260601 SO https://dashfinancial.atlassian.net/browse/DS-11593 Create "safe" report_alloc_instr_trade_record_v2 to perform testing on PROD

declare
    l_load_id                 int;
    l_step_id                 int;
    l_alloc_instr_id_reported int4[];
    l_row_cnt                 int4;
    l_row_cnt_eod             int4;
    l_msg_text                text;
    l_start_row               int4;
    l_account_ids             int4[];

begin
    l_msg_text := 'bofa_allocation_report_v2_safe intraday ' ||
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
      and to_report in ('R', 'U');


    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions collected',
                           coalesce(array_length(l_alloc_instr_id_reported, 1), 0), 'O')
    into l_step_id;


    drop table if exists t_bofa_allocation_report;
    create temp table t_bofa_allocation_report
    (
        alloc_instr_id                  integer,
        side                            char,
        avg_px                          numeric(14, 6),
        date_id                         integer,
        open_close                      char,
        alloc_qty                       integer,
        opt_is_fix_clfirm_processed     char,
        ftr_cmta                        varchar(3),
        ca_cmta                         varchar(3),
        opt_is_fix_custfirm_processed   char,
        opt_customer_firm               char,
        opt_customer_or_firm            char,
        occ_actionable_id               varchar(10),
        dataset                         integer,
        to_report                       bpchar,
        db_create_time                  timestamp default clock_timestamp() not null,
        instrument_id                   bigint,
        opt_penny_commission            numeric(12, 4),
        opt_nickel_commission           numeric(12, 4),
        root_symbol                     varchar(10),
        min_tick_increment              numeric(12, 4),
        put_call                        char,
        maturity_year                   smallint,
        maturity_month                  smallint,
        maturity_day                    smallint,
        strike_price                    numeric(12, 4),
        allocation_instruction_entry_id bigint
    );

-- insert into the table BUSTS
    with cte_ai as (select ai.alloc_instr_id
                    from genesis2.allocation_instruction ai
                    where true
                      and ai.is_deleted = 'Y'
                      and date_id between in_start_date_id and in_end_date_id
                      and exists (select ar.alloc_instr_id
                                  from dash_reporting.bofa_allocation_report ar
                                  where ar.alloc_instr_id = ai.alloc_instr_id
                                    and ar.side = ai.side
                                    and ar.date_id = ai.date_id
                                  group by ar.alloc_instr_id
                                  having count(*) = 1))
    insert into t_bofa_allocation_report
    (alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed, ftr_cmta, ca_cmta,
     opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm, occ_actionable_id, dataset, instrument_id,
     opt_penny_commission, opt_nickel_commission, root_symbol, min_tick_increment, put_call, maturity_year,
     maturity_month, maturity_day, strike_price, to_report, allocation_instruction_entry_id)
    select alin.alloc_instr_id,
           'X' as side,
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
           'B' as to_report,
           ae.allocation_instruction_entry_id
    from genesis2.allocation_instruction_entry ae
             join cte_ai on cte_ai.alloc_instr_id = ae.alloc_instr_id
             join genesis2.allocation_instruction alin
                  on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted = 'Y'
             inner join lateral (select tr.cmta,
                                        tr.opt_customer_firm
                                 from genesis2.alloc_instr2trade_record aitr
                                          inner join genesis2.trade_record tr
                                                     on aitr.trade_record_id = tr.trade_record_id
                                                         and aitr.date_id = tr.date_id
--                                                                 and tr.is_busted = 'N'
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
        and case when in_is_eod then true else acc.account_id != all (in_removed_account_ids) end
        )
             join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
             join genesis2.option_series os on os.option_series_id = oc.option_series_id
             join genesis2.instrument i on i.instrument_id = alin.instrument_id
    where alin.date_id between in_start_date_id and in_end_date_id
      and ca.account_id = any (l_account_ids);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' busts added',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

-- insert into the table the main data

    insert into t_bofa_allocation_report
    (alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed,
     ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
     occ_actionable_id, dataset, instrument_id, opt_penny_commission, opt_nickel_commission, root_symbol,
     min_tick_increment, put_call, maturity_year, maturity_month, maturity_day, strike_price, to_report,
     allocation_instruction_entry_id)
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
               when alin.is_deleted = 'Y' then 'B' -- Busted
               when ar.date_id is not null then 'C' --'skip - current alloc_instr_id'
           /*
           when or_ai.alloc_instr_ids && l_alloc_instr_id_reported
               then 'U' -- 'unable to report - alloc_instr_id has been reported before'
            */
               else 'R' end as to_report,
           ae.allocation_instruction_entry_id
    from genesis2.allocation_instruction_entry ae
             join genesis2.allocation_instruction alin
                  on alin.alloc_instr_id = ae.alloc_instr_id -- and alin.is_deleted <> 'Y'
/*             left join lateral (select alloc_instr_ids
                                from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                             alin.date_id) as x(alloc_instr_ids)
                                limit 1) or_ai on true
 */
             inner join lateral (select tr.cmta,
                                        tr.opt_customer_firm
                                 from genesis2.alloc_instr2trade_record aitr
                                          inner join genesis2.trade_record tr
                                                     on aitr.trade_record_id = tr.trade_record_id
                                                         and aitr.date_id = tr.date_id
--                                                                 and tr.is_busted = 'N'
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
        and case when in_is_eod then true else acc.account_id != all (in_removed_account_ids) end
        )
             join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
             join genesis2.option_series os on os.option_series_id = oc.option_series_id
             join genesis2.instrument i on i.instrument_id = alin.instrument_id
             left join lateral (select ar.date_id
                                from dash_reporting.bofa_allocation_report ar
                                where ar.alloc_instr_id = ae.alloc_instr_id
                                  and to_report in ('R', 'U')
                                limit 1) ar on true
    where alin.date_id between in_start_date_id and in_end_date_id
      and ca.account_id = any (l_account_ids)
      and not exists (select null
                      from dash_reporting.bofa_allocation_report ar
                      where ar.alloc_instr_id = ae.alloc_instr_id
                        and ar.side = alin.side
                        and ar.date_id = alin.date_id);

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' allocation_instructions added',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;


    --  PART 2. Printing the report for intraday
    drop table if exists t_bofa_allocation_report_history;
    create temp table t_bofa_allocation_report_history
    (
        report_row     text,
        dataset        integer,
        report_part    bpchar,
        db_create_time timestamp default clock_timestamp()
    );

    insert into t_bofa_allocation_report_history(report_row, dataset, report_part)
    select array_to_string(ARRAY [
                               'DAS' , ----Branch
                               CASE
                                   WHEN gen.to_report = 'B' then 'X' -- Busted
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
--                                    to_char(row_number() OVER () , 'FM0000') , --
                               to_char(gen.allocation_instruction_entry_id % 100000000, 'FM0000000') , --
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
           l_load_id,
           case to_report when 'B' then 'B' when 'R' then 'A' when 'U' then 'A' end as report_part
    from t_bofa_allocation_report gen
    where dataset = l_load_id
      and to_report in ('R', 'U', 'B');

    get diagnostics l_start_row = row_count;
    return query
        select report_row as ret_row
        from t_bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'B';

    return query
        select report_row as ret_row
        from t_bofa_allocation_report_history
        where dataset = l_load_id
          and report_part = 'A';

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' intraday reporting completed',
                           coalesce(l_start_row, 0), 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' FINISHED ========', l_row_cnt + l_row_cnt_eod, 'O')
    into l_step_id;


end;
$function$
;



-- DROP FUNCTION dash360.bofa_allocation_report_wrapper_v2(int4, int4, text, bool, _int4, bool);

CREATE FUNCTION dash360.bofa_allocation_report_wrapper_v2(in_start_date_id integer, in_end_date_id integer,
                                                          in_exec_broker text,
                                                          in_is_eod boolean DEFAULT false,
                                                          in_removed_account_ids integer[] DEFAULT '{62919,62939,263022,62810,62887,62923,63787,67949}'::integer[],
                                                          in_run_intraday_option_auto_allocation boolean DEFAULT true)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 20260601 SO https://dashfinancial.atlassian.net/browse/DS-11594
declare
    l_row_cnt     int;
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];
begin
    select nextval('load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper_v2 STARTED =======', 0, 'S')
    into l_step_id;

    if in_run_intraday_option_auto_allocation = 'Y' then
        -- 1. Select account_ids
        select array_agg(account_id)
        into l_account_ids
        from genesis2.account ac
        where true
          and ac.is_deleted = 'N'
          and ac.is_intraday_auto_allocate = 'Y'
          and ac.opt_report_to_mpid = 'MLCB'
--          and ac.account_id != all(in_removed_account_ids)
        ;

        l_row_cnt = array_length(l_account_ids, 1);
        --raise notice 'l_account_ids - %', l_account_ids;

        select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper_v2 account_ids calculated =======',
                               l_row_cnt, 'I')
        into l_step_id;

        -- 2. Call autoallocations
        select x
        into l_row_cnt
        from genesis2.auto_allocate_unallocated_trade(in_instrument_type_id := 'O',
                                                      in_allocation_type := 0,
                                                      in_date_id := in_start_date_id,
                                                      in_account_ids := nullif(l_account_ids, '{}'::int4[])) as x;


        select public.load_log(l_load_id, l_step_id,
                               'bofa_allocation_report_wrapper_v2 account_ids auto allocation performed =======',
                               l_row_cnt,
                               'I')
        into l_step_id;
    end if;

    -- 3. Call dash360.bofa_allocation_report
    return query
        select x.ret_row
        from dash360.bofa_allocation_report_v2(in_start_date_id, in_end_date_id,
                                               in_exec_broker, in_is_eod,
                                               in_removed_account_ids) x;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'bofa_allocation_report_wrapper_v2 account_ids COMLETED =======',
                           l_row_cnt, 'I')
    into l_step_id;

end;

$function$
;
