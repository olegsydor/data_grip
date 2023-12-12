select * from blaze7.report_daily_totals_2(in_date_begin := 20230620, in_date_end := 20230620);
except
select * from blaze7.report_daily_totals(in_date_begin := 20230620, in_date_end := 20230620);


create or replace function blaze7.report_daily_totals(in_date_begin integer, in_date_end integer)
 returns table("Date" integer, "Active Logins" integer, "# of Trading Users" integer, "# of Trading Entities" integer, "# of OBO Entities" integer, "# of FIX OE Entities" integer, "Total # of Orders" integer, "Parent Orders" integer, "Child Orders" integer, "GUI Stage Orders" integer, "FIX OE Orders" integer, "Imported Orders" integer, "OBO Orders" integer, "Manually Filled Orders" integer, "Stitched Mleg Orders" integer, "Linked Orders" integer, "Represented Orders" integer, "FLEX Orders" integer, "DMA Orders" integer, "Algo Orders" integer, "Broker Route Orders" integer, "Manual Route Orders" integer, "Vega Orders" integer, "VOL Orders" integer, "GTH Orders" integer, "Instruments" integer, "Single Equity Orders" integer, "Single Option Orders" integer, "Spread Orders" integer, "Spread tied to Stock Orders" integer, "Cross Single Orders" integer, "Cross Spread Orders" integer, "Cross Spread tied to Stock Orders" integer, "Order Reports" integer, "Manual Fill Reports" integer, "Bust Reports" integer)
    LANGUAGE plpgsql
AS
$function$
declare
    f_min_ts timestamp;
