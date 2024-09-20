select current_timestamp from dual;

INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISE', '53', 'Combo Taker Against Regular - Thru NBBO', NULL, 2, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISE', '54', 'Combo Taker Against IO - Thru NBBO', NULL, 2, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISE', '55', 'Simple Exposure Order - Upon Receipt', NULL, 4, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISE', '56', 'Simple Exposure Order - Subsequent', NULL, 4, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISE', '57', 'Simple Exposure Order - Responder', NULL, 4, 'N', current_timestamp);
commit;

update LIQUIDITY_INDICATOR
set trade_liquidity_indicator = case
                                    when trade_liquidity_indicator = 'C' then '7'
                                    when trade_liquidity_indicator = 'H' then '5'
                                    when trade_liquidity_indicator = 'M' then '1'
                                    when trade_liquidity_indicator = 'O' then '6'
                                    when trade_liquidity_indicator = 'R' then '4'
                                    when trade_liquidity_indicator = 'T' then '2'
                                    when trade_liquidity_indicator = 'X' then '0' end
where exchange_id = 'ISE'
  and trade_liquidity_indicator in ('C', 'H', 'M', 'O', 'R', 'T', 'X');
commit;



update LIQUIDITY_INDICATOR
set description = case
                      when trade_liquidity_indicator = '1' then 'Add/Maker'
                      when trade_liquidity_indicator = '2' then 'Remove/Taker' end
where exchange_id = 'ISE'
  and trade_liquidity_indicator in ('1', '2');

select * from LIQUIDITY_INDICATOR
where exchange_id = 'ISE'
order by CAST(TRADE_LIQUIDITY_INDICATOR AS integer);

insert into LIQUIDITY_INDICATOR (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID)
SELECT 'ISEF', TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID
from LIQUIDITY_INDICATOR
where EXCHANGE_ID = 'ISE'
and TRADE_LIQUIDITY_INDICATOR not in ('53', '54', '55', '56', '57')
order by CAST(TRADE_LIQUIDITY_INDICATOR AS integer);
commit;


-- INSERT INTO LIQUIDITY_INDICATOR
-- (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
-- VALUES ('C2OX', 'SC',
--         'Removes Liquidity (Public Customer), SPY, AAPL, QQQ, IWM, SLV, AMC, AMD, AMZN, HYG, PLTR, TSLA and XLF', NULL,
--         2, 'N', current_timestamp);
-- INSERT INTO LIQUIDITY_INDICATOR
-- (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
-- VALUES ('C2OX', 'SM',
--         'Adds Liquidity (C2 Market Maker), SPY, AAPL, QQQ, IWM, SLV, AMC, AMD, AMZN, HYG, PLTR, TSLA and XLF', NULL, 1,
--         'N', current_timestamp);
-- INSERT INTO LIQUIDITY_INDICATOR
-- (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
-- VALUES ('C2OX', 'SL',
--         'Adds Liquidity, NBBO Joiner or NBBO Setter (C2 Market Maker), SPY, AAPL, QQQ, IWM, SLV, AMC, AMD, AMZN, HYG, PLTR, TSLA and XLF',
--         NULL, 1, 'N', current_timestamp);
-- INSERT INTO LIQUIDITY_INDICATOR
-- (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
-- VALUES ('C2OX', 'SN',
--         'Adds Liquidity (Non-Customer, Non-Market Maker), SPY, AAPL, QQQ, IWM, SLV, AMC, AMD, AMZN, HYG, PLTR, TSLA and XLF',
--         NULL, 1, 'N', current_timestamp);

select * from LIQUIDITY_INDICATOR
where EXCHANGE_ID = 'C2OX';

INSERT INTO LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('C2OX', 'SC', 'Removes Liquidity', NULL, 2, 'N', current_timestamp);
INSERT INTO LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('C2OX', 'SM', 'Adds Liquidity', NULL, 1, 'N', current_timestamp);
INSERT INTO LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('C2OX', 'SL', 'Adds Liquidity, NBBO Joiner or NBBO Setter', NULL, 1, 'N', current_timestamp);
INSERT INTO LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('C2OX', 'SN', 'Adds Liquidity', NULL, 1, 'N', current_timestamp);
commit



select ui.USER_ROLE, ui.user_id, asa.account_id, acc.trading_firm_id
        from user_identifier ui
        inner  join PORTAL_USER pu  on (ui.user_id = pu.user_id)
        inner join ACCOUNT_SET2ACCOUNT asa on (pu.account_set_id = asa.ACCOUNT_SET_ID)
        inner join account acc on (asa.account_id = acc.account_id)
        where 1=1
--     and USER_ROLE in ('A', 'P')
--         and ui.is_deleted='N'
--         and ((ui.USER_ROLE = 'P' and asa.account_id is not null) or ui.USER_ROLE = 'A')
        and pu.USER_ID in (       15276, 15841, 15277)
        UNION
select ui.USER_ROLE, ui.user_id, acc.account_id, putf.trading_firm_id
from user_identifier ui
         left join PORTAL_USER2TRADING_FIRM putf on (ui.user_id = putf.user_id)
         left join account acc on (putf.trading_firm_id = acc.trading_firm_id and acc.is_deleted = 'N')
where 1 = 1
-- --           and USER_ROLE in ('A', 'P')
  and ui.is_deleted = 'N'
--         and ((ui.USER_ROLE = 'P' and putf.trading_firm_id is not null) or ui.USER_ROLE = 'A')
  and ui.USER_ID in (15276, 15841, 15277);