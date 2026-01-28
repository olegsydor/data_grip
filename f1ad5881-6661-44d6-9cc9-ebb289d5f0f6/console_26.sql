-- DROP FUNCTION dwh.load_flat_trade_record_inc(bool, _int8, int4);

CREATE OR REPLACE FUNCTION dwh.load_flat_trade_record_inc_0000000(in_manual_run boolean DEFAULT false, in_tarde_record_ids bigint[] DEFAULT NULL::bigint[], in_load_batch_id integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL_FAST: FLat_trade_Record incremental'
AS $function$
-- SY: DS-3269 few fileds have been introduced (allocation_avg_price, occ_actionable_id,account_nickname)
--  SY:  DS-3444  Remove    occ_actionable_id  field
--  AK:  DS-3687  Added  new  condition    subscribe_time  <  now()  in  the  l1_snapshot  subscription  logic  processing
--  AK:  DS-3687  Added  new  condition  "and  coalesce(nullif(st.instrument_id,-1),  trade_record.instrument_id)    =  trade_record.instrument_id"  during  insert  to  FTL  in  join  to  l1_snapshoti
--  AK:  DS-3782  added  input  parameter  to    public.etl_subscribe  function    -->  in_date_ids=>tr_date_id_cursor.date_id::varchar
--  AK:  DS-3427  Added  new  field  penny_nickel  to  FTR
-- OS: DS-2624 Migration ftr into native partitioning (2021-08-23)
--  AK:  DS-4135    20210910  join  to  l1_snapshot  has  been  fixed  as  in  DS-3782  ticket(looks  like  it  was  overwrited)
/* Changes log
   1. on conflict added
   2. unused variables have been removed
   3. the very slow statement with row_number and market_data.trade order by trade_time was replaced by lateral
   4. and as a result, the select has been simplified.
   5. dynamic SQL was replaced by the usual one.
   6. materialized in cte has been removed
   7. prepare-execute statement has been moved inside the loop
 */
--  SY:  DS-4118  join  to  d_exchange  using  last_market  field  was  refactored  to  use  lateral  and  limit  1  due  to  fail  of  on  conflict
--  PD:  DS-4158  added  input  parameter  in_load_batch_id,  so  we  can  create  street  level  fix  subscriptions  for  mira
--  SY:  DS-4069 migration to bigint https://dashfinancial.atlassian.net/browse/DS-4069
--  OS:  DS-4218  added market_data_trade_time populated from market_data.trade trade_time
--  SY:  20211116. MIra subscription for PTM purposes has been added https://dashfinancial.atlassian.net/browse/DS-2734
--  SY:  20211202. TCCE processing has been limited by not more then 10 subscriptions during one run
--  AK:  20211202. Conditions for NBBO has been modified to coalesce(nullif(nullif(st.instrument_id,-1),1), tr.instrument_id) = tr.instrument_id  and in another statement to nullif(nullif(st.instrument_id,-1), 1 )
--  SY:  20220128. https://dashfinancial.atlassian.net/browse/DS-4763
--                 Line 694 If statement has been added to do not process market_data fix during manual sync for todays traffic

-- AK: 20220211 added coalesce function to on conflict in insert into flat_trade_record
-- AK: 20220419 added public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
-- SY: 20220816 Manual bust processing. Cursor based on subscriptions has been improved to use two field in IN statement (date_id, load_batch_id) in (select ...)
-- AK: 20220912 Added to processing street level subscriptions new subscription 'trade_record_away_lvl_info' to process changes related to blaze_account_alias
-- SY: 20230330 https://dashfinancial.atlassian.net/browse/DS-6522. Following cindition has been added to prevent closing subscription before time. and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id )
-- SY: 20230405 https://dashfinancial.atlassian.net/browse/DS-6509. PFOF section has been commented
-- SY: 20230405 https://dashfinancial.atlassian.net/browse/DS-4917 Subscription for GOAT DTR has been commented like this one public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
-- SY: 20231113 https://dashfinancial.atlassian.net/browse/DS-7355 We need to create bust subscritpions for FYC and both billing engines whyle simple manual bust (caused by Oracle or Manual bust of DB side)
-- SO: 20260120 https://dashfinancial.atlassian.net/browse/DS-10976 change logic for ats_or_cons\int_liq_source_type
-- SO: 20260128 https://dashfinancial.atlassian.net/browse/DS-10962 added away trades

declare
    l_max_trade_record_id       int8;
    l_max_instrument_id         int;
    l_foreign_max_instrument_id int;
    date_cursor                 record;
    subs_cursor                 record;
    lp_cursor                   record;
    row_cnt                     integer;
    l_row_cnt                   integer;
    l_tarde_record_ids          bigint[];
    l_load_id                   int;
    l_step_id                   int;
--    l_max_trade_time            timestamp;
    l_sql                       varchar;
    l_trade_id_to_reprint       bigint[];
    l_subs_list_jsn             jsonb;
    tr_date_id_cursor           record;
    l_last_tr_success_time		timestamp;
    l_trade_id_away int8[];

begin
    select nextval('public.load_timing_seq') into l_load_id;

    l_step_id:=1;
    if in_manual_run then
       /* ============================  POST TRADE MODIFICATION  =================================================  */
        select public.load_log(l_load_id, l_step_id, 'FLAT_TRADE_RECORD STARTED (manual run) ===', cardinality(in_tarde_record_ids), 'O')
        into l_step_id;

         if in_tarde_record_ids is null then
                        select  coalesce(max(trade_record_id),  0)
                        into  l_max_trade_record_id
            from dwh.flat_trade_record
            where coalesce(trade_fix_message_id, 1) > 0  /*we look for dash traffic only */
                 and trade_record_reason in ('P', 'B', 'L', 'U');

                        l_tarde_record_ids  =  array(select  trade_record_id
                                                     from  staging.trade_record
                                                     where  trade_record_id  >  l_max_trade_record_id
                                                       and  trade_record_reason  in  ('P',  'B',  'L',  'U')
                                                       and  db_create_time  <=  now()::timestamp);
        else
            l_tarde_record_ids := in_tarde_record_ids;
        end if;

        select public.load_log(l_load_id, l_step_id, 'l_tarde_record_ids size is ='||cardinality(l_tarde_record_ids), 0, 'O')
        into l_step_id;

    else
    /* ============================  GENERAL CASE =================================================  */
        select public.load_log(l_load_id, l_step_id, 'FLAT_TRADE_RECORD STARTED ===', 0, 'O')
        into l_step_id;

                if  in_tarde_record_ids  is  null
                then
                        select  coalesce(max(trade_record_id),  0)
                        into  l_max_trade_record_id
            from dwh.flat_trade_record
            where /*order_id is not null / *We look for Dash traffic only */
            /* coalesce(subsystem_id,' ') not in ('LPDROP', 'LPEDW')
                                and*/  coalesce(trade_record_reason,  'X')  not  in  ('P',  'B',  'L',  'U', 'A');

             select log_date  /*- interval '60 minute' */
            into l_last_tr_success_time
			from staging.last_fact_success
			where table_name ='TRADE_RECORD';

  --         l_last_tr_success_time:= now() - interval '1 minute';

		l_tarde_record_ids = array(select trade_record_id
                                       from staging.trade_record
                                       where trade_record_id > l_max_trade_record_id
                                         and coalesce(trade_record_reason, 'X') not in ('P', 'B', 'L', 'U', 'A')
                                         and db_create_time <= l_last_tr_success_time
                                       LIMIT 50000
                                       );
--                                         and db_create_time <= now()::timestamp - interval '10 seconds'
 --               /*and coalesce(subsystem_id,' ') not in ('LPDROP', 'LPEDW')*/);
        else
            l_tarde_record_ids := in_tarde_record_ids;
        end if;

        select public.load_log(l_load_id, l_step_id, 'l_last_tr_success_time ='||l_last_tr_success_time::text, 0, 'O')
        into l_step_id;


        select public.load_log(l_load_id, l_step_id, 'l_tarde_record_ids size is ='||cardinality(l_tarde_record_ids), 0, 'O')
        into l_step_id;

