CREATE OR REPLACE FUNCTION trash.get_parent_orders_trade_activity1(in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                    in_exchange_ids character varying[] DEFAULT '{}'::character varying(6)[],
                                                                    in_start_date date DEFAULT CURRENT_DATE,
                                                                    in_end_date date DEFAULT CURRENT_DATE)
    RETURNS TABLE
            (
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                exec_time_orig            timestamp without time zone,
                exec_time                 text,
                exec_type                 character varying,
                order_status              character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
-- 2023-06-29 https://dashfinancial.atlassian.net/browse/DS-6950
-- 2023-10-03 OS improved after Bohdan Semko's request
    l_start_date_id int4;
    l_end_date_id int4;
begin
l_start_date_id := public.get_dateid(in_start_date);
l_end_date_id := public.get_dateid(coalesce(in_end_date, in_start_date));

    return query
        select co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name

        from dwh.execution ex
--                  inner join dwh.client_order co on ex.order_id = co.order_id
                 join lateral (select co.client_order_id,
                                      co.exch_order_id,
                                      co.order_id,
                                      co.side,
                                      co.order_qty,
                                      co.price,
                                      co.parent_order_id,
                                      co.account_id,
                                      co.instrument_id,
                                      co.time_in_force_id,
                                      co.sub_system_unq_id,
                                      co.multileg_reporting_type,
                                      co.create_date_id
                               from dwh.client_order co
                               where co.order_id = ex.order_id

                                 and co.create_date_id <= ex.exec_date_id
                                 and co.parent_order_id is null
                               limit 1) co on true
                 inner join dwh.d_account acc on co.account_id = acc.account_id and case when coalesce(:in_account_ids, '{}') = '{}' then true
                                         else acc.account_id = any (:in_account_ids) end
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
          and case when coalesce(in_exchange_ids, '{}') = '{}' then true else ex.exchange_id = any (in_exchange_ids) end
          and ex.exec_date_id >= l_start_date_id
          and ex.exec_date_id <= l_end_date_id
          and ex.is_parent_level;
end;
$function$
;



CREATE OR REPLACE FUNCTION dash360.get_parent_orders_trade_activity(in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                   in_exchange_ids character varying[] DEFAULT '{}'::character varying(6)[],
                                                                   in_start_date date DEFAULT CURRENT_DATE,
                                                                   in_end_date date DEFAULT CURRENT_DATE)
    RETURNS TABLE
            (
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                exec_time_orig            timestamp without time zone,
                exec_time                 text,
                exec_type                 character varying,
                order_status              character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
-- 2023-06-29 https://dashfinancial.atlassian.net/browse/DS-6950
-- 2023-10-03 OS improved after Bohdan Semko's request
    l_start_date_id int4;
    l_end_date_id   int4;
begin
    l_start_date_id := public.get_dateid(in_start_date);
    l_end_date_id := public.get_dateid(coalesce(in_end_date, in_start_date));

    return query
        select --ex.exchange_id,
               --co.account_id,
               co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name
        from dwh.client_order co
                 join dwh.execution ex on co.order_id = ex.order_id and ex.exec_date_id >= co.create_date_id and
                                          ex.exec_date_id >= l_start_date_id and ex.exec_date_id <= l_end_date_id
            and ex.is_parent_level
            and case
                    when coalesce(in_exchange_ids, '{}') = '{}' then true
                    else ex.exchange_id = any (in_exchange_ids) end
                 inner join dwh.d_account acc on co.account_id = acc.account_id
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
          and case when coalesce(in_account_ids, '{}') = '{}' then true else co.account_id = any (in_account_ids) end
          and co.create_date_id >= l_start_date_id
          and co.create_date_id <= l_end_date_id;
end;
$function$
;

select *
from dash360.get_parent_orders_trade_activity(
        in_account_ids := '{49568,63687}',
--         in_exchange_ids := '{"CBOEEH", "BATO"}',
        in_start_date := '2023-09-28',
        in_end_date := '2023-09-28'
    )

select *
from trash.get_parent_orders_trade_activity1(
        in_account_ids := '{49568,63687}',
        in_exchange_ids := '{"CBOEEH", "BATO"}',
        in_start_date := '2023-09-28',
        in_end_date := '2023-09-28'
    )
except
select *
from trash.get_parent_orders_trade_activity2(
        in_account_ids := '{49568,63687}',
--         in_exchange_ids := '{"CBOEEH", "BATO"}',
        in_start_date := '2023-09-28',
        in_end_date := '2023-09-28'
    );


CREATE OR REPLACE FUNCTION dash360.get_street_orders_trade_activity(in_account_ids integer[] DEFAULT '{}'::integer[], in_exchange_ids character varying[] DEFAULT '{}'::character varying(6)[], in_start_date date DEFAULT CURRENT_DATE, in_end_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(parent_client_order_id character varying, client_order_id character varying, exch_order_id character varying, order_id bigint, side character, order_qty integer, price numeric, time_in_force character varying, instrument_name character varying, last_trade_date timestamp without time zone, account_name character varying, sub_system_id character varying, multileg_reporting_type character, exec_id bigint, ref_exec_id bigint, exch_exec_id character varying, exec_time_orig timestamp without time zone, exec_time text, exec_type character varying, order_status character varying, leaves_qty bigint, cum_qty bigint, avg_px numeric, last_qty bigint, last_px numeric, bust_qty bigint, last_mkt character varying, last_mkt_name character varying, text_ character varying, trade_liquidity_indicator character varying, is_busted character, exec_broker character varying, exchange_id character varying, exchange_name character varying)
 LANGUAGE plpgsql
AS $function$
declare
-- 2023-06-29 https://dashfinancial.atlassian.net/browse/DS-6950
-- 2023-07-11 SO performance improvement
-- 2023-10-03 OS https://dashfinancial.atlassian.net/browse/DS-7351 improved after Bohdan Semko's request
    l_start_date_id int4;
    l_end_date_id int4;
begin
    l_start_date_id := public.get_dateid(in_start_date);
    l_end_date_id := public.get_dateid(coalesce(in_end_date, in_start_date));

    return query
        select po.client_order_id                     as parent_client_order_id,
               co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name
    from dwh.client_order co
         join dwh.execution ex on (
            co.order_id = ex.order_id and ex.exec_date_id >= co.create_date_id
        and ex.exec_date_id >= l_start_date_id and ex.exec_date_id <= l_end_date_id
        and not ex.is_parent_level
        and case
                when coalesce(in_exchange_ids, '{}') = '{}' then true
                else ex.exchange_id = any (in_exchange_ids) end)
         inner join dwh.client_order po
                    on po.order_id = co.parent_order_id and po.create_date_id <= co.create_date_id
         inner join dwh.d_account acc on co.account_id = acc.account_id
         inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
         left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
         left join dwh.d_order_status os on os.order_status = ex.order_status
         left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
         left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
         left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
         left join dwh.d_exec_type et on et.exec_type = ex.exec_type
where ex.exec_type in ('F', 'H')
  and case when coalesce(in_account_ids, '{}') = '{}' then true else co.account_id = any (in_account_ids) end
  and co.create_date_id >= l_start_date_id
  and co.create_date_id <= l_end_date_id;
end;
$function$
;


select po.client_order_id                     as parent_client_order_id,
       co.client_order_id,
       co.exch_order_id,
       ex.order_id,
       co.side,
       co.order_qty,
       co.price,
       tif.tif_short_name                        time_in_force,
       inst.instrument_name,
       inst.last_trade_date,
       acc.account_name,
       dss.sub_system_id,
       co.multileg_reporting_type,
       ex.exec_id,
       ex.ref_exec_id,
       ex.exch_exec_id,
       ex.exec_time                           as exec_time_orig,
       to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
       et.exec_type_description               as exec_type,
       os.order_status_description            as order_status,
       ex.leaves_qty,
       ex.cum_qty,
       ex.avg_px,
       ex.last_qty,
       ex.last_px,
       ex.bust_qty,
       ex.last_mkt,
       lm.last_mkt_name                       as last_mkt_name,
       ex.text_,
       ex.trade_liquidity_indicator,
       ex.is_busted,
       ex.exec_broker,
       ex.exchange_id,
       e.exchange_name
from dwh.client_order co
         join dwh.execution ex on (
            co.order_id = ex.order_id and ex.exec_date_id >= co.create_date_id
        and ex.exec_date_id >= :l_start_date_id and ex.exec_date_id <= :l_end_date_id
        and not ex.is_parent_level
        and case
                when coalesce(:in_exchange_ids, '{}') = '{}' then true
                else ex.exchange_id = any (:in_exchange_ids) end)
         inner join dwh.client_order po
                    on po.order_id = co.parent_order_id and po.create_date_id <= co.create_date_id
         inner join dwh.d_account acc on co.account_id = acc.account_id
         inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
         left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
         left join dwh.d_order_status os on os.order_status = ex.order_status
         left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
         left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
         left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
         left join dwh.d_exec_type et on et.exec_type = ex.exec_type
where ex.exec_type in ('F', 'H')
  and case when coalesce(:in_account_ids, '{}') = '{}' then true else co.account_id = any (:in_account_ids) end
  and co.create_date_id >= :l_start_date_id
  and co.create_date_id <= :l_end_date_id;



select co.client_order_id, array_agg(distinct exec_date_id), array_agg(distinct rfr.rfr_id)
from dwh.client_order co
    join dwh.gtc_order_status gtc using (create_date_id, order_id)
         left join lateral (select client_order_id
                            from dwh.client_order par
                            where par.order_id = co.parent_order_id
                              and par.create_date_id <= co.create_date_id
                            limit 1) par on true
         join dwh.execution e on (e.order_id = co.order_id and e.exec_date_id >= co.create_date_id)
         left join consolidator.cons_lite_parent_to_rfr rfr
                   on (rfr.parent_client_order_id = coalesce(par.client_order_id, co.client_order_id)
                       and rfr.date_id = e.exec_date_id)
where true
  and co.client_order_id = '194Z28891270537'
  and co.multileg_reporting_type = '1'
  and co.create_date_id between to_char(:f_day_1, 'YYYYMMDD')::int and to_char(:f_day_2, 'YYYYMMDD')::int
      and e.exec_type not in ('E', 'S', 'D', 'y')
      and co.trans_type <> 'F'
  and co.account_id in (select ac.account_id
                     from dwh.d_account ac
                              join lateral (select
                                            from dwh.d_trading_firm tf
                                            where tf.trading_firm_id = ac.trading_firm_id
                                              and tf.is_eligible4consolidator = 'Y'
                                            limit 1) tf on true
                     where true
                       and (ac.date_start, coalesce(ac.date_end, '2399-01-01'::date)) overlaps
                           (:f_day_1, :f_day_2))
group by co.client_order_id
having count(distinct exec_date_id) = count(distinct rfr.rfr_id)
-- and array_length(array_agg(distinct rfr.rfr_id), 1) = 1
limit 10


          select co.multileg_reporting_type, * from dwh.gtc_order_status gos
          join dwh.client_order co using (create_date_id, order_id)
          where co.client_order_id = '10Z2273112008994'

select co.client_order_id, co.exch_order_id, co.dash_rfr_id, exec_date_id, rfr_id
from dwh.client_order co
         left join lateral (select client_order_id
                            from dwh.client_order par
                            where par.order_id = co.parent_order_id
                              and par.create_date_id <= co.create_date_id
                            limit 1) par on true
         join dwh.execution e on (e.order_id = co.order_id and e.exec_date_id >= co.create_date_id)
         left join consolidator.cons_lite_parent_to_rfr rfr
                   on (rfr.parent_client_order_id = coalesce(par.client_order_id, co.client_order_id)
                       and rfr.date_id = e.exec_date_id)
where true
  and co.client_order_id
          in (
'10Z2273112010072',
'10Z2273112010159',
'10Z2273112011489',
'10Z2273112011980',
'10Z2273112012216',
'10Z2273112012714',
'10Z2273112013163',
'10Z2273112013325',
'10Z2273112013544',
'10Z2273112013958'
)
  and co.account_id in (select account_id
                        from dwh.d_account ac
                                 join lateral (select
                                               from dwh.d_trading_firm tf
                                               where tf.trading_firm_id = ac.trading_firm_id
                                                 and tf.is_eligible4consolidator = 'Y'
                                               limit 1) tf on true
                        where true
                          and (ac.date_start, coalesce(ac.date_end, '2399-01-01'::date)) overlaps
                              (:f_day_1, :f_day_2))
order by 1, 4;


with acc as (select ac.account_id
             from dwh.d_account ac
                      join lateral (select
                                    from dwh.d_trading_firm tf
                                    where tf.trading_firm_id = ac.trading_firm_id
                                      and tf.is_eligible4consolidator = 'Y'
                                    limit 1) tf on true
             where true
               and (ac.date_start, coalesce(ac.date_end, '2399-01-01'::date)) overlaps
                   (:f_day_1, :f_day_2))
select cl.client_order_id, cl.sub_strategy_desc, cl.create_date_id, par.*, ftr.date_id, ftr.order_id, rfr.date_id, rfr.rfr_id--array_agg(distinct ftr.date_id), array_agg(distinct rfr_id)
from dwh.gtc_order_status gos
         join dwh.client_order cl using (order_id, create_date_id)
         left join lateral (select client_order_id
                            from dwh.client_order par
                            where par.order_id = cl.parent_order_id
                              and par.create_date_id <= cl.create_date_id
                            limit 1) par on true
         left join dwh.flat_trade_record ftr on ftr.order_id = cl.order_id and ftr.date_id >= gos.create_date_id
         left join consolidator.cons_lite_parent_to_rfr rfr
                   on (rfr.parent_client_order_id = coalesce(par.client_order_id, cl.client_order_id)
--                        and rfr.date_id = ftr.date_id
                       )
where true
-- and gos.close_date_id is null
and cl.client_order_id  = '9Z1173868705625'
and cl.trans_type <> 'F'
and gos.account_id in (select account_id from acc)
and gos.create_date_id between to_char(:f_day_1, 'YYYYMMDD')::int and to_char(:f_day_2, 'YYYYMMDD')::int
group by cl.client_order_id
having count(distinct ftr.date_id) > count(distinct rfr_id)
and count(distinct ftr.date_id) > 1


select * from client_order
where client_order_id in ('DRAV6411-20231003', 'DRBD4661-20231003')

select * from dwh.flat_trade_record
where order_id = 13291617440


select * from consolidator.cons_lite_parent_to_rfr
where parent_client_order_id = 'JZ/2584/676/042752/23276H2GJ7 '


select ss.symbol, clp.instrument_type_id, clp.start_date, clp.end_date
from staging.symbol2lp_symbol_list_audit ss
         inner join staging.cons_lp_symbol_list_audit clp
                    on clp.lp_symbol_list_audit_id = ss.lp_symbol_list_audit_id
where clp.liquidity_provider_id = 'IMC'
  and clp.lp_symbol_list_type = 'B'
  and (clp.start_date, coalesce(clp.end_date, '2399-01-01'::date)) overlaps
      (:f_day_1, :f_day_2)


where true
  and ((cl.imc_black_list = 'Y')
    or (
                   cl.imc_black_list = 'N'
               and cl.trading_firm_id ilike 'OFP%'
               and rfr.rfr_id is not null
               and ((cl.parent_order_id is not null and rfr.rfr_id = t10162)
               or
                    (cl.parent_order_id is null)
                       )
           ));
select * from dash360.get_wfsweepx(in_date := '2023-10-17')

create or replace function dash360.get_wfsweepx(in_date date)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$

declare
    l_date_id int4 := to_char(in_date, 'YYYYMMDD')::int4;

begin
    return query
        select 'Trade Date,Account,Routed Time,Cl Ord ID,Symbol,Expiration Day,Security Type,Ex Destination,Sub Strategy,Orig Side,Cross Limit Px,Cross Ord Qty,Cross Ord Type,Arrival BBO Qty,Arrival BBO Px,Sweep Ex Qty,Last Mkt';

    return query
        select to_char(cl.create_time, 'MM/DD/YYYY') || ',' ||
               ac.account_name || ',' ||
               to_char(str.process_time, 'HH24:MI:SS') || ',' ||
               cl.client_order_id || ',' ||
               i.display_instrument_id || ',' ||
               case
                   when i.instrument_type_id = 'O'
                       then concat_ws('/', oc.maturity_month::text, oc.maturity_day::text, substr(oc.maturity_year::text, 3))
                   else ''
                   end || ',' ||
               case i.instrument_type_id when 'O' then 'Option' else 'Equity' end || ',' ||
               exc.ex_destination_code_name || ',' ||
               cl.sub_strategy_desc || ',' ||
               case cl.side when '2' then 'Sell' when '5' then 'Sell Short' when '6' then 'Sell Short' else 'Buy' end || ',' ||
               to_char(cl.price, 'FM9999990.0000') || ',' ||
               cl.order_qty || ',' ||
               cro.cross_type || ',' ||
               str.order_qty || ',' ||
               to_char(str.price, 'FM9999990.0000') || ',' ||
               ex.last_qty::text || ',' ||
               exch.mic_code
        from dwh.client_order cl
                 inner join dwh.client_order str on (cl.order_id = str.parent_order_id)
                 inner join dwh.cross_order cro on (cro.cross_order_id = cl.cross_order_id)
                 inner join dwh.d_account ac on cl.account_id = ac.account_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                 inner join dwh.d_ex_destination_code exc on (exc.ex_destination_code = cl.ex_destination)
                 inner join dwh.d_exchange exch on (exch.exchange_id = str.exchange_id and exch.is_active)
--
                 left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join lateral (select coalesce(sum(last_qty), 0) as last_qty
                                    from execution ex
                                    where ex.order_id = str.order_id
                                      and ex.exec_type = 'f'
                                      and ex.exec_date_id >= str.create_date_id
                                    limit 1) ex on true
        where cl.parent_order_id is null
          and cl.multileg_reporting_type <> '3'
          and cl.create_date_id = l_date_id
          and cl.sub_strategy_desc = 'SWEEPX'
          and str.strtg_decision_reason_code = '77'
          and ac.trading_firm_id = 'wellsfarg';
end;

$fx$;

select account_id, account_name from dwh.d_account
where trading_firm_id = 'mpsglobal'
and is_active
select * from dash360.get_lp_eod_compliance(20231019, 'baycrest');
select * from dash360.get_lp_eod_compliance(20231019, 'jeffllc01');
create or replace function dash360.get_lp_eod_compliance(in_date_id int4, in_firm text)
    returns table (ret_row text)
    language plpgsql
    as $fx$
  begin

      return query

		select
			case when in_firm = 'aostb01'
				then
				'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,'||
				'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,'||
				'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,'||
				'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,'||
				'BidSzNBBO,BidNBBO,AskNBBO,AskSzNBBO,BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz'
				else
				'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,'||
				'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,'||
				'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,'||
				'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,'||
				'BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz'
				end;
return query
		  select
-- 		      EX.ORDER_ID as rec_type, EX.EXEC_ID as order_status,
			AC.ACCOUNT_NAME||','|| --UserLogin
			FC.FIX_COMP_ID||','|| --SendingUserLogin
			AC.TRADING_FIRM_ID||','|| --EntityCode
			TF.TRADING_FIRM_NAME||','|| --EntityName
			''||','|| --DestinationEntity
			''||','|| --Owner
			to_char(CL.CREATE_TIME,'YYYYMMDD')||','|| --CreateDate
			to_char(EX.EXEC_TIME,'HH24MISSFF3')||','|| --CreateTime
			''||','|| --StatusDate
			''||','|| --StatusTime
			OC.OPRA_SYMBOL||','|| --OSI
			UI.SYMBOL||','||--BaseCode
			OS.ROOT_SYMBOL||','|| --Root
			UI.INSTRUMENT_TYPE_ID||','|| --BaseAssetType
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR||','|| --ExpirationDate
			OC.STRIKE_PRICE||','||
			case when OC.PUT_CALL = '0' then 'P' else 'C' end||','|| --TypeCode
			case
			  when CL.SIDE = '1' and CL.OPEN_CLOSE = 'C' then 'BC'
			  else case CL.SIDE when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end
			end||','||

 			case when cl.multileg_reporting_type = '1' then '1' else
			(select NO_LEGS from dwh.CLIENT_ORDER mcl where mcl.ORDER_ID = CL.MULTILEG_ORDER_ID) end||','||  --LegCount
--  			LN.LEG_NUMBER||','||  --LegNumber
            case when cl.multileg_reporting_type = '1' then '' else
			coalesce(staging.get_multileg_leg_number(cl.order_id)::text, '') end||','||  --LegNumber
			''||','||  --OrderType
            case
                when CL.PARENT_ORDER_ID is null then
                    case EX.ORDER_STATUS
                        when 'A' then 'Pnd Open'
                        when 'b' then 'Pnd Cxl'
                        when 'S' then 'Pnd Rep'
                        when '1' then 'Partial'
                        when '2' then 'Filled'
                        else
                            case EX.EXEC_TYPE
                                when '4' then 'Canceled'
                                when 'W' then 'Replaced'
                                else coalesce(EX.EXEC_TYPE, '') end end
                else case EX.ORDER_STATUS
                         when 'A' then 'Ex Pnd Open'
                         when '0' then 'Ex Open'
                         when '8' then 'Ex Rej'
                         when 'b' then 'Ex Pnd Cxl'
                         when '1' then 'Ex Partial'
                         when '2' then 'Ex Rpt Fill'
                         when '4' then 'Ex Rpt Out'
                         else coalesce(EX.ORDER_STATUS, '') end
			end||','||  --Status
			coalesce(to_char(CL.PRICE, 'FM999990D0099'), '')||','||
			to_char(EX.LAST_PX, 'FM999990D0099')||','||  --StatusPrice
			CL.ORDER_QTY||','|| --Entered Qty
			-- ask++
			EX.LEAVES_QTY||','|| --StatusQty
			--Order
			CL.CLIENT_ORDER_ID||','||
			case
			  when EX.EXEC_TYPE in ('S','W') then orig.client_order_id else '' end||','|| --Replaced Order
			case
			  when EX.EXEC_TYPE in ('b','4') then cxl.client_order_id else '' end||','|| --CancelOrderID
			coalesce(po.client_order_id, '')||','||
			CL.ORDER_ID||','|| --SystemOrderID
			''||','|| --Generation
			coalesce(CL.sub_strategy_desc, EXC.MIC_CODE, '')||','|| --ExchangeCode
-- 			coalesce(CL.opt_exec_broker_id,OPX.OPT_EXEC_BROKER)||','|| --GiveUpFirm -- changed
           coalesce((select opt_exec_broker
                     from dwh.d_opt_exec_broker dbr
                     where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
                     limit 1), '') || ',' ||--giveupfirm
-- 			case
-- 			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then--CL.OPT_CLEARING_FIRM_ID
-- 			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
-- 			end||','|| --CMTAFirm
          case
            when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
            else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '')
          end||','|| --CMTAFirm
			''||','||  --AccountAlias
			''||','||  --Account
			''||','||  --SubAccount
			''||','||  --SubAccount2
			''||','||  --SubAccount3
			CL.OPEN_CLOSE||','||
			case (case AC.OPT_IS_FIX_CUSTFIRM_PROCESSED
				  when 'Y' then coalesce(CL.customer_or_firm_id, AC.OPT_CUSTOMER_OR_FIRM)
				   else AC.OPT_CUSTOMER_OR_FIRM
				  end)
			   when '0' then 'CUST'
			   when '1' then 'FIRM'
			   when '2' then 'BD'
			   when '3' then 'BD-CUST'
			   when '4' then 'MM'
			   when '5' then 'AMM'
			   when '7' then 'BD-FIRM'
			   when '8' then 'CUST-PRO'
			   when 'J' then 'JBO'
			    else ''
			end||','||  --Range
			OT.ORDER_TYPE_SHORT_NAME||','|| --PriceQualifier
			TIF.TIF_SHORT_NAME||','|| --TimeQualifier
			EX.EXCH_EXEC_ID||','|| --ExchangeTransactionID
			coalesce(CL.EXCH_ORDER_ID, '')||','|| --ExchangeOrderID
			''||','||  --MPID
			''||','||  --Comment
--bid_qty, bid_price, ask_qty, ask_price
           coalesce(amex.bid_qty::text, '') || ',' || --BidSzA
           coalesce(to_char(amex.bid_price, 'FM999999.0099'), '') || ',' || --BidA
           coalesce(to_char(amex.ask_price, 'FM999999.0099'), '') || ',' || --AskA
           coalesce(amex.ask_qty::text, '') || ',' || --AskSzA

           coalesce(bato.bid_qty::text, '') || ',' || --BidSzZ
           coalesce(to_char(bato.bid_price, 'FM999999.0099'), '') || ',' || --BidZ
           coalesce(to_char(bato.ask_price, 'FM999999.0099'), '') || ',' || --AskZ
           coalesce(bato.ask_qty::text, '') || ',' || --AskSzZ

           coalesce(box.bid_qty::text, '') || ',' || --BidSzB
           coalesce(to_char(box.bid_price, 'FM999999.0099'), '') || ',' || --BidB
           coalesce(to_char(box.ask_price, 'FM999999.0099'), '') || ',' || --AskB
           coalesce(box.ask_qty::text, '') || ',' || --AskSzB
--
           coalesce(cboe.bid_qty::text, '') || ',' || --BidSzC
           coalesce(to_char(cboe.bid_price, 'FM999999.0099'), '') || ',' || --BidC
           coalesce(to_char(cboe.ask_price, 'FM999999.0099'), '') || ',' || --AskC
           coalesce(cboe.ask_qty::text, '') || ',' || --AskSzC

           coalesce(c2ox.bid_qty::text, '') || ',' || --BidSzW
           coalesce(to_char(c2ox.bid_price, 'FM999999.0099'), '') || ',' || --BidW
           coalesce(to_char(c2ox.ask_price, 'FM999999.0099'), '') || ',' || --AskW
           coalesce(c2ox.ask_qty::text, '') || ',' || --AskSzW

           coalesce(nqbxo.bid_qty::text, '') || ',' || --BidSzT
           coalesce(to_char(nqbxo.bid_price, 'FM999999.0099'), '') || ',' || --BidT
           coalesce(to_char(nqbxo.ask_price, 'FM999999.0099'), '') || ',' || --AskT
           coalesce(nqbxo.ask_qty::text, '') || ',' || --AskSzT

           coalesce(ise.bid_qty::text, '') || ',' || --BidSzI
           coalesce(to_char(ise.bid_price, 'FM999999.0099'), '') || ',' || --BidI
           coalesce(to_char(ise.ask_price, 'FM999999.0099'), '') || ',' || --AskI
           coalesce(ise.ask_qty::text, '') || ',' || --AskSzI

           coalesce(arca.bid_qty::text, '') || ',' || --BidSzP
           coalesce(to_char(arca.bid_price, 'FM999999.0099'), '') || ',' || --BidP
           coalesce(to_char(arca.ask_price, 'FM999999.0099'), '') || ',' || --AskP
           coalesce(arca.ask_qty::text, '') || ',' || --AskSzP

           coalesce(miax.bid_qty::text, '') || ',' || --BidSzM
           coalesce(to_char(miax.bid_price, 'FM999999.0099'), '') || ',' || --BidM
           coalesce(to_char(miax.ask_price, 'FM999999.0099'), '') || ',' || --AskM
           coalesce(miax.ask_qty::text, '') || ',' || --AskSzM

           coalesce(gemini.bid_qty::text, '') || ',' || --BidSzH
           coalesce(to_char(gemini.bid_price, 'FM999999.0099'), '') || ',' || --BidH
           coalesce(to_char(gemini.ask_price, 'FM999999.0099'), '') || ',' || --AskH
           coalesce(gemini.ask_qty::text, '') || ',' || --AskSzH

           coalesce(nsdqo.bid_qty::text, '') || ',' || --BidSzQ
           coalesce(to_char(nsdqo.bid_price, 'FM999999.0099'), '') || ',' || --BidQ
           coalesce(to_char(nsdqo.ask_price, 'FM999999.0099'), '') || ',' || --AskQ
           coalesce(nsdqo.ask_qty::text, '') || ',' || --AskSzQ

           coalesce(phlx.bid_qty::text, '') || ',' || --BidSzX
           coalesce(to_char(phlx.bid_price, 'FM999999.0099'), '') || ',' || --BidX
           coalesce(to_char(phlx.ask_price, 'FM999999.0099'), '') || ',' || --AskX
           coalesce(phlx.ask_qty::text, '') || ',' || --AskSzX

           coalesce(edgo.bid_qty::text, '') || ',' || --BidSzE
           coalesce(to_char(edgo.bid_price, 'FM999999.0099'), '') || ',' || --BidE
           coalesce(to_char(edgo.ask_price, 'FM999999.0099'), '') || ',' || --AskE
           coalesce(edgo.ask_qty::text, '') || ',' || --AskSzE

           coalesce(mcry.bid_qty::text, '') || ',' || --BidSzJ
           coalesce(to_char(mcry.bid_price, 'FM999999.0099'), '') || ',' || --BidJ
           coalesce(to_char(mcry.ask_price, 'FM999999.0099'), '') || ',' || --AskJ
           coalesce(mcry.ask_qty::text, '') || ',' || --AskSzJ

            case
                when in_firm = 'aostb01'
                    then
                    --Add NBBO
                        coalesce(mprl.bid_qty::text, '') || ',' || --BidSzNBBO
                        coalesce(to_char(mprl.bid_price, 'FM999999.0099'), '') || ',' || --BidNBBO
                        coalesce(to_char(mprl.ask_price, 'FM999999.0099'), '') || ',' || --AskNBBO
                        coalesce(mprl.ask_qty::text, '') ||',' --AskSzNBBO
                else ''
            end ||
            coalesce(mprl.bid_qty::text, '') || ',' || --BidSzR
            coalesce(to_char(mprl.bid_price, 'FM999999.0099'), '') || ',' || --BidR
            coalesce(to_char(mprl.ask_price, 'FM999999.0099'), '') || ',' || --AskR
            coalesce(mprl.ask_qty::text, '') || ',' || --AskSzR
            '' || ',' || --ULBidSz
            '' || ',' || --ULBid
            '' || ',' || --ULAsk
            '' || ',' || --ULAskSz
            ''
			as rec
          from dwh.client_order cl
                   inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
                   inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
                   left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                   inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                   inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                   inner join dwh.d_account ac on ac.account_id = cl.account_id
                   inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                   left join lateral (select orig.client_order_id
                                      from dwh.client_order orig
                                      where orig.order_id = cl.orig_order_id
                                        and orig.create_date_id <= cl.create_date_id
                                      limit 1) orig on true
                   left join lateral (select min(cxl.client_order_id) as client_order_id
                                      from client_order cxl
                                      where cxl.orig_order_id = cl.order_id
                                      limit 1) cxl on true
                   left join lateral (select po.client_order_id
                                      from client_order po
                                      where po.order_id = cl.parent_order_id
                                        and po.create_date_id <= cl.create_date_id
                                      limit 1) po on true
                   left join dwh.d_clearing_account ca
                             on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                                 ca.market_type = 'o' and ca.clearing_account_type = '1')
                   left join dwh.d_opt_exec_broker opx
                             on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
              --left join liquidity_indicator tli on (tli.trade_liquidity_indicator = ex.trade_liquidity_indicator and tli.exchange_id = exc.real_exchange_id)
                   left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                   left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
              --          left join CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID
--          left join dwh.STRATEGY_IN SIT
--                    on (SIT.TRANSACTION_ID = CL.TRANSACTION_ID and SIT.STRATEGY_IN_TYPE_ID in ('Ab', 'H'))
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'AMEX'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
----                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) amex on true
-- bato
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'BATO'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) bato on true
-- box
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'BOX'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) box on true
-- cboe
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'CBOE'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) cboe on true
-- c2ox
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'C2OX'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) c2ox on true
-- nqbxo
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'NQBXO'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) nqbxo on true
-- ise
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'ISE'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) ise on true
-- arca
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'ARCA'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) arca on true
-- miax
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'MIAX'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) miax on true
-- gemini
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'GEMINI'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) gemini on true
-- nsdqo
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'NSDQO'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) nsdqo on true
-- phlx
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'PHLX'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) phlx on true
-- edgo
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'EDGO'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) edgo on true
-- mcry
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'MCRY'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) mcry on true
-- mprl
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'MPRL'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) mprl on true
-- emld
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'EMLD'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                      limit 1
              ) emld on true
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'SPHR'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                      limit 1
              ) sphr on true
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'MXOP'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                      limit 1
              ) mxop on true
                   left join lateral (select ls.ask_price,
                                             ls.bid_price,
                                             ls.ask_quantity as ask_qty,
                                             ls.bid_quantity as bid_qty
                                      from dwh.l1_snapshot ls
                                      where ls.transaction_id = cl.transaction_id
                                        and ls.exchange_id = 'NBBO'
                                        and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                      limit 1
              ) nbbo on true

          where CL.CREATE_date_id = in_date_id
            and AC.TRADING_FIRM_ID = in_firm
            --and CL.PARENT_ORDER_ID is null -- all orders
            and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
            --and EX.EXEC_TYPE = 'F'
            and EX.IS_BUSTED = 'N'
            and EX.EXEC_TYPE not in ('3', 'a', '5', 'E')
            and CL.TRANS_TYPE <> 'F'
            and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
