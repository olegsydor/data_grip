select ac.account_name                                                                                          as account_name,
       CL.CREATE_TIME                                                                                           as creation_date,
       ORS.ORDER_STATUS_DESCRIPTION                                                                             as ord_status,
       I.INSTRUMENT_TYPE_ID                                                                                     as sec_type,
       CL.SIDE                                                                                                  as side,
       I.SYMBOL                                                                                                 as symbol,
       EDC.EX_DESTINATION_CODE_NAME                                                                             as ex_dest,
       CL.ORDER_QTY                                                                                             as ord_qty,
       CAST((SELECT SUM(LAST_QTY)
             FROM EXECUTION_TODAY
             WHERE ORDER_ID = CL.ORDER_ID
               AND EXEC_TYPE IN ('F', 'G')
               AND IS_BUSTED = 'N') as NUMBER(13, 0))                                                           as ex_qty,
       CL.ORDER_TYPE                                                                                            as ord_type,
       CL.PRICE                                                                                                 as price,
       EX.AVG_PX                                                                                                as avg_px,
       EX.LEAVES_QTY                                                                                            as lvs_qty,
       decode(CL.MULTILEG_REPORTING_TYPE, '1', 'N', '2', 'Y')                                                   as is_mleg,
       LEG.CLIENT_LEG_REF_ID                                                                                    as leg_id,
       cl.OPEN_CLOSE                                                                                            as open_close,
       CL.DASH_CLIENT_ORDER_ID                                                                                  as dash_id,
       CL.CLIENT_ORDER_ID                                                                                       as cl_ord_id,
       ORIG.CLIENT_ORDER_ID                                                                                     as orig_cl_ord_id,
       (select FIELD_VALUE
        from FIX_MESSAGE_FIELD
        where FIX_MESSAGE_ID = CL.FIX_MESSAGE_ID
          and TAG_NUM = 10441)                                                                                  as occ_data,
       OC.OPRA_SYMBOL                                                                                           as osi_symbol,
       CL.CLIENT_ID                                                                                             as client_id,
       CL.SUB_SYSTEM_ID                                                                                         as subsystem,
       OC.STRIKE_PRICE                                                                                          as strike_px,
       OC.PUT_CALL                                                                                              as put_call,
       OC.MATURITY_YEAR                                                                                         as exp_year,
       OC.MATURITY_MONTH                                                                                        as exp_month,
       OC.MATURITY_DAY                                                                                          as exp_day,
       CL.ORDER_ID                                                                                              as order_id,
       FC.FIX_COMP_ID                                                                                           as sender_comp_id
FROM CLIENT_ORDER_TODAY CL
         INNER JOIN INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
         LEFT JOIN CLIENT_ORDER_TODAY ORIG ON (ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
         LEFT JOIN CLIENT_ORDER_LEG LEG ON (LEG.ORDER_ID = CL.ORDER_ID)
         INNER JOIN ACCOUNT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
         INNER JOIN TRADING_FIRM tf ON (tf.TRADING_FIRM_ID = ac.TRADING_FIRM_ID)
         LEFT JOIN OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
         LEFT JOIN OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
         INNER JOIN EXECUTION_TODAY EX ON (CL.ORDER_ID = EX.ORDER_ID)
         INNER JOIN ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
         LEFT JOIN EX_DESTINATION_CODE EDC on (CL.ex_destination = EDC.ex_destination_CODE and EDC.is_deleted <> 'Y')
         LEFT JOIN FIX_CONNECTION FC ON (CL.FIX_CONNECTION_ID = FC.FIX_CONNECTION_ID)
WHERE CL.PARENT_ORDER_ID IS NULL
  AND CL.TRANS_TYPE IN ('D', 'G')
  --AND tf.TRADING_FIRM_ID <> 'baml' AND tf.TRADING_FIRM_ID <> 'eroom01'
  AND CL.TIME_IN_FORCE in ('1', '6')
  AND CL.MULTILEG_REPORTING_TYPE in ('1', '2')
  AND (trunc(i.last_trade_date) >= trunc(SYSDATE) OR i.last_trade_date IS NULL)
  AND NOT EXISTS (SELECT 1
                  FROM EXECUTION_TODAY
                  WHERE ORDER_ID = CL.ORDER_ID
                    AND ORDER_STATUS IN ('2', '4', '8')
                    and (TEXT <> 'Instrument expiration' OR TEXT is NULL))
  AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION_TODAY WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS <> '3')
  AND CL.ACCOUNT_ID in (28411, 26636)
