/*
  select array_to_string(ARRAY [
                                   to_char(tr.trade_record_time, 'MM/dd/yyyy'),-- as "Date",
                                   coalesce(hpm.portfolio_id, ac.trading_firm_id),-- as "PortfolioId",
                                   null,-- as "SubPortfolioId",
                                   os.root_symbol,-- as "Symbols",
                                   to_char(oc.maturity_month, 'FM00') || to_char(oc.maturity_day, 'FM00') ||
                                   to_char(oc.maturity_year, 'FM0000'),-- as "Expiration",
                                   oc.strike_price::text,-- as "Strike",
                                   case when oc.put_call = '0' then 'P' when oc.put_call = '1' then 'C' end,-- as "PutCall",
                                   di.instrument_type_id,-- as "InstType",
                                   'O',-- as "PositionType",
                                   null,-- as "Exchange",
                                   sum(tr.last_qty * (case when tr.side = '1' then 1.0 else -1.0 end))::text,-- as "Quantity",
                                   null,-- as "PosSettleDate",
                                   null,-- as "Cash",
                                   null -- as "ClientInfo"
                                   ], ',', '')
        from genesis2.trade_record tr
                 join genesis2.account ac on (ac.account_id = tr.account_id)
                 join genesis2.instrument di on (di.instrument_id = tr.instrument_id)
                 join genesis2.option_contract oc on (oc.instrument_id = tr.instrument_id)
                 join genesis2.option_series os on (os.option_series_id = oc.option_series_id)
                 left join fintech.hanweck_portfolio_mapping hpm on (hpm.trading_firm_id = ac.trading_firm_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and di.instrument_type_id = 'O'
          and tr.is_busted = 'N'
          and coalesce(tr.is_billed, 'N') != 'R' --Unreported
          and ac.opt_report_to_mpid = 'MLCB'     --PTA Trades
        group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), coalesce(hpm.portfolio_id, ac.trading_firm_id), os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id
        order by to_char(tr.trade_record_time, 'MM/dd/yyyy'), coalesce(hpm.portfolio_id, ac.trading_firm_id), os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id;


  SELECT t1.trans_type, t1.side, t1.last_qty,  t1.*

  FROM occ_data.occ_trade_data t1
WHERE date_id = 20260605 and instrument_id = 186495473 and trade_type = '0' AND
NOT EXISTS (
    SELECT 1
    FROM genesis2.occ_data.occ_trade_data_matching t2
    WHERE date_id = 20260605 and instrument_id = 186495473 AND
    t2.trade_id = t1.trade_id
);

 */
 select * from  genesis2.occ_data.occ_trade_data
 where date_id = 20260612;

 SELECT *
    FROM genesis2.occ_data.occ_trade_data_matching t2
    WHERE date_id = 20260605;



with base as (SELECT t1.instrument_id,
                     sum(t1.last_qty * (case when t1.side = '1' then 1.0 else -1.0 end)) as "Quantity"
              FROM occ_data.occ_trade_data t1
--                        join instrument di on di.instrument_id = t1.instrument_id
              WHERE true
                and date_id = :in_date_id
--   and t1.instrument_id = 186495473
                and trade_type = '0'
                AND NOT EXISTS (SELECT null
                                FROM genesis2.occ_data.occ_trade_data_matching t2
                                WHERE t2.date_id = :in_date_id
                                  AND t2.trade_id = t1.trade_id)
              group by t1.instrument_id
              having sum(t1.last_qty * (case when t1.side = '1' then 1.0 else -1.0 end)) <> 0)
select *
from base
         left join lateral (select sum(tr.last_qty * (case when tr.side = '1' then 1.0 else -1.0 end)) as "Quantity"
                            from genesis2.trade_record tr
--                                      join genesis2.account ac on (ac.account_id = tr.account_id)
                                     join genesis2.instrument di on (di.instrument_id = tr.instrument_id)
                            where true
                              and tr.date_id = :in_date_id
                              and di.instrument_type_id = 'O'
                              and tr.is_busted = 'N'
                              and tr.is_billed is distinct from 'R' --Unreported
--                               and ac.opt_report_to_mpid = 'MLCB'     --PTA Trades
                              and di.instrument_id = base.instrument_id
    ) tr on true
where tr."Quantity" is distinct from base."Quantity"

create temp table t_base as
SELECT t1.instrument_id,
       sum(t1.last_qty * (case when t1.side = '1' then 1.0 else -1.0 end)) as "Quantity"
FROM occ_data.occ_trade_data t1
--                        join instrument di on di.instrument_id = t1.instrument_id
WHERE true
  and date_id = :in_date_id
--   and t1.instrument_id = 186495473
  and trade_type = '0'
  AND NOT EXISTS (SELECT null
                  FROM genesis2.occ_data.occ_trade_data_matching t2
                  WHERE t2.date_id = :in_date_id
                    AND t2.trade_id = t1.trade_id)
group by t1.instrument_id
having sum(t1.last_qty * (case when t1.side = '1' then 1.0 else -1.0 end)) <> 0;


select sum(tr.last_qty * (case when tr.side = '1' then 1.0 else -1.0 end)) as "Quantity",
       di.instrument_id
from genesis2.trade_record tr
--                                      join genesis2.account ac on (ac.account_id = tr.account_id)
         join genesis2.instrument di on (di.instrument_id = tr.instrument_id)
where true
  and tr.date_id = :in_date_id
  and di.instrument_type_id = 'O'
  and tr.is_busted = 'N'
  and tr.is_billed is distinct from 'R' --Unreported
--                               and ac.opt_report_to_mpid = 'MLCB'     --PTA Trades
and di.instrument_id in (select instrument_id from t_base)
group by di.instrument_id


select * from t_base