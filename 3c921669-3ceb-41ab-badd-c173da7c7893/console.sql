select rate
from GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
         join GENESIS2_JAVA_TEST.acct_comm_opt_premium_tier prt on prt.tier_id = optr.tier_id
where 1 = 1
--and account_id = 10349
  and optr.symbol_list_id in (select sl.symbol_list_id
--, sl.*, asl.*
                              from GENESIS2_JAVA_TEST.acct_comm_symbol_list sl
                                       join GENESIS2_JAVA_TEST.symbol2acct_comm_symbol_list asl
                                            on asl.symbol_list_id = sl.symbol_list_id
                              where 1 = 1
                                and sl.is_deleted = 'N'
                                and asl.symbol = 'VB1'
                                and sl.instrument_type_id = 'F')
  and optr.symbol_list_id in (select symbol_list_id--, ac.account_id
                              from GENESIS2_JAVA_TEST.tf2acct_comm_symbol_list tfsl
                                       join GENESIS2_JAVA_TEST.trading_firm tf
                                            on tf.trading_firm_id = tfsl.trading_firm_id
                                       join GENESIS2_JAVA_TEST.account ac on ac.trading_firm_id = tf.trading_firm_id
                              where 1 = 1
                                and ac.account_id = 10349)
  and prt.min_price < :last_px
--and optr.touch_type_id = ??? -- depending on EXCHANGE_ID\last_mkt
--and optr.trading_session_type = ??? Stepan\Oleh\Sasha
  and rownum = 1
order by prt.min_price desc


select optr.rate, optr.symbol_list_id
    from GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
        where 1=1
AND EXISTS (
    SELECT 1
    FROM GENESIS2_JAVA_TEST.acct_comm_symbol_list sl
             JOIN GENESIS2_JAVA_TEST.symbol2acct_comm_symbol_list asl
                  ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_JAVA_TEST.tf2acct_comm_symbol_list tfsl
                  ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_JAVA_TEST.trading_firm tf
                  ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_JAVA_TEST.account ac
                  ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = 'VB1'
      AND sl.instrument_type_id = 'F'
      AND ac.account_id = 10349
      AND optr.symbol_list_id = sl.symbol_list_id
)


select optr.rate, optr.symbol_list_id,
       asl.symbol, sl.instrument_type_id, ac.account_id
    from GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
  JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl
     ON optr.symbol_list_id = sl.symbol_list_id
JOIN GENESIS2_JAVA_TEST.symbol2acct_comm_symbol_list asl
     ON asl.symbol_list_id = sl.symbol_list_id
JOIN GENESIS2_JAVA_TEST.tf2acct_comm_symbol_list tfsl
     ON tfsl.symbol_list_id = sl.symbol_list_id
JOIN GENESIS2_JAVA_TEST.trading_firm tf
     ON tf.trading_firm_id = tfsl.trading_firm_id
JOIN GENESIS2_JAVA_TEST.account ac
     ON ac.trading_firm_id = tf.trading_firm_id
WHERE sl.is_deleted = 'N'
  AND asl.symbol = 'VB1'
  AND sl.instrument_type_id = 'F'
  AND ac.account_id = 10349;


select E.EXCHANGE_ID, C.TOUCH_TYPE_ID, T.TOUCH_TYPE_DESC
from GENESIS2_JAVA_TEST.EXCHANGE E
         join GENESIS2_JAVA_TEST.EX_DESTINATION D on D.EXCHANGE_ID = E.EXCHANGE_ID
         join GENESIS2_JAVA_TEST.EX_DESTINATION_CODE C on C.EX_DESTINATION_CODE = D.EX_DESTINATION_CODE
         join GENESIS2_JAVA_TEST.RISK_MGMT_TOUCH_TYPE T on C.TOUCH_TYPE_ID = T.TOUCH_TYPE_ID
where E.IS_DELETED = 'N'
  and E.IS_ACTIVE = 'Y'
  and D.IS_DELETED = 'N'
  and C.IS_DELETED = 'N'
    and e.exchange_id = in_exchange_id;


select rate, optr.trading_session_type
from GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
         join GENESIS2_JAVA_TEST.acct_comm_opt_premium_tier prt on prt.tier_id = optr.tier_id
where 1 = 1
  and account_id = in_account_id
  and optr.symbol_list_id in _list
  and optr.touch_type_id = ???
and optr.trading_session_type = ???
  and rownum = 1
order by prt.min_price desc;



SELECT GENESIS2_JAVA_TEST.get_commission_rate(
         'XEUR',         -- in_exchange_id
         'VB1',          -- in_symbol
         'F',            -- in_instrument_type
         10349,          -- in_account_id
         'R',             -- in_trading_session_type
       100
       ) AS commission_rate
