-- DROP FUNCTION dash360.dash360_report_client_commission_summary(_int8, text, int4, int4);

create or replace function dash360.report_fintech_eod_strategas_allocation(
    in_start_date_id integer,
    in_end_date_id integer)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];
    l_min_date_id int4;
begin
    l_step_id := 0;
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_strategas_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id = 'strategas';

--     l_account_ids := '{69406,62961,69406}';

    select coalesce(min(create_date_id), in_start_date_id)
    into l_min_date_id
    from dwh.gtc_order_status
    where close_date_id is null
      and account_id = any (l_account_ids);


    drop table if exists t_report;
    create temp table t_report as
    select tr.date_id,
           sum(tr.last_qty)                                            as sum_last_qty,
           sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
           tr.open_close,
           tr.instrument_id,
           tr.account_id,
           tr.side,
           tr.cmta,
           at.alloc_qty                                                as alloc_qty,
           sum(tr.client_commission_rate * tr.last_qty)                as client_commission,
           tr.blaze_account_alias
    from dwh.flat_trade_record tr
             join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
             left join lateral (select alloc_qty
                                from dwh.allocation2trade_record atr
                                where atr.trade_record_id = tr.trade_record_id
                                  and atr.date_id = tr.date_id
                                  and atr.is_active
                                limit 1) at on true

    where tr.date_id between in_start_date_id and in_end_date_id
      and is_busted = 'N'
      and tr.order_id > 0
      and acc.account_id = any (l_account_ids)
    group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
             tr.account_nickname, tr.street_account_name, at.alloc_qty, tr.blaze_account_alias;

    return query
        select 'Date,TradingFirm,AccountName,Alias,Side,Total Quantity,Symbol,Average Price,InstrumentType,Allocated Quantity,CMTA,Commission';

    return query
        select array_to_string(ARRAY [
                                   to_char(ftr.date_id::text::date, 'mm/dd/yyyy') , -- as "Date",
                                   tf.trading_firm_name , -- as "TradingFirm",
                                   replace(ac.account_name, '_DESK', ''),  -- as "AccountName",
                                   ftr.blaze_account_alias , -- as "Alias",
                                   case ftr.side when '1' then 'B' when '2' then 'S' else 'T' end , -- as "Side",
                                   ftr.sum_last_qty::text , -- as "Total Quantity",
                                   i.display_instrument_id , -- as "Symbol",
                                   to_char(ftr.avg_px, 'FM9999990.0099') , -- as "Average Price",
                                   i.instrument_type_id , -- as "InstrumentType",
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty)::text , -- as "Allocated Quantity",
                                   ftr.cmta,
                                   to_char(round(client_commission, 6), 'FM9999990.009999') -- as "Commission"
                                   ], ',', '')
        from t_report ftr
                 join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join dwh.d_option_contract oc on oc.instrument_id = ftr.instrument_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_strategas_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end;
$fx$
;

select replace(:account_name, '_DASH', '')

select *
from dash360.report_fintech_eod_strategas_allocation(20250805, 20250805);
select 1876+938
select array_agg(account_id) from dwh.d_account
where trading_firm_id = 'strategas'
select dash360.widget_get_client_commission_summary('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}', 'account_id', 20250804, 20250804)



select ft.account_id::varchar                                                          as aggr_field,
       sum(ft.client_commission_rate * ft.last_qty)                                    as client_commission,
       sum(case when ft.instrument_type_id = 'E' then ft.last_qty else 0 end)::numeric as traded_eqt_volume,
       sum(case when ft.instrument_type_id = 'O' then ft.last_qty else 0 end)::numeric as traded_opt_volume
from dwh.flat_trade_record ft
--          inner join data_marts.d_account acc on ft.account_id = acc.account_id
where ft.account_id = any ('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}')
  and ft.is_busted = 'N'
--and blaze_account_alias is not null
  and date_id between 20250805 and 20250805
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



select min(create_date_id)
from dwh.gtc_order_status
where close_date_id is null
and account_id = 69406



create temp table t_report as
    select tr.date_id,
                   sum(tr.last_qty)                                            as sum_last_qty,
                   sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
                   tr.open_close,
                   tr.instrument_id,
                   tr.account_id,
                   tr.side,
                   tr.cmta,
                   at.alloc_qty                                                as alloc_qty,
                   sum(tr.client_commission_rate)                              as client_commission_rate_amount,
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
--                                     and jsn.date_id >= 20250804
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



select * from fix_capture.fix_message_json jsn
where date_id >= 20250501
and jsn.fix_message ->> '10445' is not null
limit 100;


