SELECT -- 77205
    cl.ORDER_ID,
    ac.account_name                                                                                       as "Account",
       TRUNC(CL.CREATE_TIME)                                                                                 as "Creation Date",
       decode(I.INSTRUMENT_TYPE_ID, 'E', 'Equity', 'O', 'Option')                                            as "Sec Type",
       decode(CL.SIDE, '1', 'Buy', '2', 'Sell', '5', 'Sell Short', '6', 'Sell Short')                        as "Side",
       CL.ORDER_QTY                                                                                          as "Ord Qty",
       I.SYMBOL                                                                                              as "Symbol",
       OC.STRIKE_PRICE                                                                                       as "Strike Px",
       decode(OC.PUT_CALL, '1', 'C', '2', 'P')                                                               as "Put Call",
       (OC.MATURITY_DAY || ' ' || to_char(to_date(OC.MATURITY_MONTH, 'mm'), 'Mon') || ' ' ||
        to_char(to_date(OC.MATURITY_YEAR, 'yyyy'), 'yy'))                                                    as "Exp Date",
       EDC.EX_DESTINATION_CODE_NAME                                                                          as "Ex Dest",
       OT.ORDER_TYPE_NAME                                                                                    as "Ord Type",
       CL.PRICE                                                                                              as "Price",
       CAST((SELECT SUM(LAST_QTY)
             FROM EXECUTION_TODAY
             WHERE ORDER_ID = CL.ORDER_ID
               AND EXEC_TYPE IN ('F', 'G')
               AND IS_BUSTED = 'N') as NUMBER(13, 0))                                                        as "Ex Qty",
       EX.AVG_PX                                                                                             as "Avg Px",
       EX.LEAVES_QTY                                                                                         as "Lvs Qty",
       decode(CL.MULTILEG_REPORTING_TYPE, '1', 'N', '2', 'Y')                                                as "Is Mleg",
       LEG.CLIENT_LEG_REF_ID                                                                                 as "Leg ID",
       cl.OPEN_CLOSE                                                                                         as "Open/Close",
       OC.OPRA_SYMBOL                                                                                        as "OSI Symbol",
       CL.CLIENT_ORDER_ID                                                                                    as "Cl Ord ID",
       CL.CLIENT_ID                                                                                          as "Client ID",
       FC.FIX_COMP_ID                                                                                        AS "Sender Comp ID"
FROM CLIENT_ORDER_TODAY CL
         INNER JOIN INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
         LEFT JOIN CLIENT_ORDER_TODAY ORIG ON (ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
         LEFT JOIN CLIENT_ORDER_LEG LEG ON (LEG.ORDER_ID = CL.ORDER_ID)
         INNER JOIN ACCOUNT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
         LEFT JOIN OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
         LEFT JOIN OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
         INNER JOIN EXECUTION_TODAY EX ON (CL.ORDER_ID = EX.ORDER_ID)
         INNER JOIN ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
         LEFT JOIN EX_DESTINATION_CODE EDC on (CL.ex_destination = EDC.ex_destination_CODE and EDC.is_deleted <> 'Y')
         LEFT JOIN ORDER_TYPE OT ON (OT.ORDER_TYPE_ID = CL.ORDER_TYPE)
         LEFT JOIN FIX_CONNECTION FC ON (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
WHERE CL.PARENT_ORDER_ID IS NULL
  AND CL.TRANS_TYPE IN ('D', 'G')
  AND CL.TIME_IN_FORCE in ('1', '6')
  AND CL.MULTILEG_REPORTING_TYPE in ('1', '2')
  AND (trunc(i.last_trade_date) >= trunc(SYSDATE) OR i.last_trade_date IS NULL)
  AND NOT EXISTS (SELECT 1
                  FROM EXECUTION_TODAY
                  WHERE ORDER_ID = CL.ORDER_ID
                    AND ORDER_STATUS IN ('2', '4', '8')
                    and (TEXT <> 'Instrument expiration' OR TEXT is NULL))
  AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS <> '3')
  and cl.CREATE_TIME > (date '2026-01-25')
-- and cl.ORDER_ID in (414795391607396407,414795391607396408,414795391607396409,414795391607396410,414795391618919403,414795391618919404,414795391618919405,414795391618919406,414795391647238854,414795391647238855,414795391647238856,414795391647238857,414795395922273334,414795395922273335,414795395922273336,414795395922273337,414795395953737275,414795395953737276,414795395953737277,414795395953737278,414795395968414191,414795395968414192,414795395968414193,414795395968414194,414795395982044570,414795395982044571,414795395982044572,414795395982044573,414795404552055800,414795404552055801,414795404552055802,414795404552055803,414795404563605918,414795404563605919,414795404563605920,414795404563605921,414795705143141639,414796370920745578,414796405254267307,414796675757521111,414796705883113308,414796731649767952,414796731649767953,414797027970008812,414797027970008813,414797131056559549,414797131056559550,414797178343139576,414797178343139577,414797234185063570,414797234185063571,414797655070887000,414797749545481788,414797788226400896,414798110369921749,414798599938539934,414799016528330599,414799016528330600,414799016528330601,414799016528330602,414799033686179276,414799033686179277,414799166909857107,414799171232087344,414799338657171205,414799489025063740,414799489039743110,414799489079593196,414799493312692549,414799497580398448,414799497625482424,414799566334475185,414799579164853845,414799630806173616,414799678044521071,414799678044521072,414799678044521073,414799678044521074,414799682310129750,414799682310129751,414799682310129752,414799682310129753,414799682324807001,414799682324807002,414799682324807003,414799682324807004,414799699524602212,414799699524602213,414799699524602214,414799699524602215,414799708088322425,414799905652618118,414799905652618119,414799970050915226,414799970050915227,414799970050915228,414799970050915229,414799978620932548,414799978620932549,414799978620932550)

select *
from client_order
where client_order_id = '777696407-2xnt0xp-87';
