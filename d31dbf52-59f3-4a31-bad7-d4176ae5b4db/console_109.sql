-- DROP FUNCTION dash360.dash360_report_parent_order_metrics(_int8, varchar, int4, int4, bpchar);

create or replace function trash.dash360_report_parent_order_metrics(account_ids bigint[] default '{}'::bigint[],
                                                                       instrument_type_id character varying default null::character varying(1),
                                                                       start_status_date_id integer default null::integer,
                                                                       end_status_date_id integer default null::integer,
                                                                       is_demo character default 'N'::bpchar,
                                                                       trading_firm_ids character varying[] default '{}'::character varying[])
    returns table
            (
                exec_time               timestamp without time zone,
                routed_time             timestamp without time zone,
                status_date_id          integer,
                transaction_id          bigint,
                order_id                bigint,
                client_order_id         character varying,
                multileg_reporting_type character,
                tif_name                character varying,
                order_type_name         character varying,
                order_price             numeric,
                day_order_qty           integer,
                day_cum_qty             integer,
                day_avg_px              numeric,
                side                    character,
                client_id               character varying,
                account_name            character varying,
                is_marketable           character,
                cross_order_id          bigint,
                sec_type_id             character,
                display_instrument_id   character varying,
                last_trade_date         timestamp without time zone,
                sub_strategy            character varying,
                num_exch                smallint,
                nbbo_bid_price          numeric,
                nbbo_bid_quantity       integer,
                nbbo_ask_price          numeric,
                nbbo_ask_quantity       integer,
                parent_order_id         bigint,
                wave_no                 smallint,
                first_wave_nbbo_bid_px  numeric,
                last_wave_nbbo_bid_px   numeric,
                first_wave_nbbo_ask_px  numeric,
                last_wave_nbbo_ask_px   numeric,
                first_wave_nbbo_bid_qty bigint,
                last_wave_nbbo_bid_qty  bigint,
                first_wave_nbbo_ask_qty bigint,
                last_wave_nbbo_ask_qty  bigint,
                rn                      integer
            )
    LANGUAGE plpgsql
AS
$function$
    -- https://dashfinancial.atlassian.net/browse/DS-7884 SO 20240130 changing logic especially for legs with no market_data
	-- https://dashfinancial.atlassian.net/browse/DS-9344 PD 20241224 changed datatype for output column cross_order_id int->bigint
    -- https://dashfinancial.atlassian.net/browse/DS-9346 SO 20241225 added trading_firm_ids as an input parameter
declare
    in_instrument_type_id char := $2;
    l_account_ids int8[];
begin
        if coalesce(account_ids, '{}') = '{}' and coalesce(trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id::int8)
        into l_account_ids
        from dwh.d_account
        where true
           and case when coalesce(trading_firm_ids, '{}') <> '{}'::varchar[] then trading_firm_id = ANY (trading_firm_ids) else true end
           and case when coalesce(account_ids, '{}') <> '{}'::int8[] then account_id = ANY (account_ids) else true end;
    end if;

    return query
        select po.exec_time,
               po.routed_time,
               po.status_date_id,
               po.transaction_id,
               po.order_id,
               po.client_order_id,
               po.multileg_reporting_type,
               tif.tif_name,
               ot.order_type_name,
               po.order_price,
               po.day_order_qty,
               po.day_cum_qty,
               po.day_avg_px,
               po.side,
               po.client_id,
               acc.account_name,
               po.is_marketable,
               po.cross_order_id,
               po.instrument_type_id                                                                       as sec_type_id,
               i.display_instrument_id,
               i.last_trade_date,
               dss.target_strategy_name                                                                    as sub_strategy,
               po.num_exch,
               coalesce(po.nbbo_bid_price, parent_waves.first_wave_nbbo_bid_px,
                        head_md.bid_price)                                                                 as nbbo_bid_price,
               coalesce(po.nbbo_bid_quantity, parent_waves.first_wave_nbbo_bid_qty,
                        head_md.bid_qty::int4)                                                             as nbbo_bid_quantity,
               coalesce(po.nbbo_ask_price, parent_waves.first_wave_nbbo_ask_px,
                        head_md.ask_price)                                                                 as nbbo_ask_price,
               coalesce(po.nbbo_ask_quantity, parent_waves.first_wave_nbbo_ask_qty,
                        head_md.ask_qty::int4)                                                             as nbbo_ask_quantity,
               parent_waves.parent_order_id,
               parent_waves.wave_no,
               coalesce(parent_waves.first_wave_nbbo_bid_px, head_md.bid_price)                            as first_wave_nbbo_bid_px,
               coalesce(parent_waves.last_wave_nbbo_bid_px, head_md.bid_price)                             as last_wave_nbbo_bid_px,
               coalesce(parent_waves.first_wave_nbbo_ask_px, head_md.ask_price)                            as first_wave_nbbo_ask_px,
               coalesce(parent_waves.last_wave_nbbo_ask_px, head_md.ask_price)                             as last_wave_nbbo_ask_px,
               coalesce(parent_waves.first_wave_nbbo_bid_qty::int8,
                        head_md.bid_qty)                                                                   as first_wave_nbbo_bid_qty,
               coalesce(parent_waves.last_wave_nbbo_bid_qty::int8,
                        head_md.bid_qty)                                                                   as last_wave_nbbo_bid_qty,
               coalesce(parent_waves.first_wave_nbbo_ask_qty::int8,
                        head_md.ask_qty)                                                                   as first_wave_nbbo_ask_qty,
               coalesce(parent_waves.last_wave_nbbo_ask_qty::int8,
                        head_md.ask_qty)                                                                   as last_wave_nbbo_ask_qty,
               1                                                                                           as rn
        from data_marts.f_yield_capture po
                 inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join dwh.d_account acc on (acc.account_id = po.account_id)
                 inner join lateral (select str.parent_order_id,
                                            last_value(str.wave_no) over w            as wave_no,
                                            first_value(str.nbbo_bid_price) over w    as first_wave_nbbo_bid_px,
                                            last_value(str.nbbo_bid_price) over w     as last_wave_nbbo_bid_px,
                                            first_value(str.nbbo_ask_price) over w    as first_wave_nbbo_ask_px,
                                            last_value(str.nbbo_ask_price) over w     as last_wave_nbbo_ask_px,
                                            first_value(str.nbbo_bid_quantity) over w as first_wave_nbbo_bid_qty,
                                            last_value(str.nbbo_bid_quantity) over w  as last_wave_nbbo_bid_qty,
                                            first_value(str.nbbo_ask_quantity) over w as first_wave_nbbo_ask_qty,
                                            last_value(str.nbbo_ask_quantity) over w  as last_wave_nbbo_ask_qty
                                     from data_marts.f_yield_capture str
                                     where str.parent_order_id = po.order_id
                                       and str.status_date_id >= start_status_date_id
                                       and str.status_date_id <= end_status_date_id
                                       and str.parent_order_id is not null
                                       and str.status_date_id = po.status_date_id
                                     window w as (partition by str.parent_order_id order by str.wave_no)
                                     order by str.wave_no desc
                                     limit 1
            ) parent_waves on true
                 left join lateral (select *
                                    from dwh.get_routing_market_data(in_transaction_id := po.transaction_id,
                                                                     in_exchange_id := 'NBBO',
                                                                     in_multileg_reporting_type := '3',
                                                                     in_instrument_id := 3,
                                                                     in_date_id := po.status_date_id)
                                    where po.multileg_reporting_type = '2'
                                      and num_nonnulls(parent_waves.first_wave_nbbo_bid_px,
                                                       parent_waves.first_wave_nbbo_ask_px,
                                                       parent_waves.first_wave_nbbo_bid_qty,
                                                       parent_waves.first_wave_nbbo_ask_qty) = 0
                                    limit 1
            ) head_md on true
        where po.parent_order_id is null
          and po.status_date_id >= start_status_date_id
          and po.status_date_id <= end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = in_instrument_type_id
          and po.time_in_force_id in ('0', '2', '3', '4')
          and po.account_id = any (l_account_ids);
