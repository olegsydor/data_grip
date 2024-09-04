select current_timestamp from dual;

INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISEF', '53', 'Combo Taker Against Regular - Thru NBBO', NULL, 2, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISEF', '54', 'Combo Taker Against IO - Thru NBBO', NULL, 2, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISEF', '55', 'Simple Exposure Order - Upon Receipt', NULL, 4, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISEF', '56', 'Simple Exposure Order - Subsequent', NULL, 4, 'N', current_timestamp);
INSERT INTO GENESIS2.LIQUIDITY_INDICATOR
(EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
VALUES ('ISEF', '57', 'Simple Exposure Order - Responder', NULL, 4, 'N', current_timestamp);
commit;


update LIQUIDITY_INDICATOR
set description = case
                      when trade_liquidity_indicator in ('7', '5', '6', '4', '0') then '\'
                      when trade_liquidity_indicator = '1' then 'Add/Maker'
                      when trade_liquidity_indicator = '2' then 'Remove/Taker' end
where exchange_id = 'ISE'
  and trade_liquidity_indicator in ('7', '5', '1', '6', '4', '2', '0');

select * from LIQUIDITY_INDICATOR
where exchange_id = 'ISE'
order by CAST(TRADE_LIQUIDITY_INDICATOR AS integer);