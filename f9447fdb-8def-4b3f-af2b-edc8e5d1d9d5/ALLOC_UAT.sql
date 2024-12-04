-- list of functions
--create temp table t_f as
select distinct routines.routine_schema || '.' || routines.routine_name--, parameters.data_type, parameters.ordinal_position, *
from information_schema.routines
         left join information_schema.parameters on routines.specific_name = parameters.specific_name
where true
--and routine_name ilike '%scrape%'
--and routine_name ilike '%eod_pershing_ps%'
--and routine_name ilike '%eod%'
--and parameter_name not ilike '%gtc%'
--and parameter_mode = 'IN'
and routine_name !~~* all(ARRAY['%_bkp%', '%_old%', '%_tst%', '%_test%'])
--and routines.routine_schema not in ('trash', 'pg_catalog', 'information_schema')
and routines.routine_schema in ('dash360', 'dash_reporting')
--and (routine_definition ilike $$%trans_type%<>%'F'%$$
--or routine_definition ilike $$%trans_type%in%('D',%'G')%$$)
--and routine_definition not like $$%%$$
and routine_definition ilike '%alloc_instr_id%';



with tr as
         (select tr.trade_record_id,
                 tr.account_id,
                 tr.instrument_id,
                 tr.last_qty,
                 tr.allocation_avg_price,
                 tr.open_close,
                 tr.side,
                 tr.street_account_name,
                 tr.account_nickname,
                 tr.cmta,
                 tr.clearing_account_number,
                 i.instrument_type_id
          from genesis2.trade_record tr
                   inner join genesis2.instrument i on tr.instrument_id = i.instrument_id
          where date_id = :in_date_id
            and trade_record_id = any ('{2346593042,2346593043,2346593044}')
            and is_busted = 'N')
     , aie as (
--          INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id,
--                                                         occ_actionable_id, account_nickname, alloc_qty)
         select :l_alloc_instr
              , :in_date_id
--               , dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number, tr.account_nickname,
--                                                   tr.street_account_name, tr.instrument_type_id,
--                                                   :in_user_id) as clearing_account_id,tr.street_account_name, tr.account_nickname
              , tr.street_account_name
              , tr.account_nickname
              , sum(last_qty)
         from tr
         group by /*3,*/ tr.street_account_name, tr.account_nickname
),
     a2tr as (
--      INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id)
         select trade_record_id, l_alloc_instr, in_date_id, l_load_batch_id
         from tr
         /* inner join aie on aie.clearing_account_id = tr.clearing_account_id and
                            coalesce(tr.occ_actionable_id, '---') = coalesce(aie.occ_actionable_id, '---') and
                            coalesce(tr.account_nickname, '---') = coalesce(aie.account_nickname, '---') */ )
INSERT
INTO allocation_instruction
(alloc_instr_id, date_id, create_time, account_id, instrument_id, total_qty, avg_px, open_close, side,
 created_by_user_id, dataset_id)
select l_alloc_instr,
       in_date_id,
       clock_timestamp(),
       account_id,
       instrument_id,
       sum(last_qty),
       allocation_avg_price,
       open_close,
       side,
       in_user_id,
       l_load_batch_id
from tr
group by account_id, instrument_id, allocation_avg_price, open_close, side;
-----------------------------------------------------------------------------------------------------------------------

SELECT alin.alloc_instr_id,
    ftr.trade_record_id,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select tr.trade_record_id,
                                    tr.cmta,
                                    tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
                             and aitr.
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
         join genesis2.option_series os on os.option_series_id = oc.option_series_id
         join genesis2.instrument i on i.instrument_id = alin.instrument_id
where alin.date_id between :in_start_date_id and :in_end_date_id;



select tr.trade_record_id,
       tr.cmta,
       tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
from genesis2.alloc_instr2trade_record aitr
         inner join genesis2.trade_record tr
                    on aitr.trade_record_id = tr.trade_record_id and
                       aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
where aitr.alloc_instr_id = -51641
  and aitr.date_id = :in_end_date_id

select trade_record_id , orig_trade_record_id , is_busted ,
trade_record_reason , secondary_order_id , secondary_exch_exec_id , last_qty , last_px , * from genesis2.trade_record tr
where tr.date_id = 20241129
and tr.trade_record_id in (
2346592823
,2346592824
,2346592826
)
or tr.orig_trade_record_id in (
2346592823
,2346592824
,2346592826
);

