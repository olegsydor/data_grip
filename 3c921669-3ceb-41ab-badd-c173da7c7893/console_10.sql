SELECT * FROM ALL_source WHERE UPPER(text) LIKE '%CAPACITY_GROUP_ID%'
and owner = 'GENESIS2_QA_20100601'

select * from CLEARING_ACCOUNT
    where ACCOUNT_ID = 21
and IS_DELETED = 'N';

select *
    from CAPACITY_GROUP
    where IS_DELETED <> 'Y';

SELECT * FROM all_tab_columns
where COLUMN_NAME like '%CUSTOMER_OR_FIRM_ID%'
and owner = 'GENESIS2_QA_20100601';

select * from CUSTOMER_OR_FIRM

select * from EXCHANGE2CUSTOMER_OR_FIRM

    SELECT *
    from account acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;



CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.GET_ACCOUNT_STATIC_DATA(
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
    l_client_opt_cust_or_firm varchar2(20)  := '';
    l_eq_order_capacity       char;
    l_opt_sub_acc             varchar2(256) := '';


begin
    -- 20260123 SO https://dashfinancial.atlassian.net/browse/D360-16939
    -- 20260323 SO https://dashfinancial.atlassian.net/browse/DS-11281 based on get_data_for_delayed_drop
    -- 20260408 SO https://dashfinancial.atlassian.net/browse/DS-11363 Add logic to return `OPT_SUB_ACC`


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


    -- Add logic to return `OPT_SUB_ACC`
    if in_instrument_type = 'O' and
       l_opt_customer_or_firm in
       (select CUSTOMER_OR_FIRM_ID from CUSTOMER_OR_FIRM where CAPACITY_GROUP_ID in (4)) then
        SELECT max(stv.TAG_VALUE)
        into l_opt_sub_acc
        FROM ACCOUNT2EXCHANGE ae
                 join SPECIFIC_TAG_SET sts
                      on sts.specific_tag_set_id = ae.specific_tag_set_id -- SO. Probably this join is only for check if specific_tag_set_id is allowed
                 join SPECIFIC_TAG_VALUE stv on stv.specific_tag_set_id = ae.specific_tag_set_id
        where 1 = 1
          and ae.account_id = in_account_id
          and ae.exchange_id = in_exchange_id
          and stv.tag_number = case
                                   when ae.exchange_id in ('AMEXP', 'ARCAP') then 50
                                   else 440 end;
    end if;


    select '{' ||
-- OPTIONS
           '"ACCOUNT": "' || l_account || '",' || -- +++
           '"OPT_EXEC_BROKER": "' || l_opt_exec_broker || '",' || -- +++
           '"OPT_IS_FIX_EXECBROK_PROCESSED": "' || l_opt_is_fix_execbrok_pr || '",' || -- +++
           '"OPT_CLEARING_FIRM": "' || l_clearing_firm || '",' || -- +++
           '"OPT_IS_FIX_CLFIRM_PROCESSED": "' || l_opt_is_fix_clfirm_pr || '",' || -- +++
           '"OPT_CUST_OR_FIRM": "' || l_opt_customer_or_firm || '",' || -- +++
           '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "' || l_opt_is_fix_custfirm_pr || '",' || -- +++
           '"OPT_OCC_ID": "' || l_opt_occ_id || '",' || -- +++
           '"OPT_SUB_ACC": "' || l_opt_sub_acc || '",' || -- +++
-- EQUITIES
           '"EQ_MPID": "' || l_eq_mpid || '",' || -- +++
           '"EQ_ORDER_CAPACITY": "' || l_client_opt_cust_or_firm || -- +++
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
