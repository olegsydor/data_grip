DROP FUNCTION trash.report_fintech_ml_pro_200byte(int4, int4, _int4, bpchar);

CREATE FUNCTION trash.report_fintech_ml_pro_200byte(in_start_date_id integer, in_end_date_id integer, in_account_ids integer[] DEFAULT '{}'::integer[], in_instrument_type character DEFAULT NULL::bpchar)
 RETURNS TABLE(export_row text)
 LANGUAGE plpgsql
AS $function$
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
                      --'51681001D3'                                               as "AA_ACCOUNT_NUMBER",
                      case
                          when a.account_name in ('593501616', 'QXMGLDML') then '51681001D3'
                          when a.account_name in ('QUADEYE') then '34101318D9'
                      end                                                        as "AA_ACCOUNT_NUMBER",
                      case when tr.side = '1' then 'B' else 'S' end              as "AA_BUY/SELL",
                      ---'CTCA'                                                     as "AA_EXECUTING_BROKER",
                      case
                          when tr.instrument_type_id = 'E' then 'CTCA'
                          when tr.instrument_type_id = 'O' then '0792'
                          end                                                    as "AA_EXECUTING_BROKER",
                      --'0161'                                                     as "AA_RECEIVE/DELIVER_BROKER_NUMBER",
                      case
                          when tr.instrument_type_id = 'E' then '0161'
                          when tr.instrument_type_id = 'O' then '0551'
                          end                                                    as "AA_RECEIVE/DELIVER_BROKER_NUMBER",
                      'E'                                                        as "AA_MARKET/EXCHANGE",
                      sum(tr.last_qty)                                           as "AA_QUANTITY",
                      hsd.symbol                                                 as "AA_SYMBOL/CUSIP",
                      case
                          when tr.instrument_type_id = 'E' then 'S'
                          when tr.instrument_type_id = 'O' then 'O'
                          end                                                    as "AA_STOCK/BOND/OPTION",
                      --'ID'                                                       as "AA_BLOTTER_CODE/PUT_CALL_INDICATOR",
                      case
                          when tr.instrument_type_id = 'E' then 'ID'
                          when tr.instrument_type_id = 'O' and hsd.put_call = '0' then 'OP'
                          when tr.instrument_type_id = 'O' and hsd.put_call = '1' then 'OC'
                          end                                                    as "AA_BLOTTER_CODE/PUT_CALL_INDICATOR",
                      --'A'                                                        as "AA_AGENCY/PRINC",
                      case
                          when tr.instrument_type_id = 'E' then 'A' --'P'
                          when tr.instrument_type_id = 'O' then 'A'
                          end                                                    as "AA_AGENCY/PRINC",
                      'N'                                                        as "AA_CONTRACT_CODE",
                      round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as "AA_EXTENDED_PRICE",
                      --BB Record
                      'BB'                                                       as "BB_RECORD_TYPE",
                      --'2'                                                        as "BB_RATE_ID",
                      case
                          when tr.instrument_type_id = 'E' then '2'
                          else ''
                          end                                                    as "BB_RATE_ID",
                      round(sum(
                  		case
                      		when a.account_name in ('593501616', 'QXMGLDML') then 0.0007 * tr.last_qty
                  		    when a.account_name in ('QUADEYE') then 0
							else coalesce(tr.tcce_account_dash_commission_amount, 0.0)
						end)
					  ,2)                                                        as "BB_COMMISSION_RATE/AMOUNT/BPS",
                      --'DASH'                                                     as "BB_EXECUTING_SERVICE",
                      case
                          when tr.instrument_type_id = 'E' then 'DASH'
                          when tr.instrument_type_id = 'O' then 'CMTA'
                          end                                                    as "BB_EXECUTING_SERVICE",
                      case when tr.side in ('5', '6') then 'S' else '' end      as "BB_SHORT_SALE",
                      case
                          when tr.instrument_type_id = 'O' then coalesce(tr.open_close, ' ')
                          else ''
                          end                                                    as "BB_OPTION_CODE",
                      case
                          when tr.instrument_type_id = 'O' then to_char(hsd.maturity_date, 'yy')
                          else ''
                          end                                                    as "BB_EXPIRATION_YEAR",
                      case
                          when tr.instrument_type_id = 'O' then to_char(hsd.maturity_date, 'MM')
                          else ''
                          end                                                    as "BB_EXPIRATION_MONTH",
                      case
                          when tr.instrument_type_id = 'O' then to_char(hsd.maturity_date, 'dd')
                          else ''
                          end                                                    as "BB_EXPIRATION_DAY",
                      case
                          when tr.instrument_type_id = 'O' then lpad((hsd.strike_px * 1000)::int::varchar, 8, '0')
                          else ''
                          end                                                    as "BB_STRIKE_PRICE",
                      --'DASH'                                                     as "BB_CLIENT_ID",
                      case
                          when tr.instrument_type_id = 'E' then 'DASH'
                          else ''
                          end                                                    as "BB_CLIENT_ID",
                      --'H'                                                        as "BB_HOUSE_/_BOTH",
                      case
                          when tr.instrument_type_id = 'E' then 'H'
                          else ''
                          end                                                    as "BB_HOUSE_/_BOTH",
                      '01'                                                       as "BB_FIRM",
                      '55'                                                       as "BB_MISCELLANEOUS_RATE_ID_4",
                      round(sum(
                  		case
                      		when a.account_name in ('593501616', 'QXMGLDML') then 0.0007 * tr.last_qty
                  		    when a.account_name in ('QUADEYE') then 0
							else coalesce(tr.tcce_account_dash_commission_amount, 0.0)
						end)
					  ,2)                                                        as "BB_MISCELLANEOUS_RATE_4"
                  from dwh.flat_trade_record tr
                           join dwh.d_account a on (a.account_id = tr.account_id)
                           join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                  where tr.date_id between in_start_date_id and in_end_date_id
                    and a.account_id = any (in_account_ids)
                    and case when in_instrument_type is null then true else tr.instrument_type_id = in_instrument_type end
                    and tr.is_busted = 'N'
