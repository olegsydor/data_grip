select * from dash_reporting.reporting_getallocations(in_date_begin := 20250307, in_date_end := 20250307, in_account_ids := '{263007,12931}')

-- DROP FUNCTION dash_reporting.reporting_getallocations(text, _int8, int4, int4);

CREATE OR REPLACE FUNCTION dash_reporting.reporting_getallocations(in_trading_firm_id text DEFAULT NULL::text,
                                                                   in_account_ids bigint[] DEFAULT '{}'::integer[],
                                                                   in_date_begin integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                                   in_date_end integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
    RETURNS TABLE
            (
                "Date"               date,
                "TradingFirm"        character varying,
                "AccountName"        character varying,
                "OSI Symbol"         character varying,
                "Symbol"             character varying,
                "Expiration"         text,
                "OpenClose"          character,
                "InstrumentType"     character,
                "Side"               text,
                "Total Quantity"     bigint,
                "Average Price"      numeric,
                "Allocated Quantity" bigint,
                "Commission"         numeric,
                "Maker/Taker"        numeric,
                "Transaction"        numeric,
                "Trade Processing"   numeric,
                "Royalty"            numeric,
                cmta                 character varying,
                "OCC AID"            character varying
            )
    LANGUAGE plpgsql
AS $function$
-- 2022-02-07 SO remove order_id from group by https://dashfinancial.atlassian.net/browse/DS-4811
declare


begin
    return query
        with ftr as (
            select tr.date_id,
                   sum(tr.last_qty)                                            as sum_last_qty,
                   sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
                   tr.open_close,
--                   tr.order_id,
                   tr.instrument_id,
                   tr.account_id,
                   tr.side,
                   tr.cmta,
                   at.alloc_qty                                                as alloc_qty,
                   sum(tr.tcce_maker_taker_fee_amount)                         as tcce_maker_taker_fee_amount,
                   sum(tr.tcce_account_dash_commission_amount)                 as tcce_account_dash_commission_amount,
                   sum(tr.tcce_transaction_fee_amount)                         as tcce_transaction_fee_amount,
                   sum(tr.tcce_trade_processing_fee_amount)                    as tcce_trade_processing_fee_amount,
                   sum(tr.tcce_royalty_fee_amount)                             as tcce_royalty_fee_amount,
                   tr.street_account_name
            from dwh.flat_trade_record tr
                     join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
                     left join lateral (select alloc_qty
                                        from dwh.allocation2trade_record atr
                                        where atr.trade_record_id = tr.trade_record_id
                                          and atr.date_id = tr.date_id
                                          and atr.is_active
                                        limit 1) at on true
            where tr.date_id between in_date_begin and in_date_end
              and is_busted = 'N'
              and tr.order_id > 0
               and case when in_trading_firm_id is null then true else acc.trading_firm_id = in_trading_firm_id end
              and case when in_account_ids = '{}' then true else acc.account_id = any (in_account_ids) end
--              and tr.trade_record_reason = 'L'
            group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
                     tr.account_nickname, tr.street_account_name, at.alloc_qty
        )
        select date(ftr.date_id::text)                                                                              as "Date",
               tf.trading_firm_name                                                                                 as "TradingFirm",
               ac.account_name                                                                                      as "AccountName",
               oc.opra_symbol                                                                                       as "OSI Symbol",
               i.display_instrument_id                                                                              as "Symbol",
               right('0' || oc.maturity_day::text, 2) || '/' || right('0' || oc.maturity_month::text, 2) || '/' ||
               right(oc.maturity_year::text, 2)                                                                     as "Expiration",
               ftr.open_close                                                                                       as "OpenClose",
               i.instrument_type_id                                                                                 as "InstrumentType",
               case ftr.side when '1' then 'B' when '2' then 'S' else 'T' end                                       as "Side",
               ftr.sum_last_qty                                                                                     as "Total Quantity",
               ftr.avg_px                                                                                           as "Average Price",
               coalesce(ftr.alloc_qty, ftr.sum_last_qty)                                                            as "Allocated Quantity",
               round(ftr.tcce_account_dash_commission_amount / ftr.sum_last_qty *
                     coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                     6)                                                                                             as "Commission",
               round(ftr.tcce_maker_taker_fee_amount / ftr.sum_last_qty * coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                     6)                                                                                             as "Maker/Taker",
               round(ftr.tcce_transaction_fee_amount / ftr.sum_last_qty * coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                     6)                                                                                             as "Transaction",
               round(ftr.tcce_trade_processing_fee_amount / ftr.sum_last_qty *
                     coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                     6)                                                                                             as "Trade Processing",
               round(ftr.tcce_royalty_fee_amount / ftr.sum_last_qty * coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                     6)                                                                                             as "Royalty",
               ftr.cmta,
               ftr.street_account_name                                                                              as "OCC AID"

        from ftr
                 join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join dwh.d_option_contract oc on oc.instrument_id = ftr.instrument_id;

end ;
$function$
;