select * from genesis2.option_contract
where instrument_id = 180072313;


INSERT INTO genesis2.option_contract
(instrument_id, option_series_id, maturity_year, maturity_month, maturity_day, put_call, strike_price, opra_symbol, create_time, is_deleted, delete_time)
VALUES(180072313, 70, 2025, 3, 21, '1', 160.0000, 'AAPL  250321P00160000', '2024-01-31 21:18:35.898', 'N', NULL);


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by trade_record_id asc;


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by tr.trade_record_id asc;


SELECT alin.alloc_instr_id,
       ftr.trade_record_ids,
       ftr.origs,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select
                                 aitr.alloc_instr_id, aitr.date_id,
                                 array_agg(tr.trade_record_id) as trade_record_ids,
                                 array_agg(tr.orig_trade_record_id) as origs,
                                    min(tr.cmta) as cmta,
                                    min(tr.opt_customer_firm) as opt_customer_firm--, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id
                                                        and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where true
--                                  and aitr.alloc_instr_id = alin.alloc_instr_id
--                                and aitr.date_id = alin.date_id
                              and aitr.trade_record_id in (2346592826, 2346592949,2346592950,2346593040,2346593041,2346593042,2346593043,2346593044)
                             group by aitr.alloc_instr_id, aitr.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id;



select aitr.trade_record_id, *
from genesis2.allocation_instruction_entry ae
         join genesis2.allocation_instruction alin on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
         join genesis2.alloc_instr2trade_record aitr on aitr.alloc_instr_id = alin.alloc_instr_id
         join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
         join genesis2.clearing_account ca
              on (ca.clearing_account_id = ae.clearing_account_id
                  and ca.clearing_account_type = '1' and ca.market_type = 'O')
         join genesis2.account acc
              on (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and acc.opt_report_to_mpid = 'MLCB' and
                  acc.trading_firm_id <> 'cantor')
         join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
         join genesis2.option_series os on os.option_series_id = oc.option_series_id
         join genesis2.instrument i on i.instrument_id = alin.instrument_id
where alin.date_id between :in_start_date_id and :in_end_date_id
order by aitr.trade_record_id;



create
    or replace
    function trash.report_rps_ml_options_cmta(in_start_date_id integer, in_end_date_id integer,
                                                in_exec_broker text default '792'::text)
    returns table
            (
                first_orig_trade_record_id    int8,
                side                          bpchar(1),
                alloc_qty                     int4,
                avg_px                        numeric(14, 6),
                opt_is_fix_clfirm_processed   bpchar(1),
                ftr_cmta                      varchar(3),
                ca_cmta                       varchar(3),
                date_id                       int4,
                min_tick_increment            numeric(12, 4),
                opt_penny_commission          numeric(12, 4),
                opt_nickel_commission         numeric(12, 4),
                root_symbol                   varchar(10),
                put_call                      bpchar(1),
                maturity_year                 int2,
                maturity_month                int2,
                maturity_day                  int2,
                strike_price                  numeric(12, 4),
                open_close                    bpchar(1),
                opt_is_fix_custfirm_processed bpchar(1),
                opt_customer_firm             bpchar(1),
                opt_customer_or_firm          bpchar(1),
                occ_actionable_id             varchar
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id int;
    l_step_id int;
    row_cnt   int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_rps_ml_options_cmta STARTED ====', 0, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id,
                           'l_date_id size is =' || in_start_date_id::text || '-' || in_end_date_id::text, 1, 'O')
    into l_step_id;

-- Start
    return query
        SELECT ftr.first_orig_trade_record_id,
               qty.last_qty         as first_qty,
               alin.alloc_instr_id,
