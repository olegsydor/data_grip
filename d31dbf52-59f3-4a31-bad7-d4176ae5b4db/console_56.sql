create or replace function dash360.report_fintech_ml_pro_200byte(in_start_date_id int4,
                                                                 in_end_date_id int4,
                                                                 in_account_ids integer[] default '{}'::integer[],
                                                                 in_instrument_type_ids character[] default null::character[]
)
    returns table
            (
                export_row text
            )
    language plpgsql
AS
$fx$
DECLARE
    l_row_cnt integer;
    l_load_id integer;
    l_step_id integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_ml_pro_200byte STARTED===', 0, 'O')
    into l_step_id;

    create temp table t_report on commit drop as
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
                  where tr.date_id between in_start_date_id and in_end_date_id
                    and a.account_id = any (in_account_ids)
                    and tr.instrument_type_id = any (in_instrument_type_ids)
                    and tr.is_busted = 'N'
                  group by tr.date_id,
                           tr.instrument_type_id,
                           hsd.display_instrument_id,
                           "AA_TRADE_DATE",
                           "AA_BUY/SELL",
                           "AA_SYMBOL/CUSIP",
                           "AA_STOCK/BOND/OPTION",
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
                               ], '', '') as row_text,
           row_number() over ()           as rn,
           "AA_RECORD_TYPE"               as tp
    from base
    union all
    select array_to_string(ARRAY [
                               "BB_RECORD_TYPE", -- text, 1-2
                               lpad("AA_REFERENCE_NUMBER"::text, 5, '0'),--  int8 NULL, 3-7
                               "AA_TRADE_DATE", -- text, 8-15
                               repeat(' ', 5), --"BB_FILLER", -- text, 16-20
                               "BB_RATE_ID", -- text, 21
                               to_char("BB_COMMISSION_RATE/AMOUNT/BPS", 'FM099V99990')::text, -- numeric NULL, 00025000 0002500000
                               repeat(' ', 2), --"BB_MISCELLANEOUS_RATE_ID_1", -- text, 30-31
                               repeat(' ', 8), --"BB_MISCELLANEOUS_RATE_1", -- text, 32-39
                               "BB_EXECUTING_SERVICE", -- text, 40-43
                               repeat(' ', 8), --"BB_SETTLE_DATE", -- text, 44-51
                               "BB_SHORT_SALE", -- text, 52
                               repeat(' ', 3), --"BB_RR/BRANCH", -- text, 53-55
                               ' ', --"BB_OPTION_CODE", -- text, 56
                               repeat(' ', 2), --"BB_EXPIRATION_YEAR", -- text, 57-58
                               repeat(' ', 2), --"BB_EXPIRATION_MONTH", -- text, 59-60
                               repeat(' ', 2), --"BB_EXPIRATION_DAY", -- text, 61-62
                               repeat(' ', 8), --"BB_STRIKE_PRICE", -- text, 63-70
                               "BB_CLIENT_ID", -- text, 71-74
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_2", -- text, 75-76
                               repeat(' ', 5), -- "BB_MISCELLANEOUS_RATE_2", -- text, 77-91
                               "BB_HOUSE_/_BOTH", -- text, 92
                               "BB_FIRM", -- text, 93-94
                               repeat(' ', 10), -- "BB_MARKUP", -- text, 98-107
                               repeat(' ', 11), -- "BB_PRINCIPAL_AMOUNT", -- text, 108-118
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_3", -- text, 119-120
                               repeat(' ', 8), -- "BB_MISCELLANEOUS_FLAT_RATE_3", -- text, 121-128
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_4", -- text, 129-130
                               repeat(' ', 15), -- "BB_MISCELLANEOUS_RATE_4", -- text, 131-145
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_5", -- text, 146-147
                               repeat(' ', 10), -- "BB_MISCELLANEOUS_RATE_5", -- text, 148-157
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_6", -- text, 158-159
                               repeat(' ', 15), -- "BB_MISCELLANEOUS_RATE_6", -- text, 160-174
                               repeat(' ', 10), -- FILLER 175-184
                               repeat(' ', 10), --"BB_EXTERNAL_REFNO", -- text, 185-194
                               ' ', --"BB_ACTION_CODE", -- text, 195
                               repeat(' ', 4), --"BB_EXCEPTION_CODE" -- text NULL 196-199
                               ' ' -- TAF Override 200
                               ], '', '') as row_text,
           row_number() over ()           as rn,
           "BB_RECORD_TYPE"               as tp
    from base;

    get diagnostics l_row_cnt = row_count;

    return query
        select 'UHDR ' ||
               to_char(current_date, 'CCYYDDD') ||
               repeat(' ', 12) ||
               '1700' ||
               lpad('SDS', 20, ' ') ||
               repeat(' ', 152);


    return query
        select row_text
        from t_report
        order by rn, tp;

-- trailer
    return query
        select 'UTRL ' ||
               lpad((l_row_cnt + 2)::text, 8, '0') ||
               repeat(' ', 187);


    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_ml_pro_200byte COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;
end;
$fx$;


select *
from dash360.report_fintech_ml_pro_200byte(in_start_date_id := 20240404,
                                           in_end_date_id := 20240404,
                                           in_account_ids := '{70406}',
                                           in_instrument_type_ids := '{"O", "E"}');


select to_char(current_date, 'CCYYDDD')