-- and ex.order_id = 13454466648
      ;

end;
$fx$;

select * from dash360.get_lp_eod_fills(in_date_id := '20231019', in_firm := 'mpsglobal');
select * from dash360.get_lp_eod_fills(in_date_id := '20231019', in_firm := 'LPTF49');

create or replace function dash360.get_lp_eod_fills(in_date_id int4, in_firm text)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
begin
    return query
        select 'CreateDate,CreateTime,EntityCode,Login,SystemOrderID,Underlying,ExpirationDate,Strike,TypeCode,BuySell,Quantity,OpenClose,AvgPrice,ExchangeCode,GiveUpFirm,CMTAFirm,Range';
    return query
        select cl.create_date_id::text || ',' ||
               to_char(ex.exec_time, 'HH24:MI:SS:US') || ',' ||
               ac.trading_firm_id || ',' ||
                   --cl.client_id||','||
               ac.account_name || ',' ||
               cl.client_order_id || ',' ||
               ui.symbol || ',' ||
               to_char(oc.maturity_month, 'FM00') || '/' || to_char(oc.maturity_day, 'FM00') || '/' ||
               oc.maturity_year ||
               ',' ||
               oc.strike_price || ',' ||
               case when oc.put_call = '0' then 'P' else 'C' end || ',' ||
               case when cl.side = '1' then 'B' else 'S' end || ',' ||
                   --ODCS.DAY_CUM_QTY||','||
               ex.last_qty || ',' ||
               cl.open_close || ',' ||
                   --AvgPx
               to_char(tr.avg_px, 'FM999990D0099') || ',' ||
               case ex.exchange_id
                   when 'AMEX' then 'A'
                   when 'BATO' then 'Z'
                   when 'BOX' then 'B'
                   when 'CBOE' then 'C'
                   when 'C2OX' then 'W'
                   when 'NQBXO' then 'T'
                   when 'ISE' then 'I'
                   when 'ARCA' then 'P'
                   when 'MIAX' then 'M'
                   when 'GMNI' then 'H'
                   when 'NSDQO' then 'Q'
                   when 'PHLX' then 'X'
                   when 'EDGO' then 'E'
                   when 'MCRY' then 'J'
                   when 'MPRL' then 'R'
                   else '' end || ',' ||
               coalesce((select opt_exec_broker
                         from dwh.d_opt_exec_broker dbr
                         where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
                         limit 1), '') || ',' ||
               case
                   when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
                   else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '') || ',' ||
                        case (case ac.opt_is_fix_custfirm_processed
                                  when 'Y' then coalesce(cl.customer_or_firm_id, ac.opt_customer_or_firm)
                                  else ac.opt_customer_or_firm
                            end)
                            when '0' then 'CUST'
                            when '1' then 'FIRM'
                            when '2' then 'BD'
                            when '3' then 'BD-CUST'
                            when '4' then 'MM'
                            when '5' then 'AMM'
                            when '7' then 'BD-FIRM'
                            when '8' then 'CUST-PRO'
                            when 'J' then 'JBO'
                            else '' end end--Range
                   as rec
        from dwh.client_order cl
                 inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                 inner join lateral (select exchange_id, exec_time, last_qty
                                     from dwh.execution ex
                                     where cl.order_id = ex.order_id
                                       and ex.exec_date_id = cl.create_date_id
                                       and ex.exec_type = 'F'
                                       and ex.is_busted = 'N'
                                       and ex.exec_date_id >= in_date_id
            ) ex on true
                 left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 left join dwh.d_clearing_account ca
                           on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                               ca.market_type = 'O' and ca.clearing_account_type = '1')
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                 left join lateral (select sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px
                                    from dwh.flat_trade_record tr
                                    where true
                                      and tr.order_id = cl.order_id
                                      and tr.is_busted <> 'Y'
                                      and tr.date_id = in_date_id
                                    limit 1) tr on true
        where cl.create_date_id = in_date_id
          and ac.is_active
          and ac.trading_firm_id = in_firm
          and cl.parent_order_id is null;
