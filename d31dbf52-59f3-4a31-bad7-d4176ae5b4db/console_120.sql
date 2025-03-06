select * from dwh.flat_trade_record
where date_id = 20241202
and client_order_id = '00188866720ESNY1'
and secondary_order_id = 'CMAA1211-20241202';



create temp table tmp_606_isi_bill_changes with (parallel_workers = 4)
                                           ON COMMIT drop as
select to_char(tr.trade_record_time, 'YYYY-MM-DD')         as report_date,
     tr.client_order_id as "OrderID",
     tr.secondary_order_id                                  as report_id,
     tr.secondary_exch_exec_id                                     as tag_17,
     tr.exch_exec_id                           as street_tag_17

from dwh.flat_trade_record tr
         left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and
                                                      jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
where true
    and tr.date_id = 20241202
and tr.client_order_id = '00188866720ESNY1'
and tr.secondary_order_id = 'CMAA1211-20241202';
-- and tr.date_id between :l_start_date_id and :p_end_date_id
  and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id = ANY (:l_trading_firm_ids))
  and tr.is_busted = 'N'
  and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') <>
                                           'DASH-CBOE') -- DEVREQ-4314 Exclude any execution on orders routed to non-DASH DASHOMS orders.
;