---------------




ACCOUNT_NAME VARCHAR2(30) NOT NULL,
	CREATION_DATE TIMESTAMP WITH TIME ZONE NOT NULL,
	ORD_STATUS VARCHAR2(256) NOT NULL,
	SEC_TYPE CHAR(1),
	SIDE CHAR(1) NOT NULL,
	SYMBOL VARCHAR2(10) NOT NULL,
	EX_DEST VARCHAR2(256),
	ORD_QTY NUMBER(10,0) NOT NULL,
	EX_QTY NUMBER(13,0),
	ORD_TYPE CHAR(1) NOT NULL,
	PRICE NUMBER(12,4),
	AVG_PX NUMBER(16,8),
	LVS_QTY NUMBER(10,0),
	IS_MLEG VARCHAR2(32),
	LEG_ID VARCHAR2(30),
	OPEN_CLOSE CHAR(1),
	DASH_ID VARCHAR2(128),
	CL_ORD_ID VARCHAR2(256) NOT NULL,
	ORIG_CL_ORD_ID VARCHAR2(256),
	OCC_DATA VARCHAR2(4000),
	OSI_SYMBOL VARCHAR2(30),
	CLIENT_ID VARCHAR2(255),
	SUBSYSTEM VARCHAR2(20),
	STRIKE_PX NUMBER(12,4),
	PUT_CALL CHAR(1),
	EXP_YEAR NUMBER(4,0),
	EXP_MONTH NUMBER(2,0),
	EXP_DAY NUMBER(2,0),
	ORDER_ID NUMBER(13,0) NOT NULL,
	SENDER_COMP_ID VARCHAR2(30)
	    );


----------------
DECLARE
    P_ACCOUNTS     BATCH_ACCOUNTS;
    v_Return       REPORTING_SL.REF_CURSOR;
    l_rowcount     number;
    ACCOUNT_NAME   VARCHAR2(30);
    CREATION_DATE  TIMESTAMP WITH TIME ZONE;
    ORD_STATUS     VARCHAR2(256);
    SEC_TYPE       CHAR(1);
    SIDE           CHAR(1);
    SYMBOL         VARCHAR2(10);
    EX_DEST        VARCHAR2(256);
    ORD_QTY        NUMBER(10, 0);
    EX_QTY         NUMBER(13, 0);
    ORD_TYPE       CHAR(1);
    PRICE          NUMBER(12, 4);
    AVG_PX         NUMBER(16, 8);
    LVS_QTY        NUMBER(10, 0);
    IS_MLEG        VARCHAR2(32);
    LEG_ID         VARCHAR2(30);
    OPEN_CLOSE     CHAR(1);
    DASH_ID        VARCHAR2(128);
    CL_ORD_ID      VARCHAR2(256);
    ORIG_CL_ORD_ID VARCHAR2(256);
    OCC_DATA       VARCHAR2(4000);
    OSI_SYMBOL     VARCHAR2(30);
    CLIENT_ID      VARCHAR2(255);
    SUBSYSTEM      VARCHAR2(20);
    STRIKE_PX      NUMBER(12, 4);
    PUT_CALL       CHAR(1);
    EXP_YEAR       NUMBER(4, 0);
    EXP_MONTH      NUMBER(2, 0);
    EXP_DAY        NUMBER(2, 0);
    ORDER_ID       NUMBER(13, 0);
    SENDER_COMP_ID VARCHAR2(30);


BEGIN
    P_ACCOUNTS := BATCH_ACCOUNTS(28411, 26636);
    v_Return := REPORTING_SL.getActiveParentGTCOrders(p_accounts=>P_ACCOUNTS);
    l_rowcount := 0;
    LOOP
        FETCH v_Return INTO ACCOUNT_NAME,
            CREATION_DATE,
            ORD_STATUS ,
            SEC_TYPE ,
            SIDE ,
            SYMBOL ,
            EX_DEST ,
            ORD_QTY ,
            EX_QTY ,
            ORD_TYPE,
            PRICE ,
            AVG_PX ,
            LVS_QTY ,
            IS_MLEG ,
            LEG_ID ,
            OPEN_CLOSE ,
            DASH_ID ,
            CL_ORD_ID,
            ORIG_CL_ORD_ID,
            OCC_DATA,
            OSI_SYMBOL,
            CLIENT_ID ,
            SUBSYSTEM ,
            STRIKE_PX ,
            PUT_CALL ,
            EXP_YEAR ,
            EXP_MONTH ,
            EXP_DAY ,
            ORDER_ID ,
            SENDER_COMP_ID;

        EXIT WHEN v_Return%NOTFOUND;
        l_rowcount := l_rowcount + 1;
    END LOOP;