end;
$function$
;
---
select po.account_id, acc.trading_firm_id
from data_marts.f_yield_capture po
                 inner join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = po.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = po.order_type_id
                 inner join dwh.d_instrument i on i.instrument_id = po.instrument_id
                 left join dwh.d_target_strategy dss on po.sub_strategy_id = dss.target_strategy_id
                 inner join dwh.d_account acc on (acc.account_id = po.account_id)
                 inner join lateral (select str.parent_order_id,
                                            last_value(str.wave_no) over w            as wave_no,
                                            first_value(str.nbbo_bid_price) over w    as first_wave_nbbo_bid_px,
                                            last_value(str.nbbo_bid_price) over w     as last_wave_nbbo_bid_px,
                                            first_value(str.nbbo_ask_price) over w    as first_wave_nbbo_ask_px,
                                            last_value(str.nbbo_ask_price) over w     as last_wave_nbbo_ask_px,
                                            first_value(str.nbbo_bid_quantity) over w as first_wave_nbbo_bid_qty,
                                            last_value(str.nbbo_bid_quantity) over w  as last_wave_nbbo_bid_qty,
                                            first_value(str.nbbo_ask_quantity) over w as first_wave_nbbo_ask_qty,
                                            last_value(str.nbbo_ask_quantity) over w  as last_wave_nbbo_ask_qty
                                     from data_marts.f_yield_capture str
                                     where str.parent_order_id = po.order_id
                                       and str.status_date_id >= :start_status_date_id
                                       and str.status_date_id <= :end_status_date_id
                                       and str.parent_order_id is not null
                                       and str.status_date_id = po.status_date_id
                                     window w as (partition by str.parent_order_id order by str.wave_no)
                                     order by str.wave_no desc
                                     limit 1
            ) parent_waves on true
                 left join lateral (select *
                                    from dwh.get_routing_market_data(in_transaction_id := po.transaction_id,
                                                                     in_exchange_id := 'NBBO',
                                                                     in_multileg_reporting_type := '3',
                                                                     in_instrument_id := 3,
                                                                     in_date_id := po.status_date_id)
                                    where po.multileg_reporting_type = '2'
                                      and num_nonnulls(parent_waves.first_wave_nbbo_bid_px,
                                                       parent_waves.first_wave_nbbo_ask_px,
                                                       parent_waves.first_wave_nbbo_bid_qty,
                                                       parent_waves.first_wave_nbbo_ask_qty) = 0
                                    limit 1
            ) head_md on true
        where po.parent_order_id is null
          and po.status_date_id >= :start_status_date_id
          and po.status_date_id <= :end_status_date_id
          and po.multileg_reporting_type in ('1', '2')
          and po.instrument_type_id = :in_instrument_type_id
          and po.time_in_force_id in ('0', '2', '3', '4')
          and po.account_id = any (:l_account_ids);


select *
from trash.dash360_report_parent_order_metrics(account_ids := '{63887}', instrument_type_id := 'O',
                                               start_status_date_id := 20241224, end_status_date_id := 20241224,
                                               trading_firm_ids := '{"dftdesk02"}');


select *
from dash360.dash360_report_parent_order_metrics(account_ids := '{}', instrument_type_id := 'O',
                                               start_status_date_id := 20241224, end_status_date_id := 20241224),
                                               trading_firm_ids := '{"dftdesk02"}')