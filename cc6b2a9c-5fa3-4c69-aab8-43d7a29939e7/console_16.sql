DROP FUNCTION GENESIS2.get_commission_rate;

CREATE OR REPLACE FUNCTION GENESIS2.get_commission_rate(
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
    l_touch_type_id      GENESIS2.EX_DESTINATION_CODE.TOUCH_TYPE_ID%TYPE;
    l_rate               GENESIS2.acct_comm_opt_rate.rate%TYPE;

    -- GET symbol_list_id
    TYPE t_symbol_list_ids IS TABLE OF GENESIS2.acct_comm_opt_rate.symbol_list_id%TYPE
        INDEX BY PLS_INTEGER;
    l_symbol_list_id_cnt number;
begin
    -- 20260119 SO https://dashfinancial.atlassian.net/browse/DS-10947 This function is expected to stop being used as soon as the new one is created

    -- 1. GET TOUCH_TYPE_ID
    SELECT C.TOUCH_TYPE_ID
    INTO l_touch_type_id
    FROM GENESIS2.EXCHANGE E
             JOIN GENESIS2.EX_DESTINATION D ON D.EXCHANGE_ID = E.EXCHANGE_ID
             JOIN GENESIS2.EX_DESTINATION_CODE C ON C.EX_DESTINATION_CODE = D.EX_DESTINATION_CODE
             JOIN GENESIS2.RISK_MGMT_TOUCH_TYPE T ON C.TOUCH_TYPE_ID = T.TOUCH_TYPE_ID
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
        FROM GENESIS2.acct_comm_opt_rate optr
                 JOIN GENESIS2.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
                 JOIN GENESIS2.account ac ON ac.trading_firm_id = tf.trading_firm_id
        WHERE sl.is_deleted = 'N'
          AND asl.symbol = in_symbol
          and
            case when in_symbol_suffix is null then coalesce(asl.SYMBOL_SUFFIX, 'no-suffix') else in_symbol_suffix end =
            coalesce(in_symbol_suffix, 'no-suffix')
          AND sl.instrument_type_id = in_instrument_type
          AND ac.account_id = in_account_id;

        SELECT rate
        INTO l_rate
        from (select optr.rate
              from (SELECT 1 as prioritet,
                           optr.rate,
                           prt.min_price
                    FROM GENESIS2.acct_comm_opt_rate optr
                             JOIN GENESIS2.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
                    WHERE optr.account_id = in_account_id
                      AND optr.touch_type_id = l_touch_type_id
                      AND optr.trading_session_type = in_trading_session_type
                      and case when in_rate_type_id is null then optr.RATE_TYPE_ID else in_rate_type_id end =
                          optr.RATE_TYPE_ID
                      AND case
                              when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN
                                                                (SELECT optr.symbol_list_id
                                                                 FROM GENESIS2.acct_comm_opt_rate optr
                                                                          JOIN GENESIS2.acct_comm_symbol_list sl
                                                                               ON optr.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2.symbol2acct_comm_symbol_list asl
                                                                               ON asl.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2.tf2acct_comm_symbol_list tfsl
                                                                               ON tfsl.symbol_list_id = sl.symbol_list_id
                                                                          JOIN GENESIS2.trading_firm tf
                                                                               ON tf.trading_firm_id = tfsl.trading_firm_id
                                                                          JOIN GENESIS2.account ac
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
                    FROM GENESIS2.acct_comm_opt_rate optr
                             JOIN GENESIS2.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
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
        FROM GENESIS2.acct_comm_eqt_rate optr
                 JOIN GENESIS2.acct_comm_symbol_list sl ON optr.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.symbol2acct_comm_symbol_list asl ON asl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.tf2acct_comm_symbol_list tfsl ON tfsl.symbol_list_id = sl.symbol_list_id
                 JOIN GENESIS2.trading_firm tf ON tf.trading_firm_id = tfsl.trading_firm_id
                 JOIN GENESIS2.account ac ON ac.trading_firm_id = tf.trading_firm_id
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
              FROM GENESIS2.acct_comm_eqt_rate optr
--                       JOIN GENESIS2.sg_acct_comm_eqt_rate sacer prt ON prt.tier_id = optr.tier_id
              WHERE optr.account_id = in_account_id
                AND optr.touch_type_id = l_touch_type_id
                AND case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id IN
                                                          (SELECT optr.symbol_list_id
                                                           FROM GENESIS2.acct_comm_eqt_rate optr
                                                                    JOIN GENESIS2.acct_comm_symbol_list sl
                                                                         ON optr.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2.symbol2acct_comm_symbol_list asl
                                                                         ON asl.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2.tf2acct_comm_symbol_list tfsl
                                                                         ON tfsl.symbol_list_id = sl.symbol_list_id
                                                                    JOIN GENESIS2.trading_firm tf
                                                                         ON tf.trading_firm_id = tfsl.trading_firm_id
                                                                    JOIN GENESIS2.account ac
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

DROP FUNCTION GENESIS2.get_sg_account;
CREATE OR REPLACE FUNCTION GENESIS2.get_sg_account(
    in_account_id NUMBER,
    in_instrument_type CHAR,
    in_opt_exec_broker VARCHAR2,
    in_exchange_id VARCHAR2,
    in_dash_broker varchar2 default null
) RETURN varchar2
    is

    l_opt_customer_or_firm   varchar2(10);
    l_opt_is_fix_execbrok_pr varchar2(10);
    l_opt_is_fix_clfirm_pr   varchar2(10);
    l_opt_is_fix_custfirm_pr varchar2(10);
    l_new_model              char;
    l_trading_firm_id        varchar2(9);
    l_eq_mpid                varchar2(4);
    l_opt_occ_id             varchar2(40);
    l_clearing_firm          varchar2(40);
    l_sg_sub_account         varchar2(10);
    l_sg_mint_account        varchar2(20);
    l_sg_sales_trader_id     varchar2(20);
    l_client_cust_or_firm    varchar2(20) := '';
    l_opt_exec_broker        varchar2(20);
    l_return                 varchar2(1500);
    l_parent_sub_account     integer;
    l_parent_mint_account    integer;
    l_parent_sales_trader_id integer;
    l_opt_dash_broker        varchar2(20) := '';

begin

    SELECT
        -- acc.ACCOUNT_NAME accountName,
        max(acc.OPT_CUSTOMER_OR_FIRM),
        max(coalesce(acc.OPT_IS_FIX_EXECBROK_PROCESSED, 'N')),
        max(coalesce(acc.OPT_IS_FIX_CLFIRM_PROCESSED, 'N')),
        max(coalesce(acc.OPT_IS_FIX_CUSTFIRM_PROCESSED, 'N')),
        max(acc.TRADING_FIRM_ID),
        max(acc.eq_mpid),
        max(acc.opt_occ_id),
        max(coalesce(acc.USE_NEW_MODEL, 'N'))
    into l_opt_customer_or_firm, l_opt_is_fix_execbrok_pr, l_opt_is_fix_clfirm_pr, l_opt_is_fix_custfirm_pr, l_trading_firm_id,
        l_eq_mpid, l_opt_occ_id, l_new_model
    FROM aCCOUNT acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;

    -- ExecBroker(76)

    if in_dash_broker is not null then
        select max(OPT_EXEC_BROKER)
        into l_opt_dash_broker
        from SG_DASH_EXEC_BROKER_MAP
        where DASH_EXEC_BROKER = IN_DASH_BROKER
          and TRADING_FIRM_ID = (select TRADING_FIRM_ID from SG_ACCOUNT where ACCOUNT_ID = in_account_id);
    end if;

    IF l_opt_is_fix_execbrok_pr = 'N' OR in_opt_exec_broker IS NULL THEN
        -- The OPT_EXEC_BROKER view needs to be used. All the logic regarding new/old model hiden inside

        SELECT max(OPT_EXEC_BROKER)
        into l_opt_exec_broker
        FROM OPT_EXEC_BROKER OE
        WHERE OE.IS_DELETED = 'N'
          AND OE.ACCOUNT_ID = in_account_id
          AND OE.IS_DEFAULT = 'Y';

        --        if l_new_model = 'Y' then
--            SELECT max(OE.OPT_EXEC_BROKER)
--            into l_opt_exec_broker
--            FROM GENESIS2_QA_20100601.OPT_EXEC_BROKER_CONFIG OE
--                     INNER JOIN GENESIS2_QA_20100601.ACCOUNT2OPT_EXEC_BROKER_CONFIG AO
--                                on AO.OPT_EXEC_BROKER_CONFIG_ID = OE.OPT_EXEC_BROKER_CONFIG_ID
--            WHERE OE.IS_DELETED = 'N'
--              AND AO.ACCOUNT_ID = in_account_id
--              AND AO.IS_DEFAULT = 'Y';
--        else
--            SELECT max(OPT_EXEC_BROKER)
--            into l_opt_exec_broker
--            FROM OPT_EXEC_BROKER OE
--            WHERE OE.IS_DELETED = 'N'
--              AND OE.ACCOUNT_ID = in_account_id
--              AND OE.IS_DEFAULT = 'Y';
--        end if;
    ELSE
        -- l_opt_exec_broker := 'null';
        l_opt_exec_broker := in_opt_exec_broker;

    end if;

-- II. CustomerOrFirm(204)
    IF l_opt_is_fix_custfirm_pr = 'Y' THEN
        -- l_opt_is_fix_custfirm_pr := 'null';
        -- l_client_cust_or_firm := 'null';
        l_opt_customer_or_firm := '';
    end if;

-- III. ClearingFirm(439)

    IF (in_instrument_type = 'E' or l_opt_is_fix_clfirm_pr = 'Y' or l_opt_exec_broker is null) then
        l_clearing_firm := '';
    else
        if l_new_model = 'Y' then
            select max(tv.TAG_VALUE)--, abc.ACCOUNT_ID, ocp.EXCHANGE_ID,  obc.OPT_EXEC_BROKER
            into l_clearing_firm
            from OPT_EXEC_BROKER_CONFIG obc
                     join ACCOUNT2OPT_EXEC_BROKER_CONFIG abc
                          on abc.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join EXEC_BROKER_CONFIG2EXCH_PARAM ocp
                          on ocp.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join SPECIFIC_TAG_VALUE tv on tv.SPECIFIC_TAG_SET_ID = ocp.SPECIFIC_TAG_SET_ID
            where 1 = 1
              and abc.ACCOUNT_ID = in_account_id
              and obc.OPT_EXEC_BROKER = l_opt_exec_broker
              and ocp.EXCHANGE_ID = in_exchange_id
              and abc.IS_DEFAULT = 'Y'
              and tv.TAG_NUMBER = 439;
        else
            select max(stv.TAG_VALUE)
            into l_clearing_firm
            from OPT_EXEC_BROKER_OLD od
                     join OPT_EXEC_BROKER2EXCH_PARAM_OLD ep on ep.OPT_EXEC_BROKER_ID = od.OPT_EXEC_BROKER_ID
                     join SPECIFIC_TAG_VALUE stv on stv.SPECIFIC_TAG_SET_ID = ep.SPECIFIC_TAG_SET_ID
            where od.ACCOUNT_ID = in_account_id
              and od.OPT_EXEC_BROKER = l_opt_exec_broker
              and ep.EXCHANGE_ID = in_exchange_id
              and od.IS_DEFAULT = 'Y'
              and stv.TAG_NUMBER = 439
              and od.is_deleted = 'N';
        end if;
    end if;


    --     IV. ActionableID(10440)


-- V. SG Account fields

/*
 * this piece of code should be used instead of the next 7 rows when SG_NULL_ACCOUNT_PARAMETER is present in DB (OS)
 * https://dashfinancial.atlassian.net/browse/DS-10332
*/
    select sum(case when DB_FIELD_NAME = 'SG_SUB_ACCOUNT' then 1 else 0 end),
           sum(case when DB_FIELD_NAME = 'SG_MINT_ACCOUNT' then 1 else 0 end),
           sum(case when DB_FIELD_NAME = 'SG_SALES_TRADER_ID' then 1 else 0 end)
    into l_parent_sub_account, l_parent_mint_account, l_parent_sales_trader_id
    from SG_NULL_ACCOUNT_PARAMETER
    where ACCOUNT_ID = in_account_id;

    select MAX(coalesce(ch.SG_SUB_ACCOUNT, case when l_parent_sub_account = 0 then pa.SG_SUB_ACCOUNT end)),
           MAX(coalesce(ch.SG_MINT_ACCOUNT, case when l_parent_MINT_ACCOUNT = 0 then pa.SG_MINT_ACCOUNT end)),
           MAX(coalesce(ch.SG_SALES_TRADER_ID, case when l_parent_SALES_TRADER_ID = 0 then pa.SG_SALES_TRADER_ID end))
    into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from SG_ACCOUNT ch
             left join SG_ACCOUNT pa on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = in_account_id;

/*
    select MAX(coalesce(ch.SG_SUB_ACCOUNT, pa.SG_SUB_ACCOUNT)),
           MAX(coalesce(ch.SG_MINT_ACCOUNT, pa.SG_MINT_ACCOUNT)),
           MAX(coalesce(ch.SG_SALES_TRADER_ID, pa.SG_SALES_TRADER_ID))
    into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from SG_ACCOUNT ch
    left join SG_ACCOUNT pa  on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = in_account_id;
*/

    select '{' ||
           '"OPT_IS_FIX_CLFIRM_PROCESSED": "' || l_opt_is_fix_clfirm_pr || '",' ||
           '"OPT_CLEARING_FIRM": "' || l_clearing_firm || '",' ||
           '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "' || l_opt_is_fix_custfirm_pr || '",' ||
           '"OPT_CUST_OR_FIRM": "' || l_opt_customer_or_firm || '",' ||
           '"CLIENT_CUST_OR_FIRM": "' || l_client_cust_or_firm || '",' ||
           '"OPT_IS_FIX_EXECBROK_PROCESSED": "' || l_opt_is_fix_execbrok_pr || '",' ||
           '"OPT_EXEC_BROKER": "' || l_opt_exec_broker || '",' ||
           '"OPT_OCC_ID": "' || l_opt_occ_id || '",' ||
           '"SG_SUB_ACCOUNT": "' || l_sg_sub_account || '",' ||
           '"SG_MINT_ACCOUNT": "' || l_sg_mint_account || '",' ||
           '"SG_SALES_TRADER_ID": "' || l_sg_sales_trader_id || '",' ||
           '"OPT_EXEC_BROKER_BY_DASH_BROKER": "' || l_opt_dash_broker ||
           '"}'
--select 'DATA'
    into l_return
    from dual;

    return l_return;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'NO DATA';
    WHEN OTHERS THEN
        RAISE;
END;



    select * from LIQUIDITY_INDICATOR
    where EXCHANGE_ID = 'EPRL'
and TRADE_LIQUIDITY_INDICATOR = 'eR'