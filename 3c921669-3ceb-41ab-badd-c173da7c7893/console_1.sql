select GENESIS2_QA_20100601.get_sg_account(256639, 'O', '733', 'EMLD')
from dual;

   select coalesce(ch.SG_SUB_ACCOUNT, pa.SG_SUB_ACCOUNT, 'null'),
           coalesce(ch.SG_MINT_ACCOUNT, pa.SG_SUB_ACCOUNT, 'null'),
           coalesce(ch.SG_SALES_TRADER_ID, pa.SG_SUB_ACCOUNT, 'null')
--     into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
             left join GENESIS2_QA_20100601.SG_ACCOUNT pa on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = 256639;

CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_sg_account(
    in_account_id NUMBER,
    in_instrument_type CHAR,
    in_opt_exec_broker VARCHAR2,
    in_exchange_id VARCHAR2
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
    l_exec_broker            varchar2(40);
    l_clearing_firm          varchar2(40);
    l_sg_sub_account         varchar2(10);
    l_sg_mint_account        varchar2(20);
    l_sg_sales_trader_id     varchar2(20);
    l_opt_clearing_firm      varchar2(20);
    l_client_cust_or_firm    varchar2(20);
    l_opt_exec_broker        varchar2(20);
    l_return                 varchar2(1500) := 'XYZ';

BEGIN
    SELECT
        -- acc.ACCOUNT_NAME accountName,
        acc.OPT_CUSTOMER_OR_FIRM,
        acc.OPT_IS_FIX_EXECBROK_PROCESSED,
        acc.OPT_IS_FIX_CLFIRM_PROCESSED,
        acc.OPT_IS_FIX_CUSTFIRM_PROCESSED,
        acc.TRADING_FIRM_ID,
        acc.eq_mpid,
        acc.opt_occ_id,
        acc.USE_NEW_MODEL
    into l_opt_customer_or_firm, l_opt_is_fix_execbrok_pr, l_opt_is_fix_clfirm_pr, l_opt_is_fix_custfirm_pr, l_trading_firm_id,
        l_eq_mpid, l_opt_occ_id, l_new_model
    FROM GENESIS2_QA_20100601.aCCOUNT acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;

    -- ExecBroker(76)
    IF l_opt_is_fix_execbrok_pr = 'N' THEN
        if l_new_model = 'Y' then
            SELECT OE.OPT_EXEC_BROKER
            into l_opt_exec_broker
            FROM OPT_EXEC_BROKER_CONFIG OE
                     INNER JOIN ACCOUNT2OPT_EXEC_BROKER_CONFIG AO
                                on AO.OPT_EXEC_BROKER_CONFIG_ID = OE.OPT_EXEC_BROKER_CONFIG_ID
            WHERE OE.IS_DELETED = 'N'
              AND AO.ACCOUNT_ID = in_account_id
              AND AO.IS_DEFAULT = 'Y';
        else
            SELECT OPT_EXEC_BROKER
            into l_opt_exec_broker
            FROM OPT_EXEC_BROKER OE
            WHERE OE.IS_DELETED = 'N'
              AND OE.ACCOUNT_ID = in_account_id
              AND OE.IS_DEFAULT = 'Y';
        end if;
--         l_exec_broker := 'new\old model'; --return defaultOptExecBrokerId as OPT_EXEC_BROKER.  (!) new or old model
    ELSE
        l_exec_broker := 'null';
        /* BE will handle by flag */
    end if;

-- II. CustomerOrFirm(204)
    IF coalesce(l_opt_is_fix_clfirm_pr, '-1') != 'N' THEN
        l_opt_is_fix_custfirm_pr := 'null';
    end if;

-- III. ClearingFirm(439)
    IF (in_instrument_type = 'E' or l_opt_is_fix_clfirm_pr != 'N' or in_opt_exec_broker is null) then
        l_clearing_firm := 'null';
    else
        if l_new_model = 'Y' then
            select tv.TAG_VALUE--, abc.ACCOUNT_ID, ocp.EXCHANGE_ID,  obc.OPT_EXEC_BROKER
            into l_clearing_firm
            from GENESIS2_QA_20100601.OPT_EXEC_BROKER_CONFIG obc
                     join GENESIS2_QA_20100601.ACCOUNT2OPT_EXEC_BROKER_CONFIG abc
                          on abc.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.EXEC_BROKER_CONFIG2EXCH_PARAM ocp
                          on ocp.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.SPECIFIC_TAG_VALUE tv
                          on tv.SPECIFIC_TAG_SET_ID = ocp.SPECIFIC_TAG_SET_ID
            where 1=1
              and abc.ACCOUNT_ID = in_account_id
              and obc.OPT_EXEC_BROKER = l_opt_exec_broker
              and ocp.EXCHANGE_ID = in_exchange_id
              and abc.IS_DEFAULT = 'Y'
              and tv.TAG_NUMBER = 439;
        else
            select tv.TAG_VALUE--, abc.ACCOUNT_ID, cp.EXCHANGE_ID,  obc.OPT_EXEC_BROKER
            into l_clearing_firm
            from GENESIS2_QA_20100601.ACCOUNT2OPT_EXEC_BROKER_CONFIG abc
                     join GENESIS2_QA_20100601.OPT_EXEC_BROKER_CONFIG obc
                          on obc.OPT_EXEC_BROKER_CONFIG_ID = abc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.EXEC_BROKER_CONFIG2EXCH_PARAM cp
                          on cp.OPT_EXEC_BROKER_CONFIG_ID = abc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.SPECIFIC_TAG_VALUE tv
                          on tv.SPECIFIC_TAG_SET_ID = cp.SPECIFIC_TAG_SET_ID
            where 1=1
              and abc.ACCOUNT_ID = in_account_id
              and obc.OPT_EXEC_BROKER = l_opt_exec_broker
              and cp.EXCHANGE_ID = in_exchange_id
              and abc.IS_DEFAULT = 'Y'
              and tv.TAG_NUMBER = 439;
        end if;
        if SQL%ROWCOUNT = 0 then
            l_clearing_firm := 'null';
        end if;
    end if;


    --     IV. ActionableID(10440) -- Return acc.opt_occ_id


-- V. SG Account fields
    select coalesce(ch.SG_SUB_ACCOUNT, pa.SG_SUB_ACCOUNT, 'null'),
           coalesce(ch.SG_MINT_ACCOUNT, pa.SG_SUB_ACCOUNT, 'null'),
           coalesce(ch.SG_SALES_TRADER_ID, pa.SG_SUB_ACCOUNT, 'null')
    into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
             left join GENESIS2_QA_20100601.SG_ACCOUNT pa on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = in_account_id;

--     select '{' ||
--            '"OPT_IS_FIX_CLFIRM_PROCESSED": "' || l_opt_is_fix_clfirm_pr || '",' ||
--            '"OPT_CLEARING_FIRM": "' || l_clearing_firm || '",' ||
--            '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "' || l_opt_is_fix_custfirm_pr || '",' ||
--            '"OPT_CUST_OR_FIRM": "' || l_opt_customer_or_firm || '",' ||
--            '"CLIENT_CUST_OR_FIRM": "' || l_client_cust_or_firm || '",' ||
--            '"OPT_IS_FIX_EXECBROK_PROCESSED": "' || l_opt_is_fix_execbrok_pr || '",' ||
--            '"OPT_EXEC_BROKER": "' || l_opt_exec_broker || '",' ||
--            '"OPT_OCC_ID": "' || l_opt_occ_id || '",' ||
--            '"SG_SUB_ACCOUNT": "' || l_sg_sub_account || '",' ||
--            '"SG_MINT_ACCOUNT": "' || l_sg_mint_account || '",' ||
--            '"SG_SALES_TRADER_ID": "' || l_sg_sales_trader_id || '"}'
    select 'XYZ'
    into l_return
    from dual;
DBMS_OUTPUT.PUT_LINE('About to return: ' || l_return);
    return l_return;

--  EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--          RETURN NULL;
--      WHEN OTHERS THEN
--          RAISE;
END;