FROM dual;

ALTER FUNCTION GENESIS2_JAVA_TEST.GET_COMMISSION_RATE COMPILE;
CREATE OR REPLACE FUNCTION GENESIS2_JAVA_TEST.get_commission_rate(
    in_exchange_id VARCHAR2,
    in_symbol VARCHAR2,
    in_instrument_type CHAR,
    in_account_id NUMBER,
    in_trading_session_type CHAR,
    in_price number
) RETURN NUMBER
    IS
    l_touch_type_id      GENESIS2_JAVA_TEST.EX_DESTINATION_CODE.TOUCH_TYPE_ID%TYPE;
    l_rate               GENESIS2_JAVA_TEST.acct_comm_opt_rate.rate%TYPE;

    -- Для збереження списку symbol_list_id
    TYPE t_symbol_list_ids IS TABLE OF GENESIS2_JAVA_TEST.acct_comm_opt_rate.symbol_list_id%TYPE
        INDEX BY PLS_INTEGER;
    l_symbol_list_id_arr t_symbol_list_ids;
    l_is_list_found      BOOLEAN := FALSE;
        l_symbol_list_id_cnt number;
BEGIN
    -- 1. Визначити TOUCH_TYPE_ID
    SELECT C.TOUCH_TYPE_ID
    INTO l_touch_type_id
    FROM GENESIS2_JAVA_TEST.EXCHANGE E
             JOIN GENESIS2_JAVA_TEST.EX_DESTINATION D ON D.EXCHANGE_ID = E.EXCHANGE_ID
             JOIN GENESIS2_JAVA_TEST.EX_DESTINATION_CODE C ON C.EX_DESTINATION_CODE = D.EX_DESTINATION_CODE
             JOIN GENESIS2_JAVA_TEST.RISK_MGMT_TOUCH_TYPE T ON C.TOUCH_TYPE_ID = T.TOUCH_TYPE_ID
    WHERE E.IS_DELETED = 'N'
      AND E.IS_ACTIVE = 'Y'
      AND D.IS_DELETED = 'N'
      AND C.IS_DELETED = 'N'
      AND E.EXCHANGE_ID = in_exchange_id
      AND ROWNUM = 1;

    -- 2. Отримати всі релевантні symbol_list_id
    SELECT count(*)
    INTO l_symbol_list_id_cnt
    FROM GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
             JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_JAVA_TEST.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_JAVA_TEST.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_JAVA_TEST.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_JAVA_TEST.account ac ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = in_symbol
      AND sl.instrument_type_id = in_instrument_type
      AND ac.account_id = in_account_id;


    -- 3. Знайти rate
    SELECT rate
    INTO l_rate
    FROM (SELECT optr.rate
          FROM GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
                   JOIN GENESIS2_JAVA_TEST.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
          WHERE optr.account_id = in_account_id
            AND optr.touch_type_id = l_touch_type_id
            AND optr.trading_session_type = in_trading_session_type
            AND case
                    when l_symbol_list_id_cnt > 0 then optr.symbol_list_id IN (SELECT optr.symbol_list_id
                                                                                     FROM GENESIS2_JAVA_TEST.acct_comm_opt_rate optr
                                                                                              JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl
                                                                                                   ON optr.symbol_list_id = sl.symbol_list_id
                                                                                              JOIN GENESIS2_JAVA_TEST.symbol2acct_comm_symbol_list asl
                                                                                                   ON asl.symbol_list_id = sl.symbol_list_id
                                                                                              JOIN GENESIS2_JAVA_TEST.tf2acct_comm_symbol_list tfsl
                                                                                                   ON tfsl.symbol_list_id = sl.symbol_list_id
                                                                                              JOIN GENESIS2_JAVA_TEST.trading_firm tf
                                                                                                   ON tf.trading_firm_id = tfsl.trading_firm_id
                                                                                              JOIN GENESIS2_JAVA_TEST.account ac
                                                                                                   ON ac.trading_firm_id = tf.trading_firm_id
                                                                                     WHERE sl.is_deleted = 'N'
                                                                                       AND asl.symbol = in_symbol
                                                                                       AND sl.instrument_type_id = in_instrument_type
                                                                                       AND ac.account_id = in_account_id)
                    when l_symbol_list_id_cnt = 0 then optr.rate_scope = 'G'
                    else 1 = 2 end
            AND optr.rate_scope = 'G'
            and prt.min_price < in_price
          ORDER BY prt.min_price DESC)
    WHERE ROWNUM = 1;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; -- або -1, або підставна ставка
    WHEN OTHERS THEN
        -- лог або трасування, якщо потрібно
        RAISE;
END;
/