--       insert into trash.trade_record_ids
--       select unnest(l_tarde_record_ids);

	end if;

--        if  not  in_manual_run  -- dwh.load_trade_instruments is being called directly from airflow prior to calling this function
--        then
--        select coalesce(max(instrument_id),0) into l_max_instrument_id from dwh.d_instrument;
--                select  coalesce(max(instrument_id),  0)
--                into  l_foreign_max_instrument_id
--                from  staging.instrument
--                where  instrument_id  >  l_max_instrument_id;
--
--        select public.load_log(l_load_id, l_step_id, format('l_max_instrument_id is %s, l_foreign_max_instrument_id, %s', l_max_instrument_id, l_foreign_max_instrument_id), 0, 'O')
--        into l_step_id;
--
--
--        if l_foreign_max_instrument_id> l_max_instrument_id then
--        	if public.check_environment() in ('DEV', 'UAT', 'PROD', 'dmp_prod') then
--        	    perform public.dblink_connect('ftr_instr_sync','dbname=big_data user=dwh');
--        	else
--        	    perform public.dblink_connect('ftr_instr_sync','dbname=big_data port=6432 user=dwh');
--        	end if;
--            perform public.dblink_exec('ftr_instr_sync','call dwh.load_trade_instruments('||l_max_instrument_id +1||','||l_foreign_max_instrument_id||','||l_load_id||','||l_step_id||')');
--            perform public.dblink_exec('ftr_instr_sync','commit;');
--            perform public.dblink_disconnect('ftr_instr_sync');
--            l_step_id:=l_step_id + 2;
--        end if;
--    end if;


--    l_max_trade_time:=current_timestamp - interval '10 days'; /* to avoid commission being ahead of trade_record */

--    select public.load_log(l_load_id, l_step_id, 'Dimensions done', 0, 'I')
--            into l_step_id;


    if cardinality(l_tarde_record_ids) > 0 then

       for date_cursor in (select date_id from staging.trade_record where trade_record_id = any(l_tarde_record_ids) group by date_id )
           loop

