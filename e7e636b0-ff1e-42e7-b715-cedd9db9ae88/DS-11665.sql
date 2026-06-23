SELECT t1.*
FROM occ_data.occ_trade_data t1
WHERE t1.date_id = :in_date_id
--   and instrument_id = 186495473
  and t1.trade_type = '0'
  and clearing_member_number in ('00333', '00733', '333', '733')
    and gup_clearing_firm_originator is null
--   and rpt_id =  any(array[1810288196,1810288116,1661909542,1810288230,1810288237,1661841246]::text[])
  and t1.trade_id in (1751624721,1751624714,1751624724,1751624713,1751624717,1751624722,1751624718,1751649337)
--   and not exists (select null from genesis2.occ_data.occ_trade_data_matching t2
--                               where t2.rpt_id = t1.rpt_id and t2.date_id = t1.date_id)
  and NOT EXISTS (SELECT 1
                  FROM genesis2.occ_data.occ_trade_data_matching t2
                  WHERE t2.date_id = t1.date_id
                    and t2.trade_id = t1.trade_id
                    and t2.side = t1.side);


select * from genesis2.occ_data.occ_trade_data_matching t2
                  WHERE t2.date_id = :in_date_id
and is_procesed

select tr.instrument_id,
       tr.trade_id,
       to_char(tr.trade_record_time, 'MM/dd/yyyy'),
       os.root_symbol,-- as "Symbol",
       to_char(oc.maturity_month, 'FM00') || to_char(oc.maturity_day, 'FM00') ||
       to_char(oc.maturity_year, 'FM0000'),-- as "Expiration",
       oc.strike_price::text,-- as "Strike",
       case
           when oc.put_call = '0' then 'P'
           when oc.put_call = '1' then 'C'
           end-- as "PutCall",
--        sum(case when tr.side = '1' then 1 else -1 end * tr.last_qty)::text as "Quantity"

from occ_data.occ_trade_data tr
         inner join genesis2.option_contract oc on (oc.instrument_id = tr.instrument_id)
         inner join genesis2.option_series os on (oc.option_series_id = os.option_series_id)
--                 left join lateral ( select coalesce(hpm.portfolio_id, ac.trading_firm_id) as portfolio_id
--                                     from occ_data.occ_trade_data_matching mtr
--                                              join genesis2.account ac using (account_id)
--                                              left join fintech.hanweck_portfolio_mapping hpm using (trading_firm_id)
--                                     where mtr.date_id = tr.date_id
--                                       and mtr.trade_id = tr.trade_id
--                                       and mtr.side = tr.side
--                                       and mtr.trade_record_id != -1
--                                     limit 1) pf on true
where tr.date_id = :in_date_id
  and clearing_member_number in ('00333', '00733', '333', '733')
  and gup_clearing_firm_originator is null
  and trade_type = '0'
--           and tr.instrument_id = 186495473
  and not exists (select null
                  from occ_data.occ_trade_data cnc
                  where cnc.rpt_id = tr.rpt_id
                    and cnc.date_id = tr.date_id
                    and cnc.side = tr.side
                    and cnc.trans_type = '1')
  and not exists (select null
                  from occ_data.occ_matched_trade_record mr
                  where mr.date_id = tr.date_id
                    and mr.trade_id = tr.trade_id)
group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), os.root_symbol, oc.maturity_day, oc.maturity_month,
         oc.maturity_year, oc.strike_price, oc.put_call, tr.instrument_id
having sum(case when tr.side = '1' then 1 else -1 end * tr.last_qty) != 0;
        