select * from dwh.flat_trade_record ftr
where date_id = 20250501
and order_fix_message_id in (100000042367098727,
100000042367370428,
100000042368177465,
100000042368245372,
100000042368245728,
100000042368262625,
100000042368262855,
100000042368263122,
100000042368263959,
100000042368264267
)
;

       select
                                   to_char(ftr.date_id::text::date, 'mm/dd/yyyy') , -- as "Date",
                                   tf.trading_firm_name , -- as "TradingFirm",
                                   ac.account_name , -- as "AccountName",
                                   ftr.trader_id , -- as "Alias",
                                   case ftr.side when '1' then 'B' when '2' then 'S' else 'T' end , -- as "Side",
                                   ftr.sum_last_qty::text , -- as "Total Quantity",
                                   i.display_instrument_id , -- as "Symbol",
                                   to_char(ftr.avg_px, 'FM9999990.0099') , -- as "Average Price",
                                   i.instrument_type_id , -- as "InstrumentType",
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty)::text , -- as "Allocated Quantity",
                                   ftr.cmta,
                                   to_char(round(ftr.client_commission_rate_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999'),
                                   ftr.client_commission_rate_amount * ftr.sum_last_qty -- as "Commission"
select ftr.client_commission_rate_amount * ftr.sum_last_qty, *

        from t_report ftr
                 join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join dwh.d_option_contract oc on oc.instrument_id = ftr.instrument_id;



      select 
                                   to_char(ftr.date_id::text::date, 'mm/dd/yyyy')  as "Date",
                                   tf.trading_firm_name  as "TradingFirm",
                                   ac.account_name  as "AccountName",
                                   ftr.trader_id  as "Alias",
                                   case ftr.side when '1' then 'B' when '2' then 'S' else 'T' end  as "Side",
                                   ftr.sum_last_qty::text  as "Total Quantity",
                                   i.display_instrument_id  as "Symbol",
                                   to_char(ftr.avg_px, 'FM9999990.0099')  as "Average Price",
                                   i.instrument_type_id  as "InstrumentType",
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty)::text  as "Allocated Quantity",
                                   ftr.cmta,
                                   to_char(round(ftr.tcce_account_dash_commission_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999') as "Commission",
                                   to_char(round(ftr.tcce_maker_taker_fee_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999')  as "Maker/Taker",
                                   to_char(round(ftr.tcce_transaction_fee_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999')  as "Transaction",
                                   to_char(round(ftr.tcce_trade_processing_fee_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999') as "Trade Processing",
                                   to_char(round(ftr.tcce_royalty_fee_amount / ftr.sum_last_qty *
                                                 coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6),
                                           'FM9999990.009999') -- as "Royalty"

        from t_report ftr
                 join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                 join dwh.d_account ac on ac.account_id = ftr.account_id
                 join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join dwh.d_option_contract oc on oc.instrument_id = ftr.instrument_id;


select * from dwh.flat_trade_record
where account_id = any('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}')
and date_id > 20250101

---

select
           sum(tr.last_qty)                                            as sum_last_qty,
           tr.account_id,
           sum(tr.client_commission_rate * tr.last_qty)                as client_commission

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
                                  and jsn.date_id >= :l_min_date_id
                                limit 1) jsn on true
    where tr.date_id between :in_start_date_id and :in_end_date_id
      and is_busted = 'N'
      and tr.order_id > 0
      and acc.account_id = any (:l_account_ids)
--     AND ACC.ACCOUNT_ID = 74177
    group by tr.account_id,
        tr.date_id, tr.open_close, tr.instrument_id, tr.side, tr.cmta,
             tr.account_nickname, tr.street_account_name, at.alloc_qty, trader_id;




select ft.account_id::varchar                                                          as aggr_field,
       sum(ft.client_commission_rate * ft.last_qty)                                    as client_commission,
       sum(case when ft.instrument_type_id = 'E' then ft.last_qty else 0 end)::numeric as traded_eqt_volume,
       sum(case when ft.instrument_type_id = 'O' then ft.last_qty else 0 end)::numeric as traded_opt_volume
from dwh.flat_trade_record ft
--          inner join data_marts.d_account acc on ft.account_id = acc.account_id
-- where ft.account_id = any ('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}')
    WHERE ACCOUNT_ID = 74177
  and ft.is_busted = 'N'
--and blaze_account_alias is not null
  and date_id between 20250805 and 20250805
group by ft.account_id;

select * from dwh.d_account ac
         join dwh.d_trading_firm tf using (trading_firm_id)
where ac.account_id = 74177--any ('{73994,74109,74108,74139,74170,74172,74174,74177,74188,74198,74199,74285,74396,74397,74398,74399,74130,74863,74999,75091,75112,75113,75114,74176,74998,75287,74169,75298,75255,75370,75371,75372,75381,75382}')


