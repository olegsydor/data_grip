/*
table dash_reporting.bofa_allocation_report;
table dash_reporting.bofa_trade_record;
table dash_reporting.bofa_allocation_instruction_status;
function staging.get_all_alloc_instr_id_for_orig(int4, int4, int8);
function staging.all_orig_trade_record_id_today(int8, int4);
function dash360.bofa_allocation_report(int4, int4, text, bool);
function dash360.allocation_trade_record_monitor(int4, int8[]);
function dash360.get_status_to_bofa_allocation_instruction(int4);
function dash360.set_status_to_bofa_allocation_instruction(int4, int4, bpchar);
function dash360.so_allocations_instruction_trades(int4)
function dash360.so_allocations_snapshot(int8[], int4, bpchar)
function dash360.so_allocations_instruction_delete(int4, int4)
function trash.report_alloc_instr_trade_record(int4, text)
*/
-----------------
-- TABLES
-----------------
drop table if exists dash_reporting.bofa_allocation_report;
create table if not exists dash_reporting.bofa_allocation_report
(
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
    to_report                     bpchar                              null, -- R
    db_create_time                timestamp default clock_timestamp() not null,
    instrument_id                 int8                                null,
    opt_penny_commission          numeric(12, 4)                      null,
    opt_nickel_commission         numeric(12, 4)                      null,
    root_symbol                   varchar(10)                         null,
    min_tick_increment            numeric(12, 4)                      null,
    put_call                      bpchar(1)                           null,
    maturity_year                 int2                                null,
    maturity_month                int2                                null,
    maturity_day                  int2                                null,
    strike_price                  numeric(12, 4)                      null
);
create index bofa_allocation_report_alloc_instr_id_idx on dash_reporting.bofa_allocation_report using btree (alloc_instr_id);
create index if not exists bofa_allocation_report_date_id_dataset_to_report_idx on dash_reporting.bofa_allocation_report using btree (date_id, dataset, to_report);
comment on table dash_reporting.bofa_allocation_report is 'The main table of bofa process intraday. The table is also used for further report generation in intraday part';


drop table if exists dash_reporting.bofa_trade_record;
create table if not exists dash_reporting.bofa_trade_record
(
    date_id         int4                                null,
    trade_record_id int8                                null,
    dataset         int4                                null,
    db_create_time  timestamp default clock_timestamp() not null,
    to_report       bpchar(1)                           null
);
create index bofa_trade_record_trade_record_date_id_idx on dash_reporting.bofa_trade_record using btree (date_id, trade_record_id);
comment on table dash_reporting.bofa_trade_record is 'The table of bofa process EOD. The table is also used for further report generation in EOD part';


drop table if exists dash_reporting.bofa_allocation_instruction_status;
create table dash_reporting.bofa_allocation_instruction_status
(
    alloc_instr_id int4                                not null,
    date_id        int4                                not null,
    claimed_by     int4                                null,
    claim_status   bpchar    default 'O'::bpchar       not null,
    db_update_time timestamp default clock_timestamp() not null,
    constraint bofa_allocation_instruction_status_pk primary key (alloc_instr_id),
    constraint bofa_allocation_instruction_status_user_identifier_fk foreign key (claimed_by) references genesis2.user_identifier (user_id)
);
comment on table dash_reporting.bofa_allocation_instruction_status is 'Table contains information on the current claim/resolve status on Allocation Instructions that are unreportable in BOFA report. Only Admins can change the satatus';
alter table
-- Column comments

comment on column dash_reporting.bofa_allocation_instruction_status.alloc_instr_id is 'link to allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.date_id is 'link to date_id of allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.claimed_by is 'user id from genesis2.user_identifier';
comment on column dash_reporting.bofa_allocation_instruction_status.claim_status is 'status. ''O'' - unclaimed (default & initial), ''C'' - claimed, ''R'' - resolved';
comment on column dash_reporting.bofa_allocation_instruction_status.db_update_time is 'create\last update time';

------------
-- FUNCTIONS
------------

drop function if exists staging.get_all_alloc_instr_id_for_orig(int4, int4, int8);
create or replace function staging.get_all_alloc_instr_id_for_orig(in_alloc_instr_id int4, in_date_id int4,
                                                                   in_trade_record_id int8 default null::int8)
    returns int4[]
    language plpgsql
as
$function$
    -- SO 20250113 https://dashfinancial.atlassian.net/browse/DS-9237 see below
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
comment on function staging.get_all_alloc_instr_id_for_orig is 'Auxilary function for calculating related alloc_instr_id (see the comments inside the function)'


