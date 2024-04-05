with base as (select
                  --AA Record
                  'AA'                                                       as "AA_RECORD_TYPE",
                  row_number() over (
                      partition by tr.date_id
                      order by tr.date_id, tr.instrument_type_id, hsd.display_instrument_id
                      )                                                      as "AA_REFERENCE_NUMBER",
                  to_char(tr.trade_record_time, 'yyyyMMdd')                  as "AA_TRADE_DATE",
                  '51681001D3'                                               as "AA_ACCOUNT_NUMBER",
                  case when tr.side = '1' then 'B' else 'S' end              as "AA_BUY/SELL",
                  'CTCA'                                                     as "AA_EXECUTING_BROKER",
                  null                                                       as "AA_RECEIVE/DELIVER_BROKER_ALPHA",
                  '0161'                                                     as "AA_RECEIVE/DELIVER_BROKER_NUMBER",
                  'E'                                                        as "AA_MARKET/EXCHANGE",
                  null                                                       as "AA_TIME",
                  null                                                       as "AA_EXTENDED_TIME",
                  null                                                       as "AA_FILLER",
                  sum(tr.last_qty)                                           as "AA_QUANTITY",
                  hsd.symbol                                                 as "AA_SYMBOL/CUSIP",
                  case
                      when tr.instrument_type_id = 'E' then 'S'
                      when tr.instrument_type_id = 'O' then 'O'
                      end                                                    as "AA_STOCK/BOND/OPTION",
                  'ID'                                                       as "AA_BLOTTER_CODE/PUT_CALL_INDICATOR",
                  null                                                       as "AA_BILL/NO_BILL_CODE",
                  null                                                       as "AA_RECEIVE/DELIVER_BADGE_",
                  'P'                                                        as "AA_AGENCY/PRINC",
                  'N'                                                        as "AA_CONTRACT_CODE",
                  null                                                       as "AA_MISCELLANEOUS_TRADE_TYPE_INDICATOR",
                  null                                                       as "AA_MULTI_CONTRA_FLAG",
                  round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as "AA_EXTENDED_PRICE",
                  null                                                       as "AA_EXECUTING_BADGE",
                  null                                                       as "AA_QSR_BRANCH",
                  null                                                       as "AA_QSR_SEQUENCE_NUMBER",
                  null                                                       as "AA_CUSTOMER_MNEMONIC",
                  null                                                       as "AA_RESERVED",
                  null                                                       as "AA_CUSTOMER_ID",
                  null                                                       as "AA_ORIGIN_EXCHANGE",
                  null                                                       as "AA_NTCA_INDICATOR",
                  null                                                       as "AA_ATS_MPID",
                  null                                                       as "AA_PRODUCT_TYPE",
                  null                                                       as "AA_PRODUCT_ID",
                  null                                                       as "AA_EXTERNAL_REFNO",
                  null                                                       as "AA_ACTION_CODE",
                  null                                                       as "AA_EXCEPTION_CODE",
--                   null                                                       as "AA_FILLER",
                  --BB Record
                  'BB'                                                       as "BB_RECORD_TYPE",
                  row_number() over (
                      partition by tr.date_id
                      order by tr.date_id, tr.instrument_type_id, hsd.display_instrument_id
                      )                                                      as "BB_REFERENCE_NUMBER",
                  to_char(tr.trade_record_time, 'yyyyMMdd')                  as "BB_TRADE_DATE",
                  null                                                       as "BB_FILLER",
                  '2'                                                        as "BB_RATE_ID",
                  round(sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0)),
                        2)                                                   as "BB_COMMISSION_RATE/AMOUNT/BPS",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_1",
                  null                                                       as "BB_MISCELLANEOUS_RATE_1",
                  'DASH'                                                     as "BB_EXECUTING_SERVICE",
                  null                                                       as "BB_SETTLE_DATE",
                  case when tr.side in ('5', '6') then 'S' end               as "BB_SHORT_SALE",
                  null                                                       as "BB_RR/BRANCH",
                  null                                                       as "BB_OPTION_CODE",
                  null                                                       as "BB_EXPIRATION_YEAR",
                  null                                                       as "BB_EXPIRATION_MONTH",
                  null                                                       as "BB_EXPIRATION_DAY",
                  null                                                       as "BB_STRIKE_PRICE",
                  'DASH'                                                     as "BB_CLIENT_ID",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_2",
                  null                                                       as "BB_MISCELLANEOUS_RATE_2",
                  'H'                                                        as "BB_HOUSE_/_BOTH",
                  '01'                                                       as "BB_FIRM",