--    select public.load_log(l_load_id, l_step_id, 'Processing date', date_cursor.date_id, 'I')
--            into l_step_id;

            insert into dwh.flat_trade_record (
        trade_record_id, trade_record_time, db_create_time, date_id, is_busted, trade_record_trans_type,
        trade_record_reason, subsystem_id, user_id, account_id, client_order_id, instrument_id, side, open_close,
        fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator, secondary_order_id, exch_exec_id,
        secondary_exch_exec_id, last_mkt, last_qty, last_px, ex_destination, sub_strategy, street_order_id,
        order_id, street_order_qty, order_qty, multileg_reporting_type, is_largest_leg, street_max_floor,
        exec_broker, cmta, street_time_in_force, street_order_type, opt_customer_firm, street_mpid, is_cross_order,
        street_is_cross_order, street_cross_type, cross_is_originator, street_cross_is_originator, contra_account,
        contra_broker, trade_exec_broker, order_fix_message_id, trade_fix_message_id, street_order_fix_message_id,
        order_price, street_order_price, order_process_time, ask_price, bid_price, trade_id, client_id,
        street_transaction_id, transaction_id, clearing_account_number, sub_account, remarks, optional_data,
        street_client_order_id, fix_comp_id, ask_qty, bid_qty, leaves_qty, is_billed, street_exec_inst,
        orig_trade_record_id, principal_amount, trading_firm_id, trading_firm_unq_id, fee_sensitivity,
        routing_time_bid_price, routing_time_bid_qty, routing_time_ask_price, routing_time_ask_qty,
        strategy_decision_reason_code, compliance_id, floor_broker_id, auction_id, street_opt_customer_firm,
        multileg_order_id, internal_component_type, instrument_type_id, street_trade_fix_message_id, pt_basket_id,
        pt_order_id, transact_time, trade_exchange_id, blaze_account_alias, customer_review_status, street_account_name,
        street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, int_liq_source_type,
        allocation_avg_price, account_nickname, clearing_account_id, market_participant_id,
        alternative_compliance_id, street_trade_record_time, penny_nickel, load_batch_id, market_data_trade_time, street_order_process_time,leg_ref_id,
        secondary_trade_record_time)

            select
        tr.trade_record_id, tr.trade_record_time, tr.db_create_time, tr.date_id, tr.is_busted, tr.trade_record_trans_type,
        tr.trade_record_reason, tr.subsystem_id, tr.user_id, tr.account_id, tr.client_order_id, tr.instrument_id, tr.side, tr.open_close,
        tr.fix_connection_id, tr.exec_id, tr.exchange_id, tr.trade_liquidity_indicator, tr.secondary_order_id, tr.exch_exec_id,
        tr.secondary_exch_exec_id, tr.last_mkt, tr.last_qty, tr.last_px, tr.ex_destination, tr.sub_strategy, tr.street_order_id,
        tr.order_id, tr.street_order_qty, tr.order_qty, tr.multileg_reporting_type, tr.is_largest_leg, tr.street_max_floor,
        tr.exec_broker, tr.cmta, tr.street_time_in_force, tr.street_order_type, tr.opt_customer_firm, tr.street_mpid, tr.is_cross_order,
        tr.street_is_cross_order, tr.street_cross_type, tr.cross_is_originator, tr.street_cross_is_originator, tr.contra_account,
        tr.contra_broker, tr.trade_exec_broker, tr.order_fix_message_id, tr.trade_fix_message_id, tr.street_order_fix_message_id,
        tr.order_price, tr.street_order_price, tr.order_process_time, trade.ask_price, trade.bid_price, trade.trade_id, tr.client_id,
        tr.street_transaction_id, tr.transaction_id, tr.clearing_account_number, tr.sub_account, tr.remarks, tr.optional_data,
        tr.street_client_order_id, tr.fix_comp_id, trade.ask_qty, trade.bid_qty, tr.leaves_qty, tr.is_billed, tr.street_exec_inst,
        tr.orig_trade_record_id,
        case
            when case i.instrument_type_id
                     when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                     else tr.last_qty * tr.last_px end > 9999999999999999.9999::numeric(20, 4)
                then null
            else case i.instrument_type_id
                     when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                     else tr.last_qty * tr.last_px end
            end principal_amount,
		    ac.trading_firm_id, ac.trading_firm_unq_id, tr.fee_sensitivity,
			md.l1_bid_price, md.l1_bid_qty, md.l1_ask_price, md.l1_ask_qty,
			tr.strategy_decision_reason_code, tr.compliance_id, tr.floor_broker_id, tr.auction_id, tr.street_opt_customer_firm,
            tr.multileg_order_id, tr.internal_component_type, i.instrument_type_id, tr.street_trade_fix_message_id, tr.pt_basket_id,
            pt_order_id, to_timestamp(j.fix_message->>'60', 'yyyymmdd-hh24:mi:ss.us')::timestamp at time zone 'UTC' as transact_time,
            lm.exchange_id as trade_exchange_id, tr.blaze_account_alias, tr.customer_review_status, tr.street_account_name,
			tr.street_exec_broker, tr.trade_text, tr.branch_sequence_number, tr.frequent_trader_id,

        CASE
            WHEN str2au.auction_id IS NULL THEN NULL::text
            WHEN exists (SELECT null
                         FROM request_for_quote r
                         WHERE r.auction_id = str2au.auction_id
                           AND r.auction_date_id = str2au.create_date_id) THEN 'A'::text
            ELSE 'C'::text
            END AS int_liq_source_type,

			tr.allocation_avg_price, tr.account_nickname, tr.clearing_account_id, tr.market_participant_id,
			tr.alternative_compliance_id, tr.street_trade_record_time,
            case os.min_tick_increment when 0.05 then 'N' when 0.01 then 'P' end as penny_nickel,
                        in_load_batch_id  as  load_batch_id,
                        trade.trade_time as market_data_trade_time,
            tr.street_order_process_time , tr.leg_ref_id,
			coalesce(to_timestamp(j.fix_message->>'10160', 'yyyymmdd-hh24:mi:ss.us')::timestamp at time zone 'UTC',
                     to_timestamp(public.get_message_tag_string(tr.street_trade_fix_message_id, 60, tr.date_id), 'yyyymmdd-hh24:mi:ss.us')::timestamp at time zone 'UTC') as  secondary_trade_record_time
            from staging.trade_record tr
                     LEFT JOIN lateral (select auction_id, create_date_id from client_order2auction str2au
                               where str2au.order_id = tr.street_order_id AND
                                  str2au.create_date_id = to_char(tr.street_order_process_time, 'YYYYMMDD')::int limit 1) str2au on true
                   left join dwh.d_instrument i on (tr.instrument_id = i.instrument_id)
                                      left  join  lateral  (select  exchange_id  from  dwh.d_exchange  lmm  where  tr.last_mkt  =  lmm.last_mkt  and  lmm.is_active  and  lmm.exchange_id  =  lmm.real_exchange_id  limit  1)  lm  on  true
                   left join lateral (select t.ask_price, t.bid_price, t.trade_id, t.ask_quantity as ask_qty, t.bid_quantity as bid_qty, t.trade_time
                                      from market_data.trade t
                                      where t.date_id = date_cursor.date_id
                                        and t.activ_symbol = i.activ_symbol
                                        and t.price = tr.last_px
                                        and t.quantity = tr.last_qty
                                        and t.trade_time between
                                              tr.trade_record_time::timestamp without time zone - interval '00:00:00.9'
                                          and tr.trade_record_time::timestamp without time zone + interval '00:00:00.9'
                                      order by abs(extract(epoch from (tr.trade_record_time - t.trade_time)))
                                      limit 1) trade on true
                   left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                   left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   left join dwh.d_account ac on (ac.account_id = tr.account_id)
                   left join lateral (select sum(bid_price)    as l1_bid_price,
                                             sum(ask_price)    as l1_ask_price,
                                             sum(bid_quantity) as l1_bid_qty,
                                             sum(ask_quantity) as l1_ask_qty
                                      from dwh.l1_snapshot st
                                      where exchange_id = 'NBBO'
                                        and num_nonnulls(bid_price, ask_price, bid_quantity, ask_quantity) > 0
                                        and st.transaction_id = tr.street_transaction_id
                                        --and coalesce(st.instrument_id, tr.instrument_id) = tr.instrument_id
                                        and coalesce(nullif(nullif(st.instrument_id,-1),1), tr.instrument_id) = tr.instrument_id
                                        and st.start_date_id = date_cursor.date_id) md on true
                   left join fix_capture.fix_message_json j
                             on (trade_fix_message_id = j.fix_message_id and j.date_id = date_cursor.date_id)
          where tr.trade_record_id = any(l_tarde_record_ids)
            and tr.date_id = date_cursor.date_id
        on conflict (trade_record_id, date_id) do update
                set trade_record_time             = excluded.trade_record_time,
                    is_busted                     = excluded.is_busted,
                    trade_record_trans_type       = excluded.trade_record_trans_type,
                    trade_record_reason           = excluded.trade_record_reason,
                    subsystem_id                  = excluded.subsystem_id,
                    user_id                       = excluded.user_id,
                    account_id                    = excluded.account_id,
                    client_order_id               = excluded.client_order_id,
                    instrument_id                 = excluded.instrument_id,
                    side                          = excluded.side,
                    open_close                    = excluded.open_close,
                    fix_connection_id             = excluded.fix_connection_id,
                    exec_id                       = excluded.exec_id,
                    exchange_id                   = excluded.exchange_id,
                    trade_liquidity_indicator     = excluded.trade_liquidity_indicator,
                    secondary_order_id            = excluded.secondary_order_id,
                    exch_exec_id                  = excluded.exch_exec_id,
                    secondary_exch_exec_id        = excluded.secondary_exch_exec_id,
                    last_mkt                      = excluded.last_mkt,
                    last_qty                      = excluded.last_qty,
                    last_px                       = excluded.last_px,
                    ex_destination                = excluded.ex_destination,
                    sub_strategy                  = excluded.sub_strategy,
                    street_order_id               = excluded.street_order_id,
                    order_id                      = excluded.order_id,
                    street_order_qty              = excluded.street_order_qty,
                    order_qty                     = excluded.order_qty,
                    multileg_reporting_type       = excluded.multileg_reporting_type,
                    is_largest_leg                = excluded.is_largest_leg,
                    street_max_floor              = excluded.street_max_floor,
                    exec_broker                   = excluded.exec_broker,
                    cmta                          = excluded.cmta,
                    street_time_in_force          = excluded.street_time_in_force,
                    street_order_type             = excluded.street_order_type,
                    opt_customer_firm             = excluded.opt_customer_firm,
                    street_mpid                   = excluded.street_mpid,
                    is_cross_order                = excluded.is_cross_order,
                    street_is_cross_order         = excluded.street_is_cross_order,
                    street_cross_type             = excluded.street_cross_type,
                    cross_is_originator           = excluded.cross_is_originator,
                    street_cross_is_originator    = excluded.street_cross_is_originator,
                    contra_account                = excluded.contra_account,
                    contra_broker                 = excluded.contra_broker,
                    trade_exec_broker             = excluded.trade_exec_broker,
                    order_fix_message_id          = excluded.order_fix_message_id,
                    trade_fix_message_id          = excluded.trade_fix_message_id,
                    street_order_fix_message_id   = excluded.street_order_fix_message_id,
                    order_price                   = excluded.order_price,
                    order_process_time            = excluded.order_process_time,
                    --ask_price                     = excluded.ask_price,
                    ask_price                     = coalesce(excluded.ask_price,flat_trade_record.ask_price),
                    --bid_price                     = excluded.bid_price,
                    bid_price                     = coalesce(excluded.bid_price,flat_trade_record.bid_price),
                    --trade_id                      = excluded.trade_id,
                    trade_id                      = coalesce(excluded.trade_id,flat_trade_record.trade_id),
                    client_id                     = excluded.client_id,
                    street_transaction_id         = excluded.street_transaction_id,
                    transaction_id                = excluded.transaction_id,
                    clearing_account_number       = excluded.clearing_account_number,
                    sub_account                   = excluded.sub_account,
                    remarks                       = excluded.remarks,
                    optional_data                 = excluded.optional_data,
                    street_client_order_id        = excluded.street_client_order_id,
                    fix_comp_id                   = excluded.fix_comp_id,
                    --ask_qty                       = excluded.ask_qty,
                    ask_qty                       = coalesce(excluded.ask_qty,flat_trade_record.ask_qty),
                    --bid_qty                       = excluded.bid_qty,
                    bid_qty                       = coalesce(excluded.bid_qty,flat_trade_record.bid_qty),
                    leaves_qty                    = excluded.leaves_qty,
                    is_billed                     = excluded.is_billed,
                    street_exec_inst              = excluded.street_exec_inst,
                    orig_trade_record_id          = excluded.orig_trade_record_id,
                    principal_amount              = excluded.principal_amount,
                    trading_firm_id               = excluded.trading_firm_id,
                    strategy_decision_reason_code = excluded.strategy_decision_reason_code,
                    compliance_id                 = excluded.compliance_id,
                   -- routing_time_bid_price        = excluded.routing_time_bid_price,
                    routing_time_bid_price        = coalesce(excluded.routing_time_bid_price,flat_trade_record.routing_time_bid_price),
                    --routing_time_bid_qty          = excluded.routing_time_bid_qty,
                    routing_time_bid_qty          = coalesce(excluded.routing_time_bid_qty,flat_trade_record.routing_time_bid_qty),
                    --routing_time_ask_price        = excluded.routing_time_ask_price,
                    routing_time_ask_price        = coalesce(excluded.routing_time_ask_price,flat_trade_record.routing_time_ask_price),
                    --routing_time_ask_qty          = excluded.routing_time_ask_qty,
                    routing_time_ask_qty          = coalesce(excluded.routing_time_ask_qty,flat_trade_record.routing_time_ask_qty),
                    floor_broker_id               = excluded.floor_broker_id,
                    auction_id                    = excluded.auction_id,
                    street_opt_customer_firm      = excluded.street_opt_customer_firm,
                    multileg_order_id             = excluded.multileg_order_id,
                    internal_component_type       = excluded.internal_component_type,
                    street_exec_broker            = excluded.street_exec_broker,
                    trading_firm_unq_id           = excluded.trading_firm_unq_id,
                    instrument_type_id            = excluded.instrument_type_id,
                    street_trade_fix_message_id   = excluded.street_trade_fix_message_id,
                    pt_basket_id                  = excluded.pt_basket_id,
                    pt_order_id                   = excluded.pt_order_id,
                    transact_time                 = excluded.transact_time,
                    trade_exchange_id             = excluded.trade_exchange_id,
                    blaze_account_alias           = excluded.blaze_account_alias,
                    customer_review_status        = excluded.customer_review_status,
                    street_account_name           = excluded.street_account_name,
                    trade_text                    = excluded.trade_text,
                    branch_sequence_number        = excluded.branch_sequence_number,
                    frequent_trader_id            = excluded.frequent_trader_id,
                    int_liq_source_type           = excluded.int_liq_source_type,
                    --load_batch_id  				  = excluded.load_batch_id,
                    load_batch_id  				  = coalesce(excluded.load_batch_id,flat_trade_record.load_batch_id),
					market_data_trade_time        = excluded.market_data_trade_time,
                    allocation_avg_price          = excluded.allocation_avg_price,
                    account_nickname              = excluded.account_nickname,
                    clearing_account_id           = excluded.clearing_account_id,
                    market_participant_id         = excluded.market_participant_id,
                    alternative_compliance_id     = excluded.alternative_compliance_id,
                    street_trade_record_time      = excluded.street_trade_record_time,
                    penny_nickel                  = excluded.penny_nickel,
                    street_order_process_time	  = excluded.street_order_process_time,
                    street_order_price			  = excluded.street_order_price,
                   	leg_ref_id					  = excluded.leg_ref_id,
                    secondary_trade_record_time	  = excluded.secondary_trade_record_time ;

            select public.load_log(l_load_id, l_step_id, 'insert into dwh.flat_trade_record date_id='||date_cursor.date_id::text, 0, 'I')
            into l_step_id;
        end loop;
    end if;