end;

$fx$;

select avg_px, cum_qty, * from dwh.client_order cl
join dwh.execution ex on ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id
where ex.exec_type = 'F'
and  cl.create_date_id = 20231023
and client_order_id = 'S2310230000798'


SELECT
        EX.EXEC_date_id,
        EX.ORDER_ID,
        SUM(EX.LAST_QTY) as DAY_CUM_QTY,
        SUM(EX.LAST_QTY * EX.LAST_PX)/SUM(EX.LAST_QTY) DAY_AVG_PX
    FROM EXECUTION EX
      join lateral (select null from EXECUTION LE where LE.ORDER_ID = EX.ORDER_ID  AND le.exec_date_id = ex.exec_date_id order by EX.exec_id desc limit 1) le on true
      join CLIENT_ORDER CO
        ON CO.ORDER_ID = EX.ORDER_ID
        AND MULTILEG_REPORTING_TYPE IN ('1','2')
    WHERE 1=1 --TRUNC(EX.EXEC_TIME) = TRUNC(sysdate -1)
   and EX.EXEC_TYPE in ('F', 'G')
   AND EX.IS_BUSTED <> 'Y'
    and co.order_id = 13492584928
    GROUP BY exec_date_id, EX.ORDER_ID

select account_id from dwh.d_account
where TRADING_FIRM_ID = 'LPTF49'
and is_active


		  select 2 as rec_type,
			CL.Date_id::text ||','||
 			to_char(cl.trade_record_time,'HH24:MI:SS:FF3')||','||
			AC.TRADING_FIRM_ID||','||
			--CL.CLIENT_ID||','||
			AC.ACCOUNT_NAME||','||
			CL.CLIENT_ORDER_ID||','||
			UI.SYMBOL||','||
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR||','||
			OC.STRIKE_PRICE||','||
			case when OC.PUT_CALL = '0' then 'P' else 'C' end ||','||
			case when CL.SIDE = '1' then 'B' else 'S' end||','||
			--ODCS.DAY_CUM_QTY||','||
			cl.LAST_QTY||','||
			CL.OPEN_CLOSE||','||
			--AvgPx