drop function if exists staging.all_orig_trade_record_id_today(int8, int4);
create or replace function staging.all_orig_trade_record_id_today(in_trade_record_id int8, in_date_id int4)
    returns int8[]
    language plpgsql
as
$function$
-- SO 20250113 https://dashfinancial.atlassian.net/browse/DS-9237
declare
    ret_trade_record_ids int8[];
begin
    with recursive total (trade_record_id, orig_trade_record_id) as
                       (select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                        where true
--                          and tr.orig_trade_record_id is not null
                          and tr.trade_record_id = in_trade_record_id
                          and tr.date_id = in_date_id

                        union all

                        select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                                 join total on tr.trade_record_id = total.orig_trade_record_id
                        where tr.date_id = in_date_id)
    select array_agg(trade_record_id order by trade_record_id)
    into ret_trade_record_ids
    from total;

    return ret_trade_record_ids;
end;
$function$
;
comment on function staging.all_orig_trade_record_id_today is 'Auxilary function for calculating all orig_trade_record_id';


drop function if exists dash360.bofa_allocation_report(int4, int4, text, bool);
create or replace function dash360.bofa_allocation_report(in_start_date_id int4, in_end_date_id int4,
                                                          in_exec_broker text,-- default '792'::text,
                                                          in_is_eod boolean default false)
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
comment on function dash360.bofa_allocation_report is 'The main function based on dash360.report_rps_ml_options_cmta for aggregating data intraday only (if in_is_eod = false)
and both intraday and EOD (if in_is_eod = true) and saving data into the dash_reporting.bofa_allocation_report for intraday
and dash_reporting.bofa_trade_record for EOD';


drop function if exists dash360.allocation_trade_record_monitor(int4, int8[]);
create or replace function dash360.allocation_trade_record_monitor(in_date_id int4, in_account_ids int8[] default '{}'::int8[])
    returns table
            (
                account_id                      int8,
                trading_firm_id                 character varying,
                security_type                   character,
                trades_cnt                      int8,
                trades_qty                      int8,
                trades_principal                numeric,
                trades_cnt_expiring             int8,
                trades_qty_expiring             int8,
                unallocated_trades_cnt          int8,
                unallocated_trades_qty          int8,
                unallocated_trades_principal    numeric,
                unallocated_trades_qty_expiring int8,
                allocated_trades_cnt            int8,
                allocated_trades_qty            int8,
                allocated_trades_principal      numeric,
                allocated_trades_qty_expiring   int8,
                unable_trades_cnt               int8,
                unable_trades_qty               int8,
                unable_trades_principal         numeric,
                unresolved                      int4,
                resolved                        int4
            )
    language plpgsql