--                   null                                                       as "BB_FILLER",
                  null                                                       as "BB_MARKUP",
                  null                                                       as "BB_PRINCIPAL_AMOUNT",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_3",
                  null                                                       as "BB_MISCELLANEOUS_FLAT_RATE_3",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_4",
                  null                                                       as "BB_MISCELLANEOUS_RATE_4",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_5",
                  null                                                       as "BB_MISCELLANEOUS_RATE_5",
                  null                                                       as "BB_MISCELLANEOUS_RATE_ID_6",
                  null                                                       as "BB_MISCELLANEOUS_RATE_6",
--                   null                                                       as "BB_FILLER",
                  null                                                       as "BB_EXTERNAL_REFNO",
                  null                                                       as "BB_ACTION_CODE",
                  null                                                       as "BB_EXCEPTION_CODE",
                  null                                                       as "BB_TAF_OVERRIDE"
              from dwh.flat_trade_record tr
                       join dwh.d_account a on (a.account_id = tr.account_id)
                       join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
              where tr.date_id between 20240327 and 20240328
                and a.account_id in (70406)
                and tr.instrument_type_id in ('E', 'O')
                and tr.is_busted = 'N'
              group by tr.date_id,
                       tr.instrument_type_id,
                       hsd.display_instrument_id,
                       "AA_TRADE_DATE",
                       "AA_BUY/SELL",
                       "AA_SYMBOL/CUSIP",
                       "AA_STOCK/BOND/OPTION",
                       "BB_TRADE_DATE",
                       "BB_SHORT_SALE")
select array_to_string(ARRAY [
    "AA_RECORD_TYPE", -- text NULL, 1-2
	lpad("AA_REFERENCE_NUMBER"::text, 5, '0'),--  int8 NULL, 3-7
	"AA_TRADE_DATE", --  text, - 8-15
	left("AA_ACCOUNT_NUMBER", 10),--  text, 16-25
	"AA_BUY/SELL", --  text NULL,
	"AA_EXECUTING_BROKER", --  text,
	"AA_RECEIVE/DELIVER_BROKER_ALPHA", --  text NULL,
	"AA_RECEIVE/DELIVER_BROKER_NUMBER", --  text NULL,
	"AA_MARKET/EXCHANGE", --  text NULL,
	"AA_TIME", --  text NULL,
	"AA_EXTENDED_TIME", --  text NULL,
	"AA_FILLER", --  text NULL,
	"AA_QUANTITY"::text, --  int8 NULL,
	"AA_SYMBOL/CUSIP", --  varchar(10) NULL,
	"AA_STOCK/BOND/OPTION", --  text NULL,
	"AA_BLOTTER_CODE/PUT_CALL_INDICATOR", --  text NULL,
	"AA_BILL/NO_BILL_CODE", --  text NULL,
	"AA_RECEIVE/DELIVER_BADGE_", --  text NULL,
	"AA_AGENCY/PRINC", --  text NULL,
	"AA_CONTRACT_CODE", --  text NULL,
	"AA_MISCELLANEOUS_TRADE_TYPE_INDICATOR", --  text NULL,
	"AA_MULTI_CONTRA_FLAG", --  text NULL,
	"AA_EXTENDED_PRICE"::text, --  numeric NULL,
	"AA_EXECUTING_BADGE", --  text NULL,
	"AA_QSR_BRANCH", --  text NULL,
	"AA_QSR_SEQUENCE_NUMBER", --  text NULL,
	"AA_CUSTOMER_MNEMONIC", --  text NULL,
	"AA_RESERVED", --  text NULL,
	"AA_CUSTOMER_ID", --  text NULL,
	"AA_ORIGIN_EXCHANGE", --  text NULL,
	"AA_NTCA_INDICATOR", --  text NULL,
	"AA_ATS_MPID", --  text NULL,
	"AA_PRODUCT_TYPE", --  text NULL,
	"AA_PRODUCT_ID", --  text NULL,
	"AA_EXTERNAL_REFNO", --  text NULL,
	"AA_ACTION_CODE", --  text NULL,
	"AA_EXCEPTION_CODE" --  text NULL, from base
     ], ',', ''),
    row_number() over () as rn,
    "AA_RECORD_TYPE" as tp
