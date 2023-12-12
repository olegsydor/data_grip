
select * from trash.ameritrade('OFP0001')
create or replace function trash.ameritrade(in_trading_firm_id text default 'OFP0001')
    returns table
            (
                rec text
            )
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_step_id int;

begin
    --     select nextval('public.load_timing_seq') into l_load_id;
--     l_step_id := 1;
--
--     select public.load_log(l_load_id, l_step_id,
--                            'report_fintech_eod_saxopts_execution for ' || in_start_date_id::text || '-' ||
--                            in_end_date_id::Text || 'STARTED ====', in_start_date_id,
--                            'O')
--     into l_step_id;
    return query
        SELECT "EXCH-FIRM-NO" ||
               "EXCH-SUB-NO" ||
               "EXCH-FIRM-MNEMONIC" ||
               "EXCH-BRANCH" ||
               "EXCH-BRSEQ" ||
               "EXCH-FIX-11" ||
               "EXCH-ORDR-DATE-MDCY" ||
               "EXCH-BORS" ||
               "EXCH-ORIG-QTY" ||
               "EXCH-SEC-IDENTIFIER" ||
               "EXCH-SECURITY" ||
               "EXCH-LIMIT-PRICE" ||
               "EXCH-STOP-PRICE" ||
               "EXCH-LEAVES-QTY" ||
               "EXCH-INVESTOR-CODE" ||
               "EXCH-SPREAD-IND" ||
               "EXCH-SPREAD-PRICE" ||
               "EXCH-SPREAD-PX-ID" ||
               "EXCH-MULTI-LEG" ||
               "EXCH-STOP-ORDR" ||
               "EXCH-MARKET-ORDR" ||
               "EXCH-TIME-IN-FORCE" ||
               "EXCH-POS-DUP" ||
               "EXCH-ALL-OR-NONE" ||
               "EXCH-DNR" ||
               "EXCH-OR-BETTER" ||
               "EXCH-NOT-HELD" ||
               "EXCH-CASH-TRADE" ||
               "EXCH-NEXT-DAY" ||
               "EXCH-STOP-LIMIT-WOW" ||
               "EXCH-STOP-LIMIT-IND" ||
               "EXCH-CALL-PUT-IND" ||
               "EXCH-ROOT-SYMB" ||
               "EXCH-EXP-MON" ||
               "EXCH-EXP-DAY" ||
               "EXCH-EXP-YEAR" ||
               "EXCH-STRIKE-PX" ||
               "FILLER"
        FROM (SELECT '   '                                                                           AS "EXCH-FIRM-NO",
                     '   '                                                                           AS "EXCH-SUB-NO",
                     RPAD(ac.broker_dealer_mpid, 5)                                                  AS "EXCH-FIRM-MNEMONIC",
                     '    '                                                                          AS "EXCH-BRANCH",
                     '     '                                                                         AS "EXCH-BRSEQ",
                     RPAD(CL.CLIENT_ORDER_ID, 30)                                                    AS "EXCH-FIX-11",
                     TO_CHAR(CL.CREATE_TIME, 'MMDDYYYY')                                             AS "EXCH-ORDR-DATE-MDCY",
                     CASE WHEN CL.SIDE = '1' THEN 'B ' WHEN CL.SIDE in ('2', '5', '6') THEN 'S ' END AS "EXCH-BORS",
                     LPAD(round(CL.ORDER_QTY * 100000, 0)::text, 18, '0')                            AS "EXCH-ORIG-QTY",
                     'O'                                                                             AS "EXCH-SEC-IDENTIFIER",
                     RPAD(' ', 20)                                                                   AS "EXCH-SECURITY",
                     LPAD((COALESCE(CL.PRICE * 1000000000, 0)::int8)::text, 18, '0')                 AS "EXCH-LIMIT-PRICE",

                     LPAD((COALESCE(CL.STOP_PRICE * 1000000000, 0)::int8)::text, 18,
                          '0')                                                                       AS "EXCH-STOP-PRICE",
                     LPAD((COALESCE(EX.LEAVES_QTY * 100000, 0)::int8)::text, 18, '0')                AS "EXCH-LEAVES-QTY",

                     ' '                                                                             AS "EXCH-INVESTOR-CODE",
                     CASE WHEN CL.MULTILEG_REPORTING_TYPE <> '1' THEN 'SPD' ELSE '   ' END           AS "EXCH-SPREAD-IND",
                     '0000000'                                                                       AS "EXCH-SPREAD-PRICE",
                     '   '                                                                           AS "EXCH-SPREAD-PX-ID",
                     ' '                                                                             AS "EXCH-MULTI-LEG",
                     '   '                                                                           AS "EXCH-STOP-ORDR",
                     '   '                                                                           AS "EXCH-MARKET-ORDR",
                     RPAD(UPPER(TIF.TIF_SHORT_NAME), 3)                                              AS "EXCH-TIME-IN-FORCE",
                     ' '                                                                             AS "EXCH-POS-DUP",
                     ' '                                                                             AS "EXCH-ALL-OR-NONE",
                     ' '                                                                             AS "EXCH-DNR",
                     ' '                                                                             AS "EXCH-OR-BETTER",
                     ' '                                                                             AS "EXCH-NOT-HELD",
                     ' '                                                                             AS "EXCH-CASH-TRADE",
                     ' '                                                                             AS "EXCH-NEXT-DAY",
                     ' '                                                                             AS "EXCH-STOP-LIMIT-WOW",
                     'L'                                                                             AS "EXCH-STOP-LIMIT-IND",
                     CASE
                         WHEN OC.PUT_CALL = '0' THEN 'P'
                         WHEN OC.PUT_CALL = '1' THEN 'C'
                         ELSE ' ' END                                                                AS "EXCH-CALL-PUT-IND",
                     RPAD(OS.ROOT_SYMBOL, 6)                                                         AS "EXCH-ROOT-SYMB",
                     RPAD(OC.MATURITY_MONTH::text, 2, '0')                                           AS "EXCH-EXP-MON",
                     RPAD(OC.MATURITY_DAY::text, 2, '0')                                             AS "EXCH-EXP-DAY",
                     RIGHT('0000' || OC.MATURITY_YEAR::text, 2)                                      AS "EXCH-EXP-YEAR",
                     LPAD(round(OC.STRIKE_PRICE * 1000000000, 0)::text, 18, '0')                     AS "EXCH-STRIKE-PX",
                     RPAD(' ', 232)                                                                  AS "FILLER"
              FROM dwh.gtc_order_status gtc
                       join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
                       INNER JOIN dwh.d_INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                       INNER JOIN dwh.d_ACCOUNT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
                       LEFT JOIN dwh.d_OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
                       LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
                       join lateral (select ex.exec_id as exec_id,
                                            ex.avg_px,
                                            ex.leaves_qty,
                                            ex.order_status
                                     from dwh.execution ex
                                     where gtc.order_id = ex.order_id
                                       and ex.order_status <> '3'
                                       and ex.exec_date_id >= gtc.create_date_id
                                     order by ex.exec_time desc
                                     limit 1) ex on true
                       INNER JOIN dwh.d_ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
                       LEFT JOIN dwh.d_EX_DESTINATION_CODE EDC
                                 on (CL.ex_destination = EDC.ex_destination_CODE and EDC.is_acitive)

                       LEFT JOIN dwh.d_TIME_IN_FORCE TIF ON (TIF.TIF_ID = CL.TIME_IN_FORCE_id)
              WHERE true
                and gtc.close_date_id is null
                and AC.TRADING_FIRM_ID = in_trading_firm_id
                AND CL.PARENT_ORDER_ID IS NULL
                AND CL.TRANS_TYPE IN ('D', 'G')
                AND CL.TIME_IN_FORCE_ID in ('1', '6')
                AND CL.MULTILEG_REPORTING_TYPE in ('1', '2')
              ORDER BY CL.CREATE_TIME::date) x;
end;
$fx$

