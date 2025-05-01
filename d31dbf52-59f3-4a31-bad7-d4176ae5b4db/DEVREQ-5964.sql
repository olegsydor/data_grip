select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           coalesce(tr.client_order_id, '')            as "OrderID",
           coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
           tr.account_id,
             coalesce(tr.secondary_exch_exec_id, '')     as "ReportID",
           coalesce(tr.exch_exec_id, '')               as "Tag17",
           *
    from dwh.flat_trade_record tr
             left join lateral (select jo.fix_message ->> '143'  as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true

             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')
      and tr.client_order_id = '20250325VSIND28939'
      and tr.date_id between :l_start_date_id and :p_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;