if not in_manual_run then
/*    ================================================================================================*/
/*    =====================================        TCCE    ====================================================*/
/*    ================================================================================================*/
                select  array_to_json(array(select  row  (load_batch_id,  date_id)
                                                                      FROM  staging.etl_subscriptions
                                                                      where  subscription_name  in
                                                                                  ('goat.big_data.flat_trade_commissions',  'big_data.flat_trade_record',
                                                                                    'bdark.big_data.flat_trade_record')
                                                                          and  source_table_name  =  'trade_level_book_record'
                                                                          and  not  is_processed
                                                                          and  subscribe_time  <  now()  -  interval  '60    seconds'
                                                                          and  subscribe_time  >  now()  -  interval  '4    day'
                                                                          order by load_batch_id desc
                                                                          limit 15))
                into  l_subs_list_jsn;

                IF  l_subs_list_jsn  is  not  null  and  jsonb_array_length(l_subs_list_jsn)  >  0
                then
                        for  date_cursor  in  (Select  (tr_id  ->  'f1')::int  as  load_batch_id,  coalesce((tr_id  ->>  'f2')::int,  dwh.get_dateid(current_date))  as  date_id
                                from  jsonb_array_elements(l_subs_list_jsn)  tr_id)
                                Loop
                                        select  public.load_log(l_load_id,  l_step_id,  'TCCE    date_id,    load_batch_id    cursor    opened    :    '||date_cursor.load_batch_id||'    -    '||date_cursor.date_id,  0,  'I')
                                        into  l_step_id;

                                        perform  public.dblink_connect('ftr_comm_upd',  'dbname=big_data    user=dwh');
                                        perform  public.dblink_exec('ftr_comm_upd',  'call    dwh.load_trade_commissions('||date_cursor.load_batch_id||','||date_cursor.date_id||','||l_load_id||','||l_step_id||')');
                                        perform  public.dblink_exec('ftr_comm_upd',  'commit;');
                                        perform  public.dblink_disconnect('ftr_comm_upd');
                                        l_step_id  :=  l_step_id  +  10;
                                end  loop;
                        /*date_cursor*/

