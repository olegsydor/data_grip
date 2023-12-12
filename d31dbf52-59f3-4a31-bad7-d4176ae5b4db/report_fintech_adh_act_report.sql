select * from dash360.report_fintech_adh_act_report(in_start_date_id := 20230929,
                                                      in_end_date_id := 20230929,
                                                      in_security_type := 'E',
                                                      in_account_ids := '{24051}')
where export_row is null

create or replace function dash360.report_fintech_adh_act_report(in_start_date_id int4,
                                                                 in_end_date_id int4,
                                                                 in_security_type character default null::character,
                                                                 in_account_ids integer[] default '{}'::integer[]
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

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_adh_act_report STARTED===', 0, 'O')
    into l_step_id;

    return query
        select 'Entry Type,As-of,B/S/X,Reference Number,Volume,Symbol,Price Trade Digit,Trade Modifier,Price Override,CPID,CPGU,CPID Clear Number,EPGU,EP Clear Number,EP PA Indicator,Trade Report Flag,Clearing Flag,Special Trade Indicator,Execution Time,Memo,Decimal Price,Contra Branch Sequence,Trade Date,Reversal Indicator,CP P/A Indicator,Clearing Price,Trade Through Exempt,Seller Days,Intended Market Center,Related Market Center,Trade Reference Number,Branch Office Seq No.,Advertisement Instruction,Reference Reporting Facility,Modifier 2 Time,Modifier 4 Time,Original Control Number on Reversal,Original Trade Report Date on Reversal,Side,ShortSaleIndicator';

    return query
        select "Entry Type" || ',' ||
               coalesce("As-of", '') || ',' ||
               coalesce("B/S/X", '') || ',' ||
               "Reference Number"::text || ',' ||
               coalesce("Volume"::text, '') || ',' ||
               coalesce("Symbol", '') || ',' ||
               "Price Trade Digit" || ',' ||
               "Trade Modifier" || ',' ||
               coalesce("Price Override", '') || ',' ||
               "CPID" || ',' ||
               coalesce("CPGU", '') || ',' ||
               coalesce("CPID Clear Number", '') || ',' ||
               coalesce("EPGU", '') || ',' ||
               coalesce("EP Clear Number", '') || ',' ||
               "EP PA Indicator" || ',' ||
               "Trade Report Flag" || ',' ||
               "Clearing Flag" || ',' ||
               coalesce("Special Trade Indicator", '') || ',' ||
               coalesce("Execution Time", '') || ',' ||
               coalesce("Memo", '') || ',' ||
               coalesce("Decimal Price"::text, '') || ',' ||
               coalesce("Contra  Branch Sequence", '') || ',' ||
               coalesce("Trade Date", '') || ',' ||
               coalesce("Reversal Indicator", '') || ',' ||
               "CP P/A Indicator" || ',' ||
               coalesce("Clearing Price", '') || ',' ||
               "Trade Through Exempt" || ',' ||
               coalesce("Seller Days", '') || ',' ||
               coalesce("Intended Market Center", '') || ',' ||
               coalesce("Related Market Center", '') || ',' ||
               coalesce("Trade Reference Number", '') || ',' ||
               coalesce("Branch Office Seq No.", '') || ',' ||
               coalesce("Advertisement Instruction", '') || ',' ||
               coalesce("Reference Reporting Facility", '') || ',' ||
               coalesce("Modifier 2 Time", '') || ',' ||
               coalesce("Modifier 4 Time", '') || ',' ||
               coalesce("Original Control Number on Reversal", '') || ',' ||
               coalesce("Original Trade Report Date on Reversal", '') || ',' ||
               coalesce("Side", '') || ',' ||
               coalesce("ShortSaleIndicator", '')
        from (select 'M'                                                                            as "Entry Type",
                     case when tr.trade_record_time::date < current_date then 'Y' end               as "As-of",
                     null                                                                           as "B/S/X",
                     10000 + row_number()
                             over (partition by tr.date_id order by tr.date_id, tr.trade_record_id) as "Reference Number",
                     tr.last_qty                                                                    as "Volume",
                     hsd.symbol                                                                     as "Symbol",
                     'A'                                                                            as "Price Trade Digit",
                     '@'                                                                            as "Trade Modifier",
                     null                                                                           as "Price Override",
                     'DFIN'                                                                         as "CPID",
                     a.broker_dealer_mpid                                                           as "CPGU",
                     null                                                                           as "CPID Clear Number",
                     null                                                                           as "EPGU",
                     null                                                                           as "EP Clear Number",
                     'A'                                                                            as "EP PA Indicator",
                     'N'                                                                            as "Trade Report Flag",
                     'U'                                                                            as "Clearing Flag",
                     null                                                                           as "Special Trade Indicator",
                     to_char(tr.trade_record_time, 'HH24MISSUS')                                    as "Execution Time",
                     null                                                                           as "Memo",
                     tr.last_px                                                                     as "Decimal Price",
                     null                                                                           as "Contra  Branch Sequence",
                     case
                         when tr.trade_record_time::date < current_date
                             then to_char(tr.trade_record_time, 'MMDDYYYY') end                     as "Trade Date",
                     null                                                                           as "Reversal Indicator",
                     'A'                                                                            as "CP P/A Indicator",
                     null                                                                           as "Clearing Price",
                     'Y'                                                                            as "Trade Through Exempt",
                     null                                                                           as "Seller Days",
                     null                                                                           as "Intended Market Center",
                     null                                                                           as "Related Market Center",
                     null                                                                           as "Trade Reference Number",
                     null                                                                           as "Branch Office Seq No.",
                     null                                                                           as "Advertisement Instruction",
                     null                                                                           as "Reference Reporting Facility",
                     null                                                                           as "Modifier 2 Time",
                     null                                                                           as "Modifier 4 Time",
                     null                                                                           as "Original Control Number on Reversal",
                     null                                                                           as "Original Trade Report Date on Reversal",
                     case
                         when tr.side = '1' then 'S'
                         when tr.side in ('2', '5', '6')
                             then 'B' end                                                           as "Side",
                     null                                                                           as "ShortSaleIndicator"
              from dwh.flat_trade_record tr
                       join dwh.d_account a on (a.account_id = tr.account_id)
                       join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                       join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
              where tr.date_id between in_start_date_id and in_end_date_id
                and case
                        when coalesce(in_account_ids, '{}') = '{}' then true
                        else a.account_id = any (in_account_ids) end
                and case when in_security_type is null then true else tr.instrument_type_id = in_security_type end
                and tr.is_busted = 'N'
              order by tr.date_id, tr.trade_record_id) x;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_adh_act_report COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;
end;
$fx$



select *
from dash360.report_gtc_fidelity_retail(p_is_multileg_report := 'Y',
                                        p_instrument_type_id := null,
                                        p_trading_firm_ids := '{"OFP0022"}')
where export_row ilike '%22349HHXWC%'

select *
from trash.so_report_gtc_fidelity_retail_back(p_is_multileg_report := 'Y', p_trading_firm_ids := '{"OFP0022"}',
                                              p_instrument_type_id := null)
where export_row ilike '%22349HHXWC%';