-- DBMS_OUTPUT.PUT_LINE(l_rowcount||'-'||NVL(l_price, 0)||'-'||NVL(l_quantity, 0));

END;


DECLARE
    P_ACCOUNTS       BATCH_ACCOUNTS;
    v_Return         REPORTING_SL.REF_CURSOR;
    l_rowcount       number;
    ACCOUNT_NAME     VARCHAR2(30);
    CREATION_DATE    TIMESTAMP WITH TIME ZONE;
    ORD_STATUS       VARCHAR2(256);
    SEC_TYPE         CHAR(1);
    SIDE             CHAR(1);
    SYMBOL           VARCHAR2(10);
    EXCHANGE_ID      VARCHAR2(6);
    EX_DEST          VARCHAR2(256);
    IS_BDMA          CHAR(1);
    ORD_QTY          NUMBER(10, 0);
    EX_QTY           NUMBER(13, 0);
    ORD_TYPE         CHAR(1);
    PRICE            NUMBER(12, 4);
    AVG_PX           NUMBER(16, 8);
    LVS_QTY          NUMBER(10, 0);
    IS_MLEG          VARCHAR2(32);
    LEG_ID           VARCHAR2(30);
    OPEN_CLOSE       CHAR(1);
    DASH_ID          VARCHAR2(128);
    CL_ORD_ID        VARCHAR2(256);
    ORIG_CL_ORD_ID   VARCHAR2(256);
    PARENT_CL_ORD_ID VARCHAR2(256);
    OCC_DATA         VARCHAR2(4000);
    OSI_SYMBOL       VARCHAR2(30);
    CLIENT_ID        VARCHAR2(255);
    SUBSYSTEM        VARCHAR2(20);
    STRIKE_PX        NUMBER(12, 4);
    PUT_CALL         CHAR(1);
    EXP_YEAR         NUMBER(4, 0);
    EXP_MONTH        NUMBER(2, 0);
    EXP_DAY          NUMBER(2, 0);
    ORDER_ID         NUMBER(13, 0);
    SENDER_COMP_ID   VARCHAR2(30);


BEGIN
    P_ACCOUNTS := BATCH_ACCOUNTS(11881);
    v_Return := REPORTING_SL.getActiveChildGTCOrders(p_accounts=>P_ACCOUNTS);
    l_rowcount := 0;
    LOOP
        FETCH v_Return INTO ACCOUNT_NAME,
            CREATION_DATE,
            ORD_STATUS ,
            SEC_TYPE ,
            SIDE ,
            SYMBOL ,
            EXCHANGE_ID ,
            EX_DEST ,
            IS_BDMA ,
            ORD_QTY ,
            EX_QTY ,
            ORD_TYPE,
            PRICE ,
            AVG_PX ,
            LVS_QTY ,
            IS_MLEG ,
            LEG_ID ,
            OPEN_CLOSE ,
            DASH_ID ,
            CL_ORD_ID,
            ORIG_CL_ORD_ID,
            PARENT_CL_ORD_ID,
            OCC_DATA,
            OSI_SYMBOL,
            CLIENT_ID ,
            SUBSYSTEM ,
            STRIKE_PX ,
            PUT_CALL ,
            EXP_YEAR ,
            EXP_MONTH ,
            EXP_DAY ,
            ORDER_ID ,
            SENDER_COMP_ID;

        EXIT WHEN v_Return%NOTFOUND;
        l_rowcount := l_rowcount + 1;
    END LOOP;

 DBMS_OUTPUT.PUT_LINE(l_rowcount||'-'||NVL(l_price, 0)||'-'||NVL(l_quantity, 0));

END;


CREATE UNIQUE INDEX GENESIS2_QA_20100601.UNQ_ATS_LIQUIDITY_PROVIDER ON "GENESIS2_QA_20100601".ATS_LIQUIDITY_PROVIDER
    (CASE WHEN IS_DELETED = 'N' THEN LP_DEMO_MNEMONIC end);