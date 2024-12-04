select *
into temp table t_02
from fintech_reports.adh_parent_order_count2(
--         in_start_date_id integer DEFAULT get_dateid((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date),
--         in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
        in_instrument_type := 'O',
        in_trading_firm_ids := '{"cowen01"}');


select *
into temp table t_01
from dash360.reports_fintech_adh_parent_order_count_row(
    --         in_start_date_id integer DEFAULT get_dateid((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date),
--         in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
        in_instrument_type := 'O',
        in_trading_firm_id := '{"cowen01"}'
     )

Period,Account,Qty,Parent Order Count


select status_date_id,
               a.account_name,
               sum(coalesce(hods.order_qty, 0))::text,
               count(distinct parent_order_id) as cnt
into temp table t_03
        from data_marts.f_parent_order hods
                 join dwh.d_account a on a.account_id = hods.account_id
--         join lateral (select client_order_id from dwh.client_order cl where cl.order_id = hods.parent_order_id limit 1) cl on true
        where hods.Status_Date_id between :in_start_date_id and :in_end_date_id
          and case when :in_instrument_type is null then true else hods.instrument_type_id = :in_instrument_type end
--           and hods."CustomerOrderID" is null
          and case when :in_trading_firm_id is null then true else a.trading_firm_id = any(:in_trading_firm_id) end
          and case when :in_account_id is null then true else a.account_id = any(:in_account_id) end
        group by status_date_id, a.account_name--, hods."ClientID"

        select * from t_03
        order by 1, 3
        select * from t_01


select distinct trade_liquidity_indicator from dwh.flat_trade_record
where date_id = 20241203
and instrument_type_id = 'E'