as
$function$
    -- SO 20250113 https://dashfinancial.atlassian.net/browse/DS-9313
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
        and ac.is_deleted <> 'Y' and ac.opt_report_to_mpid = 'MLCB' and ac.trading_firm_id <> 'cantor'
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
                                   and bar.to_report <> 'R'
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
               'O'::char, -- hardcoded
               --
               count(trm.trade_record_id)                                                              as trades_cnt,
               sum(trm.last_qty)                                                                       as trades_qty,
               sum(trm.last_qty * trm.last_px)                                                         as trades_principal,
               sum(case when trm.expiring_today then 1 else 0 end)                                     as trades_cnt_expiring,
               sum(case when trm.expiring_today then trm.last_qty else 0 end)                          as trades_qty_expiring,
               -- unallocated
               sum(case when trm.is_alloc = 'unallocated' then 1 else 0 end)                           as unallocated_trades_cnt,
               sum(case when trm.is_alloc = 'unallocated' then last_qty else 0 end)                    as unallocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'unallocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                                     as unallocated_trades_principal,
               sum(case
                       when trm.is_alloc = 'unallocated' and expiring_today then last_qty
                       else 0 end)                                                                     as unallocated_trades_qty_expiring,
               -- allocated
               sum(case when trm.is_alloc = 'allocated' then 1 else 0 end)                             as allocated_trades_cnt,
               sum(case when trm.is_alloc = 'allocated' then last_qty else 0 end)                      as allocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'allocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                                     as allocated_trades_principal,
               sum(case
                       when trm.is_alloc = 'allocated' and expiring_today then last_qty
                       else 0 end)                                                                     as allocated_trades_qty_expiring,
               -- unable
               sum(case when trm.is_unable then 1 else 0 end)                                          as unable_trades_cnt,
               sum(case when trm.is_unable then last_qty else 0 end)                                   as unable_trades_qty,
               sum(case
                       when trm.is_unable then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                                     as unable_trades_principal,

               sum(case when trm.is_unable
                                 and trm.claim_status is distinct from 'R' then 1 else 0 end)::int4    as unresolved,
               sum(case when coalesce(trm.claim_status, 'NO') = 'R' then 1 else 0 end)::int4           as resolved

-- select *
        from tmp_trade_record_monitor trm
                 left join genesis2.option_contract oc on oc.instrument_id = trm.instrument_id
                 left join genesis2.option_series os on os.option_series_id = oc.option_series_id
        group by trm.account_id, trm.trading_firm_id;
end;
$function$
;
comment on function dash360.allocation_trade_record_monitor is 'The monitor. It is expected to be run every 1 minute';


drop function if exists dash360.get_status_to_bofa_allocation_instruction(int4);
create or replace function dash360.get_status_to_bofa_allocation_instruction(in_alloc_instr_id int4)
    returns table
            (
                alloc_instr_id int4,
                claimed_by     int4,
                user_name      text,
                claim_status   character,
                db_update_time timestamp without time zone
            )
    language plpgsql
as
$function$
    -- 20241230 so https://dashfinancial.atlassian.net/browse/d360-15023
begin
    return query
        select bas.alloc_instr_id, bas.claimed_by, ui.user_name::text, bas.claim_status, bas.db_update_time
        from dash_reporting.bofa_allocation_instruction_status bas
                 left join genesis2.user_identifier ui on ui.user_id = bas.claimed_by
        where bas.alloc_instr_id = in_alloc_instr_id;
end;
$function$
;
comment on function dash360.get_status_to_bofa_allocation_instruction is 'Get the claim\resolve status of alloc_instr_id';


drop function if exists dash360.set_status_to_bofa_allocation_instruction(int4, int4, bpchar);
create or replace function dash360.set_status_to_bofa_allocation_instruction(in_alloc_instr_id int4, in_claimed_by int4,
                                                                             in_target_claim_status character)
    returns table
            (
                alloc_instr_id int4,
                claimed_by     int4,
                user_name      text,
                claim_status   character,
                db_update_time timestamp without time zone
            )
    language plpgsql
as
$function$
    -- 20241230 so https://dashfinancial.atlassian.net/browse/d360-15023

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
$function$
;
comment on function dash360.set_status_to_bofa_allocation_instruction(int4, int4, bpchar) is 'The function sets claim status for an Un-reportable Allocation Instruction';


drop function if exists dash360.so_allocations_instruction_trades(int4);
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
                opt_customer_firm      character,
                reported_status        character,
                reported_time          timestamp without time zone,
                claimed_by             integer,
                claim_status           character,
                is_prev_reported       boolean
            )
    language plpgsql
    cost 1
as
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
    -- OS 20250116 https://dashfinancial.atlassian.net/browse/DS-9337 changes in report_time using is_billed in trade_record
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
               tr.last_px                                                                   as avg_px,
               tr.last_qty                                                                  as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                      as principal_amount,
               CCRU.rate                                                                    as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                  as street_exec_time,
               ----------------
               i.last_trade_date                                                            as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                              as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
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
                        limit 1)) end                                                       as reported_time,
               null::int4                                                                   as claimed_by,
               null::character                                                              as claim_status,
               case when tr.is_billed = 'R' then true else false end                        as is_prev_reported
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
--                  left join lateral (select bas.claimed_by, bas.claim_status
--                                     from dash_reporting.bofa_allocation_instruction_status bas
--                                     where bas.alloc_instr_id = ai2tr.alloc_instr_id
--                                       and bas.date_id = ai2tr.date_id
--                                     limit 1) bas on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , tl.book_record_type_id , tl.billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND tl.book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;


drop function if exists dash360.so_allocations_snapshot(int8[], int4, bpchar);
create or replace function dash360.so_allocations_snapshot(in_account_ids int8[] default '{}'::int8[],
                                                           in_date_id int4 default public.get_dateid(current_date),
                                                           in_reported_status character default null::character(1))
    returns table
            (
                date_id                int4,
                trade_record_id        int8,
                account_id             int4,
                instrument_id          int8,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               int4,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                alloc_instr_id         int4,
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
                claimed_by             int4,
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
               case when coalesce(nullif(tr.is_billed, 'N'), rep.to_report) = 'R' then
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
                        limit 1), rep.db_create_time) end                  as reported_time,
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
               null::boolean
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

