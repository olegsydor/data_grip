-- DROP FUNCTION fintech_reports.eod_jonestrad_best_ex_ht3(int4, int4);

CREATE FUNCTION trash.eod_jonestrad_best_ex_ht3(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE))
    RETURNS TABLE
            (
                "Parent Cl Ord ID"     character varying,
                "Account"              character varying,
                "Ord Status"           character varying,
                "Event Date"           date,
                "Routed Time"          timestamp without time zone,
                "Executed Time"        timestamp without time zone,
                "Street Transact Time" timestamp without time zone,
                "Street Cl Ord ID"     character varying,
                "Sec Type"             character varying,
                "Side"                 character varying,
                "Symbol"               character varying,
                "Root"                 character varying,
                "Exp Date"             date,
                "TIF"                  character varying,
                "Ord Type"             character varying,
                "Jones ID"             character varying,
                "Free Text"            character varying,
                "Strategy User Data"   character varying,
                "Strategy Name"        character varying,
                "Floor Broker ID"      character varying,
                "Ex Dest - Cust"       character varying,
                "Single/Complex"       character varying,
                "Electronic"           character varying,
                "Ord Qty"              integer,
                "Ex Qty"               bigint,
                "Ex Px"                numeric,
                "Net Avg Px"           numeric,
                "Ord Px"               numeric,
                "Bid Qty"              integer,
                "Bid Px"               numeric,
                "Ask Px"               numeric,
                "Ask Qty"              integer,
                "Improvement"          numeric,
                "% Improvement"        numeric,
                "Ord Px Improvement"   numeric,
                "Ord Px % Improvement" numeric,
                "Flag"                 character varying
            )
    LANGUAGE plpgsql
