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



SELECT GENESIS2_QA_20100601.get_commission_rate(
         'SQHT',         -- in_exchange_id
         'VB1',          -- in_symbol
         'O',            -- in_instrument_type
         263201,          -- in_account_id
         'G',             -- in_trading_session_type
       1
       ) AS commission_rate
FROM dual;

ALTER FUNCTION GENESIS2_JAVA_TEST.GET_COMMISSION_RATE COMPILE;

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

    -- Для збереження списку symbol_list_id
    TYPE t_symbol_list_ids IS TABLE OF GENESIS2_QA_20100601.acct_comm_opt_rate.symbol_list_id%TYPE
        INDEX BY PLS_INTEGER;
--     l_symbol_list_id_arr t_symbol_list_ids;
--     l_is_list_found      BOOLEAN := FALSE;
    l_symbol_list_id_cnt number;
BEGIN
    -- 1. Визначити TOUCH_TYPE_ID
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

    -- 2. Отримати всі релевантні symbol_list_id
    SELECT count(*)
    INTO l_symbol_list_id_cnt
    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
             JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = in_symbol
      and case when asl.SYMBOL_SUFFIX is null then 'no_symbol' else asl.SYMBOL_SUFFIX end = in_symbol_suffix
      AND sl.instrument_type_id = in_instrument_type
      AND ac.account_id = in_account_id;


    -- 3. Знайти rate
    if in_instrument_type = 'O' then
        SELECT rate
        INTO l_rate
        FROM (SELECT optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                       JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND optr.trading_session_type = in_trading_session_type
                AND case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN (SELECT optr.symbol_list_id
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
                                                                                    AND sl.instrument_type_id = in_instrument_type
                                                                                    AND ac.account_id = in_account_id)
                            then 1
                        when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
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
                and optr.rate_scope = 'G'
                )
        WHERE ROWNUM = 1;
    end if;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; -- або -1, або підставна ставка
    WHEN OTHERS THEN
        -- лог або трасування, якщо потрібно
        RAISE;
END;

    select * from GENESIS2_QA_20100601.acct_comm_opt_premium_tier;

insert into GENESIS2_QA_20100601.acct_comm_opt_premium_tier (tier_id, tier_scope, min_price)
values (1, 'T', 0);


select * from GENESIS2_QA_20100601.TF2ACCT_COMM_OPT_PREMIUM_TIER;

insert into GENESIS2_QA_20100601.TF2ACCT_COMM_OPT_PREMIUM_TIER (trading_firm_id, tier_id)
values ('socgenps', 1);
insert into GENESIS2_QA_20100601.TF2ACCT_COMM_OPT_PREMIUM_TIER (trading_firm_id, tier_id)
  values  ('socgeneqd', 1);

select * from "GENESIS2_QA_20100601"."ACCOUNT_EDIT_SCOPE"

select * from GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE;


INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (1, 'S', 263201, 'L', 'R', 'G', 'OSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (2, 'S', 263201, 'L', 'R', 'G', 'OML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (3, 'S', 263201, 'L', 'R', 'G', 'COSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (4, 'S', 263201, 'L', 'R', 'G', 'COML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (9, 'S', 263201, 'H', 'R', 'G', 'OSL', 1, 0.4);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (10, 'S', 263201, 'H', 'R', 'G', 'OML', 1, 0.4);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (11, 'S', 263201, 'H', 'R', 'G', 'COSL', 1, 0.4);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (12, 'S', 263201, 'H', 'R', 'G', 'COML', 1, 0.4);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (13, 'S', 263201, 'H', 'G', 'G', 'OSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (14, 'S', 263201, 'H', 'G', 'G', 'OML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (15, 'S', 263201, 'H', 'G', 'G', 'COSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (16, 'S', 263201, 'H', 'G', 'G', 'COML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (17, 'S', 263205, 'L', 'R', 'G', 'OSL', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (18, 'S', 263205, 'L', 'R', 'G', 'OML', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (19, 'S', 263205, 'L', 'R', 'G', 'COSL', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (20, 'S', 263205, 'L', 'R', 'G', 'COML', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (25, 'S', 263205, 'H', 'R', 'G', 'OSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (26, 'S', 263205, 'H', 'R', 'G', 'OML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (27, 'S', 263205, 'H', 'R', 'G', 'COSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (28, 'S', 263205, 'H', 'R', 'G', 'COML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (29, 'S', 263205, 'H', 'G', 'G', 'OSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (30, 'S', 263205, 'H', 'G', 'G', 'OML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (31, 'S', 263205, 'H', 'G', 'G', 'COSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (32, 'S', 263205, 'H', 'G', 'G', 'COML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (33, 'S', 263206, 'L', 'R', 'G', 'OSL', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (34, 'S', 263206, 'L', 'R', 'G', 'OML', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (35, 'S', 263206, 'L', 'R', 'G', 'COSL', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (36, 'S', 263206, 'L', 'R', 'G', 'COML', 1, 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (41, 'S', 263206, 'H', 'R', 'G', 'OSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (42, 'S', 263206, 'H', 'R', 'G', 'OML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (43, 'S', 263206, 'H', 'R', 'G', 'COSL', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (44, 'S', 263206, 'H', 'R', 'G', 'COML', 1, 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (45, 'S', 263206, 'H', 'G', 'G', 'OSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (46, 'S', 263206, 'H', 'G', 'G', 'OML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (47, 'S', 263206, 'H', 'G', 'G', 'COSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (48, 'S', 263206, 'H', 'G', 'G', 'COML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (49, 'S', 263207, 'L', 'R', 'G', 'OSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (50, 'S', 263207, 'L', 'R', 'G', 'OML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (51, 'S', 263207, 'L', 'R', 'G', 'COSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (52, 'S', 263207, 'L', 'R', 'G', 'COML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (53, 'S', 263207, 'H', 'R', 'G', 'OSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (54, 'S', 263207, 'H', 'R', 'G', 'OML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (55, 'S', 263207, 'H', 'R', 'G', 'COSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (56, 'S', 263207, 'H', 'R', 'G', 'COML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (57, 'S', 263207, 'H', 'G', 'G', 'OSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (58, 'S', 263207, 'H', 'G', 'G', 'OML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (59, 'S', 263207, 'H', 'G', 'G', 'COSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (60, 'S', 263207, 'H', 'G', 'G', 'COML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (61, 'S', 263208, 'L', 'R', 'G', 'OSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (62, 'S', 263208, 'L', 'R', 'G', 'OML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (63, 'S', 263208, 'L', 'R', 'G', 'COSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (64, 'S', 263208, 'L', 'R', 'G', 'COML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (65, 'S', 263208, 'H', 'R', 'G', 'OSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (66, 'S', 263208, 'H', 'R', 'G', 'OML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (67, 'S', 263208, 'H', 'R', 'G', 'COSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (68, 'S', 263208, 'H', 'R', 'G', 'COML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (69, 'S', 263208, 'H', 'G', 'G', 'OSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (70, 'S', 263208, 'H', 'G', 'G', 'OML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (71, 'S', 263208, 'H', 'G', 'G', 'COSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (72, 'S', 263208, 'H', 'G', 'G', 'COML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (73, 'S', 263208, 'L', 'R', 'G', 'OSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (74, 'S', 263208, 'L', 'R', 'G', 'OML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (75, 'S', 263208, 'L', 'R', 'G', 'COSL', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (76, 'S', 263208, 'L', 'R', 'G', 'COML', 1, 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (77, 'S', 263208, 'H', 'R', 'G', 'OSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (78, 'S', 263208, 'H', 'R', 'G', 'OML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (79, 'S', 263208, 'H', 'R', 'G', 'COSL', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (80, 'S', 263208, 'H', 'R', 'G', 'COML', 1, 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (81, 'S', 263208, 'H', 'G', 'G', 'OSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (82, 'S', 263208, 'H', 'G', 'G', 'OML', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (83, 'S', 263208, 'H', 'G', 'G', 'COSL', 1, 0.85);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_OPT_RATE (RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID,
                                                     TRADING_SESSION_TYPE, RATE_SCOPE, RATE_TYPE_ID, TIER_ID, RATE)
VALUES (84, 'S', 263208, 'H', 'G', 'G', 'COML', 1, 0.85);


INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
VALUES (1, 'S', 263201, 'L', 'G', 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (9, 'S', 263201, 'H', 'G', 0.4);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (17, 'S', 263205, 'L', 'G', 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (25, 'S', 263205, 'H', 'G', 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (33, 'S', 263206, 'L', 'G', 0.25);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (41, 'S', 263206, 'H', 'G', 0.75);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (49, 'S', 263207, 'L', 'G', 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (57, 'S', 263207, 'H', 'G', 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (65, 'S', 263208, 'L', 'G', 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (73, 'S', 263208, 'H', 'G', 0.65);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (81, 'S', 263208, 'L', 'G', 0.15);
INSERT INTO GENESIS2_QA_20100601.ACCT_COMM_EQT_RATE
(RATE_ID, ACCOUNT_EDIT_SCOPE_ID, ACCOUNT_ID, TOUCH_TYPE_ID, RATE_SCOPE, RATE)
values (89, 'S', 263208, 'H', 'G', 0.65);



SELECT rate, optr.account_id, optr.touch_type_id, optr.trading_session_type
    INTO l_rate
    FROM (SELECT optr.rate, optr.account_id, optr.touch_type_id, optr.trading_session_type
          FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                   JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
          WHERE 1=1
--               amd optr.account_id = in_account_id
--             AND optr.touch_type_id = l_touch_type_id
--             AND optr.trading_session_type = in_trading_session_type
            and optr.rate_scope = 'G'
--             and prt.min_price < in_price
          ORDER BY prt.min_price DESC)
    WHERE ROWNUM = 1;



----


    -- 1. Визначити TOUCH_TYPE_ID
    SELECT C.TOUCH_TYPE_ID

    FROM GENESIS2_QA_20100601.EXCHANGE E
             JOIN GENESIS2_QA_20100601.EX_DESTINATION D ON D.EXCHANGE_ID = E.EXCHANGE_ID
             JOIN GENESIS2_QA_20100601.EX_DESTINATION_CODE C ON C.EX_DESTINATION_CODE = D.EX_DESTINATION_CODE
             JOIN GENESIS2_QA_20100601.RISK_MGMT_TOUCH_TYPE T ON C.TOUCH_TYPE_ID = T.TOUCH_TYPE_ID
    WHERE E.IS_DELETED = 'N'
      AND E.IS_ACTIVE = 'Y'
      AND D.IS_DELETED = 'N'
      AND C.IS_DELETED = 'N'
      AND E.EXCHANGE_ID = 'SQHT'
      AND ROWNUM = 1;

    -- 2. Отримати всі релевантні symbol_list_id
    SELECT count(*)
--     INTO l_symbol_list_id_cnt
    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
             JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = 'VB1'
      AND sl.instrument_type_id = 'O'
      AND ac.account_id = 263201


    -- 3. Знайти rate
    if in_instrument_type = 'O' then
        SELECT rate

        FROM (SELECT optr.rate, optr.tier_id, optr.touch_type_id, optr.trading_session_type, optr.rate_scope, prt.min_price
              FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                       JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = 263201
                AND optr.touch_type_id = 'H'
                AND optr.trading_session_type = 'R'
  and optr.rate_scope = 'G'
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
                and optr.rate_scope = 'G'
                )
        WHERE ROWNUM = 1;
    end if;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; -- або -1, або підставна ставка
    WHEN OTHERS THEN
        -- лог або трасування, якщо потрібно
        RAISE;
END;


CREATE OR REPLACE FUNCTION GENESIS2.get_commission_rate(
    in_exchange_id VARCHAR2,
    in_symbol VARCHAR2,
    in_instrument_type CHAR,
    in_account_id NUMBER,
    in_trading_session_type CHAR,
    in_price number
) RETURN NUMBER
    IS
    l_touch_type_id      GENESIS2_QA_20100601.EX_DESTINATION_CODE.TOUCH_TYPE_ID%TYPE;
    l_rate               GENESIS2_QA_20100601.acct_comm_opt_rate.rate%TYPE;

    -- Для збереження списку symbol_list_id
    TYPE t_symbol_list_ids IS TABLE OF GENESIS2_QA_20100601.acct_comm_opt_rate.symbol_list_id%TYPE
        INDEX BY PLS_INTEGER;
--     l_symbol_list_id_arr t_symbol_list_ids;
--     l_is_list_found      BOOLEAN := FALSE;
    l_symbol_list_id_cnt number;
BEGIN
    -- 1. Визначити TOUCH_TYPE_ID
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

    -- 2. Отримати всі релевантні symbol_list_id
    SELECT count(*)
    INTO l_symbol_list_id_cnt
    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
             JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = in_symbol
      AND sl.instrument_type_id = in_instrument_type
      AND ac.account_id = in_account_id;


    -- 3. Знайти rate
    if in_instrument_type = 'O' then
        SELECT rate
        INTO l_rate
        FROM (SELECT optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                       JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND optr.trading_session_type = in_trading_session_type
                AND case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN (SELECT optr.symbol_list_id
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
                                                                                    AND sl.instrument_type_id = in_instrument_type
                                                                                    AND ac.account_id = in_account_id)
                            then 1
                        when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
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
                and optr.rate_scope = 'G'
                )
        WHERE ROWNUM = 1;
    end if;

    RETURN l_rate;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;


update GENESIS2_QA_20100601.sg_account
set OPT_CUSTOMER_OR_FIRM = '0'
where OPT_CUSTOMER_OR_FIRM <> '8';


drop FUNCTION GENESIS2_QA_20100601.get_commission_rate;
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
--     l_symbol_list_id_arr t_symbol_list_ids;
--     l_is_list_found      BOOLEAN := FALSE;
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
    SELECT count(*)
    INTO l_symbol_list_id_cnt
    FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
             JOIN GENESIS2_JAVA_TEST.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
             JOIN GENESIS2_QA_20100601.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
             JOIN GENESIS2_QA_20100601.account ac ON ac.trading_firm_id = tf.trading_firm_id
    WHERE sl.is_deleted = 'N'
      AND asl.symbol = in_symbol
      and case when asl.SYMBOL_SUFFIX is null then 'no_symbol' else asl.SYMBOL_SUFFIX end = in_symbol_suffix
      AND sl.instrument_type_id = in_instrument_type
      AND ac.account_id = in_account_id;


    -- 3. GET rate
    if in_instrument_type = 'O' then
        SELECT rate
        INTO l_rate
        FROM (SELECT optr.rate
              FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
                       JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND optr.trading_session_type = in_trading_session_type
                AND case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN (SELECT optr.symbol_list_id
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
                                                                                                then 'no_symbol'
                                                                                            else asl.SYMBOL_SUFFIX end =
                                                                                        in_symbol_suffix
                                                                                    AND sl.instrument_type_id = in_instrument_type
                                                                                    AND ac.account_id = in_account_id)
                            then 1
                        when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
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