comment on function dash360.so_allocations_snapshot is 'The report allocations_snapshot temp nsme with the prefix os_ until it is tested';


create or replace function dash360.so_allocations_instruction_delete(in_alloc_instr_id integer, in_user_id integer)
    returns table
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               bigint,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                blaze_account_alias    character varying,
                orig_trade_record_id   bigint,
                street_exec_time       timestamp without time zone,
                opt_customer_firm      character,
                reported_status        character,
                reported_time          timestamp without time zone
            )
    language plpgsql
as
$function$

-- SY 20210531 DS-3420 return type has been changed from id into query
-- The logic to modify trade_record has been implemented
-- SY 20210617 https://dashfinancial.atlassian.net/browse/DS-3642 CMTA field has been added to revertion process
-- VP 20231130 https://dashfinancial.atlassian.net/browse/DS-7591 Added field street_exec_time
-- SO 20250116 https://dashfinancial.atlassian.net/browse/DS-9407 Add new fields is_prev_reported, opt_customer_firm
declare
    l_user_id              int;
    l_system_id            varchar;
    l_revert_vector        jsonb;
    l_new_trade_record_ids bigint[];
    l_date_id              int;
    l_load_batch_id        bigint;
    l_step_id              int;
begin
    l_step_id := 0;

    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete STARTED =====', 0,
                             'S'::char)
    into l_step_id;

    with ct as ( update genesis2.allocation_instruction ai
        set
            is_deleted = 'Y',
            delete_time = 'now'::timestamp,
            deleted_by_user_id = in_user_id
        where alloc_instr_id = in_alloc_instr_id
        returning ai.created_by_user_id, ai.created_by_subsystem_id, ai.date_id)
    select ct.created_by_user_id, ct.created_by_subsystem_id, ct.date_id
    into l_user_id, l_system_id, l_date_id
    from ct;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'genesis2.allocation_instruction updated', 0, 'S'::char)
    into l_step_id;


--  raise info '%: l_user_id=%, l_system_id=%, date_id = %', clock_timestamp(),l_user_id, l_system_id, l_date_id ;

 if l_user_id is null and l_system_id = 'RPS'
  then l_new_trade_record_ids := array[]::bigint[];
  else
   /* UNALLOCATE MANUAL ALLOCATION with reverting trade_record changes*/
		  select ('{'||string_agg('"'||tr.trade_record_id||'":[{"clearing_account_number":"'||coalesce(orig_tr.clearing_account_number, 'NULL')||'"
															  , "account_nickname":"'       ||coalesce(orig_tr.account_nickname, 'NULL')||'"
															  , "street_account_name":"'    ||coalesce(orig_tr.street_account_name,'NULL')||'"
															  , "cmta":"'                   ||coalesce(orig_tr.cmta,'NULL')||'"
		      												  , "allocation_avg_price":"NULL"
															  , "trade_record_reason":"U"
															  , "user_id":'                 ||in_user_id||'}]', ',')||'}')::jsonb
          into l_revert_vector
          from alloc_instr2trade_record aitr
                   inner join trade_record tr on aitr.trade_record_id = tr.trade_record_id and tr.is_busted = 'N' and
                                                 tr.date_id = aitr.date_id and trade_record_reason = 'L'
                   inner join trade_record orig_tr
                              on tr.orig_trade_record_id = orig_tr.trade_record_id and tr.date_id = orig_tr.date_id
          where aitr.alloc_instr_id = in_alloc_instr_id
            and aitr.date_id = l_date_id;

          select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_revert_vector defined ', 0, 'S'::char)
          into l_step_id;

          raise info 'Revert vector is %', l_revert_vector;

          if l_revert_vector is not null
          then
              l_new_trade_record_ids := dash360.ptm_process_trades(l_date_id, in_user_id, l_revert_vector);