from base
-- where "AA_RECORD_TYPE" = 'AA'
union all
select array_to_string(ARRAY [
    "BB_RECORD_TYPE", -- text NULL,
	"BB_REFERENCE_NUMBER"::text, -- int8 NULL,
	"BB_TRADE_DATE", -- text NULL,
	"BB_FILLER", -- text NULL,
	"BB_RATE_ID", -- text NULL,
	"BB_COMMISSION_RATE/AMOUNT/BPS"::text, -- numeric NULL,
	"BB_MISCELLANEOUS_RATE_ID_1", -- text NULL,
	"BB_MISCELLANEOUS_RATE_1", -- text NULL,
	"BB_EXECUTING_SERVICE", -- text NULL,
	"BB_SETTLE_DATE", -- text NULL,
	"BB_SHORT_SALE", -- text NULL,
	"BB_RR/BRANCH", -- text NULL,
	"BB_OPTION_CODE", -- text NULL,
	"BB_EXPIRATION_YEAR", -- text NULL,
	"BB_EXPIRATION_MONTH", -- text NULL,
	"BB_EXPIRATION_DAY", -- text NULL,
	"BB_STRIKE_PRICE", -- text NULL,
	"BB_CLIENT_ID", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_2", -- text NULL,
	"BB_MISCELLANEOUS_RATE_2", -- text NULL,
	"BB_HOUSE_/_BOTH", -- text NULL,
	"BB_FIRM", -- text NULL,
	"BB_MARKUP", -- text NULL,
	"BB_PRINCIPAL_AMOUNT", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_3", -- text NULL,
	"BB_MISCELLANEOUS_FLAT_RATE_3", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_4", -- text NULL,
	"BB_MISCELLANEOUS_RATE_4", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_5", -- text NULL,
	"BB_MISCELLANEOUS_RATE_5", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_6", -- text NULL,
	"BB_MISCELLANEOUS_RATE_6", -- text NULL,
	"BB_EXTERNAL_REFNO", -- text NULL,
	"BB_ACTION_CODE", -- text NULL,
	"BB_EXCEPTION_CODE" -- text NULL
 ], ',', ''),
    row_number() over () as rn,
    "BB_RECORD_TYPE" as tp
from base
order by rn, tp;

----------------------------

