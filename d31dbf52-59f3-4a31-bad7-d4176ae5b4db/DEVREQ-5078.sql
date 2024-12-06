select * from dash360.report_fintech_ebsubs_single_leg_marketability_by_wave(20241001, 20241031);

create
--     or replace
    function dash360.report_fintech_ebsubs_single_leg_marketability_by_wave(in_start_date_id integer default public.get_dateid(current_date),
                                                                            in_end_date_id integer default public.get_dateid(current_date)
)
    returns table
            (
                "Period"                      text,
                "FillPx > Farside Street BBO" text,
                "Wave Type"                   varchar,
                "Order Count"                 int8
            )
    language plpgsql
AS
$function$
    -- 2024-12-06 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5078
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ebsubs_single_leg_marketability_by_wave for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select to_char(ly.create_time, 'yyyy-MM') as "Period",
               case
                   when ly.side = '1' and ly.avg_px > ly.nbbo_ask_px_street then 'Yes'
                   when ly.side = '2' and ly.avg_px < ly.nbbo_bid_px_street then 'Yes'
                   else 'No'
                   end                            as "FillPx > Farside Street BBO",
               case
                   when ly.street_sdrc = '3' then 'Aggressive Linkage'
                   when ly.street_sdrc = '5' then 'Aggressive Synthetic IOC'
                   when ly.street_sdrc = '9' then 'Passive Posting'
                   when ly.street_sdrc = '10' then 'Aggressive IOC'
                   when ly.street_sdrc = '11' then 'Aggressive Linkage'
                   when ly.street_sdrc = '30' then 'At the Open'
                   when ly.street_sdrc = '32' then 'Auction (Scrape)'
                   when ly.street_sdrc = '50' then 'DMA'
                   when ly.street_sdrc = '57' then 'ATS Cross'
                   when ly.street_sdrc = '58' then 'ATS Sweep'
                   else ly.street_sdrc::varchar
                   end                            as "Wave Type",
               count(distinct ly.client_order_id) as "Order Count"
        from data_marts.sleg_yc ly
        where ly.create_date_id between in_start_date_id and in_end_date_id
          and ly.trading_firm_id = 'ebsubs'
          and ly.multileg_reporting_type = '1'
          and ly.target_strategy_name = 'SENSOR'
        group by "Period", "FillPx > Farside Street BBO", "Wave Type"
        order by "Period", "FillPx > Farside Street BBO" desc, "Wave Type";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ebsubs_single_leg_marketability_by_wave for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;


create
--     or replace
    function dash360.report_fintech_ebsubs_single_leg_fillpx_exceeds_farside(in_start_date_id integer default public.get_dateid(current_date),
                                                                             in_end_date_id integer default public.get_dateid(current_date)
)
    returns table
            (
                "Create Date"                 text,
                "Client Order ID"             varchar(256),
                "Symbol"                      text,
                "Order Size vs Farside BBO"   text,
                "Side"                        text,
                "Wave #"                      int8,
                "FillPx > Farside Street BBO" text,
                "Wave Type"                   varchar,
                "Order Type"                  varchar(255),
                "Exchange ID"                 varchar(6),
                "Process Time"                text,
                "Order Qty"                   int4,
                "Price"                       numeric(12, 4),
                "Exec Px"                     numeric,
                "Exec Qty"                    numeric,
                "Farside Street BBO Px"       numeric,
                "Farside Street BBO Qty"      int8
            )
    language plpgsql