-- 			to_char(ODCS.DAY_AVG_PX, 'FM999990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||
 			to_char(tr.AVG_PX, 'FM999990D0099')||','||
            case cl.EXCHANGE_ID
                when 'AMEX' then 'A'
                when 'BATO' then 'Z'
                when 'BOX' then 'B'
                when 'CBOE' then 'C'
                when 'C2OX' then 'W'
                when 'NQBXO' then 'T'
                when 'ISE' then 'I'
                when 'ARCA' then 'P'
                when 'MIAX' then 'M'
                when 'GMNI' then 'H'
                when 'NSDQO' then 'Q'
                when 'PHLX' then 'X'
                when 'EDGO' then 'E'
                when 'MCRY' then 'J'
                when 'MPRL' then 'R'
                else '' end ||','||
-- 			coalesce((select opt_exec_broker
--                      from dwh.d_opt_exec_broker dbr
--                      where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
--                      limit 1), '')||','||
coalesce(opx.opt_exec_broker::text,'')||','|| --GiveUpFirm
--  case
--             when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
--             else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '')||','||
coalesce(cl.cmta::text,'')||','||
-- ''||','||
case cl.opt_customer_firm
			   when '0' then 'CUST'
			   when '1' then 'FIRM'
			   when '2' then 'BD'
			   when '3' then 'BD-CUST'
			   when '4' then 'MM'
			   when '5' then 'AMM'
			   when '7' then 'BD-FIRM'
			   when '8' then 'CUST-PRO'
			   when 'J' then 'JBO'
			    else ''			end ||','||--Range
		''	as rec
		  select *
          from dwh.flat_trade_record cl
                   inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                   left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                   inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                   inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                   left join dwh.d_clearing_account ca
                             on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                                 ca.market_type = 'O' and ca.clearing_account_type = '1')
                   left join dwh.d_opt_exec_broker opx
                             on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                   left join lateral (select sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px
                                      from dwh.flat_trade_record tr
                                      where true
                                        and tr.order_id = cl.order_id
                                        and tr.is_busted <> 'Y'
                                        and tr.date_id = 20231023
                                      limit 1) tr on true

          where cl.date_id = 20231023
            and ac.is_active
            and ac.trading_firm_id = 'mpsglobal'