/* ================================================================================================*/
/* =====================================  LP Traffic ==============================================*/
/* ================================================================================================*/

            select public.load_log(l_load_id, l_step_id, 'Start LP traffic ', 0, 'I')
            into l_step_id;
   for lp_cursor in (select subs.load_batch_id, array_agg(trade_record_id) as trade_record_ids
                      from staging.trade_record st_tr
                       inner  join  public.etl_subscriptions  subs on  (subs.load_batch_id  =  st_tr.load_batch_id)
                       where  subscription_name  in  ('goat.big_data.flat_trade_record',  'big_data.flat_trade_record')
                        and source_table_name in ('liquid_point_trade_record', 'liquid_point_trade_record.u')
                        and not is_processed
                        and st_tr.subsystem_id in ('LPDROP', 'LPEDW')
                        and st_tr.trade_record_id < l_max_trade_record_id
                          and  1=2  /*  Deprectaed since middle of 2020 */
                      group by subs.load_batch_id
                      order by load_batch_id desc
                      limit 1)
        loop

            select public.load_log(l_load_id, l_step_id, 'LP Traffic for  load_batch_id='||lp_cursor.load_batch_id, 0, 'I')
            into l_step_id;

            select dwh.load_flat_trade_record_inc(true, lp_cursor.trade_record_ids) into l_row_cnt;

            update public.etl_subscriptions
            set is_processed = true,
                process_time = clock_timestamp()
                                        where  load_batch_id  =  lp_cursor.load_batch_id
                                            and  subscription_name  in  ('goat.big_data.flat_trade_record',  'big_data.flat_trade_record')
                                            and  source_table_name  in  ('liquid_point_trade_record',  'liquid_point_trade_record.u')
                                            and  not  is_processed;

        end loop;

        select public.load_log(l_load_id, l_step_id, 'After LP Traffic', 0, 'I')
        into l_step_id;

        end if;
--
--/* ================================================================================================*/
--/* ====================================  PFOF =====================================================*/
--/* ================================================================================================*/
--            select public.load_log(l_load_id, l_step_id, 'START PFOF Traffic', 0, 'I')
--            into l_step_id;
--               for  subs_cursor  in  (select  distinct  date_id,  load_batch_id
--                        from staging.etl_subscriptions
--                        where subscription_name = 'big_data.flat_trade_record'
--                          and source_table_name = 'trade_level_book_record_pfof'
--                          and not is_processed)
--    loop
--        update dwh.flat_trade_record
--        set (pfof_exchange_marketing_fee, pfof_maker_taker_fee, pfof_royalty_fee, pfof_complex_rebates,
--             pfof_break_up_rebates, pfof_crossing_rebates) =
--                (commission_data.pfof_exchange_marketing_fee, commission_data.pfof_maker_taker_fee,
--                 commission_data.pfof_royalty_fee, commission_data.pfof_complex_rebates,
--                 commission_data.pfof_break_up_rebates, commission_data.pfof_crossing_rebates)
--        from (select trade_record_id,
--                     sum(case when book_record_type_id = 'EMF' then amount end)  as pfof_exchange_marketing_fee,
--                     sum(case when book_record_type_id = 'MKTK' then amount end) as pfof_maker_taker_fee,
--                     sum(case when book_record_type_id = 'RYTF' then amount end) as pfof_royalty_fee,
--                     sum(case when book_record_type_id = 'CPRB' then amount end) as pfof_complex_rebates,
--                     sum(case when book_record_type_id = 'BURB' then amount end) as pfof_break_up_rebates,
--                     sum(case when book_record_type_id = 'CRRB' then amount end) as pfof_crossing_rebates
--              from staging.trade_level_book_record
--              where load_batch_id = subs_cursor.load_batch_id
--                                                and  date_id  =  subs_cursor.date_id
--              group by trade_record_id) commission_data
--                                where  flat_trade_record.trade_record_id  =  commission_data.trade_record_id
--                                    and  flat_trade_record.date_id  =  subs_cursor.date_id;
--
--        get diagnostics row_cnt = row_count;
--
--        select public.load_log(l_load_id, l_step_id, 'PFOF Commission Updated load_batch_id = '||subs_cursor.load_batch_id , row_cnt , 'U')
--        into l_step_id;
--
--        if row_cnt > 0
--        then
--            update staging.etl_subscriptions
--            set is_processed = true,
--                process_time = clock_timestamp()
--            where load_batch_id = subs_cursor.load_batch_id
--                                            and  date_id  =  subs_cursor.date_id
--              and subscription_name = 'big_data.flat_trade_record'
--              and source_table_name = 'trade_level_book_record_pfof';
--        end if;
--    end loop;

/* ==================================================================================================*/
/* =================================  Busted Trades =================================================*/
/* ==================================================================================================*/
 --    with upd as (update staging.etl_subscriptions s
--        set is_processed = true,
--            process_time = clock_timestamp()
--        where is_processed = false
--            and subscription_name = 'big_data.flat_trade_record'
--            and source_table_name = 'TRADE_RECORD.BUSTED_TRADES'
--            and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id ) /* We need to be sure trade to bust already there */
--                        RETURNING  load_batch_id,  date_id  /*it  contains  trade_record_id  for  that  specific  source  'TRADE_RECORD.BUSTED_TRADES'*/)
--    update dwh.flat_trade_record
--    set is_busted = 'Y'
--    where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)
--      and is_busted = 'N';
--     get diagnostics row_cnt = row_count;

 with upd as (update staging.etl_subscriptions s
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
            and subscription_name = 'big_data.flat_trade_record'
            and source_table_name = 'TRADE_RECORD.BUSTED_TRADES'
            and exists (select null from dwh.flat_trade_record ft where ft.trade_record_id=s.load_batch_id  and ft.date_id = s.date_id ) /* We need to be sure trade to bust already there */
                        RETURNING  load_batch_id,  date_id  ),
  ftr_upd as (update dwh.flat_trade_record
    set is_busted = 'Y'
    where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)
      and is_busted = 'N')--,
