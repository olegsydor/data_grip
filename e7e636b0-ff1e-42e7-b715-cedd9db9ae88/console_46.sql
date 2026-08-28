select * from genesis2.rt_clearing_trade_record where date_id = 20260805 and client_order_id in ('ER-20260805-48385','ER-20260805-57792')


select * from genesis2.trade_record
where date_id = 20260805
--    and client_order_id in ('ER-20260805-48385','ER-20260805-57792')
-- and secondary_exch_exec_id = '4087427';
and trade_record_id between 5304351380 - :incr and 5304351380 + :incr
and orig_trade_record_id is not null
;

2026-08-05 10:28:12.582784

select * from staging.trade_record_blaze7
where true
and trade_record_id = 5304351380;

select * from etl_subscriptions
where load_batch_id = 5304351380;


select * from exchange
where exchange_id = 'NITEL'


select * from staging.d_exchange
where exchange_id = 'NITEL'

select * from instrument
where instrument_id = 128126584

select * from staging.d_instrument
where instrument_id = 128126584

select *
    from genesis2.trade_record tr

--             inner join genesis2.account ac on ac.account_id = tr.account_id and ac.create_time < f_date_id::text::date
--        and coalesce(ac.delete_time, f_next_date) >= f_next_date
             inner join genesis2.mv_active_account_snapshot ac on ac.account_id = tr.account_id
             inner join genesis2.instrument i on (i.instrument_id = tr.instrument_id and i.is_deleted = 'N')

        --BAML Express change
             left join genesis2.exchange exch on (tr.exchange_id = exch.exchange_id and exch.is_deleted = 'N')
             left join staging.cusip_list_import lcl on (lcl.symbol = i.symbol and coalesce(lcl.symbol_suffix, 'NONE') =
                                                                                   coalesce(i.symbol_suffix, 'NONE'))

    where true
      and i.instrument_type_id = 'E'
      and (i.symbol not in (select test_symbol from dash_reporting.test_symbol_tb) or i.symbol = 'ZAZZT')
      and ac.eq_real_time_report_to_mpid is not null
      and coalesce(tr.ex_destination, 'NONE') not in ('BRKPT', 'TRAFX', 'JSEB', 'RPTR', 'SQHT', 'CTDH', 'WEEDN')
--      and tr.is_busted = 'N'
      and tr.orig_trade_record_id is null
      and client_order_id in ('ER-20260805-48385','ER-20260805-57792')
--       and tr.trade_record_id in (5303994560, 5304351380)
      and tr.date_id = :f_date_id;



select *
from genesis2.trade_record tr
--             inner join genesis2.account ac on ac.account_id = tr.account_id and ac.create_time < f_date_id::text::date
--        and coalesce(ac.delete_time, f_next_date) >= f_next_date
             inner join genesis2.mv_active_account_snapshot ac on ac.account_id = tr.account_id
             inner join genesis2.instrument i on (i.instrument_id = tr.instrument_id and i.is_deleted = 'N')
             left join staging.cusip_list_import LCL on (LCL.SYMBOL = I.SYMBOL and coalesce(LCL.symbol_suffix, 'NONE') =
                                                                                   coalesce(I.symbol_suffix, 'NONE'))
             left join genesis2.clearing_account ca
                       on CA.ACCOUNT_ID = AC.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.MARKET_TYPE = 'E' and
                          CA.IS_DELETED = 'N'
    where i.instrument_type_id = 'E'
      and (i.symbol not in (select test_symbol from dash_reporting.test_symbol_tb) or i.symbol = 'ZAZZT')
--       and cl.parent_order_id is null
      and ac.eq_real_time_report_to_mpid is not null
      and coalesce(ac.nscc_mpid, 'DFIN') <> 'DFIN'
--       and EX.EXEC_TYPE in ('F','G')
--      and tr.is_busted = 'N'
      and tr.orig_trade_record_id is null
      and coalesce(tr.ex_destination, 'NONE') not in ('BRKPT', 'TRAFX', 'JSEB', 'RPTR', 'SQHT', 'CTDH', 'WEEDN')
      and client_order_id in ('ER-20260805-48385','ER-20260805-57792')
      and tr.date_id = :f_date_id;




-- UAT
-- DROP FUNCTION genesis2.load_away_trade(text, text);