--             and cl.parent_order_id is null
            and cl.client_order_id = '20231023EDFM50'
            and cl.order_id in (13483308990,
                                13483308985,
                                13483308985
              )

select *
from dwh.client_order cl
         join dwh.execution ex on (ex.order_id = cl.order_id and ex.exec_type = 'F'
    and ex.is_busted = 'N')
where cl.client_order_id = '20231023EDFM50'
  and cl.order_id in (13483308990,
                      13483308985,
                      13483308985
    )


select is_busted, *
from dwh.flat_trade_record cl
where cl.date_id = 20231023
  and cl.client_order_id = '20231023EDFM50'
  and cl.order_id in (13483308990,
                      13483308985,
                      13483308985
    );



	  select 2 as rec_type,
			CL.Date_id::text ||','||
 			to_char(cl.trade_record_time,'HH24:MI:SS:FF3')||','||
			AC.TRADING_FIRM_ID||','||
			--CL.CLIENT_ID||','||
			AC.ACCOUNT_NAME||','||
			CL.CLIENT_ORDER_ID||','||
			UI.SYMBOL||','||
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR||','||
			OC.STRIKE_PRICE||','||
			case when OC.PUT_CALL = '0' then 'P' else 'C' end ||','||
			case when CL.SIDE = '1' then 'B' else 'S' end||','||
			--ODCS.DAY_CUM_QTY||','||
			cl.LAST_QTY||','||
			CL.OPEN_CLOSE||','||
			--AvgPx