--   fyc_subs as (select count(1) as cn
--   				from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,  date_id::varchar, 1)
--			          from (select distinct order_id, date_id
--			                from flat_trade_record
--			                where (trade_record_id, date_id) in (select load_batch_id, date_id from upd)) l ) L2 )
  select count(1)
  from (select  	public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_mira'::varchar, 'flat_trade_record'::varchar, date_id::varchar,1) ,
	    	public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_ptm'::varchar, 'flat_trade_record'::varchar, date_id::varchar,1)
 	    from 	upd  ) L1--,
 	 --fyc_subs
  into 	row_cnt   ;



    select public.load_log(l_load_id, l_step_id, 'Busted trades updated ', row_cnt , 'U')
    into l_step_id;


/* ==================================================================================================*/
/* =================================  NBBO based on strategy_in_l1_snapshopt ========================*/
/* ==================================================================================================*/

                if  (select  count(*)  from  pg_prepared_statements  where  name  ilike  'update_nbbo')  >  0  then
                        deallocate  update_nbbo;
                end  if;

                prepare  update_nbbo(int,  int)  as  with  md  as  (
                        select
                                nullif(nullif(st.instrument_id,-1), 1 )  as  instrument_id,
                                transaction_id,
                                start_date_id,
			                                          	sum (bid_price) as bid_price,
			                                      		sum (ask_price) as ask_price,
			                                      		sum (bid_quantity) as bid_qty,
			                                      		sum (ask_quantity ) as ask_qty
		                                         from dwh.l1_snapshot st
                  where  exchange_id  =  'NBBO'
                      and  (bid_price  is  not  null  or  ask_price  is  not  null  or
                                bid_quantity  is  not  null  or  ask_quantity  is  not  null)
		                                         and st.dataset_id = $1
		                                         and st.start_date_id = $2
		                                         group by nullif(nullif(st.instrument_id,-1), 1 ),transaction_id, start_date_id),

                         upd as (      update dwh.flat_trade_record ft
                               set routing_time_bid_price 	= coalesce(md.bid_price, routing_time_bid_price)
                                 , routing_time_bid_qty 	= coalesce(md.bid_qty, routing_time_bid_qty)
                                 , routing_time_ask_price 	= coalesce(md.ask_price, routing_time_ask_price)
                                 , routing_time_ask_qty 	= coalesce(md.ask_qty, routing_time_ask_qty)
                                 , is_street_order_marketable = null

                               from md
                               where md.transaction_id = ft.street_transaction_id
                                and (ft.multileg_reporting_type = '1' or  coalesce(md.instrument_id, ft.instrument_id) = ft.instrument_id)
                                and ft.date_id = $2
                                and (ft.routing_time_ask_price is null or routing_time_bid_price is null)
                               returning trade_record_id )
                          select count(1) from upd ;

                for  subs_cursor  in  (select  load_batch_id,  date_id
                                                        from  public.etl_subscriptions
                        where is_processed = false
		 					and subscription_name = 'flat_trade_record'
                 			and source_table_name = 'strategy_in'
                                                            and  subscribe_time  <  now()
                 			group by load_batch_id, date_id
                 			order by load_batch_id desc
                                                        limit  15)  loop

    execute 'execute update_nbbo('||subs_cursor.load_batch_id||', '||subs_cursor.date_id||')' into row_cnt;
        select public.load_log(l_load_id, l_step_id,
                               'NBBO updated load_batch_id = ' || subs_cursor.load_batch_id || ', date_id=' ||
                               subs_cursor.date_id, row_cnt, 'U')
        into l_step_id;
        /*  if row_cnt>0
           then*/
        update public.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
          and subscription_name = 'flat_trade_record'
          and source_table_name = 'strategy_in'
          and load_batch_id = subs_cursor.load_batch_id
          and date_id = subs_cursor.date_id;
        /*	end if;*/
    end loop;



     if  (select  extract(minute  from  now()))  in  (0,  10,  20,  30,  40,  50)  and    now()::time  between  '09:45:00.0'::time  and  '19:05:00.0'::time
       then row_cnt := dwh.fix_ftr_market_data(to_char(now(), 'YYYYMMDD')::int, l_load_id);

        select public.load_log(l_load_id, l_step_id, 'Fix Market Matching ', row_cnt, 'U')
        into l_step_id;
      end if;

/* ================================================================================================*/
/* ==================================  Street level fix  =======================================*/
/* ================================================================================================*/
    l_trade_id_to_reprint := array(select distinct load_batch_id
                                    from    (select  load_batch_id
	                                           	from  staging.etl_subscriptions  es
                                   				where is_processed = false
                                     				and subscription_name = 'big_data.flat_trade_record'
		                                            and  source_table_name  in  ('trade_record_street_lvl_info','trade_record_away_lvl_info')
		                                            and  subscribe_time  <=  now()  -  interval  '1  minute'
                                                    /*for  update  skip  locked*/
		                                            order by subscribe_time desc
                                                    limit  5000)  L  );
                if  cardinality(l_trade_id_to_reprint)  >  0
                then
        select public.load_log(l_load_id, l_step_id, 'Street fix processing ', cardinality(l_trade_id_to_reprint), 'U')
        into l_step_id;

	    select dwh.load_flat_trade_record_inc(true, l_trade_id_to_reprint) into l_row_cnt;

                        select  public.load_log(l_load_id,  l_step_id,
                                                                      'Processed  '  ||  left(array_to_string(l_trade_id_to_reprint,  ',',  '*'),  235),
                                                                      cardinality(l_trade_id_to_reprint),  'U')
        into l_step_id;

	    select count(1)
        into l_row_cnt
        from (select public.etl_subscribe(trade_record_id::bigint, 'mira_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
        			--,public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
       	  	  from (select distinct trade_record_id, date_id
       	  	  		from flat_trade_record ftr
       	 			where ftr.trade_record_id = any(l_trade_id_to_reprint))l) l2;

--              		select  count(1)
--                	into  l_row_cnt
--                	from  (select  public.etl_subscribe(l_load_id::bigint,  'mira_street_lvl_fix'::varchar,  'flat_trade_record'::varchar,  date_id::varchar,  1)
--              		    	    from  (select  distinct  date_id  from  flat_trade_record  ftr
--              		  			where  ftr.trade_record_id  =  any(l_trade_id_to_reprint))l)  l2;


                        select  public.load_log(l_load_id,  l_step_id,  'Mira  subscriptions  created    ',  l_row_cnt,  'U')
                        into  l_step_id;

        update staging.etl_subscriptions
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
          and subscription_name = 'big_data.flat_trade_record'
          and source_table_name in ('trade_record_street_lvl_info','trade_record_away_lvl_info')
          and load_batch_id = any (l_trade_id_to_reprint);

	 	  get diagnostics row_cnt = row_count;

        select public.load_log(l_load_id, l_step_id, 'update staging.etl_subscriptions  ', row_cnt, 'U')
        into l_step_id;

--        select count(1)
--        into l_row_cnt
--        from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,
--                                          date_id::varchar, 1)
--              from (select distinct order_id, to_char(order_process_time, 'YYYYMMDD')::int as date_id
--                    from dwh.flat_trade_record
--                    where trade_record_id = any (l_trade_id_to_reprint)
--                                                    and  order_id  >  0
--                                                    and  order_fix_message_id  >  0
--                                                    and order_process_time::date>=current_date -3  )  L)  l2;
--
--        select public.load_log(l_load_id, l_step_id, 'subscribed  ', l_row_cnt , 'U')
--        into l_step_id;