AS
$function$
    -- 2024-12-06 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5078
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ebsubs_single_leg_fillpx_exceeds_farside for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        with cte_coid as
                 (
                     --Include all waves of order if at least one wave appears to have inferior price to street BBO.
                     select ly.create_date_id, ly.client_order_id
                     from data_marts.sleg_yc ly
                              left join dwh.d_order_type ot on (ot.order_type_id = ly.order_type_id)
                     where ly.create_date_id between in_start_date_id and in_end_date_id
                       and ly.trading_firm_id = 'ebsubs'
                       and ly.multileg_reporting_type = '1'
                       and ly.target_strategy_name = 'SENSOR'
                       and ((ly.side = '1' and ly.avg_px > ly.nbbo_ask_px_street) or
                            (ly.side in ('2', '5', '6') and ly.avg_px < ly.nbbo_bid_px_street)))
        select to_char(ly.create_time, 'MM/dd/yyyy')                                as "Create Date",
               ly.client_order_id                                                   as "Client Order ID",
               --replace(array_to_string(ly.display_instrument_id, ','), '''', '') as "Symbol",
               replace(array_to_string(ly.display_instrument_id, ','), chr(39), '') as "Symbol",
               case
                   when ly.side = '1' and ly.order_qty > ly.nbbo_ask_qty_street then 'Oversized'
                   when ly.side in ('2', '5', '6') and ly.order_qty < ly.nbbo_bid_qty_street then 'Oversized'
                   else 'Undersized'
                   end                                                              as "Order Size vs Farside BBO",
               case
                   when ly.side = '1' then 'Buy'
                   when ly.side in ('2', '5', '6') then 'Sell'
                   end                                                              as "Side",
               ly.rn                                                                as "Wave #",
               case
                   when ly.side = '1' and ly.avg_px > ly.nbbo_ask_px_street then 'Yes'
                   when ly.side in ('2', '5', '6') and ly.avg_px < ly.nbbo_bid_px_street then 'Yes'
                   else 'No'
                   end                                                              as "FillPx > Farside Street BBO",
               case
                   when ly.street_sdrc = '3' then 'Aggressive Linkage'
                   when ly.street_sdrc = '5' then 'Aggressive Synthetic IOC'
                   when ly.street_sdrc = '9' then 'Passive Posting'
                   when ly.street_sdrc = '10' then 'Aggressive IOC'
                   when ly.street_sdrc = '11' then 'Aggressive Linkage'
                   when ly.street_sdrc = '30' then 'At the Open'
                   when ly.street_sdrc = '32' then 'Auction (Scrape)'
                   when ly.street_sdrc = '50' then 'DMA'
                   when ly.street_sdrc = '57' then 'ATS Cross'
                   when ly.street_sdrc = '58' then 'ATS Sweep'
                   else ly.street_sdrc::varchar
                   end                                                              as "Wave Type",
               ot.order_type_name                                                   as "Order Type", --ISO?
               ly.street_exchange_id                                                as "Exchange ID",
               to_char(ly.process_time, 'HH24:MI:SS.MS')                            as "Process Time",
               ly.order_qty                                                         as "Order Qty",
               ly.price                                                             as "Price",
               ly.avg_px                                                            as "Exec Px",
               ly.last_qty_sum                                                      as "Exec Qty",
               case
                   when ly.side = '1' then ly.nbbo_ask_px_street
                   when ly.side in ('2', '5', '6') then ly.nbbo_bid_px_street
                   end                                                              as "Farside Street BBO Px",
               case
                   when ly.side = '1' then ly.nbbo_ask_qty_street
                   when ly.side in ('2', '5', '6') then ly.nbbo_bid_qty_street
                   end                                                              as "Farside Street BBO Qty"
        from cte_coid cc
                 join data_marts.sleg_yc ly
                      on (ly.create_date_id = cc.create_date_id and ly.client_order_id = cc.client_order_id)
                 left join dwh.d_order_type ot on (ot.order_type_id = ly.order_type_id)
        where ly.create_date_id between in_start_date_id and in_end_date_id
        order by ly.create_date_id, ly.order_id, ly.rn;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ebsubs_single_leg_fillpx_exceeds_farside for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$;





--------------
select * from dash360.report_fintech_ebsubs_single_leg_fillpx_exceeds_farside(20241001,20241030)
