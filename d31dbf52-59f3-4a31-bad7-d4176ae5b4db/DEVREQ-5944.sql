-- DROP FUNCTION dash360.report_fintech_adh_allocation_xls(int4, int4, _int4, bpchar, _varchar, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_fintech_laniakea_allocation(in_start_date_id integer, in_end_date_id integer)
    RETURNS TABLE
            (
                ret_row text
--                 "Trading Firm"         character varying,
--                 "Account"              character varying,
--                 "Date"                 text,
--                 "OCC AID"              character varying,
--                 "Clearing Account"     character varying,
--                 "Settlement Date"      character varying,
--                 "Alloc ID"             integer,
--                 "Allocated By"         character varying,
--                 "Alloc Time"           text,
--                 "Sec Type"             text,
--                 "Symbol"               character varying,
--                 "Side"                 text,
--                 "O/C"                  text,
--                 "Exec Qty"             bigint,
--                 "Avg Px"               numeric,
--                 "Alloc Qty"            bigint,
--                 "Pricipal Amount"      numeric,
--                 "CMTA"                 character varying,
--                 "OSI Symbol"           character varying,
--                 "Root Symbol"          character varying,
--                 "Expiration"           text,
--                 "Put/Call"             text,
--                 "Strike"               numeric,
--                 "Commission"           numeric,
--                 "Execution Cost"       numeric,
--                 "Maker/Taker Fee"      numeric,
--                 "Transaction Fee"      numeric,
--                 "Trade Processing Fee" numeric,
--                 "Royalty Fee"          numeric,
--                 "Client Commission"    numeric
            )
    LANGUAGE plpgsql
AS $function$
    -- 2025-04-25 SO: https://dashfinancial.atlassian.net/browse/DS-9930
declare
    l_account_ids int4[];
    begin



select array_agg(account_id)
into l_account_ids
from dwh.d_account ac
where ac.trading_firm_id = 'laniakea';

    select
        tr.account_id,

        to_char(tr.trade_record_time, 'MM/dd/yyyy')                as "Trade Date",
                     ca.clearing_account_number                                 as "Dash Prime Account",
                     hsd.display_instrument_id                                  as "Symbol",
                     case
                         when tr.side = '1' then 'BOT'
                         when tr.side = '2' then 'SLD'
                         when tr.side in ('5', '6') then 'SLD SHORT'
                         end                                                    as "Side",
                     sum(tr.last_qty)                                           as "Exec Qty",
                     round(sum(tr.last_qty * tr.last_px) / sum(tr.last_qty), 4) as "Avg Px",
                     round(sum(tr.last_qty * tr.last_px) / sum(tr.last_qty), 4) * sum(tr.last_qty) *
                     coalesce(hsd.contract_multiplier, 1.0)                     as "Principal Amount",
                     round(a.eq_commission * sum(tr.last_qty), 2)               as "Commissions",
                     --round(sum(coalesce(tr.tcce_sec_fee_amount, 0.0)), 2)       as "SEC Fee",
					 round(coalesce(sum(
						 case
							 when tr.side in ('2','5','6') then tr.principal_amount * 0.0000278
							 else 0.0
						 end
					 ),0.0 ), 2)                                                as "SEC Fee",
                     --
                     ai.alloc_instr_id

              from dwh.flat_trade_record tr
                       join dwh.d_account a on (a.account_id = tr.account_id)
                       join dwh.historic_security_definition_all hsd
                            on (hsd.instrument_id = tr.instrument_id)
                       left join lateral (
                  select alloc_qty, alloc_instr_id, clearing_account_id
                  from dwh.allocation2trade_record atr
                  where atr.trade_record_id = tr.trade_record_id
                    and atr.date_id = tr.date_id
                    and atr.is_active
                  limit 1) alt on true
                       left join staging.allocation_instruction ai
                                 on (ai.date_id between :in_start_date_id and :in_end_date_id and
                                     ai.alloc_instr_id = alt.alloc_instr_id and
                                     ai.is_deleted = 'N')
                       left join staging.allocation_instruction_entry aie
                                 on (aie.date_id between :in_start_date_id and :in_end_date_id and
                                     aie.alloc_instr_id = alt.alloc_instr_id and
                                     aie.clearing_account_id = alt.clearing_account_id)
                       left join dwh.d_clearing_account ca
                                 on (ca.clearing_account_id = aie.clearing_account_id)
              where tr.date_id between :in_start_date_id and :in_end_date_id
                and tr.account_id = any(:l_account_ids)
                and tr.is_busted = 'N'
              group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), ca.clearing_account_number,
                       hsd.display_instrument_id, tr.side, ai.alloc_instr_id,
                       hsd.contract_multiplier, a.eq_commission, tr.account_id;


end ;
$function$
;
