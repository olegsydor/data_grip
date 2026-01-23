-- DROP FUNCTION external_data.surveillance_ats_daily_summaries_report(date, bool, _varchar);

CREATE OR REPLACE FUNCTION external_data.surveillance_ats_daily_summaries_report(in_date date DEFAULT NULL::date,
                                                                                 in_calc boolean DEFAULT true,
                                                                                 in_client_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "ClientOrderID"      character varying,
                "OFPCrossOrderID"    text,
                "LPOCrossOrderID"    text,
                "LPOCrossOrdersCnt"  bigint,
                "RespondedCnt"       bigint,
                "RespondedQty"       bigint,
                "TradeDate"          date,
                "Price"              numeric,
                "AvgPx"              numeric,
                "CreateDateTime"     timestamp without time zone,
                "FirstFillDateTime"  timestamp without time zone,
                "OrderQty"           integer,
                "FilledQty"          integer,
                "CrossQty"           bigint,
                "CrossQtyFilled"     bigint,
                "LPOQty"             bigint,
                "LPOQtyFilled"       bigint,
                "ActionLPO"          text,
                "LiquidityProviders" text,
                "OFPAccount"         character varying,
                "OFPTradingFirm"     character varying,
                "LPOAccount"         text,
                "LPOTradingFirm"     text,
                "SymboType"          character varying,
                "CrossExchange"      text,
                "Symbol"             character varying,
                "NBBOBidPx"          numeric,
                "NBBOAskPx"          numeric,
                "NBBOBidSz"          bigint,
                "NBBOAskSz"          bigint,
                "Side"               character varying,
                "OrderType"          character varying,
                "LegCount"           bigint
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    select_stmt     text;
    sql_params      text;
    l_row_cnt       integer;
    l_start_date_id integer;
    l_end_date_id   integer;
    l_load_id       integer;
    l_step_id       integer;

    -- ak 20210312 added new input parameter in_client_ids and filter at 217-221 lines
    -- MB: 20220929 removed join to data_marts.d_client and changed client_src_id with client_id_text field from dwh.client_order
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_ats_daily_summaries_report STARTED===', 0,
                           'O')
    into l_step_id;

    /* period definition */
    if (in_date is null) -- for CSV to set NULL:date as default value in parameter
    then
        select                                                          -- to calculate the last working day
            to_char(public.get_last_workdate(), 'YYYYMMDD')::integer    --as l_start_date_id
             , to_char(public.get_last_workdate(), 'YYYYMMDD')::integer --as l_end_date_id
        into l_start_date_id, l_end_date_id;
    else
        select to_char(in_date, 'YYYYMMDD')::integer into l_start_date_id;
        select to_char(in_date, 'YYYYMMDD')::integer into l_end_date_id;
    end if;

    RAISE info 'l_start_date_id = % , l_end_date_id = % ', l_start_date_id, l_end_date_id;

    select public.load_log(l_load_id, l_step_id,
                           'l_start_date_id = ' || l_start_date_id::varchar || ' , l_end_date_id = ' ||
                           l_end_date_id::varchar, 0, 'O')
    into l_step_id;


    -- Let's split data into separate temp tables:
    -- parent OFP and LPO temp table.
    execute 'DROP TABLE IF EXISTS tmp_surveillance_ats_daily_summaries_ofp_lpo_par;';
    create temp table tmp_surveillance_ats_daily_summaries_ofp_lpo_par with (parallel_workers = 4)
                                                                       ON COMMIT drop as
        -- explain
    select src.*
    from (select cl.client_order_id
               , r.resp_cnt
               , r.resp_qty
               , o.order_create_time
               , o.order_price
               , o.order_qty
               , r.resp_liquidity_providers
               , o.nbbo_bid_price
               , o.nbbo_ask_price
               , o.nbbo_bid_quantity
               , o.nbbo_ask_quantity
               , o.side
               , cl.order_type_name
               -- additional
               , o.order_id
               , o.ofp_orig_order_id
               , o.create_date_id
               , o.auction_date_id
               , o.instrument_id
               , o.account_id
          from data_marts.f_ats_cons_details o
                   left join lateral
              (
              select cl.client_order_id, ot.order_type_name, cl.client_id_text
              from dwh.client_order cl
                       left join dwh.d_order_type ot
                                 ON cl.order_type_id = ot.order_type_id
              where cl.order_id = o.order_id
                -- without dates, GTC
                and cl.create_date_id = o.create_date_id
              limit 1
              ) cl ON true
                   left join lateral
              (
              select rg.ofp_orig_order_id
                   , rg.instrument_id
                   , sum(rg.resp_cnt)                                    as resp_cnt
                   , min(rg.first_responce_time)                         as first_responce_time
                   , sum(rg.provider_resp_qty)                           as resp_qty
                   , string_agg(distinct rg.liquidity_provider_id, ', ') as resp_liquidity_providers
              from (select r.liquidity_provider_id
                         , r.ofp_orig_order_id
                         , r.instrument_id
                         , count(1)                 as resp_cnt
                         , min(r.order_create_time) as first_responce_time
                         , max(r.order_qty)         as provider_resp_qty
                    from data_marts.f_ats_cons_details r
                    where r.ofp_orig_order_id = o.ofp_orig_order_id
                      and r.auction_date_id = o.auction_date_id
                      and r.auction_date_id between l_start_date_id and l_end_date_id
                      and r.instrument_id = o.instrument_id
                      and r.is_lpo_parent = true
                      and r.is_ats_or_cons = 'A'
                    group by r.liquidity_provider_id, r.ofp_orig_order_id, r.instrument_id) rg
              group by rg.ofp_orig_order_id, rg.instrument_id
              limit 1
              ) r on true
          where o.is_ofp_parent = true
            and o.is_ats_or_cons = 'A'
            and o.ofp_parent_auctions_no = 1
            and o.auction_date_id between l_start_date_id and l_end_date_id
            and case in_client_ids
                    when '{}'::varchar[]
                        then true
                    else cl.client_id_text = any (in_client_ids)
              end) src;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    raise NOTICE 'l_row_cnt = % ', l_row_cnt;

    execute 'analyze tmp_surveillance_ats_daily_summaries_ofp_lpo_par';

    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_lpo_par;';
    --create table trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_lpo_par as select * from tmp_surveillance_ats_daily_summaries_ofp_lpo_par;

    select public.load_log(l_load_id, l_step_id, 'Loaded tmp_surveillance_ats_daily_summaries_ofp_lpo_par', l_row_cnt,
                           'I')
    into l_step_id;


    -- trades, lc and dict temp table.
    execute 'DROP TABLE IF EXISTS tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict;';
    create temp table tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict with (parallel_workers = 4)
                                                                          ON COMMIT drop as
        -- explain
    select src.*
    from (select o.*
               , tr_par.filled_qty
               , tr_par.filled_price
               , tr_par.principal_amount
               , tr_par.first_fill_date_time
               , lc.leg_count
               , ac.account_name
               , tf.trading_firm_name
               , it.instrument_type_name
               , i.display_instrument_id
          from tmp_surveillance_ats_daily_summaries_ofp_lpo_par o
                   --trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_lpo_par o
                   left join lateral
              (
              select tr.order_id
                   , sum(tr.last_qty)                                           as filled_qty
                   , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as filled_price
                   , sum(tr.principal_amount)                                   as principal_amount
                   , min(tr.trade_record_time)                                  as first_fill_date_time
              from dwh.flat_trade_record tr
              where 1 = 1
                and tr.order_id = o.order_id -- parent level
                and tr.is_busted = 'N'
                and tr.date_id >= o.create_date_id
              group by tr.order_id
              limit 1
              ) tr_par ON true
              -- legs count
                   left join lateral
              ( select count(lc.order_id) as leg_count --"LegCount"
                from data_marts.f_ats_cons_details lc
                where lc.ofp_orig_order_id = o.ofp_orig_order_id
                  and lc.auction_date_id = o.auction_date_id
                  --and lc.instrument_id = o.instrument_id should not be joined with instrument
                  and lc.is_ofp_parent = true -- each leg is the separate parent level order.
                  --and multileg_reporting_type <> '1' -- should be equal to 1 in non-multileg
                  and lc.is_ats_or_cons = 'A'
                  and lc.ofp_parent_auctions_no = 1
                  and lc.auction_date_id between l_start_date_id and l_end_date_id
              ) lc on true
                   left join dwh.d_account ac
                             ON o.account_id = ac.account_id
                   left join dwh.d_trading_firm tf
                             ON ac.trading_firm_unq_id = tf.trading_firm_unq_id
                   left join dwh.d_instrument i
                             ON o.instrument_id = i.instrument_id
                   left join dwh.d_instrument_type it
                             ON i.instrument_type_id = it.instrument_type_id) src;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    raise NOTICE 'l_row_cnt = % ', l_row_cnt;

    execute 'analyze tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict';

    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict;';
    --create table trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict as select * from tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict;

    select public.load_log(l_load_id, l_step_id, 'Loaded tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict',
                           l_row_cnt, 'I')
    into l_step_id;


    -- street cross table.
    execute 'DROP TABLE IF EXISTS tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str;';
    create temp table tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str with (parallel_workers = 4)
                                                                              ON COMMIT drop as
        -- explain
    select src.*
    from (select o.*
               , s.*
          from tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict o
                   --trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict o
                   left join lateral
              ( select left(string_agg(case when s.is_ofp_street = true then cl.client_order_id end, ', '),
                            32000)                                                                                 as "OFPCrossOrderID"
                     , left(string_agg(case when s.is_lpo_street = true then cl.client_order_id end, ', '),
                            32000)                                                                                 as "LPOCrossOrderID"
                     , nullif(sum(case when s.is_lpo_street = true then 1 else 0 end), 0)                          as "LPOCrossOrdersCnt"
                     , nullif(sum(case when s.is_ofp_street = true then s.order_qty else 0 end),
                              0)                                                                                   as "CrossQty"
                     , nullif(sum(case when s.is_ofp_street = true then tr_str.filled_qty else 0 end),
                              0)                                                                                   as "CrossQtyFilled"
                     , nullif(sum(case when s.is_lpo_street = true then s.order_qty else 0 end),
                              0)                                                                                   as "LPOQty"
                     , nullif(sum(case when s.is_lpo_street = true then tr_str.filled_qty else 0 end),
                              0)                                                                                   as "LPOQtyFilled"
                     , left(string_agg(case when s.is_ofp_street = true then cl.exchange_id end, ', '),
                            32000)                                                                                 as "CrossExchange"
                     , left(
                          string_agg(distinct case when s.is_lpo_street = true then s.liquidity_provider_id end, ', '),
                          32000)                                                                                   as "ActionLPO"
                     , left(string_agg(distinct case when s.is_lpo_street = true then ac.account_name end, ', '),
                            32000)                                                                                 as "LPOAccount"
                     , left(string_agg(distinct case when s.is_lpo_street = true then tf.trading_firm_name end, ', '),
                            32000)                                                                                 as "LPOTradingFirm"
                from data_marts.f_ats_cons_details s
                         left join dwh.client_order cl
                                   ON cl.order_id = s.order_id and cl.create_date_id = s.auction_date_id
                         left join dwh.d_account ac
                                   ON ac.account_id = s.account_id
                                       and s.is_lpo_street = true
                         left join dwh.d_trading_firm tf
                                   ON ac.trading_firm_unq_id = tf.trading_firm_unq_id
                         left join lateral
                    (
                    select sum(tr.last_qty)                                                      as filled_qty
                         , round(sum(tr.last_px * tr.last_qty) / nullif(sum(tr.last_qty), 0), 4) as filled_price
                         , sum(tr.principal_amount)                                              as principal_amount
                         , min(tr.trade_record_time)                                             as first_fill_date_time
                    from dwh.flat_trade_record tr
                    where 1 = 1
                      -- street level
                      and tr.order_id = s.parent_order_id
                      and tr.secondary_order_id = s.client_order_id
                      --and tr.street_order_id = s.order_id
                      and tr.is_busted = 'N'
                      and tr.date_id = s.auction_date_id
                      and tr.date_id between l_start_date_id and l_end_date_id
                    ) tr_str ON true
                where s.auction_date_id = o.auction_date_id -- do we need explicit date here?
                  and s.auction_date_id between l_start_date_id and l_end_date_id
                  and s.ofp_orig_order_id = o.ofp_orig_order_id
                  and s.is_ats_or_cons = 'A'
                  and (
                    s.is_ofp_street = true
                        or
                    s.is_lpo_street = true
                    )
                  and s.instrument_id = o.instrument_id -- for correct matching streets for complex orders
              ) s on true) src;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    raise NOTICE 'l_row_cnt = % ', l_row_cnt;

    execute 'analyze tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str';

    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str;';
    --create table trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str as select * from tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str;

    select public.load_log(l_load_id, l_step_id, 'Loaded tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str',
                           l_row_cnt, 'I')
    into l_step_id;


    --2) return calculated report
    RETURN QUERY
        select t.client_order_id                                                 as "ClientOrderID"
             , t."OFPCrossOrderID"                                               as "OFPCrossOrderID"
             , t."LPOCrossOrderID"                                               as "LPOCrossOrderID"
             , t."LPOCrossOrdersCnt"                                             as "LPOCrossOrdersCnt"
             , t.resp_cnt::bigint                                                as "RespondedCnt"
             , t.resp_qty::bigint                                                as "RespondedQty"
             , to_date(to_char(t.order_create_time, 'DD.MM.YYYY'), 'DD.MM.YYYY') as "TradeDate"
             , t.order_price                                                     as "Price"
             , t.filled_price                                                    as "AvgPx"              -- FilledPrice
             , t.order_create_time                                               as "CreateDateTime"
             , t.first_fill_date_time                                            as "FirstFillDateTime"  -- time of the first trade on the parent order
             , t.order_qty                                                       as "OrderQty"
             , t.filled_qty::integer                                             as "FilledQty"
             , t."CrossQty"                                                      as "CrossQty"
             , t."CrossQtyFilled"::bigint                                        as "CrossQtyFilled"
             , t."LPOQty"::bigint                                                as "LPOQty"
             , t."LPOQtyFilled"::bigint                                          as "LPOQtyFilled"
             , t."ActionLPO"                                                     as "ActionLPO"          -- возьмем те, по которым были LP кроссы
             , t.resp_liquidity_providers                                        as "LiquidityProviders" -- вот тут интересно: похоже здесь берется из реквестед. мы пока возьмем из респондед
             , t.account_name                                                    as "OFPAccount"
             , t.trading_firm_name                                               as "OFPTradingFirm"
             , t."LPOAccount"                                                    as "LPOAccount"
             , t."LPOTradingFirm"                                                as "LPOTradingFirm"
             , t.instrument_type_name                                            as "SymboType"
             , t."CrossExchange"                                                 as "CrossExchange"
             , t.display_instrument_id                                           as "Symbol"
             , t.nbbo_bid_price                                                  as "NBBOBidPx"
             , t.nbbo_ask_price                                                  as "NBBOAskPx"
             , t.nbbo_bid_quantity::bigint                                       as "NBBOBidSz"
             , t.nbbo_ask_quantity::bigint                                       as "NBBOAskSz"
             , (case t.side
                    when '1' then 'Buy'
                    when '2' then 'Sell'
                    when '3' then 'Buy minus'
                    when '4' then 'Sell plus'
                    when '5' then 'Sell short'
                    when '6' then 'Sell short exempt'
                    when '7' then 'Undisclosed'
                    when '8' then 'Cross'
                    when '9' then 'Cross short'
            end)::varchar                                                        as "Side"
             , t.order_type_name                                                 as "OrderType"
             , t.leg_count                                                       as "LegCount"
        from tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str t
        --trash.sdn_tmp_surveillance_ats_daily_summaries_ofp_tr_lc_dict_str t
        order by t.order_id, t.client_order_id;



    select public.load_log(l_load_id, l_step_id, 'external_data.surveillance_ats_daily_summaries_report FINISHED===', 0,
                           'O')
    into l_step_id;

END;
$function$
;
