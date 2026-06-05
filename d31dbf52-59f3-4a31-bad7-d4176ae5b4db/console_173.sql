
-- DROP FUNCTION data_marts.dash360_reports_sor_strategy_data(_varchar, _int8, varchar, int4, int4, _varchar, _varchar);
select *
from dash360.report_perf_xtx_sor_child_orders(in_account_ids := '{63109}',
                                              in_start_status_date_id := 20260605, in_end_status_date_id := 20260605);

-- DROP FUNCTION dash360.report_perf_xtx_sor_child_orders(_varchar, _int8, varchar, int4, int4, _varchar, _varchar);
select * from dwh.d_exchange
CREATE OR REPLACE FUNCTION dash360.report_perf_xtx_sor_child_orders(in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                    in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                    in_start_status_date_id integer DEFAULT NULL::integer,
                                                                    in_end_status_date_id integer DEFAULT NULL::integer,
                                                                    in_exchange_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Parent Cl Ord ID" character varying,
                "Account"          character varying,
                "Ord Status"       character varying,
                "Event Date"       text,
                "Routed Time"      text,
                "Street Cl Ord ID" character varying,
                "Side"             text,
                "Parent Ord Qty"   integer,
                "Child Ord Qty"    integer,
                "Symbol"           character varying,
                "Exp Date"         timestamp without time zone,
                "Price"            numeric,
                "Avg Px"           numeric,
                "Ex Qty"           integer,
                "Lvs Qty"          integer,
                "Exchange Name"    character varying
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
        select f_par.client_order_id                                                                    as "Parent Cl Ord ID",
               acc.account_demo_mnemonic                                                                as "Account",
               osd.order_status_description                                                             as "Ord Status",
               to_char(f_str.routed_time, 'DD-MM-YYYY')                                                 as "Event Date",
               to_char(f_str.routed_time, 'HH24:MI:SS.MS')                                              as "Routed Time",
               f_str.client_order_id                                                                    as "Street Cl Ord ID",
               case when f_par.side = '1' then 'Buy' when f_par.side in ('2', '5', '6') then 'Sell' end as "Side",
               f_par.order_qty                                                                          as "Parent Ord Qty",
               f_str.order_qty                                                                          as "Child Ord Qty",
               i.display_instrument_id                                                                  as "Symbol",
               i.last_trade_date::timestamp                                                             as "Exp Date",
               f_str.order_price                                                                        as "Price",
               f_str.day_avg_px                                                                         as "Avg Px",
               f_str.day_cum_qty                                                                        as "Ex Qty",
               f_str.day_leaves_qty                                                                     as "Lvs Qty",
               real_exch.exchange_name                                                                  as "Exchange Name"
        from data_marts.f_yield_capture f_str
                 inner join data_marts.f_yield_capture f_par on f_par.order_id = f_str.parent_order_id and
                                                                f_par.status_date_id between in_start_status_date_id and in_end_status_date_id and
                                                                f_par.parent_order_id is null
                 inner join dwh.d_account acc on (acc.account_id = f_par.account_id)
                 inner join dwh.d_instrument i on (i.instrument_id = f_par.instrument_id)
                 inner join dwh.d_target_strategy dss on f_par.sub_strategy_id = dss.target_strategy_id
                 join dwh.d_strategy_decision_reason_code sdrc on sdrc.is_active and
                                                                  sdrc.strategy_decision_reason_code =
                                                                  f_str.strategy_decision_reason_code
                 left join dwh.d_order_type ot on ot.order_type_id = f_par.order_type_id
                 left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = f_par.time_in_force_id
                 left join dwh.d_exchange exch on (f_str.exchange_unq_id = exch.exchange_unq_id)
                 left join dwh.d_exchange real_exch
                           on (exch.real_exchange_id = real_exch.exchange_id and real_exch.is_active)
                 left join lateral (select (fmj.fix_message ->> '9150')::int as tag_9150
                                    from fix_capture.fix_message_json fmj
                                    where f_par.order_fix_message_id = fmj.fix_message_id
                                      and fmj.message_type not in ('8', '9', 'F')
                                      and fmj.date_id between in_start_status_date_id and in_end_status_date_id
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
          and dss.target_strategy_name = 'RETAILNML'
          and f_par.exec_time::time between '09:30'::time and '16:00'::time
          and i.instrument_type_id = 'E'
          and sdrc.strategy_user_data in
              ('Maker/Taker order', 'Conditional Primary Peg order', 'Dark IOC Primary Peg order')
          and case when in_exchange_ids <> '{}' then real_exch.exchange_id = any (in_exchange_ids) else true end
          and f_str.order_price >= 1;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_perf_xtx_sor_child_orders' || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;


-- DROP FUNCTION data_marts.dash360_reports_sor_parent_orders(_varchar, _int8, varchar, int4, int4, _varchar);
select *
from dash360.report_perf_xtx_sor_parent_orders(in_account_ids := '{63109}',
                                              in_start_status_date_id := 20260604, in_end_status_date_id := 20260604);

CREATE OR REPLACE FUNCTION dash360.report_perf_xtx_sor_parent_orders(in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                     in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                     in_start_status_date_id integer DEFAULT NULL::integer,
                                                                     in_end_status_date_id integer DEFAULT NULL::integer
)
    RETURNS TABLE
            (

                "Cl Ord ID"     character varying,
                "Creation Date" text,
                "Creation Time" text,
                "Account"       character varying,
                "Side"          text,
                "Ord Qty"       integer,
                "Ex Qty"        integer,
                "Symbol"        character varying,
                "Price"         numeric,
                "Avg Px"        numeric
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- OS 20260528 https://dashfinancial.atlassian.net/browse/DS-11582 EOD Routing/Trades File for XTX
DECLARE
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin


    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_perf_xtx_sor_parent_orders' || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
        select f_par.client_order_id,
               to_char(f_par.routed_time, 'DD-MM-YYYY')                                                 as "Creation Date",
               to_char(f_par.routed_time, 'HH24:MI:SS.MS')                                              as "Creation Time",
               acc.account_demo_mnemonic                                                                as "Account",
               case when f_par.side = '1' then 'Buy' when f_par.side in ('2', '5', '6') then 'Sell' end as "Side",
               f_par.order_qty                                                                          as "Ord Qty",
               f_par.day_cum_qty                                                                        as "Ex Qty",
               i.display_instrument_id                                                                  as "Symbol",
               f_par.order_price                                                                        as "Price",
               f_par.day_avg_px                                                                         as "Avg Px"
        from data_marts.f_yield_capture f_par
                 inner join dwh.d_account acc on acc.is_active and acc.account_id = f_par.account_id
                 inner join dwh.d_instrument i on i.instrument_id = f_par.instrument_id
                 join dwh.d_strategy_decision_reason_code sdrc on sdrc.is_active and
                                                                  sdrc.strategy_decision_reason_code =
                                                                  f_par.strategy_decision_reason_code
                 left join dwh.d_target_strategy dss on f_par.sub_strategy_id = dss.target_strategy_id
                 left join dwh.client_order co on co.order_id = f_par.order_id
        where f_par.parent_order_id is null
          and f_par.multileg_reporting_type in ('1', '2')
          and f_par.status_date_id between in_start_status_date_id and in_end_status_date_id
          and case when in_trading_firm_ids <> '{}' then acc.trading_firm_id = any (in_trading_firm_ids) else true end
          and case when in_account_ids <> '{}' then acc.account_id = any (in_account_ids) else true end
          and dss.target_strategy_name = 'RETAILNML'
          and f_par.exec_time::time between '09:30'::time and '16:00'::time
          and i.instrument_type_id = 'E'
          and sdrc.strategy_user_data in
              ('Maker/Taker order', 'Conditional Primary Peg order', 'Dark IOC Primary Peg order')
          and f_par.order_price >= 1;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_perf_xtx_sor_parent_orders' || ' COMPLETED ===', l_row_cnt,
                           'O')
    into l_step_id;
end;
$function$
;


select * from dwh.d_strategy_decision_reason_code
where strategy_user_data in ('Maker/Taker order', 'Conditional Primary Peg order', 'Dark IOC Primary Peg order');


  select acc.account_id,
         f_par.client_order_id,
               to_char(f_par.routed_time, 'DD-MM-YYYY')                                                 as "Creation Date",
               to_char(f_par.routed_time, 'HH24:MI:SS.MS')                                              as "Creation Time",
               acc.account_demo_mnemonic                                                                as "Account",
               case when f_par.side = '1' then 'Buy' when f_par.side in ('2', '5', '6') then 'Sell' end as "Side",
               f_par.order_qty                                                                          as "Ord Qty",
               f_par.day_cum_qty                                                                        as "Ex Qty",
               i.display_instrument_id                                                                  as "Symbol",
               f_par.order_price                                                                        as "Price",
               f_par.day_avg_px                                                                         as "Avg Px"
        from data_marts.f_yield_capture f_par
                 inner join dwh.d_account acc on acc.is_active and acc.account_id = f_par.account_id
                 inner join dwh.d_instrument i on i.instrument_id = f_par.instrument_id
                 join dwh.d_strategy_decision_reason_code sdrc on sdrc.is_active and
                                                                  sdrc.strategy_decision_reason_code =
                                                                  f_par.strategy_decision_reason_code
                 left join dwh.d_target_strategy dss on f_par.sub_strategy_id = dss.target_strategy_id
                 left join dwh.client_order co on co.order_id = f_par.order_id
        where f_par.parent_order_id is null
          and f_par.multileg_reporting_type in ('1', '2')
          and f_par.status_date_id between :in_start_status_date_id and :in_end_status_date_id
--           and case when in_trading_firm_ids <> '{}' then acc.trading_firm_id = any (in_trading_firm_ids) else true end
--           and case when in_account_ids <> '{}' then acc.account_id = any (in_account_ids) else true end
          and dss.target_strategy_name = 'RETAILNML'
          and f_par.exec_time::time between '09:30'::time and '16:00'::time
          and i.instrument_type_id = 'E'
          and sdrc.strategy_user_data in
              ('Maker/Taker order', 'Conditional Primary Peg order', 'Dark IOC Primary Peg order')
          and f_par.order_price >= 1;