-- 			to_char(ODCS.DAY_AVG_PX, 'FM999990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||
 			to_char(tr.AVG_PX, 'FM999990D0099')||','||
            case cl.EXCHANGE_ID
                when 'AMEX' then 'A'
                when 'BATO' then 'Z'
                when 'BOX' then 'B'
                when 'CBOE' then 'C'
                when 'C2OX' then 'W'
                when 'NQBXO' then 'T'
                when 'ISE' then 'I'
                when 'ARCA' then 'P'
                when 'MIAX' then 'M'
                when 'GMNI' then 'H'
                when 'NSDQO' then 'Q'
                when 'PHLX' then 'X'
                when 'EDGO' then 'E'
                when 'MCRY' then 'J'
                when 'MPRL' then 'R'
                else '' end ||','||
-- 			coalesce((select opt_exec_broker
--                      from dwh.d_opt_exec_broker dbr
--                      where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
--                      limit 1), '')||','||
coalesce(opx.opt_exec_broker::text,'')||','|| --GiveUpFirm
--  case
--             when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
--             else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '')||','||
coalesce(cl.cmta::text,'')||','||
-- ''||','||
case cl.opt_customer_firm
			   when '0' then 'CUST'
			   when '1' then 'FIRM'
			   when '2' then 'BD'
			   when '3' then 'BD-CUST'
			   when '4' then 'MM'
			   when '5' then 'AMM'
			   when '7' then 'BD-FIRM'
			   when '8' then 'CUST-PRO'
			   when 'J' then 'JBO'
			    else ''			end ||','||--Range
		''	as rec
		  select *
          from dwh.flat_trade_record cl
                   inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                   left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                   inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                   inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                   left join dwh.d_clearing_account ca
                             on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                                 ca.market_type = 'O' and ca.clearing_account_type = '1')
                   left join dwh.d_opt_exec_broker opx
                             on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                   left join lateral (select sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px
                                      from dwh.flat_trade_record tr
                                      where true
                                        and tr.order_id = cl.order_id
                                        and tr.is_busted <> 'Y'
                                        and tr.date_id = 20231023
                                      limit 1) tr on true

          where cl.date_id = 20231023
            and ac.is_active
            and ac.trading_firm_id = 'mpsglobal'
