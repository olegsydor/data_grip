select GENESIS2_QA_20100601.get_sg_account(263201, 'O', '733', 'CDOE')
from dual;


CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_sg_account(
    in_account_id NUMBER,
    in_instrument_type CHAR,
    in_giveup VARCHAR2,
    in_exchange_id VARCHAR2
) RETURN varchar2
    is

    l_opt_customer_or_firm   char;
    l_opt_is_fix_execbrok_pr char;
    l_opt_is_fix_clfirm_pr   char;
    l_opt_is_fix_custfirm_pr char;
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
    l_return                 varchar2(1500);

    BEGIN
    SELECT
        -- acc.ACCOUNT_NAME accountName,
        acc.OPT_CUSTOMER_OR_FIRM,
        acc.OPT_IS_FIX_EXECBROK_PROCESSED,
        acc.OPT_IS_FIX_CLFIRM_PROCESSED,
        acc.OPT_IS_FIX_CUSTFIRM_PROCESSED,
        acc.TRADING_FIRM_ID,
        acc.eq_mpid,
        acc.opt_occ_id
    into l_opt_customer_or_firm, l_opt_is_fix_execbrok_pr, l_opt_is_fix_clfirm_pr, l_opt_is_fix_custfirm_pr, l_trading_firm_id,
        l_eq_mpid, l_opt_occ_id
    FROM GENESIS2_QA_20100601.aCCOUNT acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;

    -- ExecBroker(76)
    IF l_opt_is_fix_execbrok_pr = 'N' THEN
        l_exec_broker := 'new\old model'; --return defaultOptExecBrokerId as OPT_EXEC_BROKER.  (!) new or old model
    ELSE
        l_exec_broker := 'null';
        /* BE will handle by flag */
    end if;

-- II. CustomerOrFirm(204)
    IF l_opt_is_fix_clfirm_pr != 'N' THEN
        l_opt_is_fix_custfirm_pr := 'null';
    end if;

-- III. ClearingFirm(439)
    IF in_instrument_type = 'E' or l_opt_is_fix_clfirm_pr != 'N' then
        l_clearing_firm := null;
    else
        l_clearing_firm := 'find exact value';
    end if;

    --     IV. ActionableID(10440) -- Return acc.opt_occ_id


-- V. SG Account fields
    select coalesce(ch.SG_SUB_ACCOUNT, pa.SG_SUB_ACCOUNT),
           coalesce(ch.SG_MINT_ACCOUNT, pa.SG_SUB_ACCOUNT),
           coalesce(ch.SG_SALES_TRADER_ID, pa.SG_SUB_ACCOUNT)
    into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
             left join GENESIS2_QA_20100601.SG_ACCOUNT pa on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = in_account_id;

    select '{' ||
           '"OPT_IS_FIX_CLFIRM_PROCESSED": "'|| l_opt_is_fix_clfirm_pr || '",' ||
           '"OPT_CLEARING_FIRM": "'|| l_opt_clearing_firm || '",' ||
           '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "'|| l_opt_is_fix_custfirm_pr || '",' ||
           '"OPT_CUST_OR_FIRM": "'|| l_opt_customer_or_firm || '",' ||
           '"CLIENT_CUST_OR_FIRM": "'|| l_client_cust_or_firm || '",' ||
           '"OPT_IS_FIX_EXECBROK_PROCESSED": "'|| l_opt_is_fix_execbrok_pr || '",' ||
           '"OPT_EXEC_BROKER": "'|| l_opt_exec_broker || '",' ||
           '"OPT_OCC_ID": "'|| l_opt_occ_id || '",' ||
           '"SG_SUB_ACCOUNT": "'|| l_sg_sub_account || '",' ||
           '"SG_MINT_ACCOUNT": "'|| l_sg_mint_account || '",' ||
           '"SG_SALES_TRADER_ID": "'|| l_sg_sales_trader_id|| '"}'
    into l_return
    from dual;

    return l_return;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;

    {"OPT_IS_FIX_CLFIRM_PROCESSED": N,"OPT_CLEARING_FIRM": ,"OPT_IS_FIX_CUSTFIRM_PROCESSED": Y,"OPT_CUST_OR_FIRM": ,"CLIENT_CUST_OR_FIRM": ,"OPT_IS_FIX_EXECBROK_PROCESSED": N,"OPT_EXEC_BROKER": ,"OPT_OCC_ID": ,"SG_SUB_ACCOUNT": ,"SG_MINT_ACCOUNT": ,"SG_SALES_TRADER_ID": lee.cashin}{"OPT_IS_FIX_CLFIRM_PROCESSED": N,"OPT_CLEARING_FIRM": ,"OPT_IS_FIX_CUSTFIRM_PROCESSED": Y,"OPT_CUST_OR_FIRM": ,"CLIENT_CUST_OR_FIRM": ,"OPT_IS_FIX_EXECBROK_PROCESSED": N,"OPT_EXEC_BROKER": ,"OPT_OCC_ID": ,"SG_SUB_ACCOUNT": ,"SG_MINT_ACCOUNT": ,"SG_SALES_TRADER_ID": lee.cashin}