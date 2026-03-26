CREATE OR REPLACE FUNCTION GET_ACCOUNT_STATIC_DATA(
    in_account_id NUMBER,
    in_instrument_type CHAR,
    in_opt_exec_broker VARCHAR2,
    in_exchange_id VARCHAR2
) RETURN varchar2
    is
    l_account                 varchar2(30);
    l_new_model               char;
    l_opt_customer_or_firm    varchar2(10);
    l_opt_is_fix_execbrok_pr  varchar2(10);
    l_opt_is_fix_clfirm_pr    varchar2(10);
    l_opt_is_fix_custfirm_pr  varchar2(10);
    l_trading_firm_id         varchar2(9);
    l_eq_mpid                 varchar2(4);
    l_opt_occ_id              varchar2(40);
    l_clearing_firm           varchar2(40);
    l_opt_exec_broker         varchar2(20);
    l_return                  varchar2(1500);
    l_client_opt_cust_or_firm varchar2(20) := '';
    l_eq_order_capacity       char;


begin
    -- 20260123 SO https://dashfinancial.atlassian.net/browse/D360-16939
    -- 20260323 SO https://dashfinancial.atlassian.net/browse/DS-11281 based on get_data_for_delayed_drop


    SELECT max(acc.ACCOUNT_NAME),
           max(acc.OPT_CUSTOMER_OR_FIRM),
           max(coalesce(acc.OPT_IS_FIX_EXECBROK_PROCESSED, 'N')),
           max(coalesce(acc.OPT_IS_FIX_CLFIRM_PROCESSED, 'N')),
           max(coalesce(acc.OPT_IS_FIX_CUSTFIRM_PROCESSED, 'N')),
           max(acc.TRADING_FIRM_ID),
           max(acc.eq_mpid),
           max(acc.opt_occ_id),
           max(acc.EQ_ORDER_CAPACITY),
           max(coalesce(acc.USE_NEW_MODEL, 'N'))
    into
        l_account,
        l_opt_customer_or_firm,
        l_opt_is_fix_execbrok_pr,
        l_opt_is_fix_clfirm_pr,
        l_opt_is_fix_custfirm_pr,
        l_trading_firm_id,
        l_eq_mpid,
        l_opt_occ_id,
        l_eq_order_capacity,
        l_new_model
    from account acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;


    IF l_opt_is_fix_execbrok_pr = 'N' OR in_opt_exec_broker IS NULL THEN

        SELECT max(OPT_EXEC_BROKER)
        into l_opt_exec_broker
        FROM OPT_EXEC_BROKER OE
        WHERE OE.IS_DELETED = 'N'
          AND OE.ACCOUNT_ID = in_account_id
          AND OE.IS_DEFAULT = 'Y';

    ELSE
        l_opt_exec_broker := in_opt_exec_broker;

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


    select '{' ||
-- OPTIONS
           '"ACCOUNT": "' || l_account || '",' ||                                      -- +++
           '"OPT_EXEC_BROKER": "' || l_opt_exec_broker || '",' ||                      -- +++
           '"OPT_IS_FIX_EXECBROK_PROCESSED": "' || l_opt_is_fix_execbrok_pr || '",' || -- +++
           '"OPT_CLEARING_FIRM": "' || l_clearing_firm || '",' ||                      -- +++
           '"OPT_IS_FIX_CLFIRM_PROCESSED": "' || l_opt_is_fix_clfirm_pr || '",' ||     -- +++
           '"OPT_CUST_OR_FIRM": "' || l_opt_customer_or_firm || '",' ||                -- +++
           '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "' || l_opt_is_fix_custfirm_pr || '",' || -- +++
           '"OPT_OCC_ID": "' || l_opt_occ_id || '",' ||                                -- +++
-- EQUITIES
           '"EQ_MPID": "' || l_eq_mpid || '",' ||                                      -- +++
           '"EQ_ORDER_CAPACITY": "' || l_client_opt_cust_or_firm ||                    -- +++
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