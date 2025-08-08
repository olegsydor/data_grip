CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_commission_rate_(
    in_exchange_id VARCHAR2,
    in_symbol VARCHAR2,
    in_instrument_type CHAR,
    in_account_id NUMBER,
    in_trading_session_type CHAR,
    in_price number,
    in_symbol_suffix varchar2 default null,
    in_rate_type_id varchar2 default null
) RETURN NUMBER
    IS
    l_touch_type_id      GENESIS2_QA_20100601.EX_DESTINATION_CODE.TOUCH_TYPE_ID%TYPE;
    l_rate               GENESIS2_QA_20100601.acct_comm_opt_rate.rate%TYPE;

    -- GET symbol_list_id
    TYPE t_symbol_list_ids IS TABLE OF GENESIS2_QA_20100601.acct_comm_opt_rate.symbol_list_id%TYPE
        INDEX BY PLS_INTEGER;
    l_symbol_list_id_cnt number;
BEGIN
    -- 1. GET TOUCH_TYPE_ID
    SELECT C.TOUCH_TYPE_ID
    INTO l_touch_type_id
    FROM GENESIS2_QA_20100601.EXCHANGE E
             JOIN GENESIS2_QA_20100601.EX_DESTINATION D ON D.EXCHANGE_ID = E.EXCHANGE_ID
             JOIN GENESIS2_QA_20100601.EX_DESTINATION_CODE C ON C.EX_DESTINATION_CODE = D.EX_DESTINATION_CODE
             JOIN GENESIS2_QA_20100601.RISK_MGMT_TOUCH_TYPE T ON C.TOUCH_TYPE_ID = T.TOUCH_TYPE_ID
    WHERE E.IS_DELETED = 'N'
      AND E.IS_ACTIVE = 'Y'
      AND D.IS_DELETED = 'N'
      AND C.IS_DELETED = 'N'
      AND E.EXCHANGE_ID = in_exchange_id
      AND ROWNUM = 1;

    -- 2. GET symbol_list_id
    -- 3. GET rate
    if in_instrument_type = 'O' then
        with cte_symbol_list as
                 (select optr.symbol_list_id
                  FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                           JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                           JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl
                                ON asl.symbol_list_id = sl.symbol_list_id
                           JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                           JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl
                                ON tfsl.symbol_list_id = sl.symbol_list_id
                           JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
                           JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
                  WHERE sl.is_deleted = 'N'
                    AND asl.symbol = in_symbol
                    and case when in_symbol_suffix is null then asl.SYMBOL_SUFFIX else in_symbol_suffix end =
                        asl.SYMBOL_SUFFIX
                    AND sl.instrument_type_id = in_instrument_type
                    AND ac.account_id = in_account_id)
        SELECT rate
        INTO l_rate
        FROM (SELECT optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                       JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND optr.trading_session_type = in_trading_session_type
                and
                  case when in_rate_type_id is null then optr.RATE_TYPE_ID else in_rate_type_id end = optr.RATE_TYPE_ID
                AND case
                        when (select count(*) from cte_symbol_list) > 0 and optr.symbol_list_id IN
                                                                            (SELECT optr.symbol_list_id
                                                                             FROM cte_symbol_list)
                            then 1
                        when (select count(*) from cte_symbol_list) = 0 and optr.rate_scope = 'G' then 1
                        else 0 end = 1
                and prt.min_price < in_price
              ORDER BY prt.min_price DESC)
        WHERE ROWNUM = 1;
    else
        SELECT rate
        INTO l_rate
        FROM (SELECT optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_eqt_rate optr
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                and optr.rate_scope = 'G')
        WHERE ROWNUM = 1;
    end if;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;