--                ae.al
               ftr.last_qty,
               ae.alloc_qty,
               alin.side,
               alin.avg_px,
               acc.opt_is_fix_clfirm_processed,
               ftr.cmta             AS ftr_cmta,
               ca.cmta              AS ca_cmta,
               alin.date_id,
               os.min_tick_increment,
               acc.opt_penny_commission,
               acc.opt_nickel_commission,
               os.root_symbol,
               oc.put_call,
               oc.maturity_year,
               oc.maturity_month,
               oc.maturity_day,
               oc.strike_price,
               alin.open_close,
               acc.opt_is_fix_custfirm_processed,
               ftr.opt_customer_firm,
               acc.opt_customer_or_firm,
               ae.occ_actionable_id as occ_actionable_id --, ftr.street_account_name
        FROM genesis2.allocation_instruction_entry ae
                 JOIN genesis2.allocation_instruction alin
                      ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                 inner join lateral (select tr.cmta,
                                            tr.opt_customer_firm,-- coalesce(tr.street_account_name,'') street_account_name
                                            tr.last_qty,
                                            staging.last_orig_trade_record_id_today(tr.trade_record_id,
                                                                                    tr.date_id) as first_orig_trade_record_id,
                                         tr.trade_record_id

                                     from genesis2.alloc_instr2trade_record aitr
                                              inner join genesis2.trade_record tr
                                                         on aitr.trade_record_id = tr.trade_record_id
                                                             and aitr.date_id = tr.date_id
                                                             and tr.is_busted = 'N'
                                                             and case
                                                                     when :in_exec_broker is null then true
                                                                     else tr.exec_broker = :in_exec_broker end
                                     and tr.exec_broker is not null
                                     where aitr.alloc_instr_id = alin.alloc_instr_id
                                       and aitr.date_id = alin.date_id
                                     limit 1) ftr on true
                 join lateral (select last_qty
                               from genesis2.trade_record tr
                               where tr.trade_record_id = ftr.first_orig_trade_record_id
                               limit 1) qty on true
                 JOIN genesis2.clearing_account ca
                      ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                          AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
                 JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                               acc.opt_report_to_mpid = 'MLCB' AND acc.trading_firm_id <> 'cantor')
                 JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                 JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                 JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
        WHERE alin.date_id between :in_start_date_id and :in_end_date_id;

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
    into l_step_id;

-- Finish

END;
$function$
;
select * from trash.report_rps_ml_options_cmta(20241204,20241204, null)
select * from dash360.report_rps_ml_options_cmta(20241204, 20241204, null)
CREATE or replace FUNCTION dash360.report_rps_ml_options_cmta(in_start_date_id integer, in_end_date_id integer, in_exec_broker text DEFAULT '792'::text)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
declare
    ref       refcursor;
--   l_date_id int;
    l_load_id int;
    l_step_id int;
    row_cnt   int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_rps_ml_options_cmta STARTED ====', 0, 'O')
    into l_step_id;

-- 	l_date_id:= to_char(in_date, 'YYYYMMDD')::int;
    select public.load_log(l_load_id, l_step_id,
                           'l_date_id size is =' || in_start_date_id::text || '-' || in_end_date_id::text, 1, 'O')
    into l_step_id;

