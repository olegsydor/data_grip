-- data_marts.dash360_reports_sor_strategy_data -> dash360.report_perf_xtx_sor_child_orders

-- Strategy Step
-- Sec Type
-- Root
-- Ex Dest - Cust
-- TIF
-- Ord Type
-- Client ID
-- Bid Qty
-- Bid Px
-- Ask Qty
-- Ask Px
-- Strategy

-- DROP FUNCTION data_marts.dash360_reports_sor_strategy_data(_varchar, _int8, varchar, int4, int4, _varchar, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_perf_xtx_sor_child_orders(in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                    in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                    in_instrument_type_id character varying DEFAULT NULL::character varying(1),
                                                                    in_start_status_date_id integer DEFAULT NULL::integer,
                                                                    in_end_status_date_id integer DEFAULT NULL::integer,
                                                                    in_sub_strategies character varying[] DEFAULT '{}'::character varying[],
                                                                    in_exchange_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                parent_cl_ord_id   character varying,
                account_name       character varying,
--                 strategy_step      integer,
                order_status_desc  character varying,
                routed_time        timestamp without time zone,
                street_cl_ord_id   character varying,
--                 sec_type           character,
                side               character,
                order_qty          integer,
                parent_order_qty   integer,
--                 root_symbol        character varying,
                symbol             character varying,
                expiration_date    timestamp without time zone,
                street_order_price numeric,
                avg_px             numeric,
                street_exec_qty    integer,
                parent_exec_qty    integer,
                leaves_qty         integer,
--                 tif_name           character varying,
--                 order_type_name    character varying,
--                 client_id          character varying,
--                 nbbo_bid_quantity  integer,
--                 nbbo_bid_price     numeric,
--                 nbbo_ask_quantity  integer,
--                 nbbo_ask_price     numeric,
                strategy_user_data character varying,
                strategy_name      character varying,
                exchange_name      character varying
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- AK 20250424 https://dashfinancial.atlassian.net/browse/DS-9765
-- OS 20260528 https://dashfinancial.atlassian.net/browse/DS-11582 EOD Routing/Trades File for XTX
DECLARE

    l_load_id      int;
    l_row_cnt      int;
    l_step_id      int;
    l_array_symbol varchar[];

begin

    l_array_symbol := array_agg(dts.symbol) from dwh.d_test_symbol dts;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_perf_xtx_sor_child_orders' || ' STARTED ===', 0, 'O')
    into l_step_id;

    RETURN QUERY
        select f_par.client_order_id        as                                 parent_cl_ord_id,
               acc.account_name             as                                 account_name,
               f_str.wave_no::integer       as                                 strategy_step,
               osd.order_status_description as                                 order_status_desc,
               f_str.routed_time            as                                 routed_time,
               f_str.client_order_id        as                                 street_cl_ord_id,
               i.instrument_type_id         as                                 sec_type,
               f_par.side as side,
               f_str.order_qty              as                                 order_qty,
               f_par.order_qty              as                                 parent_order_qty,
               i.symbol                     as                                 root_symbol,
               i.display_instrument_id      as                                 symbol,
               i.last_trade_date::timestamp as                                 expiration_date,
               f_str.order_price            as                                 street_order_price,
               f_str.day_avg_px             as                                 avg_px,
               f_str.day_cum_qty                                               street_exec_qty,
               f_par.day_cum_qty                                               parent_exec_qty,
               f_str.day_leaves_qty                                            leaves_qty,
               tif.tif_name,
               ot.order_type_name,
               f_par.client_id,
               f_str.nbbo_bid_quantity,
               f_str.nbbo_bid_price,
               f_str.nbbo_ask_quantity,
               f_str.nbbo_ask_price,
               sdrc.strategy_user_data,
               coalesce(bsn.bloomberg_strategy_name, dss.target_strategy_name) strategy_name,
               real_exch.exchange_name
        from data_marts.f_yield_capture f_str
                 inner join data_marts.f_yield_capture f_par on f_par.order_id = f_str.parent_order_id and
                                                                f_par.status_date_id between start_status_date_id and end_status_date_id and
                                                                f_par.parent_order_id is null
                 inner join data_marts.d_account acc on (acc.account_id = f_par.account_id)
                 inner join data_marts.d_instrument i on (i.instrument_id = f_par.instrument_id)
                 inner join dwh.d_target_strategy dss on f_par.sub_strategy_id = dss.target_strategy_id
                 left join dwh.d_order_type ot on ot.order_type_id = f_par.order_type_id
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = f_par.time_in_force_id
                 left join dwh.d_strategy_decision_reason_code sdrc on sdrc.is_active and
                                                                       sdrc.strategy_decision_reason_code =
                                                                       f_str.strategy_decision_reason_code
                 left join dwh.d_exchange exch on (f_str.exchange_unq_id = exch.exchange_unq_id)
                 left join dwh.d_exchange real_exch
                           on (exch.real_exchange_id = real_exch.exchange_id and real_exch.is_active)
                 left join lateral (select (fmj.fix_message ->> '9150')::int as tag_9150
                                    from fix_capture.fix_message_json fmj
                                    where f_par.order_fix_message_id = fmj.fix_message_id
                                      and fmj.message_type not in ('8', '9', 'F')
                                      and fmj.date_id between start_status_date_id and end_status_date_id
                                    limit 1) fm on true
                 left join dwh.d_bloomberg_strategy_name bsn on (acc.trading_firm_id = bsn.trading_firm_id and
                                                                 dss.target_strategy_name =
                                                                 bsn.original_sub_strategy and
                                                                 coalesce(fm.tag_9150, -1) =
                                                                 coalesce(bsn.aggression_level, -1))
                 left join lateral
            (
            select os.order_status_description
            from dwh.execution ex
                     left join dwh.d_order_status os on (ex.order_status = os.order_status)
            where ex.order_id = f_par.order_id
              and ex.exec_date_id = f_par.status_date_id
              and ex.exec_date_id between in_start_status_date_id and in_end_status_date_id
              and ex.order_status <> '3'
            order by ex.exec_id desc
            limit 1
            ) osd on true
        where f_str.parent_order_id is not null
          and f_str.multileg_reporting_type in ('1', '2')
          and i.symbol != any (l_array_symbol)
          and f_str.status_date_id between in_start_status_date_id and in_end_status_date_id
          and case when in_trading_firm_ids <> '{}' then acc.trading_firm_id = any (in_trading_firm_ids) else true end
          and case when in_account_ids <> '{}' then f_par.account_id = any (in_account_ids) else true end
          and case when in_sub_strategies <> '{}' then dss.target_strategy_name = any (in_sub_strategies) else true end
          and case
                  when in_instrument_type_id is not null then i.instrument_type_id = in_instrument_type_id
                  else true end
          and case when in_exchange_ids <> '{}' then real_exch.exchange_id = any (in_exchange_ids) else true end;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_perf_xtx_sor_child_orders' || ' COMPLETED ===', 0, 'O')
    into l_step_id;

end;
$function$
;
