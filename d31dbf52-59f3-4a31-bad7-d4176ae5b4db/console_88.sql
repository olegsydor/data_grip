select * from dwh.client_order
where true
    and create_date_id = 20240905
    client_order_id = '8a02ec80-4460-4b3d-8aec-ad1c768d267f ';


select * from dwh.execution
where execution.exch_exec_id = '40711000000002900000';


select --array_to_string(ARRAY [
       tr.order_process_time::date,
       tr.order_process_time::time,
       -- SYMBOL
       di.symbol,                                                                                 -- as "SYMBOL",
       ui.symbol,                                                                                 -- underlying_symbol
       to_char(oc.maturity_year, 'FM0000'),                                                       -- as "EXPYEAR",
       to_char(oc.maturity_month, 'FM00'),                                                        -- as "EXPMONTH",
       to_char(oc.maturity_day, 'FM00'),                                                          -- as "EXPDAY",
       to_char(oc.strike_price, 'FM99999990D0099'),                                               -- as "STRIKEPRICE",
       case when oc.put_call = '0' then 'P' when oc.put_call = '1' then 'C' end,                  -- as "PUTCALL",
       --
       case
           when tr.side = '1' then 'B'
           when tr.side in ('2', '5', '6') then 'S' end,                                          -- as "SIDE",
       tr.last_qty::text,                                                                         -- as "QUANTITY",
       to_char(tr.last_px, 'FM99999990D009999'),                                                  -- as "PRICE",

       case di.instrument_type_id when 'E' then 'EQUITY_OPTION' when 'O' then 'INDEX_OPTION' end, -- rate_category
       case di.instrument_type_id when 'E' then 0.51 when 'O' then 0 end,                         -- rate
       case when di.instrument_type_id = 'E' then tr.last_qty * 0.51 else 0 end,                  -- PFOF = rate * last_qty
       tr.client_order_id,
       tr.exec_id
--
--        tr.open_close,                                                                             -- as "CMTAOPENCLOSE",
--                                    ], ',', '')
from dwh.flat_trade_record tr
         join dwh.d_account ac on (ac.account_id = tr.account_id)
         join dwh.d_instrument di on di.instrument_id = tr.instrument_id
         left join dwh.d_option_contract oc on (oc.instrument_id = tr.instrument_id)
         left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
         left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
where tr.date_id between :in_start_date_id and :in_end_date_id
--   and ac.trading_firm_id = 'OFT0068'
      	and ac.account_name = '0007BYV'
--           and tr.instrument_type_id = 'O'
  and di.symbol in
      ('VIX', 'VIXW', 'SPX', 'SPXW', 'SPXPM', 'OEX', 'XEO', 'RUT', 'RUTW', 'DJX', 'XSP', 'MXEF', 'NDX', 'NDXP', 'NANOS',
       'SPIKE', 'MXACW', 'MXUSA', 'MXWLD')
  and tr.is_busted = 'N'
order by ac.account_name, di.symbol, tr.side;