with base as (select
                  --AA Record
                  'AA'                                                       as "AA_RECORD_TYPE",
                  row_number() over (
                      partition by tr.date_id
                      order by tr.date_id, tr.instrument_type_id, hsd.display_instrument_id
                      )                                                      as "AA_REFERENCE_NUMBER",
                  to_char(tr.trade_record_time, 'yyyyMMdd')                  as "AA_TRADE_DATE",
                  '51681001D3'                                               as "AA_ACCOUNT_NUMBER",
                  case when tr.side = '1' then 'B' else 'S' end              as "AA_BUY/SELL",
                  'CTCA'                                                     as "AA_EXECUTING_BROKER",
                  '0161'                                                     as "AA_RECEIVE/DELIVER_BROKER_NUMBER",
                  'E'                                                        as "AA_MARKET/EXCHANGE",
                  sum(tr.last_qty)                                           as "AA_QUANTITY",
                  hsd.symbol                                                 as "AA_SYMBOL/CUSIP",
                  case
                      when tr.instrument_type_id = 'E' then 'S'
                      when tr.instrument_type_id = 'O' then 'O'
                      end                                                    as "AA_STOCK/BOND/OPTION",
                  'ID'                                                       as "AA_BLOTTER_CODE/PUT_CALL_INDICATOR",
                  'P'                                                        as "AA_AGENCY/PRINC",
                  'N'                                                        as "AA_CONTRACT_CODE",
                  round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as "AA_EXTENDED_PRICE",
                  --BB Record
                  'BB'                                                       as "BB_RECORD_TYPE",
                  row_number() over (
                      partition by tr.date_id
                      order by tr.date_id, tr.instrument_type_id, hsd.display_instrument_id
                      )                                                      as "BB_REFERENCE_NUMBER",
                  to_char(tr.trade_record_time, 'yyyyMMdd')                  as "BB_TRADE_DATE",
                  null                                                       as "BB_FILLER",
                  '2'                                                        as "BB_RATE_ID",
                  round(sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0)),
                        2)                                                   as "BB_COMMISSION_RATE/AMOUNT/BPS",
                  'DASH'                                                     as "BB_EXECUTING_SERVICE",
                  case when tr.side in ('5', '6') then 'S' end               as "BB_SHORT_SALE",
                  'DASH'                                                     as "BB_CLIENT_ID",
                  'H'                                                        as "BB_HOUSE_/_BOTH",
                  '01'                                                       as "BB_FIRM"
              from dwh.flat_trade_record tr
                       join dwh.d_account a on (a.account_id = tr.account_id)
                       join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
              where tr.date_id between 20240327 and 20240328
                and a.account_id in (70406)
                and tr.instrument_type_id in ('E', 'O')
                and tr.is_busted = 'N'
              group by tr.date_id,
                       tr.instrument_type_id,
                       hsd.display_instrument_id,
                       "AA_TRADE_DATE",
                       "AA_BUY/SELL",
                       "AA_SYMBOL/CUSIP",
                       "AA_STOCK/BOND/OPTION",
                       "BB_TRADE_DATE",
                       "BB_SHORT_SALE")
select array_to_string(ARRAY [
                           "AA_RECORD_TYPE", -- text NULL, 1-2
                           lpad("AA_REFERENCE_NUMBER"::text, 5, '0'),--  int8 NULL, 3-7
                           "AA_TRADE_DATE", --  text, - 8-15
                           left("AA_ACCOUNT_NUMBER", 10),--  text, 16-25
                           "AA_BUY/SELL", --  text, 26
                           "AA_EXECUTING_BROKER", --  text, 27-30
                           repeat(' ', 4), --"AA_RECEIVE/DELIVER_BROKER_ALPHA", --  text, 31-34
                           "AA_RECEIVE/DELIVER_BROKER_NUMBER", --  text, 35-38
                           "AA_MARKET/EXCHANGE", --  text, 39
                           repeat(' ', 4), --"AA_TIME", --  text, 40-43
                           repeat(' ', 4), --"AA_EXTENDED_TIME", --  text, 44-47
                           repeat(' ', 6), --"AA_FILLER", --  text, 48-53
                           lpad("AA_QUANTITY"::text, 9, '0'), --  int8, 54-62
                           rpad("AA_SYMBOL/CUSIP", 10, ' '), --  varchar(10), 63-72
                           "AA_STOCK/BOND/OPTION", --  text, 73
                           "AA_BLOTTER_CODE/PUT_CALL_INDICATOR", --  text, 74-75
                           ' ', --"AA_BILL/NO_BILL_CODE", --  text, 76
                           repeat(' ', 4), --"AA_RECEIVE/DELIVER_BADGE_", --  text, 77-80
                           "AA_AGENCY/PRINC", --  text, 81
                           "AA_CONTRACT_CODE", --  text, 82
                           ' ', --"AA_MISCELLANEOUS_TRADE_TYPE_INDICATOR", --  text, 83
                           ' ', --"AA_MULTI_CONTRA_FLAG", --  text, 84
                           to_char("AA_EXTENDED_PRICE", 'FM09999V99999990'), --  numeric, 85-97
                           repeat(' ', 4), -- "AA_EXECUTING_BADGE", --  text, 98-101
                           repeat(' ', 4), -- "AA_QSR_BRANCH", --  text NULL, 102-105
                           repeat(' ', 4), -- "AA_QSR_SEQUENCE_NUMBER", --  text, 106-109
                           repeat(' ', 4), -- "AA_CUSTOMER_MNEMONIC", --  text, 110-113
                           repeat(' ', 13), -- "AA_RESERVED", --  text NULL, 114-126
                           repeat(' ', 10), -- "AA_CUSTOMER_ID", --  text NULL, 127-136
                           ' ', -- "AA_ORIGIN_EXCHANGE", --  text NULL, 137
                           ' ', -- "AA_NTCA_INDICATOR", --  text NULL, 138
                           repeat(' ', 4), -- "AA_ATS_MPID", --  text NULL, 139-142
                           ' ', -- "AA_PRODUCT_TYPE", --  text NULL, 143
                           repeat(' ', 21), -- "AA_PRODUCT_ID", --  text NULL, 144-164
                           repeat(' ', 20), -- filler 165-184
                           repeat(' ', 10), -- "AA_EXTERNAL_REFNO", --  text NULL,185-194
                           ' ', -- "AA_ACTION_CODE", --  text NULL,195
                           repeat(' ', 4) -- "AA_EXCEPTION_CODE" --  text NULL,  196-199
                           ], '', ''),
       row_number() over () as rn,
       "AA_RECORD_TYPE"     as tp