AS
$function$
-- 2024-09-11 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
declare
    l_start_date_id int;
    l_end_date_id   int;
    l_load_id       int8;
    l_step_id       int4;
    l_row_cnt       int4;
    l_msg_log       text;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;


    l_start_date_id := in_start_date_id;
    l_end_date_id := in_end_date_id;

    l_msg_log :=
            'fintech_reports.eod_jonestrad_best_ex_ht3 for' || l_start_date_id::text || '-' || l_end_date_id::text ||
            ' ';
    select public.load_log(l_load_id, l_step_id, l_msg_log || 'STARTED===', 0, 'O')
    into l_step_id;


    drop table if exists ex_agg_str;
    create temp table ex_agg_str as
    select f_str1.status_date_id                    as date_id,
           f_str1.client_order_id,
           round(abs(sum((case when f_str1.side = '1' then 1.0 else -1.0 end) * coalesce(f_str1.avg_px, 0.0) * (case
                                                                                                                    when po1.ratio_qty is null
                                                                                                                        then 1
                                                                                                                    when f_str1.instrument_type_id = 'E'
                                                                                                                        then po1.ratio_qty / 100.0
                                                                                                                    else po1.ratio_qty end))) *
                 sign(coalesce(po1.price, 1.0)), 4) as net_avg_px
    from data_marts.f_yield_capture f_str1
             join dwh.client_order po1 on (po1.order_id = f_str1.parent_order_id and
                                           po1.create_date_id between l_start_date_id and l_end_date_id and
                                           po1.create_date_id = f_str1.status_date_id)
             join dwh.d_account a1 on (a1.account_id = f_str1.account_id)
    where f_str1.status_date_id between l_start_date_id and l_end_date_id
      and f_str1.parent_order_id is not null
      and f_str1.multileg_reporting_type in ('1', '2')
      and f_str1.day_cum_qty > 0
      and a1.trading_firm_id = 'jonestrad'
    group by f_str1.status_date_id, f_str1.client_order_id, po1.price;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_log || 'ex_agg_str table created===', l_row_cnt, 'O')
    into l_step_id;

    drop table if exists ex_agg_par;
    create temp table ex_agg_par as
    select f_par1.status_date_id                    as date_id,
           f_par1.client_order_id,
           round(abs(sum((case when f_par1.side = '1' then 1.0 else -1.0 end) * coalesce(f_par1.avg_px, 0.0) * (case
                                                                                                                    when po1.ratio_qty is null
                                                                                                                        then 1
                                                                                                                    when f_par1.instrument_type_id = 'E'
                                                                                                                        then po1.ratio_qty / 100.0
                                                                                                                    else po1.ratio_qty end))) *
                 sign(coalesce(po1.price, 1.0)), 4) as net_avg_px
    from data_marts.f_yield_capture f_par1
             join dwh.client_order po1 on (po1.order_id = f_par1.order_id and
                                           po1.create_date_id between l_start_date_id and l_end_date_id and
                                           po1.create_date_id = f_par1.status_date_id)
             join dwh.d_account a1 on (a1.account_id = f_par1.account_id)
    where f_par1.status_date_id between l_start_date_id and l_end_date_id
      and f_par1.parent_order_id is null
      and f_par1.multileg_reporting_type in ('1', '2')
      and f_par1.day_cum_qty > 0
      and a1.trading_firm_id = 'jonestrad'
    group by f_par1.status_date_id, f_par1.client_order_id, po1.price;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_log || 'ex_agg_par table created===', l_row_cnt, 'O')
    into l_step_id;

    drop table if exists ret_table;

    create temp table ret_table as
    select f_par.client_order_id                                                               as "Parent Cl Ord ID",
           a.account_name                                                                      as "Account",
           os.order_status_description                                                         as "Ord Status",
           f_str.routed_time::date                                                             as "Event Date",
           f_str.routed_time::timestamp                                                        as "Routed Time",
           --f_str.exec_time::timestamp as "Executed Time",
           ex.exec_time::timestamp                                                             as "Executed Time",
           to_timestamp(fme.fix_message ->> '10160'::varchar, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC' at time zone
           'EST'                                                                               as "Street Transact Time",
           f_str.client_order_id                                                               as "Street Cl Ord ID",
           (case
                when hsd.instrument_type_id = 'O' then 'Option'
                when hsd.instrument_type_id = 'E' then 'Equity' end)::varchar                  as "Sec Type",
           (case
                when f_par.side = '1' then 'Buy'
                when f_par.side = '2' then 'Sell'
                when f_par.side in ('5', '6') then 'Sell Short'
                else null end)::varchar                                                        as "Side",
           hsd.display_instrument_id                                                           as "Symbol",
           hsd.symbol                                                                          as "Root",
           hsd.maturity_date::date                                                             as "Exp Date",
           tif.tif_name                                                                        as "TIF",
           ot.order_type_name                                                                  as "Ord Type",
           f_par.client_id                                                                     as "Jones ID",
           ex.exec_text                                                                        as "Free Text",
           sdrc.strategy_user_data                                                             as "Strategy User Data",
           coalesce(bsn.bloomberg_strategy_name, dss.target_strategy_name)                     as "Strategy Name",
           --null::varchar as "Floor Broker ID",
           (fm.fix_message ->> '143')::varchar                                                 as "Floor Broker ID",
           real_exch.exchange_name                                                             as "Ex Dest - Cust",
           (case
                when f_str.multileg_reporting_type = '1' then 'Single-Leg'
                else 'Complex' end)::varchar                                                   as "Single/Complex",
           (case when a.account_name like '%_BP' then 'Manual' else 'Electronic' end)::varchar as "Electronic",
           f_str.order_qty                                                                     as "Ord Qty",
           ex.last_qty                                                                         as "Ex Qty",
           ex.last_px                                                                          as "Ex Px",
           ex_agg_str.net_avg_px                                                               AS "Net Avg Px",
           f_par.order_price                                                                   as "Ord Px",
           --(case when f_str.multileg_reporting_type = '1' then f_str.nbbo_bid_quantity end)  as "Bid Qty",
           --(case when f_str.multileg_reporting_type = '1' then f_str.nbbo_bid_price end) as "Bid Px",
           --(case when f_str.multileg_reporting_type = '1' then f_str.nbbo_ask_price end) as "Ask Px",
           --(case when f_str.multileg_reporting_type = '1' then f_str.nbbo_ask_quantity end) as "Ask Qty",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_str.multileg_reporting_type <> '1') then null
               else f_str.nbbo_bid_quantity end                                                as "Bid Qty",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_str.multileg_reporting_type <> '1') then null
               else f_str.nbbo_bid_price end                                                   as "Bid Px",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_str.multileg_reporting_type <> '1') then null
               else f_str.nbbo_ask_price end                                                   as "Ask Px",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_str.multileg_reporting_type <> '1') then null
               else f_str.nbbo_ask_quantity end                                                as "Ask Qty",
           case
               when f_str.multileg_reporting_type <> '1' or coalesce(f_str.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_str.nbbo_bid_price, 0.0) = 0.0 then null
               when (f_str.multileg_reporting_type = '1' and f_str.side = '1') and
                    ex_agg_str.net_avg_px < f_str.nbbo_ask_price
                   then f_str.nbbo_ask_price - ex_agg_str.net_avg_px
               when (f_str.multileg_reporting_type = '1' and f_str.side <> '1') and
                    ex_agg_str.net_avg_px > f_str.nbbo_bid_price
                   then ex_agg_str.net_avg_px - f_str.nbbo_bid_price
               else 0.0
               end                                                                             as "Improvement",
           case
               when f_str.multileg_reporting_type <> '1' or coalesce(f_str.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_str.nbbo_bid_price, 0.0) = 0.0 then null
               when (f_str.multileg_reporting_type = '1' and f_str.side = '1') and
                    ex_agg_str.net_avg_px < f_str.nbbo_ask_price
                   then round((f_str.nbbo_ask_price - ex_agg_str.net_avg_px) / abs(f_str.nbbo_ask_price), 4)
               when (f_str.multileg_reporting_type = '1' and f_str.side <> '1') and
                    ex_agg_str.net_avg_px > f_str.nbbo_bid_price
                   then round((ex_agg_str.net_avg_px - f_str.nbbo_bid_price) / abs(f_str.nbbo_bid_price), 4)
               else 0.0
               end                                                                             as "% Improvement",
           case
               --when coalesce(f_str.nbbo_ask_price, 0.0) = 0.0 or coalesce(f_str.nbbo_bid_price, 0.0) = 0.0 or coalesce(f_par.order_price, 0.0) = 0.0 then null
               when f_par.multileg_reporting_type <> '1' and ex_agg_str.net_avg_px < f_par.order_price
                   then f_par.order_price - ex_agg_str.net_avg_px
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_str.net_avg_px < f_par.order_price
                   then f_par.order_price - ex_agg_str.net_avg_px
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_str.net_avg_px > f_par.order_price
                   then ex_agg_str.net_avg_px - f_par.order_price
               else 0.0
               end                                                                             as "Ord Px Improvement",
           case
               --when coalesce(f_str.nbbo_ask_price, 0.0) = 0.0 or coalesce(f_str.nbbo_bid_price, 0.0) = 0.0 or coalesce(f_par.order_price, 0.0) = 0.0 then null
               when f_par.multileg_reporting_type <> '1' and ex_agg_str.net_avg_px < f_par.order_price
                   then round((f_par.order_price - ex_agg_str.net_avg_px) / abs(f_par.order_price), 4)
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_str.net_avg_px < f_par.order_price
                   then round((f_par.order_price - ex_agg_str.net_avg_px) / abs(f_par.order_price), 4)
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_str.net_avg_px > f_par.order_price
                   then round((ex_agg_str.net_avg_px - f_par.order_price) / abs(f_par.order_price), 4)
               else 0.0
               end                                                                             as "Ord Px % Improvement",
           case
               when coalesce(fm.fix_message ->> '143', '') <> '' then null
               when f_str.cross_order_id is not null then 'N'
               when f_str.multileg_reporting_type <> '1' or coalesce(f_str.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_str.nbbo_bid_price, 0.0) = 0.0 then null
               else
                   case
                       when ((f_str.side = '1' and ex_agg_str.net_avg_px >= 0) or
                             (f_str.side <> '1' and ex_agg_str.net_avg_px < 0))
                           then (case when ex_agg_str.net_avg_px > f_str.nbbo_ask_price then 'Y' else 'N' end)
                       when ((f_str.side <> '1' and ex_agg_str.net_avg_px >= 0) or
                             (f_str.side = '1' and ex_agg_str.net_avg_px < 0))
                           then (case when ex_agg_str.net_avg_px < f_str.nbbo_bid_price then 'Y' else 'N' end)
                       end
               end::varchar                                                                    as "Flag"
    from data_marts.f_yield_capture f_str
             left join data_marts.f_yield_capture f_par on (f_par.order_id = f_str.parent_order_id and
                                                            f_par.status_date_id between l_start_date_id and l_end_date_id and
                                                            f_par.status_date_id = f_str.status_date_id and
                                                            f_par.parent_order_id is null)
             join dwh.execution ex
                  on (ex.order_id = f_str.order_id and ex.exec_date_id between l_start_date_id and l_end_date_id and
                      ex.exec_date_id = f_str.status_date_id and ex.order_status in ('1', '2') and ex.is_busted = 'N')
             join dwh.d_account a on (a.account_id = f_par.account_id)
             join dwh.historic_security_definition_all hsd on (hsd.instrument_id = f_par.instrument_id)
             left join dwh.d_target_strategy dss on (f_par.sub_strategy_id = dss.target_strategy_id)
             join ex_agg_str
                  on (ex_agg_str.date_id = f_str.status_date_id and ex_agg_str.client_order_id = f_str.client_order_id)
             left join dwh.d_order_type ot on (ot.order_type_id = f_par.order_type_id)
             left join dwh.d_time_in_force tif on (tif.is_active and tif.tif_id = f_par.time_in_force_id)
             left join dwh.d_strategy_decision_reason_code sdrc
                       on (sdrc.is_active and sdrc.strategy_decision_reason_code = f_str.strategy_decision_reason_code)
             left join dwh.d_exchange exch on (f_str.exchange_unq_id = exch.exchange_unq_id)
             left join dwh.d_exchange real_exch
                       on (exch.real_exchange_id = real_exch.exchange_id and real_exch.is_active)
             left join fix_capture.fix_message_json fm on (fm.date_id between l_start_date_id and l_end_date_id and
                                                           fm.date_id = f_par.status_date_id and
                                                           fm.fix_message_id = f_par.order_fix_message_id)
             left join fix_capture.fix_message_json fme
                       on (fme.date_id between l_start_date_id and l_end_date_id and fme.date_id = ex.exec_date_id and
                           fme.fix_message_id = ex.fix_message_id)
             left join dwh.d_bloomberg_strategy_name bsn on (a.trading_firm_id = bsn.trading_firm_id and
                                                             dss.target_strategy_name = bsn.original_sub_strategy and
                                                             coalesce((fm.fix_message ->> '9150')::int, -1) =
                                                             coalesce(bsn.aggression_level, -1))
             left join dwh.d_order_status os on (os.order_status = ex.order_status)
    where f_str.status_date_id between l_start_date_id and l_end_date_id
      and f_str.parent_order_id is not null
      and f_str.multileg_reporting_type in ('1', '2')
      and f_str.day_cum_qty > 0
      and a.trading_firm_id = 'jonestrad'
      and a.account_name not in
          ('jonestrading', 'jonestrading1', 'jonestrading2', 'jonestrading3', 'jonestrading4', 'JONE')
      and (f_par.client_id not in ('jonestrading', 'rons@JONE.US', 'JLE') or f_par.client_id is null);
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_log || 'street part table created===', l_row_cnt, 'O')
    into l_step_id;

    insert into ret_table
    select f_par.client_order_id                                                               as "Parent Cl Ord ID",
           a.account_name                                                                      as "Account",
           os.order_status_description                                                         as "Ord Status",
           f_par.routed_time::date                                                             as "Event Date",
           f_par.routed_time::timestamp                                                        as "Routed Time",
           --f_par.exec_time::timestamp as "Executed Time",
           ex.exec_time::timestamp                                                             as "Executed Time",
           to_timestamp(fme.fix_message ->> '10160'::varchar, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC' at time zone
           'EST'                                                                               as "Street Transact Time",
           --null::timestamp as "Street Transact Time",
           null::varchar                                                                       as "Street Cl Ord ID",
           (case
                when hsd.instrument_type_id = 'O' then 'Option'
                when hsd.instrument_type_id = 'E' then 'Equity' end)::varchar                  as "Sec Type",
           (case
                when f_par.side = '1' then 'Buy'
                when f_par.side = '2' then 'Sell'
                when f_par.side in ('5', '6') then 'Sell Short'
                else null end)::varchar                                                        as "Side",
           hsd.display_instrument_id                                                           as "Symbol",
           hsd.symbol                                                                          as "Root",
           hsd.maturity_date::date                                                             as "Exp Date",
           tif.tif_name                                                                        as "TIF",
           ot.order_type_name                                                                  as "Ord Type",
           f_par.client_id                                                                     as "Jones ID",
           ex.exec_text                                                                        as "Free Text",
           sdrc.strategy_user_data                                                             as "Strategy User Data",
           coalesce(bsn.bloomberg_strategy_name, dss.target_strategy_name,
                    'DMA')                                                                     as "Strategy Name",
           (fm.fix_message ->> '143')::varchar                                                 as "Floor Broker ID",
           real_exch.exchange_name                                                             as "Ex Dest - Cust",
           (case
                when f_par.multileg_reporting_type = '1' then 'Single-Leg'
                else 'Complex' end)::varchar                                                   as "Single/Complex",
           (case when a.account_name like '%_BP' then 'Manual' else 'Electronic' end)::varchar as "Electronic",
           f_par.order_qty                                                                     as "Ord Qty",
           ex.last_qty                                                                         as "Ex Qty",
           ex.last_px                                                                          as "Ex Px",
           ex_agg_par.net_avg_px                                                               AS "Net Avg Px",
           f_par.order_price                                                                   as "Ord Px",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_par.multileg_reporting_type <> '1') then null
               else f_par.nbbo_bid_quantity end                                                as "Bid Qty",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_par.multileg_reporting_type <> '1') then null
               else f_par.nbbo_bid_price end                                                   as "Bid Px",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_par.multileg_reporting_type <> '1') then null
               else f_par.nbbo_ask_price end                                                   as "Ask Px",
           case
               when (coalesce(fm.fix_message ->> '143', '') <> '' or f_par.multileg_reporting_type <> '1') then null
               else f_par.nbbo_ask_quantity end                                                as "Ask Qty",
           case
               when coalesce(fm.fix_message ->> '143', '') <> '' then null
               when f_par.multileg_reporting_type <> '1' or coalesce(f_par.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_par.nbbo_bid_price, 0.0) = 0.0 then null
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_par.net_avg_px < f_par.nbbo_ask_price
                   then f_par.nbbo_ask_price - ex_agg_par.net_avg_px
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_par.net_avg_px > f_par.nbbo_bid_price
                   then ex_agg_par.net_avg_px - f_par.nbbo_bid_price
               else 0.0
               end                                                                             as "Improvement",
           case
               when coalesce(fm.fix_message ->> '143', '') <> '' then null
               when f_par.multileg_reporting_type <> '1' or coalesce(f_par.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_par.nbbo_bid_price, 0.0) = 0.0 then null
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_par.net_avg_px < f_par.nbbo_ask_price
                   then round((f_par.nbbo_ask_price - ex_agg_par.net_avg_px) / abs(f_par.nbbo_ask_price), 4)
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_par.net_avg_px > f_par.nbbo_bid_price
                   then round((ex_agg_par.net_avg_px - f_par.nbbo_bid_price) / abs(f_par.nbbo_bid_price), 4)
               else 0.0
               end                                                                             as "% Improvement",
           case
               --when coalesce(fm.fix_message->>'143', '') <> '' then null
               --when coalesce(f_par.nbbo_ask_price, 0.0) = 0.0 or coalesce(f_par.nbbo_bid_price, 0.0) = 0.0 or coalesce(f_par.order_price, 0.0) = 0.0 then null
               when f_par.multileg_reporting_type <> '1' and ex_agg_par.net_avg_px < f_par.order_price
                   then f_par.order_price - ex_agg_par.net_avg_px
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_par.net_avg_px < f_par.order_price
                   then f_par.order_price - ex_agg_par.net_avg_px
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_par.net_avg_px > f_par.order_price
                   then ex_agg_par.net_avg_px - f_par.order_price
               else 0.0
               end                                                                             as "Ord Px Improvement",
           case
               --when coalesce(fm.fix_message->>'143', '') <> '' then null
               --when coalesce(f_par.nbbo_ask_price, 0.0) = 0.0 or coalesce(f_par.nbbo_bid_price, 0.0) = 0.0 or  coalesce(f_par.order_price, 0.0) = 0.0 then null
               when f_par.multileg_reporting_type <> '1' and ex_agg_par.net_avg_px < f_par.order_price
                   then round((f_par.order_price - ex_agg_par.net_avg_px) / abs(f_par.order_price), 4)
               when (f_par.multileg_reporting_type = '1' and f_par.side = '1') and
                    ex_agg_par.net_avg_px < f_par.order_price
                   then round((f_par.order_price - ex_agg_par.net_avg_px) / abs(f_par.order_price), 4)
               when (f_par.multileg_reporting_type = '1' and f_par.side <> '1') and
                    ex_agg_par.net_avg_px > f_par.order_price
                   then round((ex_agg_par.net_avg_px - f_par.order_price) / abs(f_par.order_price), 4)
               else 0.0
               end                                                                             as "Ord Px % Improvement",
           case
               when coalesce(fm.fix_message ->> '143', '') <> '' then null
               when f_par.cross_order_id is not null then 'N'
               when f_par.multileg_reporting_type <> '1' or coalesce(f_par.nbbo_ask_price, 0.0) = 0.0 or
                    coalesce(f_par.nbbo_bid_price, 0.0) = 0.0 then null
               else
                   case
                       when ((f_par.side = '1' and ex_agg_par.net_avg_px >= 0) or
                             (f_par.side <> '1' and ex_agg_par.net_avg_px < 0))
                           then (case when ex_agg_par.net_avg_px > f_par.nbbo_ask_price then 'Y' else 'N' end)
                       when ((f_par.side <> '1' and ex_agg_par.net_avg_px >= 0) or
                             (f_par.side = '1' and ex_agg_par.net_avg_px < 0))
                           then (case when ex_agg_par.net_avg_px < f_par.nbbo_bid_price then 'Y' else 'N' end)
                       end
               end::varchar                                                                    as "Flag"
    from data_marts.f_yield_capture f_par
             join dwh.client_order po
                  on (po.order_id = f_par.order_id and po.create_date_id between l_start_date_id and l_end_date_id and
                      po.create_date_id = f_par.status_date_id)
             join dwh.execution ex
                  on (ex.order_id = f_par.order_id and ex.exec_date_id between l_start_date_id and l_end_date_id and
                      ex.exec_date_id = f_par.status_date_id and ex.order_status in ('1', '2') and ex.is_busted = 'N')
             join dwh.d_account a on (a.account_id = f_par.account_id)
             join dwh.historic_security_definition_all hsd on (hsd.instrument_id = f_par.instrument_id)
             join ex_agg_par
                  on (ex_agg_par.date_id = f_par.status_date_id and ex_agg_par.client_order_id = f_par.client_order_id)
             left join dwh.d_target_strategy dss on (f_par.sub_strategy_id = dss.target_strategy_id)
             left join dwh.d_fix_connection fc on (fc.fix_connection_id = po.fix_connection_id)
             left join dwh.d_order_type ot on (ot.order_type_id = f_par.order_type_id)
             left join dwh.d_time_in_force tif on (tif.is_active and tif.tif_id = f_par.time_in_force_id)
             left join dwh.d_strategy_decision_reason_code sdrc
                       on (sdrc.is_active and sdrc.strategy_decision_reason_code = f_par.strategy_decision_reason_code)
             left join dwh.d_exchange exch on (f_par.exchange_unq_id = exch.exchange_unq_id)
             left join dwh.d_exchange real_exch
                       on (exch.real_exchange_id = real_exch.exchange_id and real_exch.is_active)
             left join fix_capture.fix_message_json fm on (fm.date_id between l_start_date_id and l_end_date_id and
                                                           fm.date_id = f_par.status_date_id and
                                                           fm.fix_message_id = f_par.order_fix_message_id)
             left join fix_capture.fix_message_json fme
                       on (fm.date_id between l_start_date_id and l_end_date_id and fme.date_id = ex.exec_date_id and
                           fme.fix_message_id = ex.fix_message_id)
             left join dwh.d_bloomberg_strategy_name bsn on (a.trading_firm_id = bsn.trading_firm_id and
                                                             dss.target_strategy_name = bsn.original_sub_strategy and
                                                             coalesce((fm.fix_message ->> '9150')::int, -1) =
                                                             coalesce(bsn.aggression_level, -1))
             left join dwh.d_order_status os on (os.order_status = ex.order_status)
    where f_par.status_date_id between l_start_date_id and l_end_date_id
      and f_par.parent_order_id is null
      and (f_par.sub_strategy_id = 99 or fc.fix_comp_id = 'FDSABRP') --DMA
      --and (f_par.sub_strategy_id = 99 or fc.fix_comp_id in ('FDSABRP', 'FLEXOP1')) --DMA
      and f_par.multileg_reporting_type in ('1', '2')
      and a.trading_firm_id = 'jonestrad'
      and a.account_name not in
          ('jonestrading', 'jonestrading1', 'jonestrading2', 'jonestrading3', 'jonestrading4', 'JONE')
      and (f_par.client_id not in ('jonestrading', 'rons@JONE.US', 'JLE') or f_par.client_id is null)
      and f_par.day_cum_qty > 0;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_log || 'parent part table created===', l_row_cnt, 'O')
    into l_step_id;

    return query
        select *
        from ret_table
        order by "Routed Time", "Parent Cl Ord ID", "Street Cl Ord ID", "Symbol", "Side", "Executed Time";
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg_log || 'COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;


select * from fintech_reports.eod_jonestrad_best_ex_ht3(20250318, 20250318);

SELECT entity_id,
       created_by,
       creation_time,
       is_deleted,
       deleted_by,
       deleted_time,
       index_nyse,
       index_nasdaq,
       index_cboe,
       index_ftse,
       cob_amxo,
       cob_xcbo,
       cob_edgo,
       cob_xisx,
       cob_xmio,
       cob_arco,
       cob_c2ox,
       cob_xpho,
       bi_amxo,
       bi_xcbo,
       bi_arco,
       bi_xbox,
       bi_xpho,
       equity_nyse,
       equity_nasdaq,
       option_opra
FROM blaze7_configuration.entity_market_data_entitlement;

drop FUNCTION fintech_reports.eod_jonestrad_best_ex_ht3;
alter FUNCTION trash.eod_jonestrad_best_ex_ht3 set schema fintech_reports