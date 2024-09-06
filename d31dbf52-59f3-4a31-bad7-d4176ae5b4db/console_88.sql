select * from dwh.client_order
where true
    and create_date_id = 20240905
    client_order_id = '8a02ec80-4460-4b3d-8aec-ad1c768d267f ';


select * from dwh.execution
where execution.exch_exec_id = '40711000000002900000';


select process_time::date, process_time::time, di.symbol, * from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id
                                                join dwh.d_instrument di on di.instrument_id = cl.instrument_id
where true
    and create_date_id >= 20240805
    and ac.trading_firm_id = 'OFT0068'