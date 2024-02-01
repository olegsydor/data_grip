-- DROP FUNCTION eod_reports.export_rbc_orders_tbl(int4, int4, _varchar);

Executing procedure:("eod_reports.export_rbc_orders_tbl"). Parameters: "@in_start_date_id=20240131; @in_end_date_id=20240131; "
"42703: column po.ex_destination_code_id does not exist"

select * from trash.export_rbc_orders_tbl(in_start_date_id := 20240131,
                                                             in_end_date_id := 20240131,
                                                             in_client_ids := '{42703}')

CREATE or replace FUNCTION eod_reports.export_rbc_orders_tbl(in_start_date_id integer DEFAULT NULL::integer,
                                                             in_end_date_id integer DEFAULT NULL::integer,
                                                             in_client_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "Account"           character varying,
                "Is Cross"          character varying,
                "Is MLeg"           character varying,
                "Ord Status"        character varying,
                "Event Type"        character varying,
                "Routed Time"       character varying,
                "Event Time"        character varying,
                "Cl Ord ID"         character varying,
                "Side"              character varying,
                "Symbol"            character varying,
                "Ord Qty"           bigint,
                "Price"             numeric,
                "Ex Qty"            bigint,
                "Avg Px"            numeric,
                "Sub Strategy"      character varying,
                "Ex Dest"           character varying,
                "Ord Type"          character varying,
                "TIF"               character varying,
                "Sending Firm"      character varying,
                "Capacity"          character varying,
                "Client ID"         character varying,
                "CMTA"              character varying,
                "Creation Date"     character varying,
                "Cross Ord Type"    character varying,
                "Event Date"        character varying,
                "Exec Broker"       character varying,
                "Expiration Day"    date,
                "Leg ID"            character varying,
                "Lvs Qty"           bigint,
                "O/C"               character varying,
                "Orig Cl Ord ID"    character varying,
                "OSI Symbol"        character varying,
                "Root Symbol"       character varying,
                "Security Type"     character varying,
                "Stop Px"           numeric,
                "Underlying Symbol" character varying
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE

   l_row_cnt integer;
   l_load_id integer;
   l_step_id integer;

  l_start_date_id integer;
  l_end_date_id   integer;

  l_gtc_start_date_id integer;

 -- ak 20210303 added new input parament in_client_ids and added filter to 129-133 lines
 -- MB: 20220929 removed join to data_marts.d_client and changed client_src_id with client_id_text field from dwh.client_order
BEGIN

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id := 1;

  raise notice 'l_load_id=%',l_load_id;

  select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl STARTED===', 0, 'O')
   into l_step_id;

  if in_start_date_id is not null and in_end_date_id is not null
  then
    l_start_date_id := in_start_date_id;
    l_end_date_id := in_end_date_id;
  else
    --l_start_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    --l_end_date_id := (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer;
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;

  end if;

  --l_start_date_id := coalesce(in_date_id, (to_char(NOW() - interval '1 day', 'YYYYMMDD'))::integer);

  l_gtc_start_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD')::date - interval '6 month'), 'YYYYMMDD');

    select public.load_log(l_load_id, l_step_id, 'Step 1. l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar||', l_gtc_start_date_id = '||l_gtc_start_date_id::varchar, 0 , 'O')
     into l_step_id;

  return QUERY
/*  with par_ords as
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      ) */
    select --po.order_id
        ac.account_name as "Account"
      , (case when po.cross_order_id is not null then 'Y' else 'N' end)::varchar as "Is Cross"
      , (case when po.multileg_reporting_type = '1' then 'N' else 'Y' end)::varchar as "Is MLeg"
      , st.order_status_description as "Ord Status"
      , et.exec_type_description as "Event Type"
      , to_char(fyc.routed_time, 'HH24:MI:SS.US')::varchar as "Routed Time"
      --, to_char(po.process_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , to_char(fyc.exec_time, 'HH24:MI:SS.MS')::varchar as "Event Time"
      , po.client_order_id as "Cl Ord ID"
      , (case po.side
                  when '1' then 'Buy'
                  when '2' then 'Sell'
                  when '3' then 'Buy minus'
                  when '4' then 'Sell plus'
                  when '5' then 'Sell short'
                  when '6' then 'Sell short exempt'
                  when '7' then 'Undisclosed'
                  when '8' then 'Cross'
                  when '9' then 'Cross short'
                end)::varchar as "Side"
      , i.display_instrument_id as "Symbol"
      , po.order_qty::bigint as "Ord Qty"
      , po.price as "Price"
      , fyc.filled_qty as "Ex Qty"
      , fyc.avg_px as "Avg Px"
      , ss.target_strategy_desc as "Sub Strategy"
      , dc.ex_destination_code_name as "Ex Dest"
      , ot.order_type_name as "Ord Type"
      , tif.tif_name as "TIF"
      , f.fix_comp_id as "Sending Firm"
      , cf.customer_or_firm_name as "Capacity"
      , oo.client_id_text as "Client ID"
      , coalesce(po.clearing_firm_id, fx_co.clearing_firm_id) as "CMTA"
      , to_char(to_date(po.create_date_id::varchar, 'YYYYMMDD'), 'DD.MM.YYYY')::varchar as "Creation Date"
      , cro.cross_type::varchar as "Cross Ord Type"
      , to_char(fyc.exec_time, 'DD.MM.YYYY')::varchar as "Event Date"
      , ebr.opt_exec_broker as "Exec Broker"
      , date_trunc('day', i.last_trade_date)::date as "Expiration Day"
      , l.client_leg_ref_id as "Leg ID"
      , ex.leaves_qty::bigint as "Lvs Qty"
      , (case when po.open_close = 'O' then 'Open' else 'Close' end)::varchar as "O/C"
      , oo.client_order_id as "Orig Cl Ord ID"
      , po.opra_symbol as "OSI Symbol"
      , po.root_symbol as "Root Symbol"
      , it.instrument_type_name as "Security Type"
      , po.stop_price as "Stop Px"
      , ui.display_instrument_id as "Underlying Symbol"
      --, po.*
--select count(1)
    from
      (
        select order_id  -- , null::integer as date_id --, date_id -- non-GTC or today's GTC. null in date_id is because we need to have distincted order_ids
        from dwh.client_order co
        where
          -- parent level only
          co.parent_order_id is null
          -- only single ords and legs
          and co.multileg_reporting_type in ('1','2')
          -- scope filter
          and co.create_date_id between l_start_date_id and l_end_date_id
          and co.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
          and case in_client_ids
  					when '{}'::varchar[]
  						then true
  			else co.client_id_text = any(in_client_ids)
  	  	end
       -- union -- not all to distinct result set
       -- select tr.order_id -- , null::integer as date_id -- trades have no time_in_force information
       -- from dwh.flat_trade_record tr
       -- where tr.date_id between 20181001 and 20181231 --l_start_date_id and l_end_date_id
       --   and tr.account_id in (select ac.account_id from dwh.d_account ac where ac.trading_firm_id in ('ebsrbc'))
      )  scp
      left join lateral
      (
        select po.order_id
          , po.orig_order_id
          , po.account_id
          , po.multileg_reporting_type
          , po.multileg_order_id
          , po.cross_order_id
          , po.create_date_id
          , po.client_order_id
          , po.instrument_id
          , po.order_qty
          , po.price
          , po.side
          , po.sub_strategy_id
--           , po.ex_destination_code_id
          , po.ex_destination
          , po.order_type_id
          , po.time_in_force_id
          , po.customer_or_firm_id
          , po.order_capacity_id
          , po.client_id
          , po.process_time
          , po.opt_exec_broker_id
          , po.no_legs
          , po.open_close
          , po.fix_connection_id
          , po.clearing_firm_id
          , po.fix_message_id
          , po.stop_price
          , po.trans_type
          , oc.option_series_id
          , oc.opra_symbol
          , os.underlying_instrument_id
          , os.root_symbol
          --, po.*
        from dwh.client_order po
        left join dwh.d_option_contract oc
          ON po.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          --ON oc.option_series_id = os.option_series_id
          ON oc.option_series_id = os.option_series_id
        where 1=1
          and po.create_date_id between l_gtc_start_date_id and l_end_date_id -- last half of year. GTC purpose
          and po.order_id = scp.order_id
        limit 1 -- for NL acceleration
      ) po ON true
      left join dwh.client_order oo
        ON po.orig_order_id = oo.order_id
        and oo.create_date_id between l_gtc_start_date_id and l_end_date_id
      left join dwh.d_account ac
        ON po.account_id = ac.account_id
      left join lateral
        (
           select sum(fyc.day_cum_qty) as filled_qty
             , round(sum(fyc.day_avg_px*fyc.day_cum_qty)/nullif(sum(fyc.day_cum_qty), 0)::numeric, 4)::numeric as avg_px
             , min(fyc.routed_time) as routed_time
             , max(fyc.exec_time) as exec_time -- can it be event_time or transact time? min or max?
             , fyc.order_id
             , min(fyc.nbbo_bid_price) as nbbo_bid_price
             , min(fyc.nbbo_bid_quantity) as nbbo_bid_quantity
             , min(fyc.nbbo_ask_price) as nbbo_ask_price
             , min(fyc.nbbo_ask_quantity) as nbbo_ask_quantity
           from data_marts.f_yield_capture fyc -- here we have all orders, so we can use it for cum_qty calculation (instead of FTR)
           where fyc.order_id = po.order_id
             and fyc.status_date_id between l_gtc_start_date_id and l_end_date_id
           group by fyc.order_id
           limit 1 -- just in case to insure NL join method
        ) fyc on true
      -- the last execution
      left join lateral
        (
          select ex.text_
            , ex.order_status
            , ex.exec_type
            , ex.exec_id
            , ex.leaves_qty
          from dwh.execution ex
          where 1=1
            --and ex.exec_date_id = 20190604
            and ex.exec_date_id between l_start_date_id and l_end_date_id
            and ex.order_id = po.order_id
          order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
          limit 1
        ) ex on true
      -- fix_message of order
      left join lateral
        (
          select (j.fix_message->>'439')::varchar as clearing_firm_id
          from fix_capture.fix_message_json j
          where 1=1
            and po.clearing_firm_id is null --
            and j.date_id between l_start_date_id and l_end_date_id -- l_gtc_start_date_id was very slow condition
            and j.fix_message_id = po.fix_message_id
            and j.date_id = po.create_date_id
          limit 1
        ) fx_co on true
      left join dwh.d_order_status st
        ON ex.order_status = st.order_status
      left join dwh.d_exec_type et
        ON ex.exec_type = et.exec_type
      left join dwh.d_instrument i
        ON po.instrument_id = i.instrument_id
      left join dwh.d_instrument_type it
        ON i.instrument_type_id = it.instrument_type_id
      left join dwh.d_instrument ui
        --ON os.underlying_instrument_id = ui.instrument_id
        ON po.underlying_instrument_id = ui.instrument_id
      left join dwh.d_target_strategy ss
        ON po.sub_strategy_id = ss.target_strategy_id
      left join dwh.d_ex_destination_code dc
        ON po.ex_destination = dc.ex_destination_code
      left join dwh.d_order_type ot
        ON po.order_type_id = ot.order_type_id
      left join dwh.d_time_in_force tif
        ON po.time_in_force_id = tif.tif_id
    /*  left join --lateral
        (
          select ---min(ecf.customer_or_firm_id) as customer_or_firm_id
            ecf.customer_or_firm_id
            , ecf.exch_customer_or_firm_id, ecf.exchange_id  -- lookup key
            , row_number() over (partition by ecf.exch_customer_or_firm_id, ecf.exchange_id order by ecf.customer_or_firm_id) as rn
          from dwh.d_exchange2customer_or_firm ecf
        ) ecf
        ON ecf.rn = 1 --true
          and o.customer_or_firm is null
          and ecf.exch_customer_or_firm_id = o.order_capacity
          and ecf.exchange_id = o.exchange_id */
      left join dwh.d_customer_or_firm cf ON cf.customer_or_firm_id = COALESCE(po.customer_or_firm_id, ac.opt_customer_or_firm) and cf.is_active = true -- ecf.customer_or_firm_id,
      left join dwh.cross_order cro
        ON po.cross_order_id = cro.cross_order_id
      left join dwh.d_opt_exec_broker ebr
        ON po.opt_exec_broker_id = ebr.opt_exec_broker_id
      left join dwh.d_fix_connection f
        ON po.fix_connection_id = f.fix_connection_id
      /*left join dwh.client_order_leg l
        ON l.order_id = po.order_id
        and l.multileg_order_id = po.multileg_order_id*/
      left join lateral
        (
          select l.order_id, l.client_leg_ref_id
          from dwh.client_order_leg l
          where l.multileg_order_id = po.multileg_order_id
          limit 3000
        ) l ON l.order_id = po.order_id
    where po.trans_type <> 'F' -- not cancell request
    order by po.process_time, 1;


    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

 select public.load_log(l_load_id, l_step_id, 'export_rbc_orders_tbl COMPLETE ========= ' , l_row_cnt, 'O')
   into l_step_id;
   RETURN;
END;
$function$
;
