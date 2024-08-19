SELECT
	TO_CHAR(CL.CREATE_TIME, 'MM/DD/YYYY') AS "CreateDate", --HH:MI:SS AM
	TF.TRADING_FIRM_NAME AS "TradingFirm",
	AC.ACCOUNT_NAME AS "Account",
	CL.CLIENT_ORDER_ID AS "ClOrdID",
	CASE
		WHEN CL.SIDE = '1' THEN 'BUY'
		WHEN CL.SIDE IN ('2', '5', '6') THEN 'SELL'
	END AS "Side",
	(CASE WHEN I.INSTRUMENT_TYPE_ID = 'E' THEN 'Equity' ELSE 'Option' END) AS "InstrumentType",
	I.DISPLAY_INSTRUMENT_ID AS "DisplaySymbol",
	I.SYMBOL AS "Symbol",
	LPAD(CAST(OC.MATURITY_MONTH AS VARCHAR(2)), 2, '0') || '/' || LPAD(CAST(OC.MATURITY_DAY AS VARCHAR(2)), 2, '0') || '/' || CAST(OC.MATURITY_YEAR AS VARCHAR(4)) AS "ExpirationDate",
	CASE OC.PUT_CALL WHEN '0' THEN 'P' WHEN '1' THEN 'C' END AS "CallPut",
	OC.STRIKE_PRICE AS "Strike",
	EX.LEAVES_QTY AS "OpenQty",
	CL.PRICE AS "Price",
	TIF.TIF_SHORT_NAME as "TIF"
	--ORS.ORDER_STATUS_DESCRIPTION as "OrderStatus"
FROM CLIENT_ORDER_TODAY CL
INNER JOIN INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
--LEFT JOIN CLIENT_ORDER_TODAY ORIG ON (ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
--LEFT JOIN CLIENT_ORDER_LEG LEG ON (LEG.ORDER_ID = CL.ORDER_ID)
LEFT JOIN ORDER_TYPE OT ON (OT.ORDER_TYPE_ID = CL.ORDER_TYPE)
INNER JOIN ACCOUNT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
INNER JOIN TRADING_FIRM TF ON (TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID AND I.IS_DELETED = 'N')
LEFT JOIN OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
LEFT JOIN OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
INNER JOIN EXECUTION_TODAY EX ON (CL.ORDER_ID = EX.ORDER_ID)
INNER JOIN ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
--LEFT JOIN EX_DESTINATION_CODE EDC on (CL.ex_destination = EDC.ex_destination_CODE and EDC.is_deleted <> 'Y')
--LEFT JOIN FIX_CONNECTION FC ON (CL.FIX_CONNECTION_ID = FC.FIX_CONNECTION_ID)
LEFT JOIN TIME_IN_FORCE TIF ON (TIF.TIF_ID = CL.TIME_IN_FORCE)
WHERE CL.PARENT_ORDER_ID IS NULL
	AND CL.TRANS_TYPE IN ('D','G')
	AND CL.TIME_IN_FORCE in ('1','6')
	AND CL.MULTILEG_REPORTING_TYPE in ('1','2')
	AND (trunc(i.last_trade_date) >= trunc(SYSDATE) OR i.last_trade_date IS NULL)
	AND NOT EXISTS (SELECT 1 FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS IN ('2','4','8') and (TEXT <>'Instrument expiration' OR TEXT is NULL))
	--AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS = '0' and EXEC_TYPE = 'y')
	AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS in ('0', '1') and EXEC_TYPE = 'y')
ORDER BY TRUNC(CL.CREATE_TIME);



select *
 from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id and cl.parent_order_id is null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
inner join dwh.d_trading_firm tf on (tf.trading_firm_id = ac.trading_firm_id)
left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
inner join lateral (select * from dwh.execution ex where ex.order_id = cl.order_id and ex.order_status in ('0','1') and ex.exec_type =
left join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id)
where cl.parent_order_id is null
	and cl.trans_type in ('D','G')
	and gtc.time_in_force_id in ('1','6')
	and cl.multileg_reporting_type in ('1','2')
-- 	AND (trunc(i.last_trade_date) >= trunc(SYSDATE) OR i.last_trade_date IS NULL)
  and gtc.create_date_id <= :in_start_date_id
  and (gtc.close_date_id is null
          -- the code below has been added to provide the same performance in the case we use the report for CURRENT date
           or (case
                when :l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > :in_end_date_id end))
	AND NOT EXISTS (SELECT 1 FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS IN ('2','4','8') and (TEXT <>'Instrument expiration' OR TEXT is NULL))
	--AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS = '0' and EXEC_TYPE = 'y')
	AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS in ('0', '1') and EXEC_TYPE = 'y')



select * from dwh.execution ex where ex.exec_date_id = 20240819
and exec_type = 'y'

select * from dwh.d_exec_type