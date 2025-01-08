
-- drop table if exists dash_reporting.bofa_allocation_instruction_status;
create table if not exists dash_reporting.bofa_allocation_instruction_status
(
    alloc_instr_id int4                                not null, -- link to allocation instruction
    date_id        int4                                not null, -- link to date_id of allocation instruction
    claimed_by     int4                                null,     -- user id from genesis2.user_identifier
    claim_status   bpchar    default 'O'::bpchar       not null, -- status. 'O' - unclaimed (default & initial), 'C' - claimed, 'R' - resolved
    db_update_time timestamp default clock_timestamp() not null, -- create\last update time
    constraint bofa_allocation_instruction_status_pk primary key (alloc_instr_id),
    constraint bofa_allocation_instruction_status_user_identifier_fk foreign key (claimed_by) references genesis2.user_identifier (user_id)
);
comment on table dash_reporting.bofa_allocation_instruction_status is 'Table contains information on the current claim/resolve status on Allocation Instructions that are unreportable in BOFA report. Only Admins can change the satatus';

-- Column comments

comment on column dash_reporting.bofa_allocation_instruction_status.alloc_instr_id is 'link to allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.date_id is 'link to date_id of allocation instruction';
comment on column dash_reporting.bofa_allocation_instruction_status.claimed_by is 'user id from genesis2.user_identifier';
comment on column dash_reporting.bofa_allocation_instruction_status.claim_status is 'status. ''O'' - unclaimed (default & initial), ''C'' - claimed, ''R'' - resolved';
comment on column dash_reporting.bofa_allocation_instruction_status.db_update_time is 'create\last update time';


drop table if exists dash_reporting.bofa_allocation_report;
create table dash_reporting.bofa_allocation_report
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
    to_report                     bpchar                              null,
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
create index bofa_allocation_report_date_id_idx on dash_reporting.bofa_allocation_report using btree (date_id);

-- dash_reporting.bofa_trade_record definition
-- Drop table

drop table if exists dash_reporting.bofa_trade_record;
create table if not exists dash_reporting.bofa_trade_record
(
    date_id         int4                                null,
    trade_record_id int8                                null,
    dataset         int4                                null,
    db_create_time  timestamp default clock_timestamp() not null
);
create index bofa_trade_record_trade_record_date_id_idx on dash_reporting.bofa_trade_record using btree (date_id, trade_record_id);



CREATE OR REPLACE FUNCTION staging.get_all_alloc_instr_id_for_orig(in_alloc_instr_id integer, in_date_id integer,
                                                                   in_trade_record_id bigint DEFAULT NULL::bigint)
    RETURNS integer[]
    LANGUAGE plpgsql
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
comment on function staging.get_all_alloc_instr_id_for_orig is 'Returns all alloc_instr_id that contain any of orig_trade_record_id from passed alloc_instr_id or trade_record_id';


create or replace function staging.all_orig_trade_record_id_today(in_trade_record_id bigint, in_date_id integer)
    returns bigint[]
    language plpgsql
as
$function$
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
comment on function staging.all_orig_trade_record_id_today is 'Returns all orig_trade_records of passed trade_record for today';


CREATE OR REPLACE FUNCTION dash360.bofa_allocation_report(in_start_date_id integer, in_end_date_id integer, in_exec_broker text DEFAULT '792'::text, in_is_eod boolean DEFAULT false)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
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
            select
                   alin.alloc_instr_id,
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
                                       END
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
          and ba.to_report in ('R')
        ;

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
        join genesis2.allocation_instruction ai on ai.alloc_instr_id = aitr.alloc_instr_id and ai.date_id = aitr.date_id
        where aitr.date_id between in_start_date_id and in_end_date_id
        and ai.is_deleted = 'N';

        -- find all valid trade_records: all except the records from the prev

        drop table if exists t_reported_trade_record;
        create temp table t_reported_trade_record as
        SELECT ftr.date_id           AS date_id,
               ftr.trade_record_id,
               l_load_id            as dataset,
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
                   else 'R' end as to_report
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

        insert into  dash_reporting.bofa_trade_record (date_id, trade_record_id, dataset, to_report)
        select date_id, trade_record_id, dataset, to_report from t_reported_trade_record;

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
        select public.load_log(l_load_id, l_step_id, l_msg_text || ' EOD reporting table for trade_record created', l_row_cnt_eod,
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
                                           END , --
                                       ''
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


-- DROP FUNCTION dash360.allocation_trade_record_monitor(int4, _int8);

create or replace function dash360.allocation_trade_record_monitor(in_date_id integer, in_account_ids bigint[] default '{}'::bigint[])
    returns table
            (
                account_id                      bigint,
                trading_firm_id                 character varying,
                security_type                   character,
                trades_cnt                      bigint,
                trades_qty                      bigint,
                trades_principal                numeric,
                trades_cnt_expiring             bigint,
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
                unresolved                      integer,
                resolved                        integer
            )
    language plpgsql
as
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
             join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y' and
                                         ac.opt_report_to_mpid = 'MLCB' and
                                         ac.trading_firm_id <> 'cantor'
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
               'O'::char, -- hardcoded
               --
               count(trm.trade_record_id)                                                       as trades_cnt,
               sum(trm.last_qty)                                                                as trades_qty,
               sum(trm.last_qty * trm.last_px * os.contract_multiplier)                         as trades_principal,
               sum(case when trm.expiring_today then 1 else 0 end)                              as trades_cnt_expiring,
               sum(case when trm.expiring_today then trm.last_qty else 0 end)                   as trades_qty_expiring,
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



select * from dash360.bofa_allocation_report(20250103, 20250104, null, true);

select * from dash360.allocation_trade_record_monitor(20250106);

select * from tmp_trade_record_monitor

select * from staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id)