--                   and display_instrument_id = 'VXX'
                  group by tr.date_id,
                           tr.instrument_type_id,
                           hsd.display_instrument_id,
                           hsd.put_call,
                           hsd.maturity_date,
                           "AA_TRADE_DATE",
                           "AA_ACCOUNT_NUMBER",
                           "AA_BUY/SELL",
                           "AA_SYMBOL/CUSIP",
                           "AA_STOCK/BOND/OPTION",
                           "BB_SHORT_SALE",
                           "BB_OPTION_CODE",
                           "BB_STRIKE_PRICE")
    select array_to_string(ARRAY [
                               "AA_RECORD_TYPE", -- text NULL, 1-2
                               lpad("AA_REFERENCE_NUMBER"::text, 5, '0'),--  int8 NULL, 3-7
                               "AA_TRADE_DATE", --  text, - 8-15
                               left("AA_ACCOUNT_NUMBER", 10),--  text, 16-25
                               "AA_BUY/SELL", --  text, 26
                               rpad("AA_EXECUTING_BROKER", 4, ' '), --  text, 27-30
                               repeat(' ', 4), --"AA_RECEIVE/DELIVER_BROKER_ALPHA", --  text, 31-34
                               rpad("AA_RECEIVE/DELIVER_BROKER_NUMBER", 4, ' '), --  text, 35-38
                               "AA_MARKET/EXCHANGE", --  text, 39
                               repeat(' ', 4), --"AA_TIME", --  text, 40-43
                               repeat(' ', 4), --"AA_EXTENDED_TIME", --  text, 44-47
                               repeat(' ', 6), --"AA_FILLER", --  text, 48-53
                               lpad("AA_QUANTITY"::text, 9, '0'), --  int8, 54-62
                               rpad("AA_SYMBOL/CUSIP", 10, ' '), --  varchar(10), 63-72
                               rpad("AA_STOCK/BOND/OPTION", 1, ' '), --  text, 73
                               rpad("AA_BLOTTER_CODE/PUT_CALL_INDICATOR", 2, ' '), --  text, 74-75
                               ' ', --"AA_BILL/NO_BILL_CODE", --  text, 76
                               repeat(' ', 4), --"AA_RECEIVE/DELIVER_BADGE_", --  text, 77-80
                               rpad("AA_AGENCY/PRINC", 1, ' '), --  text, 81
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
                               repeat(' ', 4), -- "AA_EXCEPTION_CODE" --  text NULL,  196-199,
                               ' ' --"FILER", --200
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
                               ' ', --"BB_RATE_ID", -- text, 21
                               repeat(' ', 8), --"BB_COMMISSION_RATE/AMOUNT/BPS", -- numeric NULL, 00025000 0002500000
                               repeat(' ', 2), --"BB_MISCELLANEOUS_RATE_ID_1", -- text, 30-31
                               repeat(' ', 8), --"BB_MISCELLANEOUS_RATE_1", -- text, 32-39
                               rpad("BB_EXECUTING_SERVICE", 4, ' '), -- text, 40-43
                               repeat(' ', 8), --"BB_SETTLE_DATE", -- text, 44-51
                               rpad("BB_SHORT_SALE", 1, ' '), -- text, 52
                               repeat(' ', 3), --"BB_RR/BRANCH", -- text, 53-55
                               --' ', --"BB_OPTION_CODE", -- text, 56
                               --repeat(' ', 2), --"BB_EXPIRATION_YEAR", -- text, 57-58
                               --repeat(' ', 2), --"BB_EXPIRATION_MONTH", -- text, 59-60
                               --repeat(' ', 2), --"BB_EXPIRATION_DAY", -- text, 61-62
                               --repeat(' ', 8), --"BB_STRIKE_PRICE", -- text, 63-70
                               rpad("BB_OPTION_CODE", 1, ' '), -- text, 56
                               rpad("BB_EXPIRATION_YEAR", 2, ' '), -- text, 57-58
                               rpad("BB_EXPIRATION_MONTH", 2, ' '), -- text, 59-60
                               rpad("BB_EXPIRATION_DAY", 2, ' '), -- text, 61-62
                               rpad("BB_STRIKE_PRICE", 8, ' '), -- text, 63-70
                               rpad("BB_CLIENT_ID", 4, ' '), -- text, 71-74
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_2", -- text, 75-76
                               repeat(' ', 15), -- "BB_MISCELLANEOUS_RATE_2", -- text, 77-91
                               rpad("BB_HOUSE_/_BOTH", 1, ' '), -- text, 92
                               "BB_FIRM", -- text, 93-94
                               repeat(' ', 3), --"FILLER" 95-97
                               repeat(' ', 10), -- "BB_MARKUP", -- text, 98-107
                               repeat(' ', 11), -- "BB_PRINCIPAL_AMOUNT", -- text, 108-118
                               repeat(' ', 2), -- "BB_MISCELLANEOUS_RATE_ID_3", -- text, 119-120
                               repeat(' ', 8), -- "BB_MISCELLANEOUS_FLAT_RATE_3", -- text, 121-128
                               '55', -- "BB_MISCELLANEOUS_RATE_ID_4", -- text, 129-130
--                                repeat(' ', 15), -- "BB_MISCELLANEOUS_RATE_4", -- text, 131-145
                               to_char("BB_COMMISSION_RATE/AMOUNT/BPS", 'FM000000000999V990')::text,
                               --"BB_MISCELLANEOUS_RATE_ID_4", -- "BB_MISCELLANEOUS_RATE_ID_4", -- text, 129-130
                               --to_char("BB_MISCELLANEOUS_RATE_4", 'FM00999V990')::text, -- "BB_MISCELLANEOUS_RATE_4", -- text, 131-145
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
               to_char(current_date, 'YYYYDDD') ||
               repeat(' ', 12) ||
               '1700' ||
               rpad('SDS', 20, ' ') ||
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
$function$
;

select * from dwh.d_account
    where account_name in ('QUADEYE')


        select * from trash.report_fintech_ml_pro_200byte(in_start_date_id := 20240919, in_end_date_id := 20240919, in_account_ids := '{72307}', in_instrument_type := 'O')
