CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_commission_rate(
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


        SELECT count(*)
        INTO l_symbol_list_id_cnt
        FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                 JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
                 JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
        WHERE sl.is_deleted = 'N'
          AND asl.symbol = in_symbol
          and
            case when in_symbol_suffix is null then coalesce(asl.SYMBOL_SUFFIX, 'no-suffix') else in_symbol_suffix end =
            coalesce(in_symbol_suffix, 'no-suffix')
          AND sl.instrument_type_id = in_instrument_type
          AND ac.account_id = in_account_id;

        SELECT rate
        INTO l_rate
        from (select *
              from (SELECT 1 as prioritet,
                           optr.rate,
                           prt.min_price
                    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                             JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
                    WHERE optr.account_id = in_account_id
                      AND optr.touch_type_id = l_touch_type_id
                      AND optr.trading_session_type = in_trading_session_type
                      and case when in_rate_type_id is null then optr.RATE_TYPE_ID else in_rate_type_id end =
                          optr.RATE_TYPE_ID
                      AND case
                              when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN
                                                                (SELECT optr.symbol_list_id
                                                                 FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                                                                          JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl
                                                                               ON optr.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl
                                                                               ON asl.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl
                                                                               ON tfsl.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2_QA_20100601.trading_firm tf
                                                                               ON tf.trading_firm_id = tfsl.trading_firm_id
                                                                          JOIN GENESIS2_QA_20100601.account ac
                                                                               ON ac.trading_firm_id = tf.trading_firm_id
                                                                 WHERE sl.is_deleted = 'N'
                                                                   AND asl.symbol = in_symbol
                                                                   and case
                                                                           when in_symbol_suffix is null
                                                                               then coalesce(asl.SYMBOL_SUFFIX, 'no-suffix')
                                                                           else in_symbol_suffix end =
                                                                       coalesce(asl.SYMBOL_SUFFIX, 'no-suffix')
                                                                   AND sl.instrument_type_id = in_instrument_type
                                                                   AND ac.account_id = in_account_id)
                                  then 1
                              when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
--                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id is null then 1
                              else 0 end = 1
                      and prt.min_price <= in_price

                    union all

                    SELECT 2 as prioritet,
                           optr.rate,
                           prt.min_price
                    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                             JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
                    WHERE optr.account_id = in_account_id
                      AND optr.touch_type_id = l_touch_type_id
                      AND optr.trading_session_type = in_trading_session_type
                      and case when in_rate_type_id is null then optr.RATE_TYPE_ID else in_rate_type_id end =
                          optr.RATE_TYPE_ID
                      and l_symbol_list_id_cnt > 0
                      and optr.symbol_list_id is null
                      and prt.min_price <= in_price) x
              ORDER BY prioritet, x.min_price desc) y
        WHERE ROWNUM = 1;
    else

        SELECT count(*)
        INTO l_symbol_list_id_cnt
        FROM GENESIS2_QA_20100601.acct_comm_eqt_rate optr
                 JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
                 JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
        WHERE sl.is_deleted = 'N'
          AND asl.symbol = in_symbol
          and
            case when in_symbol_suffix is null then coalesce(asl.SYMBOL_SUFFIX, 'no-suffix') else in_symbol_suffix end =
            coalesce(in_symbol_suffix, 'no-suffix')
          AND sl.instrument_type_id = in_instrument_type
          AND ac.account_id = in_account_id;

        select rate
        into l_rate
        from (SELECT 1 as prioritet,
                     optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_eqt_rate optr
--                       JOIN GENESIS2_QA_20100601.sg_acct_comm_eqt_rate sacer prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN
                                                          (SELECT optr.symbol_list_id
                                                           FROM GENESIS2_QA_20100601.acct_comm_eqt_rate optr
                                                                    JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl
                                                                         ON optr.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl
                                                                         ON asl.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl
                                                                         ON tfsl.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2_QA_20100601.trading_firm tf
                                                                         ON tf.trading_firm_id = tfsl.trading_firm_id
                                                                    JOIN GENESIS2_QA_20100601.account ac
                                                                         ON ac.trading_firm_id = tf.trading_firm_id
                                                           WHERE sl.is_deleted = 'N'
                                                             AND asl.symbol = in_symbol
                                                             and case
                                                                     when in_symbol_suffix is null
                                                                         then coalesce(asl.SYMBOL_SUFFIX, 'no-suffix')
                                                                     else in_symbol_suffix end =
                                                                 coalesce(asl.SYMBOL_SUFFIX, 'no-suffix')
                                                             AND sl.instrument_type_id = in_instrument_type
                                                             AND ac.account_id = in_account_id)
                            then 1
                        when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
                        else 0 end = 1
              order by optr.symbol_list_id nulls last) x
        where rownum < 2;


    end if;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;