--             and cl.parent_order_id is null
            and cl.client_order_id = '20231023EDFM50'
            and cl.order_id in (13483308990,
                                13483308985,
                                13483308985
              )


select * from dwh.d_liquidity_indicator
where d_liquidity_indicator.trade_liquidity_indicator ilike '%04N ICRDA    N6000000 9R    E%'

select trade_liquidity_indicator, * from dwh.execution
where order_id = 13454236243
and exec_date_id = 20231019;

select trade_liquidity_indicator, * from dwh.flat_trade_record
where exec_id = 44722920744
and order_id= 13454236243

create or replace function dash360.report_rps_lpeod_fees(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
begin
    return query
        select 1 as rec_type,
               'CreateDate,CreateTime,EntityCode,Login,BuySell,Underlying,Quantity,Price,ExpirationDate,Strike,TypeCode,ExchangeCode,SystemOrderID,GiveUpFirm,CMTA,Range,isSpread,isALGO,isPennyName,RouteName,LiquidityTag,Handling,' ||
               'StandardFee,MakeTakeFee,LinkageFee,SurchargeFee,Total';
    return query
        select 2 as rec_type,
               cl.order_id,
               cl.TRADE_LIQUIDITY_INDICATOR,
               TLI.LIQUIDITY_INDICATOR_TYPE_ID,
               CL.Date_id::text || ',' ||
               to_char(cl.trade_record_time, 'HH24MISSFF3') || ',' ||
               AC.TRADING_FIRM_ID || ',' ||
                   --CL.CLIENT_ID||','||
               AC.ACCOUNT_NAME || ',' ||
               case when CL.SIDE = '1' then 'B' else 'S' end || ',' ||
               UI.SYMBOL || ',' ||
               cl.LAST_QTY || ',' ||
               to_char(cl.LAST_PX, 'FM999990D0099') || ',' ||
               to_char(OC.MATURITY_MONTH, 'FM00') || '/' || to_char(OC.MATURITY_DAY, 'FM00') || '/' ||
               OC.MATURITY_YEAR || ',' ||
               coalesce(staging.trailing_dot(oc.strike_price), '') || ',' ||
               case when OC.PUT_CALL = '0' then 'P' else 'C' end || ',' ||
                   --ODCS.DAY_CUM_QTY||','||
                   --CL.OPEN_CLOSE||','||
               case cl.EXCHANGE_ID
                   when 'AMEX' then 'A'
                   when 'BATO' then 'Z'
                   when 'BOX' then 'B'
                   when 'CBOE' then 'C'
                   when 'C2OX' then 'W'
                   when 'NQBXO' then 'T'
                   when 'ISE' then 'I'
                   when 'ARCA' then 'P'
                   when 'MIAX' then 'M'
                   when 'GMNI' then 'H'
                   when 'NSDQO' then 'Q'
                   when 'PHLX' then 'X'
                   when 'EDGO' then 'E'
                   when 'MCRY' then 'J'
                   when 'MPRL' then 'R'
                   else '' end || ',' ||
               CL.CLIENT_ORDER_ID || ',' ||
-- 			NVL(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER)||','||
               coalesce(opx.opt_exec_broker::text, '') || ',' ||
                   -- 			case
-- 			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CL.OPT_CLEARING_FIRM_ID
-- 			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
-- 			end||','||
               coalesce(cl.cmta::text, '') || ',' ||
               case cl.opt_customer_firm
                   when '0' then 'CUST'
                   when '1' then 'FIRM'
                   when '2' then 'BD'
                   when '3' then 'BD-CUST'
                   when '4' then 'MM'
                   when '5' then 'AMM'
                   when '7' then 'BD-FIRM'
                   when '8' then 'CUST-PRO'
                   when 'J' then 'JBO'
                   else '' end || ',' ||--Range
               case CL.MULTILEG_REPORTING_TYPE when '1' then 'N' else 'Y' end || ',' || --isSpread
               case CL.SUB_STRATEGY when 'DMA' then 'N' else 'Y' end || ',' || --isALGO
               case OS.MIN_TICK_INCREMENT when 0.01 then 'Y' else 'N' end || ',' ||
               CL.SUB_STRATEGY || ',' ||
               cl.TRADE_LIQUIDITY_INDICATOR || ',' ||
               case TLI.LIQUIDITY_INDICATOR_TYPE_ID
                   when '1' then '128'
                   when '2' then '129'
                   when '3' then '140'
                   else '' end || ',' || --Handling Code
-- 			to_char(ROUND(BEX.TRANSACTION_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--StandardFee
               to_char(ROUND(coalesce(cl.tcce_transaction_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--StandardFee
-- 			to_char(ROUND(BEX.MAKER_TAKER_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--MakeTakeFee
               to_char(ROUND(coalesce(cl.tcce_maker_taker_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--MakeTakeFee
-- 			''||','||--LinkageFee
-- 			to_char(ROUND(BEX.ROYALTY_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--SurchargeFee
               to_char(ROUND(coalesce(cl.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--SurchargeFee
               to_char(ROUND(coalesce(cl.tcce_transaction_fee_amount, 0) + coalesce(cl.tcce_maker_taker_fee_amount, 0) +
                             coalesce(cl.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') --Total
-- 			to_char(ROUND(NVL(BEX.TRANSACTION_FEE,0)+NVL(BEX.MAKER_TAKER_FEE,0)+NVL(BEX.ROYALTY_FEE,0), 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')--Total

                 as rec
--  select cl.order_id, exec_id
        from dwh.flat_trade_record CL
                 inner join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                 left join dwh.d_clearing_account ca
                           on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                               ca.market_type = 'O' and ca.clearing_account_type = '1')
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                 left join dwh.d_LIQUIDITY_INDICATOR TLI
                           on (TLI.TRADE_LIQUIDITY_INDICATOR = cl.TRADE_LIQUIDITY_INDICATOR and
                               TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID and tli.is_active)
        where cl.date_id between :in_start_date_id and :in_end_date_id
          and ac.is_active
          and cl.account_id = any (:in_account_ids)
          and cl.IS_BUSTED = 'N'
    and cl.client_order_id = '20231019EDFM218';
end;
$fn$;

select distinct on (cl.order_id, exec_id) cl.order_id,
                                          exec_id,
                                          ---
                                          cl.trade_record_time,
                                          AC.TRADING_FIRM_ID,
                                          AC.ACCOUNT_NAME,
                                          CL.SIDE,
                                          UI.SYMBOL,
                                          cl.LAST_QTY,
                                          ftr.last_qty,
                                          cl.LAST_PX,
                                          OC.MATURITY_MONTH,
                                          OC.MATURITY_DAY,
                                          OC.MATURITY_YEAR,
                                          oc.strike_price,
                                          OC.PUT_CALL,
                                          cl.EXCHANGE_ID,
                                          CL.CLIENT_ORDER_ID,
                                          opx.opt_exec_broker,
                                          cl.cmta,
                                          cl.opt_customer_firm,
                                          CL.MULTILEG_REPORTING_TYPE,
                                          CL.SUB_STRATEGY,
                                          OS.MIN_TICK_INCREMENT,
                                          CL.SUB_STRATEGY,
                                          cl.TRADE_LIQUIDITY_INDICATOR,
                                          TLI.LIQUIDITY_INDICATOR_TYPE_ID,
                                          ftr.tcce_transaction_fee_amount,
                                          ftr.tcce_maker_taker_fee_amount,
                                          ftr.tcce_royalty_fee_amount

from dwh.flat_trade_record CL
         inner join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
         inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
         inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
         inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
         inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         left join dwh.d_clearing_account ca
                   on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                       ca.market_type = 'O' and ca.clearing_account_type = '1')
         left join dwh.d_opt_exec_broker opx
                   on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
         left join dwh.d_LIQUIDITY_INDICATOR TLI
                   on (TLI.TRADE_LIQUIDITY_INDICATOR = cl.TRADE_LIQUIDITY_INDICATOR and
                       TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID and tli.is_active)
         left join lateral (select sum(last_qty)                    as last_qty,
                                   sum(coalesce(tcce_transaction_fee_amount, 0)) as tcce_transaction_fee_amount,
                                   sum(coalesce(tcce_maker_taker_fee_amount, 0)) as tcce_maker_taker_fee_amount,
                                   sum(coalesce(tcce_royalty_fee_amount, 0))     as tcce_royalty_fee_amount
                            from dwh.flat_trade_record ftr
                            where ftr.order_id = cl.order_id
                              and ftr.exec_id = cl.exec_id
                              and ftr.date_id = cl.date_id
                              and ftr.is_busted <> 'Y'
                            limit 1) ftr on true
where cl.date_id between :in_start_date_id and :in_end_date_id
  and ac.is_active
  and cl.account_id = any (:in_account_ids)
  and cl.IS_BUSTED = 'N'
  and cl.client_order_id = '20231019EDFM218';




               to_char(ROUND(coalesce(cl.tcce_transaction_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--StandardFee
-- 			to_char(ROUND(BEX.MAKER_TAKER_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--MakeTakeFee
               to_char(ROUND(coalesce(cl.tcce_maker_taker_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--MakeTakeFee
-- 			''||','||--LinkageFee
-- 			to_char(ROUND(BEX.ROYALTY_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--SurchargeFee
               to_char(ROUND(coalesce(cl.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--SurchargeFee
               to_char(ROUND(coalesce(cl.tcce_transaction_fee_amount, 0) + coalesce(cl.tcce_maker_taker_fee_amount, 0) +
                             coalesce(cl.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') --Total
    ---

  select last_qty as last_qty, * from dwh.flat_trade_record ftr where ftr.order_id = 13454842497 and ftr.exec_id = 44725015247 and ftr.date_id = 20231019
 13457380278,44732970379


select coalesce(extract(epoch from (tca_time - basket_arrival_time)), 0)
from tca.pt_tca
where date_id = public.get_dateid(current_date)
  and activ_symbol not in ('ZVZZT')
order by basket_arrival_time desc
limit 1