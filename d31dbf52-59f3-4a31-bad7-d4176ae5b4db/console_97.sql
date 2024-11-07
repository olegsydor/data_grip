select * from trash.so_worm_orders
from eod_reports.export_rbc_orders_tbl(in_start_date_id=>20181001, in_end_date_id=>20181231)
;
select array_agg(v)
from (select distinct "Underlying Symbol" as v
      from trash.so_worm_orders
--       where "Ask Px" is null
--         order by 1 nulls first
      limit 5) x

select *
from eod_reports.export_rbc_trades_tbl(in_start_date_id=>20181001, in_end_date_id=>20181231)

select tr.account_id, count(*)
 from dwh.flat_trade_record tr
             join dwh.d_instrument di on (di.instrument_id = tr.instrument_id)
    where tr.date_id between :in_start_date_id and :in_end_date_id
      and tr.is_busted = 'N'
      and di.instrument_type_id = any(:l_instrument_type_ids)
      group by tr.account_id
      and tr.account_id = any (l_account_ids);

select * from dash360.report_fintech_eod_pershing_ps_trade_file(in_start_date_id := 20241107, in_end_date_id:= 20241107, in_account_ids := '{8112}');

select lpad('1', 5, '0');
drop table t_rec
select sum(last_qty) from t_rec
where side = 'S'