select tr.account_id,
       tr.trade_record_id,
       'A',
       exc.mic_code,
       'O',
       to_char(tr.trade_record_time, 'yyyyMMdd'),   -- as "Date",
       to_char(tr.trade_record_time, 'HH24:MI:SS'), -- as "Time",
       hsd.underlying_symbol,
       to_char(hsd.maturity_date, 'yyyyMMdd'),
       hsd.strike_px,
       case hsd.put_call when 'C' then 'Call' when 'P' then 'Put' end,
       case when tr.SIDE in ('2', '5') then 'Sell' else 'Buy' end,
       tr.last_px,
       tr.secondary_order_id,
       tr.secondary_exch_exec_id,
       tr.client_id,
       exc.mic_code,
       last_qty,
       case when tr.open_close = 'C' then 'Close' when tr.open_close = 'O' then 'Open' end

from dwh.flat_trade_record tr
         join dwh.d_account da on (da.account_id = tr.account_id)
         join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
         left join dwh.d_exchange exc on (exc.exchange_id = tr.exchange_id and exc.is_active)
where tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.is_busted <> 'Y'
  and da.account_name not in (select * from fintech_dwh.users_fbw_tb)
  and tr.account_id = any (:l_account_ids)
  and tr.multileg_reporting_type in ('1', '2')
  and tr.instrument_type_id = 'O'
  and 'option'!!
        order by tr.date_id, tr.trade_record_id;
