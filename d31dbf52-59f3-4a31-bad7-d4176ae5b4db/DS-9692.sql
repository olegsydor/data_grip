-- DROP FUNCTION dwh.dash360_widgets_latest_orders_summary_tbl(int4);

CREATE OR REPLACE FUNCTION dwh.dash360_widgets_latest_orders_summary_tbl(in_date_id integer)
    RETURNS TABLE
            (
                exec_time             timestamp without time zone,
                account_id            integer,
                trading_firm_id       character varying,
                max_exec_id           bigint,
                order_id              bigint,
                client_order_id       character varying,
                side                  character,
                order_qty             integer,
                order_px              numeric,
                instrument_type_id    character,
                display_instrument_id character varying,
                exec_qty              integer,
                avg_px                numeric,
                execution_cost        numeric,
                sub_strategy          character varying,
                client_id             character varying
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
DECLARE
-- 20240315 AK: https://dashfinancial.atlassian.net/browse/DS-8099 dash360_widgets_latest_orders_summary_tbl widget shows wrong exec_qty values
-- 20260112 OS: https://dashfinancial.atlassian.net/browse/DS-9692 [D360] Fix orders widet by removing impact from Away Trades and changed TRs where account_id was changed
begin
    drop table if exists t_data_cet;
    create temp table t_data_cet as
    select last_trade_record_id, order_avg_px, order_execution_cost, leaves_qty--,order_qty,leaves_qty
    from (select max(last_trade_record_id)                                                                       as last_trade_record_id,
                 row_number()
                 over (partition by pt.account_id,pt.instrument_type_id order by max(last_trade_record_id) desc) as rnk,
                 sum(pt.last_qty * pt.last_px) /
                 nullif(sum(pt.last_qty), 0)                                                                     as order_avg_px,
                 sum(coalesce(pt.tcce_maker_taker_fee_amount, 0) +
                     coalesce(pt.tcce_transaction_fee_amount, 0) +
                     coalesce(pt.tcce_trade_processing_fee_amount, 0) +
                     coalesce(pt.tcce_royalty_fee_amount, 0) +
                     coalesce(pt.tcce_account_dash_commission_amount, 0))                                        as order_execution_cost,
                 min(pt.leaves_qty)                                                                              as leaves_qty
          from (select ftr.last_qty,
                       ftr.last_px,
                       ftr.tcce_maker_taker_fee_amount,
                       ftr.tcce_transaction_fee_amount,
                       ftr.tcce_trade_processing_fee_amount,
                       ftr.tcce_royalty_fee_amount,
                       ftr.tcce_account_dash_commission_amount,
                       ftr.leaves_qty,
                       ftr.account_id,
                       ftr.order_id,
                       di.instrument_type_id,
                       first_value(ftr.trade_record_id)
                       over (partition by ftr.account_id, ftr.order_id, di.instrument_type_id order by ftr.trade_record_time desc,ftr.trade_record_id desc) as last_trade_record_id
                from dwh.flat_trade_record ftr
                         inner join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
                where ftr.is_busted = 'N'
                  and ftr.order_id > 0 --filter out LP orders
                  and date_id = :in_date_id) pt
          group by pt.account_id, pt.order_id,
                   pt.instrument_type_id) trades
    where RNK <= 15;

    return query
        select ft.trade_record_time         as exec_time, --trade_record_time
               ft.account_id,
               ft.trading_firm_id,
               ft.exec_id                   as max_exec_id,
               ft.order_id,
               ft.client_order_id,
               ft.side,
               ft.order_qty,
               ft.order_price               as order_px,
               i.instrument_type_id,
               i.display_instrument_id2     as display_instrument_id,
               ft.order_qty - ft.leaves_qty as exec_qty,
               ds.order_avg_px              as avg_px,
               ds.order_execution_cost      as execution_cost,
               ft.sub_strategy,
               ft.client_id
        from t_data_set ds
                 inner join dwh.flat_trade_record ft on (ft.trade_record_id = ds.last_trade_record_id)
                 inner join dwh.d_instrument i on i.instrument_id = ft.instrument_id
                 inner join dwh.d_account a on ft.account_id = a.account_id
        where ft.date_id = in_date_id
          and ft.order_id is not null;
end;
$function$
;


