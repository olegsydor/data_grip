-- function getuserpermissions(p_user_role in character, p_user_name in varchar2 default null) return ref_cursor is
drop function if exists dash360.get_user_permissions;
create function dash360.get_user_permissions(in_user_role varchar(1), in_user_name varchar(30) default null)
    returns table
            (
                user_name   varchar(30),
                first_name  varchar(30),
                last_name   varchar(100),
                is_locked   varchar(1),
                create_time timestamp,
                description varchar(255)
            )
    language plpgsql
as
$fx$
begin
    return query
        select ui.user_name, ui.first_name, ui.last_name, ui.is_locked, ui.date_start as create_time, uf.description
        from dwh.d_user_identifier ui
                 left join dwh.d_user2user_function uuf
                 join dwh.d_user_function uf on uuf.function_id = uf.function_id on ui.user_id = uuf.user_id
        where ui.is_active
          and ui.user_role = in_user_role
          and case when in_user_name is null then true else ui.user_name = in_user_name end
        order by ui.is_locked, ui.user_name, uf.description;
end;
$fx$;
select * from dash360.get_user_permissions('P', 'BARC.jloftus')


     SELECT null as  "StrategyInID",
       SILS.TRANSACTION_ID as "TransactionID",
       SILS.INSTRUMENT_ID as "InstrumentID",
       SILS.L1_SCOPE as "L1Scope",
       SILS.SIDE as "Side",
       SILS.EXCHANGE_ID as "ExchangeID",
       SILS.PRICE as "Price",
       SILS.QUANTITY as "Qty"
   FROM  STRATEGY_ROUTING_TABLE SINO
    inner join STRATEGY_TRANSACTION st on (SINO.transaction_id = ST.transaction_id)
    inner join  STRATEGY_IN_L1_SNAPSHOT_V2 SILS on (SINO.transaction_id = SILS.transaction_id)
   where st.STRATEGY_DATA_MODEL_TYPE=2
   and SINO.INTERNAL_ORDER_ID = p_order_id;


     select co.internal_order_id,
         null              as "StrategyInID",
            co.TRANSACTION_ID as "TransactionID",
            co.INSTRUMENT_ID  as "InstrumentID",
--            ls.exchange_id,
            co.EXCHANGE_ID    as "ExchangeID",
            ls.bid_price      as "Bid Price",
            ls.bid_quantity   as "Bid Qty",
            ls.ask_price      as "Ask Price",
            ls.bid_quantity   as "Ask Qty"
     from dwh.client_order co
              join dwh.l1_snapshot ls
                   on ls.transaction_id = co.transaction_id
                       and ls.start_date_id = co.create_date_id
     where co.create_date_id = 20230629
       and co.internal_order_id = 793027343579

     select * from strategy_transaction_output;


select * from dwh.d_osr_param_dictionary
select * from dwh.d_osr_param_set
select * from dwh.d_routing_table

SELECT
    CASE b.RISK_MGMT_CONF_SCOPE
        WHEN 'T' THEN 'Trading Firm (Cloud)'
        WHEN 'A' THEN 'Account (Cloud)'
        WHEN 'H' THEN 'Account (HFT)'
        WHEN 'B' THEN 'Account (Crosses)'
        WHEN 'U' THEN 'Trading Firm (Crosses)'
        WHEN 'G' THEN 'DASH Global Parametes'
        WHEN 'C' THEN 'Trader (Cloud)'
        WHEN 'D' THEN 'Trader (Crosses)'
    END AS RISK_MGMT_CONF_SCOPE_TEXT,
    tf.TRADING_FIRM_NAME,
    a.ACCOUNT_NAME,
    b.CREATE_TIME,
    CASE b.RISK_CHANGE_TYPE
        WHEN 'P' THEN 'Permanent'
        WHEN 'T' THEN 'Temporary'
    END AS RISK_CHANGE_TYPE,
    CASE b.RISK_CHANGE_REASON
        WHEN 'C' THEN 'Client Request'
        WHEN 'L' THEN 'Limit Breach'
        WHEN 'R' THEN 'Reverting'
        WHEN 'S' THEN 'Soft Limit Breach'
        --WHEN 'A' THEN 'Auto-Reverting'
    END AS RISK_CHANGE_REASON,
    u.USER_NAME,
    u.FIRST_NAME || ' ' || u.LAST_NAME AS full_name,
    t.OSR_PARAM_CODE,
    p.OSR_PARAM_NAME,
    p.OSR_PARAM_TYPE,
    p.OSR_PARAM_DESC,
    t.OSR_PARAM_OLD_VALUE,
    t.OSR_PARAM_NEW_VALUE,
    trd.TRADER_ID
FROM risk_limit_audit_trail t
INNER JOIN RISK_LIMIT_AUDIT_TRAIL_BATCH b ON b.RISK_LIMIT_AUDIT_BATCH_ID=t.RISK_LIMIT_AUDIT_BATCH_ID
LEFT JOIN USER_IDENTIFIER u ON u.USER_ID=b.USER_ID
LEFT JOIN OSR_PARAM_DICTIONARY p ON p.OSR_PARAM_CODE=t.OSR_PARAM_CODE
LEFT JOIN account a ON a.ACCOUNT_ID = b.ACCOUNT_ID
LEFT JOIN trading_firm tf ON tf.TRADING_FIRM_ID=b.TRADING_FIRM_ID
LEFT JOIN genesis2.trader trd ON trd.trader_internal_id = b.trader_internal_id
WHERE b.CREATE_TIME between p_start_date and p_end_date
  and coalesce(case when p.OSR_PARAM_TYPE = 'F' then to_char(trunc(to_number(t.OSR_PARAM_OLD_VALUE, '9999999999999999999999999999999.9999999999999999999999'))) else t.OSR_PARAM_OLD_VALUE end, '-1') <>
      coalesce(case when p.OSR_PARAM_TYPE = 'F' then to_char(trunc(to_number(t.OSR_PARAM_NEW_VALUE, '9999999999999999999999999999999.9999999999999999999999'))) else t.OSR_PARAM_NEW_VALUE end, '-2')
ORDER BY b.CREATE_TIME ASC;