--      select count(1)
--        into l_row_cnt
--        from (select public.etl_subscribe(order_id::bigint, 'yield_capture'::varchar, 'flat_trade_record'::varchar,  date_id::varchar, 1)
--                    from dwh.flat_trade_record
--                    where trade_record_id = any (l_trade_id_to_reprint)
--                     and  order_id  >  0
--                     and  order_fix_message_id  >  0) l;
--
--        select public.load_log(l_load_id, l_step_id, 'subscribed  ', l_row_cnt , 'U')
--        into l_step_id;

       end if; /* cardinality(l_trade_id_to_reprint)>0  */

/* ================================================================================================*/
/* ==================================  Street exec_broker   =======================================*/
/* ================================================================================================*/
--		                    with  subs  as  (select  s.load_batch_id,  s.date_id
--						      from  public.etl_subscriptions  s
--							where  source_table_name  ='insert_street_exec_broker'
--			        		              and  subscription_name='big_data.flat_trade_record'
--						              and  not  is_processed),
--			              upd  as  (update  flat_trade_record  ft
--			                              set  street_exec_broker  =  lt.street_exec_broker
--						      from  subs,  staging.trade_record_late_metrics  lt
--						      where  lt.load_batch_id=subs.load_batch_id
--						          and  lt.date_id=subs.date_id
--						          and  ft.date_id  =  subs.date_id
--						          and  ft.trade_record_id  =  lt.trade_record_id
--						          returning  ft.trade_record_id)
--				  update  public.etl_subscriptions  ss
--				  set  is_processed  =  true,
--				          process_time  =  clock_timestamp()
--				    from  subs
--				  where    ss.load_batch_id=subs.load_batch_id
--				        and  ss.date_id  =  subs.date_id
--				        and  source_table_name  ='insert_street_exec_broker'
--			        	and  subscription_name='big_data.flat_trade_record'
--					and  not  is_processed;
--
--
--			      GET  DIAGNOSTICS  row_cnt  =  ROW_COUNT;
--
--		        select  public.load_log(l_load_id,  l_step_id,  'update  street_exec_broker    ',  row_cnt  ,  'U')
--	                into  l_step_id;


-------------------------
/* =============================================================================================== */
/* ==================================  AWAY TRADES =============================================== */
/* =============================================================================================== */
    for lp_cursor in (select distinct date_id
                      from staging.etl_subscriptions es
                      where is_processed = false
                        and subscription_name = 'big_data.flat_trade_record'
                        and source_table_name = 'TRADE_RECORD.AWAY_TRADES'
                        and subscribe_time <= now() - interval '1  minute'
                      order by subscribe_time desc)
        loop
            l_trade_id_away := array(select load_batch_id
                                     from (select load_batch_id, date_id
                                           from staging.etl_subscriptions es
                                           where is_processed = false
                                             and date_id = lp_cursor.date_id
                                             and subscription_name = 'big_data.flat_trade_record'
                                             and source_table_name = 'TRADE_RECORD.AWAY_TRADES'
                                             and subscribe_time <= now() - interval '1  minute'
                                           order by subscribe_time desc
                                           limit 5000) L);
            if cardinality(l_trade_id_away) > 0
            then
                select public.load_log(l_load_id, l_step_id, 'AWAY TRADES FOR ' || lp_cursor.date_id::text,
                                       cardinality(l_trade_id_away), 'U')
                into l_step_id;

                select dwh.load_flat_trade_record_inc(true, l_trade_id_away) into l_row_cnt;

                select public.load_log(l_load_id, l_step_id,
                                       'Processed  ' ||
                                       left(array_to_string(l_trade_id_away, ',', '*'), 235),
                                       cardinality(l_trade_id_away), 'U')
                into l_step_id;

                select count(1)
                into l_row_cnt
                from (select public.etl_subscribe(trade_record_id::bigint, 'mira_street_lvl_fix'::varchar,
                                                  'flat_trade_record'::varchar, date_id::varchar, 1)
                      --,public.etl_subscribe(trade_record_id::bigint, 'goat_street_lvl_fix'::varchar, 'flat_trade_record'::varchar, date_id::varchar, 1)
                      from (select distinct trade_record_id, date_id
                            from flat_trade_record ftr
                            where ftr.trade_record_id = any (l_trade_id_away)) l) l2;

                select public.load_log(l_load_id, l_step_id, 'Mira  subscriptions  created    ', l_row_cnt,
                                       'U')
                into l_step_id;

                update staging.etl_subscriptions
                set is_processed = true,
                    process_time = clock_timestamp()
                where is_processed = false
                  and subscription_name = 'big_data.flat_trade_record'
                  and source_table_name = 'TRADE_RECORD.AWAY_TRADES'
                  and load_batch_id = any (l_trade_id_away);

                get diagnostics row_cnt = row_count;

                select public.load_log(l_load_id, l_step_id, 'update staging.etl_subscriptions  ', row_cnt,
                                       'U')
                into l_step_id;

            end if; /* cardinality(l_trade_id_to_reprint)>0  */
        end loop;
-------------------------

 else /* Manual sync */
/* ================================================================================================*/
/* ==================================  Manual Busted Trades =======================================*/
/* ================================================================================================*/

    select public.load_log(l_load_id, l_step_id, 'Processing manual busts', 1 , 'U')
    into l_step_id;

    for tr_date_id_cursor in (select date_id, array_agg(load_batch_id) as trade_to_process
                              from public.etl_subscriptions
                              where is_processed = false
                                and subscription_name = 'big_data.flat_trade_record'
                                and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
                                and (date_id, load_batch_id) in (select date_id, orig_trade_record_id
			                                                      from dwh.flat_trade_record
			                                                      where trade_record_id = any (l_tarde_record_ids)
			                                                        and orig_trade_record_id is not null
			                                                         /* for update skip locked*/)
                              group by date_id)
 --==================== Probably better query for cursor