-- Start
return query
        WITH ftr_clear AS materialized (SELECT l.date_id,
                                               l.cmta,
                                               l.open_close,
                                               l.order_id,
                                               l.instrument_id,
                                               l.side,
                                               sum(last_qty)                                        AS day_cum_qty,
                                               CASE sum(last_qty)
                                                   WHEN 0 THEN NULL
                                                   ELSE sum(last_qty * last_px) / sum(last_qty) END AS avg_px,
                                               max(opt_customer_firm)                               AS customer_or_firm_id,
                                               l.opt_is_fix_clfirm_processed,
                                               l.opt_customer_or_firm,
                                               l.opt_nickel_commission,
                                               l.opt_penny_commission,
                                               l.opt_is_fix_custfirm_processed
                                        /*,
                                               max(street_account_name) as street_account_name*/
                                        FROM (SELECT ftr.date_id                                              AS date_id,
                                                     CASE
                                                         WHEN (ci.clearing_instr_id IS NOT NULL OR acc.opt_is_fix_clfirm_processed = 'Y')
                                                             THEN ftr.cmta
                                                         ELSE NULL END                                        AS cmta,
                                                     ftr.open_close,
                                                     ftr.order_id                                             AS order_id,
                                                     ftr.instrument_id,
                                                     ftr.account_id,
                                                     ftr.side,
                                                     CASE
                                                         WHEN ci.clearing_instr_id IS NULL THEN ftr.last_qty
                                                         ELSE cie.last_qty END                                AS last_qty,
                                                     CASE
                                                         WHEN ci.clearing_instr_id IS NULL THEN ftr.last_px
                                                         ELSE cie.last_px END                                 AS last_px,
                                                     CASE
                                                         WHEN ci.clearing_instr_id IS NULL THEN ftr.opt_customer_firm
                                                         ELSE cie.opt_customer_firm END                          opt_customer_firm,
                                                     CASE WHEN ci.clearing_instr_id IS NULL THEN 0 ELSE 1 END AS is_cleared,
                                                     acc.opt_is_fix_clfirm_processed,
                                                     acc.opt_customer_or_firm,
                                                     acc.opt_nickel_commission,
                                                     acc.opt_penny_commission,
                                                     acc.opt_is_fix_custfirm_processed
                                              /*,
                                                         coalesce(ftr.street_account_name, '') as street_account_name*/
                                              FROM genesis2.trade_record ftr
                                                       JOIN genesis2.account acc ON (acc.account_id = ftr.account_id AND
                                                                                     acc.is_deleted <> 'Y' AND
                                                                                     acc.opt_report_to_mpid = 'MLCB' AND
                                                                                     acc.trading_firm_id <> 'cantor')
                                                       LEFT JOIN genesis2.clearing_instruction_entry cie
                                                                 ON (cie.date_id = ftr.date_id AND
                                                                     COALESCE(cie.new_trade_record_id, cie.trade_record_id) =
                                                                     ftr.trade_record_id AND cie.cmta IS NOT NULL)
                                                       LEFT JOIN genesis2.clearing_instruction ci
                                                                 ON (ci.clearing_instr_id =
                                                                     cie.clearing_instr_entry_id AND ci.status = 'D' AND
                                                                     ci.is_deleted <> 'Y')
                                              WHERE ftr.date_id between in_start_date_id and in_end_date_id
                                                AND is_busted = 'N'
                                                AND ftr.order_id > 0
                                                and ftr.exec_broker = in_exec_broker
                                                AND NOT EXISTS (SELECT NULL
                                                                FROM genesis2.alloc_instr2trade_record t
                                                                WHERE date_id between in_start_date_id and in_end_date_id
                                                                  AND t.trade_record_id = ftr.trade_record_id
                                                  --and t.is_active
                                              )) l
                                        GROUP BY l.date_id, l.cmta, l.open_close, l.order_id, l.instrument_id, l.side,
                                                 l.opt_is_fix_clfirm_processed, l.opt_customer_or_firm,
                                                 l.opt_nickel_commission, l.opt_penny_commission,
                                                 l.opt_is_fix_custfirm_processed)
        SELECT 'DAS' || ',' ||--Branch
               CASE
                   WHEN gen.side = '1' THEN 'B'
                   WHEN gen.side in ('2', '5', '6') THEN 'S'
                   ELSE 'S'
                   END || ',' ||--Action
               '' || ',' ||--Symbol
               '?' || ',' ||--Destination
               gen.alloc_qty || ',' ||--Quantity
               to_char(gen.avg_px, 'FM99990D009999') || ',' ||
               coalesce(CASE
                            WHEN gen.opt_is_fix_clfirm_processed = 'Y' THEN lpad(ftr_cmta, 5, '0')
                            WHEN gen.opt_is_fix_clfirm_processed = 'N' THEN lpad(ca_cmta, 5, '0')
                            ELSE ''
                            END, '') || ',' ||
               SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 5, 2) || '/' ||
               SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 7, 2) || '/' ||
               SUBSTRING(TO_CHAR(gen.date_id, 'FM99999999'), 3, 2) || '/' ||
               '00/00' || ',' ||
               'DASH' || ',' ||--Execution Venue
