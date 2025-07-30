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


select optr.rate, optr.symbol_list_id
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
  AND ac.account_id = 10349