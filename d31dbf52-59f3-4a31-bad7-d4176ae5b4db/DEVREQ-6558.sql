-- DROP FUNCTION dash360.dash360_report_client_commission_summary(_int8, text, int4, int4);

CREATE OR REPLACE FUNCTION dash360.dash360_report_client_commission_summary(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                            in_mode text DEFAULT 'account_id'::text,
                                                                            in_date_id integer DEFAULT NULL::integer,
                                                                            in_date_id_end integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                "Account name / Alias name" character varying,
                "Opt Volume"                numeric,
                "Eqt Volume"                numeric,
                "Commission"                numeric
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
    l_sql varchar;
begin

    if in_mode not in ('account_id', 'blaze_account_alias')
    then
        raise 'Incorrect in_mode parameter. It should be ''account_name'' or ''blaze_account_alias''';
    end if;
    --   coalesce(sum(summary.client_commission), 0.00000000::numeric)
    l_sql := 'sum(summary.traded_opt_volume), sum(summary.traded_eqt_volume), coalesce(sum(summary.client_commission), 0.00000000::numeric)
from (
select coalesce(aggr_field,''Not specified'') as aggr_field,client_commission,traded_eqt_volume,traded_opt_volume from dash360.widget_get_client_commission_summary($1, $2, $3, $4)
) summary ';

    if in_mode = 'account_id'
    then
        l_sql := 'select coalesce(da.account_name, ''Total'') as account, ' || l_sql ||
                 'join dwh.d_account da on summary.aggr_field::integer = da.account_id group by rollup(da.account_name) having count(*)>0 order by grouping(da.account_name)';
    elsif in_mode = 'blaze_account_alias'
    then
        l_sql := 'select coalesce(summary.aggr_field, ''Total'') as alias, ' || l_sql ||
                 'group by rollup(summary.aggr_field) having count(*)>0 order by grouping(summary.aggr_field)';
    end if;

    raise notice 'sql: %', l_sql;
    return query
        execute l_sql using in_account_ids, in_mode, in_date_id, in_date_id_end;


end;
$function$
;
select array_agg(account_id) from dwh.d_account
where trading_firm_id = 'strategas'
select dash360.widget_get_client_commission_summary('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}', 'account_id', 20250804, 20250804)



select ft.account_id::varchar                                                          as aggr_field,
       sum(ft.client_commission_rate * ft.last_qty)                                    as client_commission,
       sum(case when ft.instrument_type_id = 'E' then ft.last_qty else 0 end)::numeric as traded_eqt_volume,
       sum(case when ft.instrument_type_id = 'O' then ft.last_qty else 0 end)::numeric as traded_opt_volume
from dwh.flat_trade_record ft
         inner join data_marts.d_account acc on ft.account_id = acc.account_id
where case when $1 = '{}' then true else ft.account_id = any ($1) end
  and ft.is_busted = 'N'
--and blaze_account_alias is not null
  and date_id between $2 and $3
group by ft.account_id;


select * from dash360.dash360_report_client_commission_summary(in_account_ids := '{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}',
                                                               in_mode := 'account_id', in_date_id := 20250804, in_date_id_end := 20250804);


select coalesce(da.account_name, 'Total') as account,
       sum(summary.traded_opt_volume),
       sum(summary.traded_eqt_volume),
       coalesce(sum(summary.client_commission), 0.00000000::numeric)
from (select coalesce(aggr_field, 'Not specified') as aggr_field,
             client_commission,
             traded_eqt_volume,
             traded_opt_volume
      from dash360.widget_get_client_commission_summary($1, $2, $3, $4)) summary
         join dwh.d_account da on summary.aggr_field::integer = da.account_id
group by rollup (da.account_name)
having count(*) > 0
order by grouping(da.account_name);





create temp table t_report as
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
                   trader_id
            from dwh.flat_trade_record tr
                     join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
                     left join lateral (select alloc_qty
                                        from dwh.allocation2trade_record atr
                                        where atr.trade_record_id = tr.trade_record_id
                                          and atr.date_id = tr.date_id
                                          and atr.is_active
                                        limit 1) at on true
                             left join lateral (select jsn.fix_message ->> '10445' as trader_id
                                    from fix_capture.fix_message_json jsn
                                    where jsn.date_id >= public.get_dateid(tr.order_process_time::date)
                                      and jsn.fix_message_id = tr.order_fix_message_id
                                    limit 1) jsn on true
            where tr.date_id between :in_date_begin and :in_date_end
              and is_busted = 'N'
              and tr.order_id > 0
              and case when :in_trading_firm_id is null then true else acc.trading_firm_id = :in_trading_firm_id end
              and case when :in_account_ids = '{}' then true else acc.account_id = any (:in_account_ids) end
            group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
                     tr.account_nickname, tr.street_account_name, at.alloc_qty, trader_id


        select date(ftr.date_id::text)                                                                              as "Date",
               tf.trading_firm_name                                                                                 as "TradingFirm",
               ac.account_name                                                                                      as "AccountName",
               ftr.trader_id as "Alias",
               case ftr.side when '1' then 'B' when '2' then 'S' else 'T' end                                       as "Side",
               ftr.sum_last_qty                                                                                     as "Total Quantity",
               i.display_instrument_id                                                                              as "Symbol",
               ftr.avg_px                                                                                           as "Average Price",
               i.instrument_type_id                                                                                 as "InstrumentType",
               coalesce(ftr.alloc_qty, ftr.sum_last_qty)                                                            as "Allocated Quantity",
               ftr.cmta,
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
                     6)                                                                                             as "Royalty"

--                oc.opra_symbol                                                                                       as "OSI Symbol",
--
--                right('0' || oc.maturity_day::text, 2) || '/' || right('0' || oc.maturity_month::text, 2) || '/' ||
--                right(oc.maturity_year::text, 2)                                                                     as "Expiration",
--                ftr.open_close                                                                                       as "OpenClose"

        from t_report ftr
                 join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join dwh.d_option_contract oc on oc.instrument_id = ftr.instrument_id;