--		street_account_name ||','||--Client Identifier
               occ_actionable_id || ',' ||--Client Identifier
               to_char(row_number() OVER (), 'FM0000') || ',' ||
               to_char(((CASE coalesce(gen.min_tick_increment, 0.01)
                             WHEN 0.01 THEN gen.opt_penny_commission
                             WHEN 0.05 THEN gen.opt_nickel_commission END) * gen.alloc_qty), 'FM99990D0') || ',' ||--13
               '' || ',' ||--Liquidity
               'S' || ',' ||--Single/Basket
               '' || ',' ||--Pass Through Fees
               coalesce(gen.root_symbol, '') || ',' ||--Symbol
               CASE
                   WHEN gen.put_call = '0' THEN 'P'
                   WHEN gen.put_call = '1' THEN 'C'
                   END || ',' ||--Put/Call
               gen.maturity_year || ',' ||
               to_char(gen.maturity_month, 'FM00') || ',' ||
               to_char(gen.MATURITY_DAY, 'FM00') || ',' ||
               to_char(gen.strike_price, 'FM999990D0099') || ',' ||--Strike
               gen.open_close || ',' ||
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
                   END || ',' ||
               '' || ','
                   AS rec
        FROM (SELECT alin.side,
                     ae.alloc_qty,
                     alin.avg_px,
                     acc.opt_is_fix_clfirm_processed,
                     ftr.cmta                           AS ftr_cmta,
                     ca.cmta                            AS ca_cmta,
                     alin.date_id,
                     os.min_tick_increment,
                     acc.opt_penny_commission,
                     acc.opt_nickel_commission,
                     os.root_symbol,
                     oc.put_call,
                     oc.maturity_year,
                     oc.maturity_month,
                     oc.maturity_day,
                     oc.strike_price,
                     alin.open_close,
                     acc.opt_is_fix_custfirm_processed,
                     ftr.opt_customer_firm,
                     acc.opt_customer_or_firm,
                     coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
              FROM genesis2.allocation_instruction_entry ae
                       JOIN genesis2.allocation_instruction alin
                            ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                       inner join lateral (select tr.cmta,
                                                  tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
                                           from genesis2.alloc_instr2trade_record aitr
                                                    inner join genesis2.trade_record tr
                                                               on aitr.trade_record_id = tr.trade_record_id and
                                                                  aitr.date_id = tr.date_id and tr.is_busted = 'N'
                                                                      and case when in_exec_broker is null then true else tr.exec_broker = in_exec_broker end
                                           where aitr.alloc_instr_id = alin.alloc_instr_id
                                             and aitr.date_id = alin.date_id
                                           limit 1) ftr on true
                       JOIN genesis2.clearing_account ca
                            ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                                ca.clearing_account_type = '1' AND ca.market_type = 'O')
                       JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                                     acc.opt_report_to_mpid = 'MLCB' AND
                                                     acc.trading_firm_id <> 'cantor')
                       JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                       JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                       JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
              WHERE alin.date_id between in_start_date_id and in_end_date_id) gen

        UNION ALL

        SELECT 'DAS' || ',' ||--Branch
               CASE WHEN ftr.SIDE = '1' THEN 'B' WHEN ftr.SIDE in ('2', '5', '6') THEN 'S' ELSE 'S' END || ',' ||--Action
               '' || ',' ||--Symbol
               '?' || ',' ||--Destination
               ftr.day_cum_qty || ',' ||--Quantity
               to_char(ftr.avg_px, 'FM99990D009999') || ',' ||--Avg. Price
               COALESCE(lpad(ftr.cmta, 5, '0'), '') || ',' || -- CMTA
               SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 5, 2) || '/' ||
               SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 7, 2) || '/' ||
               SUBSTRING(TO_CHAR(ftr.date_id, 'FM99999999'), 3, 2) || '/' ||
               '00/00' || ',' ||
               'DASH' || ',' ||--Execution Venue
--		ftr.street_account_name ||','||--Client Identifier
               '' || ',' ||--Client Identifier
               to_char(row_number() OVER (), 'FM0000') || ',' ||
               to_char(((CASE coalesce(OS.MIN_TICK_INCREMENT, 0.01)
                             WHEN 0.01 THEN ftr.OPT_PENNY_COMMISSION
                             WHEN 0.05 THEN ftr.OPT_NICKEL_COMMISSION END) * ftr.day_cum_qty), 'FM99990D0') || ',' ||--13
               '' || ',' ||--Liquidity
               'S' || ',' ||--Single/BASket
               '' || ',' ||--PASs Through Fees
               COALESCE(OS.ROOT_SYMBOL, '') || ',' ||--Symbol
               CASE WHEN OC.PUT_CALL = '0' THEN 'P' WHEN OC.PUT_CALL = '1' THEN 'C' END || ',' ||--Put/Call
               OC.MATURITY_YEAR || ',' ||
               to_char(OC.maturity_month, 'FM00') || ',' ||
               to_char(OC.MATURITY_DAY, 'FM00') || ',' ||
               to_char(OC.STRIKE_PRICE, 'FM999990D0099') || ',' ||--Strike
               ftr.open_close || ',' ||
               CASE (CASE ftr.OPT_IS_FIX_CUSTFIRM_PROCESSED
                         WHEN 'Y' THEN coalesce(ftr.CUSTOMER_OR_FIRM_ID, ftr.OPT_CUSTOMER_OR_FIRM)
                         ELSE ftr.OPT_CUSTOMER_OR_FIRM END)
                   WHEN '0' THEN 'C'
                   WHEN '1' THEN 'F'
                   WHEN '2' THEN 'F'
                   WHEN '3' THEN 'C'
                   WHEN '4' THEN 'M'
                   WHEN '5' THEN 'M'
                   WHEN '7' THEN 'F'
                   WHEN '8' THEN 'C'
                   END || ',' ||
               '' || ','
                   AS rec
        FROM ftr_clear AS ftr
                 INNER JOIN genesis2.option_contract oc ON (oc.instrument_id = ftr.instrument_id)
                 INNER JOIN genesis2.option_series os ON (os.option_series_id = oc.option_series_id)
                 INNER JOIN genesis2.instrument i ON (i.instrument_id = ftr.instrument_id);

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
    into l_step_id;

