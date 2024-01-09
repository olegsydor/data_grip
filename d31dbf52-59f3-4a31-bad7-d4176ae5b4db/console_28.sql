with tmp_gtc_fidelity_retail_ord_open as (
select di.instrument_type_id,
    gtc.account_id,
         gtc.order_id,
         cl.client_order_id,
         gtc.create_date_id,
         cl.instrument_id,
         cl.order_type_id,
         cl.time_in_force_id,
         cl.stop_price,
         cl.price,
         cl.order_qty,
         cl.create_time,
         cl.side,
         cl.open_close,
         gtc.close_date_id
  from dwh.gtc_order_status gtc
           join dwh.client_order cl using (order_id, create_date_id)
  join dwh.d_instrument di on di.instrument_id = cl.instrument_id
  where true
  and cl.account_id = any(:l_account_ids)
    and cl.parent_order_id is null
--     and case when :l_instrument_type is null then true else instrument_type_id = :l_instrument_type end
    and gtc.time_in_force_id = '1'
--       and gtc.create_date_id >= :l_gtc_date_id
    and gtc.create_date_id <= :l_current_date_id
    and cl.sub_strategy_id in (select dts.target_strategy_id
                               from dwh.d_target_strategy dts
                               where dts.target_strategy_name = 'RETAIL')       -- only 9000 tag = RETAIL
    and ((gtc.close_date_id is not null and gtc.close_date_id >= :l_current_date_id)
      or gtc.close_date_id is null)
    and cl.multileg_reporting_type = :l_multileg_reporting_type
   and cl.client_order_id in ('JZ/6232/X42/799840/24005HAEZH ')
      )

        select 'DASM' as dasm_mm_firm
          , to_char(co.create_time, 'YYMMDD') as dasm_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as dasm_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as dasm_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as dasm_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as dasm_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as dasm_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders_interval(in_order_id => co.order_id, in_date_id => co.create_date_id, in_max_date_id => :l_current_date_id), 0))::varchar, 8, '0') as dasm_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as dasm_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as dasm_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as dasm_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as dasm_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as dasm_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as dasm_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as dasm_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as dasm_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as dasm_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_lmt_price
          , lpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as dasm_tif
          , 'LST' as dasm_listed_otc_ind
          , lpad(co.client_order_id,29,' ') as dasm_order_id -- filler(19) + order_id(10)
          , lpad(' ',2,' ') as filler
          , '2' as dasm_d_rec_id
            , case when close_date_id is null then 0
            when close_date_id <= :l_current_date_id then 1
            else 0
            end as gts_is_closed
        from tmp_gtc_fidelity_retail_ord_open co
            inner join lateral
              (
                select 1
                from dwh.client_order cl
                where cl.order_id = co.order_id
                  and cl.sub_strategy_id = 78 --in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                  and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                  and cl.multileg_reporting_type = '2' --l_multileg_reporting_type
                  and cl.trans_type <> 'F'
                  and cl.create_date_id >= :l_gtc_date_id
                  and cl.create_date_id <= :l_current_date_id
                  and cl.parent_order_id is null
                  limit 1
              ) co_in on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc on oc.instrument_id = co.instrument_id
          left join dwh.d_option_series dos on dos.option_series_id = oc.option_series_id
          left join dwh.d_instrument di    on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot      on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif  on co.time_in_force_id = tif.tif_id

        where true
        and coalesce (close_date_id, 30011231) > :l_current_date_id  -- as a max date to comare
--        and case when (dos.exercise_style = 'E' and di.last_trade_date = l_current_date_id::text::date + interval '1 day') then false else true end
        and case when (di.symbol in ('VIX', 'SPX') and di.last_trade_date = :l_current_date_id::text::date + interval '1 day') then false else true end


select * from dash360.report_gtc_fidelity_retail(p_report_date_id := 20240108, p_is_multileg_report := 'Y', p_trading_firm_ids := '{"OFP0022"}', p_account_ids := '{29609}')



select * from dwh.d_instrument
    where d_instrument.instrument_id = 396918



-- DROP FUNCTION dash360.get_active_child_gtc_orders(_int4);

CREATE or replace FUNCTION trash.get_active_child_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[], in_date_id int4 default null)
 RETURNS TABLE(account_name character varying, creation_date timestamp without time zone, ord_status character varying, sec_type character, side character, symbol character varying, exchange_id character varying, ex_dest character varying, is_bdma text, ord_qty integer, ex_qty numeric, ord_type character, price numeric, avg_px numeric, lvs_qty bigint, is_mleg text, leg_id character varying, open_close character, dash_id character varying, cl_ord_id character varying, orig_cl_ord_id character varying, parent_cl_ord_id character varying, occ_data text, osi_symbol character varying, client_id character varying, subsystem character varying, strike_px numeric, put_call character, exp_year smallint, exp_month smallint, exp_day smallint, order_id bigint, sender_comp_id character varying)
 LANGUAGE plpgsql
AS $function$
-- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
declare
    row_cnt       int4;
    l_load_id     int;
    l_step_id     int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || current_date::text || ' started====', 0, 'O')
    into l_step_id;

    return query
        select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
               exch.exchange_id             as exchange_id,
               exch.exchange_name           as ex_dest,
               exch.is_bdma                 as is_bdma,
               cl.order_qty                 as ord_qty,
               exl.ex_qty                   as ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               par.client_order_id          as parent_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
               cl.client_id_text            as client_id,
               dss.sub_system_id            as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id and
                                             cl.parent_order_id is not null
                 join dwh.d_account ac on gtc.account_id = ac.account_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
                 inner join dwh.client_order par
                            on (cl.parent_order_id = par.order_id and par.create_date_id <= gtc.create_date_id)
                 join lateral (select ex.exec_id as exec_id
                               from dwh.execution ex
                               where gtc.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gtc.create_date_id
                               order by ex.exec_id desc
                               limit 1) gtex on true
                 inner join lateral (select ex.avg_px, ex.last_px, ex.leaves_qty, ex.order_status
                                     from dwh.execution ex
                                     where ex.exec_id = gtex.exec_id
                                       and ex.exec_date_id >= gtc.create_date_id
                                     limit 1) ex on true
                 join dwh.d_order_status ors on ors.order_status = ex.order_status
                 inner join lateral (select exch.exchange_id,
                                            exch.exchange_name,
                                            case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
                                     from dwh.d_exchange exch
                                     where exch.exchange_id = cl.exchange_id
                                       and exch.is_active
                                     limit 1) exch on true
                 left join dwh.client_order orig
                           on (orig.order_id = cl.orig_order_id and orig.create_date_id <= cl.create_date_id)
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join dwh.client_order_leg leg on (leg.order_id = gtc.order_id)
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = par.sub_system_unq_id and dss.is_active
                 left join dwh.d_fix_connection fc on (cl.fix_connection_id = fc.fix_connection_id)
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
        where true
          and cl.parent_order_id is not null
          and gtc.close_date_id is null
          or gtc.close_date_id > in_date_id
          and cl.trans_type in ('D', 'G')
          and cl.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
        order by gtc.order_id;

    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || current_date::text || ' finished====', row_cnt, 'O')
    into l_step_id;
end;
$function$
;