begin
    f_min_ts = in_date_begin::text::timestamp;


    create temp table active_logins on commit drop as
    select distinct(ueh.user_id),
                   to_char(ueh.event_time at time zone 'America/New_York', 'YYYYMMDD')::int as creation_date_id
    from blaze7_identity.user_events_history ueh
    where ueh.event_time at time zone 'America/New_York' between to_timestamp(in_date_begin::text, 'YYYYMMDD') and to_timestamp(in_date_end::text, 'YYYYMMDD') + interval '1 day'
      and ueh.event_type = 1;

    create temp table orders on commit drop as
    select co.creation_date_id,
           (co.payload ->> 'OwnerUserId')::int   as user_id,
           case
               when co.order_class = 'O' then (co.payload ->> 'OwnerUserId')::int
               end                               as obo_user_id,
           (co.payload ->> 'OwnerEntityId')::int as entity_id,
           case
               when co.order_class = 'O' then (co.payload ->> 'OwnerEntityId')::int
               end                               as obo_entity_id,
           case
               when co.order_class = 'F' and (co.payload ->> 'OrderSource')::bpchar = 'P' then co.entity_id
               end                               as fixoe_entity_id,
           co.order_id,
           case
               when co.parent_order_id is null then order_id
               end                               as parent_order_id,
           case
               when co.order_class = 'G' and co.route_type = 'S' and
                    (co.crossing_side = 'O' or co.crossing_side is null) then order_id
               end                               as gui_stage_order_id,
           case
               when co.order_class = 'F' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as fix_order_id,
           case
               when co.order_class = 'O' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as obo_order_id,
           case
               when co.order_class = 'I' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as imported_order_id,
           case
               when co.payload ->> 'IsStitched' = 'Y' then co.order_id
               end                               as stitched_order_id,
           case
               when co.parent_order_id is not null then co.order_id
               end                               as child_order_id,
           case
               when co.crossing_side = 'O' and co.payload -> 'OriginatorOrder' ->> 'HasLinkedOrders' = 'Y' then order_id
               when co.crossing_side = 'C' and co.payload -> 'ContraOrder' ->> 'HasLinkedOrders' = 'Y' then order_id
               when co.payload ->> 'HasLinkedOrders' = 'Y' then order_id
               end                                  link_stage_order_id,
           case
               when co.crossing_side = 'O' and co.payload -> 'OriginatorOrder' ->> 'IsRepresented' = 'Y' then order_id
               when co.crossing_side = 'C' and co.payload -> 'ContraOrder' ->> 'IsRepresented' = 'Y' then order_id
               when co.payload ->> 'IsRepresented' = 'Y' then order_id
               end                                  represented_order_id,
           case
               when co.route_destination = 'VEGA' then co.order_id
               end                               as vega_order_id,
           case
               when co.route_destination = 'VOLT' then co.order_id
               when co.route_destination = 'VOLHEDGE' then co.order_id
               end                               as vol_order_id,
           case
               when co.payload -> 'AlgoDetails' ->> 'CBOESessionEligibility' in ('A', 'G', 'D') and
                    (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as gth_order_id,
           case
               when co.payload ->> 'IsFlex' = 'Y' and co.order_class <> 'O' and
                    (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as flex_order_id,
           case
               when co.route_type = 'D' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as dma_order_id,
           case
               when co.route_type = 'A' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as algo_order_id,
           case
               when co.route_type = 'B' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as broker_route_order_id,
           case
               when co.route_type = 'M' and (co.crossing_side = 'O' or co.crossing_side is null) then co.order_id
               end                               as manual_route_order_id,
           case
               when co.instrument_type = 'E' then co.order_id
               end                               as single_equity_order_id,
           case
               when co.instrument_type = 'O' then co.order_id
               end                               as single_option_order_id,
           case
               when co.instrument_type = 'M' and co.cross_order_id is null and co.payload ->> 'SpreadType' = '0'
                   then co.order_id
               end                               as single_spread_order_id,
           case
               when co.instrument_type = 'M' and co.cross_order_id is null and co.payload ->> 'SpreadType' = '1'
                   then co.order_id
               end                               as single_spread_with_stock_order_id,
           case
               when co.instrument_type = 'O' and co.crossing_side = 'O' then co.order_id
               end                               as cross_single_order_id,
           case
               when co.instrument_type = 'M' and co.crossing_side = 'O' and co.payload ->> 'SpreadType' = '0'
                   then co.order_id
               end                               as cross_spread_order_id,
           case
               when co.instrument_type = 'M' and co.crossing_side = 'O' and co.payload ->> 'SpreadType' = '1'
                   then co.order_id
               end                               as cross_spread_with_stock_order_id
    from blaze7.blaze7.client_order co
    where co.creation_date_id between in_date_begin and in_date_end
      and co.record_type = '0';

    create temp table reports on commit drop as
    select co.creation_date_id,
           count(*) as reports_count,
           sum
               (
                   case
                       when rep.exec_type in ('1', '2') and rep.multileg_reporting_type in ('1', '2') and
                            rep.payload ->> 'OrderReportSpecialType' = 'M' then 1
                       else 0
                       end
               )    as manual_fill_reports_count,
           sum
               (
                   case
                       when rep.exec_type = 'r' then 1
                       else 0
                       end
               )    as bust_reports_count
    from blaze7.blaze7.order_report rep
             join blaze7.blaze7.client_order co on rep.order_id = co.order_id and rep.chain_id = co.chain_id
    where co.creation_date_id between in_date_begin and in_date_end
      and co.record_type in ('0', '2')
      and rep.db_create_time >= f_min_ts
    group by co.creation_date_id;

    create temp table manual_filled_orders on commit drop as
    select co.creation_date_id,
           count(distinct (co.order_id)) as orders_count
    from blaze7.blaze7.order_report rep
             join blaze7.blaze7.client_order co on rep.order_id = co.order_id and rep.chain_id = co.chain_id
    where co.creation_date_id between in_date_begin and in_date_end
      and co.record_type in ('0')
      and co.route_type = 'S'
      and rep.exec_type in ('1', '2')
      and rep.payload ->> 'OrderReportSpecialType' = 'M'
      and rep.db_create_time >= f_min_ts
    group by co.creation_date_id;

    create temp table instruments on commit drop as
    select co.creation_date_id,
           count(distinct (
               case
                   when co.instrument_type <> 'M' and co.crossing_side = 'O'
                       then co.payload -> 'OriginatorOrder' ->> 'DashSecurityId'
                   when co.instrument_type <> 'M' and co.crossing_side = 'C'
                       then co.payload -> 'ContraOrder' ->> 'DashSecurityId'
                   when co.instrument_type = 'M' then leg.payload ->> 'DashSecurityId'
                   else co.payload ->> 'DashSecurityId'
                   end
               )) as instruments_count
    from blaze7.blaze7.client_order co
             left join blaze7.blaze7.client_order_leg leg on leg.order_id = co.order_id and leg.chain_id = co.chain_id
    where co.creation_date_id between in_date_begin and in_date_end
      and co.record_type in ('0')
      and co.chain_id = 0
    group by co.creation_date_id;

    return query
        select o.creation_date_id                                                              "Date",
               count(distinct al.user_id)::integer                                             "Active Logins",
               count(distinct o.user_id)::integer - count(distinct o.obo_user_id)::integer     "# of Trading Users",
               count(distinct o.entity_id)::integer - count(distinct o.obo_entity_id)::integer "# of Trading Entities",
               count(distinct o.obo_entity_id)::integer                                        "# of OBO Entities",
               count(distinct o.fixoe_entity_id)::integer                                      "# of FIX OE Entities",
               count(distinct o.order_id)::integer                                             "Total # of Orders",
               count(distinct o.parent_order_id)::integer                                      "Parent Orders",
               count(distinct o.child_order_id)::integer                                       "Child Orders",
               count(distinct o.gui_stage_order_id)::integer                                   "GUI Stage Orders",
               count(distinct o.fix_order_id)::integer                                         "FIX OE Orders",
               count(distinct o.imported_order_id)::integer                                    "Imported Orders",
               count(distinct o.obo_order_id)::integer                                         "OBO Orders",
               max(mfr.orders_count)::integer                                                  "Manually Filled Orders",
               count(distinct o.stitched_order_id)::integer                                    "Stitched Mleg Orders",
               count(distinct o.link_stage_order_id)::integer                                  "Linked Orders",
               count(distinct o.represented_order_id)::integer                                 "Represented Orders",
               count(distinct o.flex_order_id)::integer                                        "FLEX Orders",
               count(distinct o.dma_order_id)::integer                                         "DMA Orders",
               count(distinct o.algo_order_id)::integer                                        "Algo Orders",
               count(distinct o.broker_route_order_id)::integer                                "Broker Route Orders",
               count(distinct o.manual_route_order_id)::integer                                "Manual Route Orders",
               count(distinct o.vega_order_id)::integer                                        "Vega Orders",
               count(distinct o.vol_order_id)::integer                                         "VOL Orders",
               count(distinct o.gth_order_id)::integer                                         "GTH Orders",
               max(i.instruments_count)::integer         as                                    "Instruments",
               count(distinct o.single_equity_order_id)::integer                               "Single Equity Orders",
               count(distinct o.single_option_order_id)::integer                               "Single Option Orders",
               count(distinct o.single_spread_order_id)::integer                               "Spread Orders",
               count(distinct o.single_spread_with_stock_order_id)::integer                    "Spread tied to Stock Orders",
               count(distinct o.cross_single_order_id)::integer                                "Cross Single Orders",
               count(distinct o.cross_spread_order_id)::integer                                "Cross Spread Orders",
               count(distinct o.cross_spread_with_stock_order_id)::integer                     "Cross Spread tied to Stock Orders",
               max(r.reports_count)::integer             as                                    "Order Reports",
               max(r.manual_fill_reports_count)::integer as                                    "Manual Fill Reports",
               max(r.bust_reports_count)::integer        as                                    "Bust Reports"
        from orders o
                 left join reports r on r.creation_date_id = o.creation_date_id
                 left join manual_filled_orders mfr on mfr.creation_date_id = o.creation_date_id
                 left join instruments i on i.creation_date_id = o.creation_date_id
                 left join active_logins al on al.creation_date_id = o.creation_date_id
        group by o.creation_date_id;

end;
$function$
;


SELECT id,
       user_id,
       entity_id,
       event_data ->> 'ClientVersion'                    as client_version,
       event_time::timestamptz at time zone 'US/Central' as event_time
FROM blaze7_identity.user_events_history
where true
  and event_type = '1'
  and event_data ->> 'ClientVersion' !~* '[[:alpha:]]'

select 36467 -19
select regexp_match('s1dyp', '\d')
select 'yup' !~* '[[:alpha:]]'