-- Finish

END;
$function$
;



-- DROP FUNCTION staging.last_orig_order(int8);

create function staging.last_orig_trade_record_id_today(in_trade_record_id bigint, in_date_id int4)
    returns bigint
    language plpgsql
as
$fn$
declare
    ret_trade_record_id int8;
begin
    with recursive total (trade_record_id, orig_trade_record_id) as
                       (select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                        where tr.orig_trade_record_id is not null
                          and tr.trade_record_id = in_trade_record_id
                          and tr.date_id = in_date_id

                        union all

                        select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                                 join total on tr.trade_record_id = total.orig_trade_record_id
                        where tr.date_id = in_date_id)
    select trade_record_id
    into ret_trade_record_id
    from total
    where orig_trade_record_id is null
    limit 1;
    return ret_trade_record_id;
end;
$fn$
;

select * from genesis2.alloc_instr2trade_record
where alloc_instr_id = -51678

select last_qty, * from genesis2.trade_record
where trade_record_id in (2346593078, 2346593027, 2346592823)

select staging.last_orig_trade_record_id_today(2346593043, 20241129);

select last_qty, * from trade_record where trade_record_id = 2346592826;

with base as (SELECT ftr.first_orig_trade_record_id,
                     qty.last_qty                                         as first_qty,
                     ftr.orig_trade_record_id,
                     ftr.trade_record_id,
                     ftr.last_qty,
                     alin.alloc_instr_id,
                     alin.side,
                     alin.avg_px,
                     alin.date_id,
                     alin.open_close,
                     ae.alloc_qty,
                     acc.opt_is_fix_clfirm_processed,
                     ftr.cmta                                             AS ftr_cmta,
                     ca.cmta                                              AS ca_cmta,
                     acc.opt_is_fix_custfirm_processed,
                     ftr.opt_customer_firm,
                     acc.opt_customer_or_firm,
                     ae.occ_actionable_id                                 as occ_actionable_id,
                     to_char(now(), 'YYYYMMDDHH24MI')                     as dataset,
                     row_number() over (partition by ftr.trade_record_id) as rn

              FROM genesis2.allocation_instruction_entry ae
                       JOIN genesis2.allocation_instruction alin
                            ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                       inner join lateral (select tr.cmta,
                                                  tr.opt_customer_firm,-- coalesce(tr.street_account_name,'') street_account_name
                                                  tr.last_qty,
                                                  staging.last_orig_trade_record_id_today(tr.trade_record_id,
                                                                                          tr.date_id) as first_orig_trade_record_id,
                                                  tr.trade_record_id,
                                                  tr.orig_trade_record_id

                                           from genesis2.alloc_instr2trade_record aitr
                                                    inner join genesis2.trade_record tr
                                                               on aitr.trade_record_id = tr.trade_record_id
                                                                   and aitr.date_id = tr.date_id
                                                     and tr.is_busted = 'N'
                                                                   and case
                                                                           when :in_exec_broker is null then true
                                                                           else tr.exec_broker = :in_exec_broker end
                                                                   and tr.exec_broker is not null
                                           where aitr.alloc_instr_id = alin.alloc_instr_id
                                             and aitr.date_id = alin.date_id
--                                      limit 1
                  ) ftr on true
                       join lateral (select last_qty
                                     from genesis2.trade_record tr
                                     where tr.trade_record_id = ftr.first_orig_trade_record_id
                                     limit 1) qty on true
                       JOIN genesis2.clearing_account ca
                            ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                                AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
                       JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                                     acc.opt_report_to_mpid = 'MLCB' AND
                                                     acc.trading_firm_id <> 'cantor')
                       JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                       JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                       JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
              WHERE alin.date_id between :in_start_date_id and :in_end_date_id)
