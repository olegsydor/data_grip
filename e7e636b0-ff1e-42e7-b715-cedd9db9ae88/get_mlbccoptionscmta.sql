-- DROP FUNCTION dash_reporting.get_mlbccoptionscmta(timestamp, text);
select * from dash360.report_rps_ml_options_cmta(20231103, 20231103)

CREATE FUNCTION dash360.report_rps_ml_options_cmta(in_start_date_id int4, in_end_date_id int4,
                                                   in_exec_broker text DEFAULT '792'::text)
    RETURNS table
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
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
                                           from alloc_instr2trade_record aitr
                                                    inner join trade_record tr
                                                               on aitr.trade_record_id = tr.trade_record_id and
                                                                  aitr.date_id = tr.date_id and tr.is_busted = 'N' and
                                                                  tr.exec_broker = in_exec_broker
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
update aux.d_account as dst
set account_name = src.account_name
from (values (1, 'account_1', 101),
             (2, 'account_1', 102),
             (3, 'account_1', 103),
             (4, 'account_1', 104)) as src (account_id, account_name, account_type_id)
where src.account_id = dst.account_id
  and src.account_type_id = dst.account_type_id;