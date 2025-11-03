SELECT optr.rate, prt.min_price, optr.*, prt.*
FROM GENESIS2_QA_20100601.acct_comm_opt_rate optr
         JOIN GENESIS2_QA_20100601.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
WHERE optr.account_id = :in_account_id
  AND optr.touch_type_id = :l_touch_type_id
  AND optr.trading_session_type = :in_trading_session_type
  and case when :in_rate_type_id is null then optr.RATE_TYPE_ID else :in_rate_type_id end = optr.RATE_TYPE_ID

  AND case
          when :l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN
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
                                                AND asl.symbol = :in_symbol
                                                and case
                                                        when :in_symbol_suffix is null then asl.SYMBOL_SUFFIX
                                                        else :in_symbol_suffix end = asl.SYMBOL_SUFFIX
                                                AND sl.instrument_type_id = :in_instrument_type
                                                AND ac.account_id = :in_account_id)
              then 1
          when :l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
          else 0 end = 1

  and prt.min_price <= :in_price
ORDER BY prt.min_price desc