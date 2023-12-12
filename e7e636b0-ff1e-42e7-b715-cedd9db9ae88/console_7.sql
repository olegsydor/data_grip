-- FUNCTION getClearingTemplateCheck RETURN REF_CURSOR IS
--     rs REF_CURSOR;
-- BEGIN
--
-- 	OPEN rs FOR
select * from
((select
    ACCT.ACCOUNT_NAME,
    TF.TRADING_FIRM_NAME,
    DIFF.OPT_EXEC_BROKER,
    CF.OPT_EXEC_BROKER_CONFIG_NAME,
    DIFF.EXCHANGE_ID,
    DIFF.TAG_NUMBER,
    ORIG.TAG_VALUE as tag_value,
    DIFF.TAG_VALUE as config_tag_value
  from
    (
      select * from (
          SELECT  C.ACCOUNT_ID, D.OPT_EXEC_BROKER, E.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM genesis2.ACCOUNT A, staging.ACCOUNT2OPT_EXEC_BROKER_CONFIG C, staging.OPT_EXEC_BROKER_CONFIG D, staging.EXEC_BROKER_CONFIG2EXCH_PARAM E, staging.SPECIFIC_TAG_VALUE S
          WHERE
          C.ACCOUNT_ID = A.ACCOUNT_ID
          AND C.OPT_EXEC_BROKER_CONFIG_ID = D.OPT_EXEC_BROKER_CONFIG_ID
          AND D.IS_DELETED = 'N'
          AND C.OPT_EXEC_BROKER_CONFIG_ID = E.OPT_EXEC_BROKER_CONFIG_ID
          AND S.SPECIFIC_TAG_SET_ID = E.SPECIFIC_TAG_SET_ID
          AND A.IS_DELETED = 'N'
      )
      minus
      select * from (
          SELECT O.ACCOUNT_ID, O.OPT_EXEC_BROKER, P.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM OPT_EXEC_BROKER O, OPT_EXEC_BROKER2EXCHANGE_PARAM P, SPECIFIC_TAG_VALUE S, ACCOUNT A
          WHERE
          A.IS_DELETED = 'N'
          AND A.ACCOUNT_ID = O.ACCOUNT_ID
          AND O.ACCOUNT_ID in (SELECT UNIQUE(ACCOUNT_ID) FROM ACCOUNT2OPT_EXEC_BROKER_CONFIG)
          AND O.IS_DELETED = 'N'
          AND O.OPT_EXEC_BROKER_ID = P.OPT_EXEC_BROKER_ID
          AND P.SPECIFIC_TAG_SET_ID = S.SPECIFIC_TAG_SET_ID
      )
    ) DIFF
  LEFT JOIN
      (select * from
        (
          SELECT O.ACCOUNT_ID, O.OPT_EXEC_BROKER, P.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM staging.OPT_EXEC_BROKER O, staging.OPT_EXEC_BROKER2EXCHANGE_PARAM P, staging.SPECIFIC_TAG_VALUE S, ACCOUNT A
          WHERE
          A.IS_DELETED = 'N'
          AND A.ACCOUNT_ID = O.ACCOUNT_ID
          AND O.ACCOUNT_ID in (SELECT UNIQUE(ACCOUNT_ID) FROM ACCOUNT2OPT_EXEC_BROKER_CONFIG)
          AND O.IS_DELETED = 'N'
          AND O.OPT_EXEC_BROKER_ID = P.OPT_EXEC_BROKER_ID
          AND P.SPECIFIC_TAG_SET_ID = S.SPECIFIC_TAG_SET_ID
        )
      ) ORIG
  ON
    DIFF.ACCOUNT_ID = ORIG.ACCOUNT_ID
    and DIFF.OPT_EXEC_BROKER = ORIG.OPT_EXEC_BROKER
    and DIFF.EXCHANGE_ID = ORIG.EXCHANGE_ID
    and DIFF.TAG_NUMBER = ORIG.TAG_NUMBER
  JOIN ACCOUNT ACCT ON DIFF.ACCOUNT_ID = ACCT.ACCOUNT_ID
  JOIN TRADING_FIRM TF ON TF.TRADING_FIRM_ID = ACCT.TRADING_FIRM_ID
  JOIN ACCOUNT2OPT_EXEC_BROKER_CONFIG ACF ON ACF.ACCOUNT_ID = DIFF.ACCOUNT_ID
  JOIN OPT_EXEC_BROKER_CONFIG CF ON CF.OPT_EXEC_BROKER_CONFIG_ID = ACF.OPT_EXEC_BROKER_CONFIG_ID AND CF.OPT_EXEC_BROKER = DIFF.OPT_EXEC_BROKER
)
union
(
select
    ACCT.ACCOUNT_NAME,
    TF.TRADING_FIRM_NAME,
    DIFF.OPT_EXEC_BROKER,
    CF.OPT_EXEC_BROKER_CONFIG_NAME,
    DIFF.EXCHANGE_ID,
    DIFF.TAG_NUMBER,
    DIFF.TAG_VALUE as tag_value,
    ORIG.TAG_VALUE as config_tag_value
  from
    (
      select * from (
          SELECT O.ACCOUNT_ID, O.OPT_EXEC_BROKER, P.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM OPT_EXEC_BROKER O, OPT_EXEC_BROKER2EXCHANGE_PARAM P, SPECIFIC_TAG_VALUE S, ACCOUNT A
          WHERE
          A.IS_DELETED = 'N'
          AND A.ACCOUNT_ID = O.ACCOUNT_ID
          AND O.ACCOUNT_ID in (SELECT UNIQUE(ACCOUNT_ID) FROM ACCOUNT2OPT_EXEC_BROKER_CONFIG)
          AND O.IS_DELETED = 'N'
          AND O.OPT_EXEC_BROKER_ID = P.OPT_EXEC_BROKER_ID
          AND P.SPECIFIC_TAG_SET_ID = S.SPECIFIC_TAG_SET_ID
      )

      minus

      select * from (
          SELECT  C.ACCOUNT_ID, D.OPT_EXEC_BROKER, E.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM ACCOUNT A, ACCOUNT2OPT_EXEC_BROKER_CONFIG C, OPT_EXEC_BROKER_CONFIG D, EXEC_BROKER_CONFIG2EXCH_PARAM E, SPECIFIC_TAG_VALUE S
          WHERE
          C.ACCOUNT_ID = A.ACCOUNT_ID
          AND C.OPT_EXEC_BROKER_CONFIG_ID = D.OPT_EXEC_BROKER_CONFIG_ID
          AND D.IS_DELETED = 'N'
          AND C.OPT_EXEC_BROKER_CONFIG_ID = E.OPT_EXEC_BROKER_CONFIG_ID
          AND S.SPECIFIC_TAG_SET_ID = E.SPECIFIC_TAG_SET_ID
          AND A.IS_DELETED = 'N'
      )
    ) DIFF

  LEFT JOIN
      (select * from
        (
          SELECT  C.ACCOUNT_ID, D.OPT_EXEC_BROKER, E.EXCHANGE_ID, S.TAG_NUMBER, S.TAG_VALUE
          FROM ACCOUNT A, ACCOUNT2OPT_EXEC_BROKER_CONFIG C, OPT_EXEC_BROKER_CONFIG D, EXEC_BROKER_CONFIG2EXCH_PARAM E, SPECIFIC_TAG_VALUE S
          WHERE
          C.ACCOUNT_ID = A.ACCOUNT_ID
          AND C.OPT_EXEC_BROKER_CONFIG_ID = D.OPT_EXEC_BROKER_CONFIG_ID
          AND D.IS_DELETED = 'N'
          AND C.OPT_EXEC_BROKER_CONFIG_ID = E.OPT_EXEC_BROKER_CONFIG_ID
          AND S.SPECIFIC_TAG_SET_ID = E.SPECIFIC_TAG_SET_ID
          AND A.IS_DELETED = 'N'
        )
      ) ORIG
  ON
    DIFF.ACCOUNT_ID = ORIG.ACCOUNT_ID
    and DIFF.OPT_EXEC_BROKER = ORIG.OPT_EXEC_BROKER
    and DIFF.EXCHANGE_ID = ORIG.EXCHANGE_ID
    and DIFF.TAG_NUMBER = ORIG.TAG_NUMBER

  JOIN ACCOUNT ACCT ON DIFF.ACCOUNT_ID = ACCT.ACCOUNT_ID
  JOIN TRADING_FIRM TF ON TF.TRADING_FIRM_ID = ACCT.TRADING_FIRM_ID
  JOIN ACCOUNT2OPT_EXEC_BROKER_CONFIG ACF ON ACF.ACCOUNT_ID = DIFF.ACCOUNT_ID
  JOIN OPT_EXEC_BROKER_CONFIG CF ON CF.OPT_EXEC_BROKER_CONFIG_ID = ACF.OPT_EXEC_BROKER_CONFIG_ID AND CF.OPT_EXEC_BROKER = DIFF.OPT_EXEC_BROKER
))
order by 1,2,3,4;