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
where exchange_id = 'ISEF'
order by CAST(TRADE_LIQUIDITY_INDICATOR AS integer);

insert into LIQUIDITY_INDICATOR (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID)
SELECT 'ISEF', TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT", LIQUIDITY_INDICATOR_TYPE_ID
from LIQUIDITY_INDICATOR
where EXCHANGE_ID = 'ISE'
and TRADE_LIQUIDITY_INDICATOR not in ('53', '54', '55', '56', '57')
order by CAST(TRADE_LIQUIDITY_INDICATOR AS integer);
commit;