select * from base
         where rn = 1
order by first_orig_trade_record_id, alloc_instr_id desc, trade_record_id;


select tr.trade_record_id,
                 tr.account_id,
                 tr.instrument_id,
                 tr.last_qty,
                 tr.allocation_avg_price,
                 tr.open_close,
                 tr.side,
                 tr.street_account_name,
                 tr.account_nickname,
                 tr.cmta,
                 tr.clearing_account_number,
                 i.instrument_type_id
          from genesis2.trade_record tr
                   inner join genesis2.instrument i on tr.instrument_id = i.instrument_id
          where date_id = :in_date_id
            and trade_record_id = any ('{2346593042,2346593043,2346593044}');


select *
from genesis2.allocation_instruction alin
         join genesis2.allocation_instruction_entry ae
              on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
--          join genesis2.alloc_instr2trade_record aitr
--               on aitr.alloc_instr_id = alin.alloc_instr_id and aitr.date_id = alin.date_id
--          inner join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
--          join genesis2.clearing_account ca
--               on (ca.clearing_account_id = ae.clearing_account_id and ca.clearing_account_type = '1' and
--                   ca.market_type = 'O')
--          join genesis2.account acc
--               on (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and acc.opt_report_to_mpid = 'MLCB' and
--                   acc.trading_firm_id <> 'cantor')
--          join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
--          join genesis2.option_series os on os.option_series_id = oc.option_series_id
--          join genesis2.instrument i on i.instrument_id = alin.instrument_id
where true
  and alin.date_id between :in_start_date_id and :in_end_date_id
--   and alin.alloc_instr_id = -51641;


select tr.clearing_account_id,
       tr.street_account_name,
       tr.account_nickname,
       array_agg(tr.trade_record_id),
       sum(tr.last_qty)
from genesis2.trade_record tr
where trade_record_id in (2346593042, 2346593043, 2346593044)
group by tr.clearing_account_id, tr.street_account_name, tr.account_nickname;


insert into trash.allocation_report (first_orig_trade_record_id, first_qty, orig_trade_record_id, trade_record_id,
                                     last_qty, alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty,
                                     opt_is_fix_clfirm_processed, ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed,
                                     opt_customer_firm, opt_customer_or_firm, occ_actionable_id, dataset, to_report)
SELECT ftr.first_orig_trade_record_id,
       qty.last_qty                     as first_qty,
       ftr.orig_trade_record_id,
       ftr.trade_record_id,
       ftr.last_qty,
       alin.alloc_instr_id,
       alin.side,
       alin.avg_px,
       alin.date_id,
       alin.open_close,
       ae.alloc_qty,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                         AS ftr_cmta,
       ca.cmta                          AS ca_cmta,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       ae.occ_actionable_id             as occ_actionable_id,
       to_char(now(), 'YYYYMMDDHH24MI') as dataset,
--        row_number() over (partition by ftr.trade_record_id) as rn
       case
           when exists (select null
                        from trash.allocation_report ar
                        where ar.alloc_instr_id = ae.alloc_instr_id
                          and ar.side = alin.side
                          and ar.date_id = alin.date_id) then 'skip'
           when ae.alloc_qty > ftr.last_qty then 'skip 2'
           else 'report' end            as to_report
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select tr.cmta,
                                    tr.opt_customer_firm,
                                    tr.last_qty,
                                    staging.last_orig_trade_record_id_today(tr.trade_record_id,
                                                                            tr.date_id) as first_orig_trade_record_id,
                                    tr.trade_record_id,
                                    tr.orig_trade_record_id

                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id
                                                     and aitr.date_id = tr.date_id
                                                     and tr.is_busted = 'N'
                                                     and case
                                                             when :in_exec_broker is null then true
                                                             else tr.exec_broker = :in_exec_broker end
                                                     and tr.exec_broker is not null
                             where aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
                             limit 1
    ) ftr on true
         join lateral (select last_qty
                       from genesis2.trade_record tr
                       where tr.trade_record_id = ftr.first_orig_trade_record_id
                       limit 1) qty on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                  AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id
and not exists (select null
                        from trash.allocation_report ar
                        where ar.alloc_instr_id = ae.alloc_instr_id
                          and ar.side = alin.side
                          and ar.date_id = alin.date_id)


select first_orig_trade_record_id, orig_trade_record_id, last_qty, alloc_qty, * from trash.allocation_report