--        then l_new_trade_record_ids:=trash.so_ptm_process_trades(l_date_id, in_user_id, l_revert_vector);

              select genesis2.load_log(l_load_batch_id::int, l_step_id, 'cardinality(l_new_trade_record_ids): ',
                                       cardinality(l_new_trade_record_ids), 'S'::char)
              into l_step_id;

              perform dash360.trade_record_update_ccru(in_user_id =>in_user_id, in_date_id => l_date_id,
                                                       in_trade_record_id =>l.trade_record_id, in_rate => l.rate,
                                                       in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
              from (select tr.trade_record_id::bigint,
                           tlbr.rate,
                           tr.last_qty * tlbr.rate                                                                                 as amount,
                           row_number()
                           over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
                    from genesis2.trade_record tr
                             inner join genesis2.trade_level_book_record tlbr
                                        on tlbr.date_id = tr.date_id and
                                           tlbr.trade_record_id = tr.orig_trade_record_id and
                                           book_record_type_id = 'CCRU'
                             inner join genesis2.book_record_creator brc
                                        on tlbr.book_record_creator_id = brc.book_record_creator_id
                    where tr.date_id = l_date_id
                      and tr.trade_record_id = any (array [l_new_trade_record_ids])) l
              where rn = 1;

          else
              select array_agg(trade_record_id::bigint)
              into l_new_trade_record_ids
              from alloc_instr2trade_record a
              where a.date_id = l_date_id
                and a.alloc_instr_id = in_alloc_instr_id;
          end if;
          select genesis2.load_log(l_load_batch_id::int, l_step_id, 'After IF ', 0, 'S'::char)
          into l_step_id;

 end if;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete returning query', 0,
                             'S'::char)
    into l_step_id;

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id::bigint,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty::bigint                                         as exec_qty,
               i.display_instrument_id2,
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
               tr.orig_trade_record_id::bigint,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               tr.opt_customer_firm,
               case when tr.is_billed = 'R' then 'R'::char end             as reported_status,
               case
                   when true
                       and tr.is_billed = 'R'
                       then (select bar.db_create_time
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
                        limit 1) end                                       as reported_time
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
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
                 left join lateral (select to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and tr.trade_record_id = any (l_new_trade_record_ids);

end;

$function$
;

drop function if exists trash.report_alloc_instr_trade_record;
create or replace function trash.report_alloc_instr_trade_record(in_date_id integer, in_exec_broker text)
    returns table
        -- select
        -- exec_broker as "Exec Broker", type as "Type", account_name as "Account Name", alloc_instr_id # only as "Alloc Instr ID", trade_record_id as "Trade Record ID",
        -- sybmol as "Symbol", side  as "Side", open_close as "O/C", exec_qty as "Exec Qty", avg_px as "Avg Px", reported_status as "Reported Status",
        -- reported_time as "Reported Time", is_deleted as "Alloc is deleted", is_busted as "Trade is busted", deleted_by_user_name as "Deleted by User", deleted_time as "Deleted time"
        --
            (
                "Exec Broker"      varchar(32),
                "Type"             text,
                "Account Name"     varchar(30),
                "Alloc Instr ID"   int4,
                "Trade Record ID"  int8,
                "Symbol"           varchar,
                "Side"             text,
                "O/C"              text,
                "Exec Qty"         int4,
                "Avg Px"           numeric,
                "Reported Status"  text,
                "Reported Time"    timestamp,
                "Trade is busted"  bpchar,
                "Alloc is deleted" bpchar,
                "Deleted time"     timestamp,
                "Deleted by User"  varchar(30)
            )
    language plpgsql
as
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
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
        select distinct on (ai.alloc_instr_id) tr.exec_broker,
                                               'allocation',
                                               ac.account_name,
                                               bar.alloc_instr_id,
                                               null::int8,
                                               bar.root_symbol,
                                               case bar.side when '1' then 'Buy' when '2' then 'Sell' end,
                                               case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end,
                                               ai.total_qty,
                                               bar.avg_px,
                                               'Reported',
                                               bar.db_create_time,
                                               '',
                                               ai.is_deleted,
                                               ai.delete_time,
                                               ui.user_name

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join genesis2.alloc_instr2trade_record aitr
                      on (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.trade_record tr
                               where tr.trade_record_id = aitr.trade_record_id
                                 and tr.date_id = in_date_id
                                 and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
        union all
        select tr.exec_broker,
               'trade',
               ac.account_name,
               null,
               btr.trade_record_id,
               di.symbol,
               case tr.side when '1' then 'Buy' when '2' then 'Sell' end,
               case tr.open_close when 'O' then 'Open' when 'C' then 'Close' end,
               tr.last_qty,
               tr.last_px,
               'Reported',
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
                         limit 1), tr.db_create_time),
               tr.is_busted,
               null,
               null,
               null

        from dash_reporting.bofa_trade_record btr
                 join genesis2.trade_record tr using (trade_record_id, date_id)
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = tr.instrument_id
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
select *
from trash.report_alloc_instr_trade_record(in_date_id := 20250114, in_exec_broker := '792')