--   for tr_date_id_cursor in ( with ct as materialized (select orig_trade_record_id
--                         								from dwh.flat_trade_record
--                          							where trade_record_id = any (l_tarde_record_ids)
--                            							and orig_trade_record_id is not null )
--								select date_id, array_agg(load_batch_id) as trade_to_process
--                              from ct
--							  inner join lateral (select date_id, load_batch_id
--												  from staging.etl_subscriptions
--                              				where is_processed = true
--                               				 	and subscription_name = 'big_data.flat_trade_record'
--                                					and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
--                                					and load_batch_id =ct.orig_trade_record_id
--												 limit 1) l on true
--                              				group by date_id)

        loop
            if cardinality(tr_date_id_cursor.trade_to_process) > 0
            then
                select public.load_log(l_load_id, l_step_id, 'Manual Bust processing ', cardinality (tr_date_id_cursor.trade_to_process) , 'U')
                into l_step_id;

                with tr as materialized (select trade_record_reason, user_id, trade_record_id
                            from staging.trade_record
                            where trade_record_id = any (tr_date_id_cursor.trade_to_process)
                              and date_id = tr_date_id_cursor.date_id)
                update dwh.flat_trade_record ftr
                set is_busted = 'Y',
                    trade_record_reason = tr.trade_record_reason,
                    user_id = tr.user_id
                from tr
                where ftr.is_busted = 'N'
                  and ftr.trade_record_id = tr.trade_record_id
                  and ftr.date_id = tr_date_id_cursor.date_id;

            get diagnostics row_cnt = row_count;
            select  public.load_log(l_load_id,  l_step_id,  'Processed  '  ||  left(array_to_string(tr_date_id_cursor.trade_to_process,  ',',  '*'),  200),
                                                                                row_cnt,  'U')
            into l_step_id;

             if tr_date_id_cursor.date_id::int < public.get_dateid(current_date)
              then  row_cnt  :=  dwh.fix_ftr_market_data(tr_date_id_cursor.date_id::int,  l_load_id,  l_tarde_record_ids::bigint[]);

		            select public.load_log(l_load_id, l_step_id, 'Fix Market Matching Manual for = '||tr_date_id_cursor.date_id::text , row_cnt , 'U')
		            into l_step_id;
              end if;

            -- TO REVIEW: IF we need process clearing changes there or it is already processed by some Talend job

            select public.load_log(l_load_id, l_step_id, 'updating clearing_instruction_entry... ', cardinality(tr_date_id_cursor.trade_to_process) , 'U')
            into l_step_id;

            with dt as (select clearing_instr_entry_id, new_trade_record_id
                        from dwh.clearing_instruction_entry cie
                        where new_trade_record_id = any (in_tarde_record_ids)
                          and new_trade_record_id is not null
            )
            update dwh.clearing_instruction_entry i
            set new_trade_record_id = dt.new_trade_record_id
            from dt
            where dt.clearing_instr_entry_id = i.clearing_instr_entry_id;


           select public.load_log(l_load_id, l_step_id, 'updating clearing_instructiony... ', cardinality(tr_date_id_cursor.trade_to_process) , 'U')
           into l_step_id;

            update dwh.clearing_instruction i
            set status = s.status
            from dwh.clearing_instruction s,
                 dwh.clearing_instruction_entry ie
            where ie.new_trade_record_id = any (in_tarde_record_ids)
              and ie.clearing_instr_id = s.clearing_instr_id
              and ie.new_trade_record_id is not null
              and i.clearing_instr_id = s.clearing_instr_id;

                                  select  public.load_log(l_load_id,  l_step_id,  'closing  TRADE_RECORD.MANUAL_BUST  subscriptions',
                                                                                cardinality(tr_date_id_cursor.trade_to_process),  'U')
            into l_step_id;

            declare
            begin
                update public.etl_subscriptions
                set is_processed = true,
                    process_time = clock_timestamp()
                where is_processed = false
                  and subscription_name = 'big_data.flat_trade_record'
                  and source_table_name in ('TRADE_RECORD.MANUAL_BUST')
                  and load_batch_id = any (tr_date_id_cursor.trade_to_process);

            exception
                when others then
                    select public.load_log(l_load_id, l_step_id, sqlerrm, 0, 'E')
                    into l_step_id;
                    perform public.load_error_log('load_flat_trade_record_inc', 'I', sqlerrm, l_load_id);
            end;

            get diagnostics row_cnt = row_count;

            select public.load_log(l_load_id, l_step_id, 'update staging.etl_subscriptions  ', row_cnt, 'U')
            into l_step_id;

            with ins as (select /*public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_edw'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1),*/
                                public.etl_subscribe(load_batch_id, 'dash_trade_record_bust_mira'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1)
                         from unnest(tr_date_id_cursor.trade_to_process) as load_batch_id)
            select count(1)
            into row_cnt
            from ins;

        select public.load_log(l_load_id, l_step_id, 'subscribed for EDW & MIRA ', row_cnt , 'I')
        into l_step_id;

       with subs as (select public.etl_subscribe(ftr.trade_record_id, 'dash_trade_record_bust_ptm'::varchar,
                                                     'flat_trade_record'::varchar,
                                                     in_date_ids=>tr_date_id_cursor.date_id::varchar,
                                                     in_row_count=>1)
				        from   flat_trade_record ftr
				        where ftr.date_id = tr_date_id_cursor.date_id
				        and ftr.trade_record_id = any (l_tarde_record_ids)
				        and trade_record_reason is not null)
			select count(1)
            into row_cnt
            from subs;

        select public.load_log(l_load_id, l_step_id, 'subscribed for MIRA PTM', row_cnt , 'I')
        into l_step_id;
    end if;
end loop;

end if;

/*    if  in_manual_run  then
    	  update  public.flat_trade_record_mng
	  set  status=false
	  where  oparation='MANUAL_RUN';
    end  if;                                      */

        if  not  in_manual_run    then
        perform dwh.p_upd_fact_last_load_time('flat_trade_record');
        select public.load_log(l_load_id, l_step_id, 'p_upd_fact_last_load_time ', 0, 'O')
        into l_step_id;
    end if;

    select public.load_log(l_load_id, l_step_id, 'dwh.flat_trade_record COMPLETE ========= ', 0, 'O')
    into l_step_id;
    return 1;

exception
    when others then
        select public.load_log(l_load_id, l_step_id, sqlerrm, 0, 'E')
        into l_step_id;

        if (select 'ftr_comm_upd' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('ftr_comm_upd');
        end if;

        if (select 'ftr_instr_sync' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('ftr_instr_sync');
        end if;

        if (select 'ftr_comm_upd' = any (dblink_get_connections()))
        then
            perform public.dblink_disconnect('err_pragma');
        end if;

        perform public.load_error_log('load_flat_trade_record_inc', 'I', sqlerrm, l_load_id);
        raise;

end;
$function$
;