from base
-- where "AA_RECORD_TYPE" = 'AA'
union all
select array_to_string(ARRAY [
    "BB_RECORD_TYPE", -- text NULL,
	"BB_REFERENCE_NUMBER"::text, -- int8 NULL,
	"BB_TRADE_DATE", -- text NULL,
	"BB_FILLER", -- text NULL,
	"BB_RATE_ID", -- text NULL,
	"BB_COMMISSION_RATE/AMOUNT/BPS"::text, -- numeric NULL,
	"BB_MISCELLANEOUS_RATE_ID_1", -- text NULL,
	"BB_MISCELLANEOUS_RATE_1", -- text NULL,
	"BB_EXECUTING_SERVICE", -- text NULL,
	"BB_SETTLE_DATE", -- text NULL,
	"BB_SHORT_SALE", -- text NULL,
	"BB_RR/BRANCH", -- text NULL,
	"BB_OPTION_CODE", -- text NULL,
	"BB_EXPIRATION_YEAR", -- text NULL,
	"BB_EXPIRATION_MONTH", -- text NULL,
	"BB_EXPIRATION_DAY", -- text NULL,
	"BB_STRIKE_PRICE", -- text NULL,
	"BB_CLIENT_ID", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_2", -- text NULL,
	"BB_MISCELLANEOUS_RATE_2", -- text NULL,
	"BB_HOUSE_/_BOTH", -- text NULL,
	"BB_FIRM", -- text NULL,
	"BB_MARKUP", -- text NULL,
	"BB_PRINCIPAL_AMOUNT", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_3", -- text NULL,
	"BB_MISCELLANEOUS_FLAT_RATE_3", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_4", -- text NULL,
	"BB_MISCELLANEOUS_RATE_4", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_5", -- text NULL,
	"BB_MISCELLANEOUS_RATE_5", -- text NULL,
	"BB_MISCELLANEOUS_RATE_ID_6", -- text NULL,
	"BB_MISCELLANEOUS_RATE_6", -- text NULL,
	"BB_EXTERNAL_REFNO", -- text NULL,
	"BB_ACTION_CODE", -- text NULL,
	"BB_EXCEPTION_CODE" -- text NULL
 ], ',', ''),
    row_number() over () as rn,
    "BB_RECORD_TYPE" as tp
from base
order by rn, tp