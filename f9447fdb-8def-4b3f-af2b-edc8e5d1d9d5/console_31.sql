-- DROP FUNCTION genesis2.lp_load_missed_trades_blaze7(int8, int4, int4);

CREATE OR REPLACE FUNCTION genesis2.lp_load_missed_trades_blaze7_00000(in_load_batch_id bigint DEFAULT NULL::bigint, in_start_date integer DEFAULT get_dateid(CURRENT_DATE), in_end_date integer DEFAULT get_dateid(CURRENT_DATE))
 RETURNS integer
 LANGUAGE plpgsql
AS $function$

-- OS 20210218 Added ON CONFLICT for using native partitioning  https://dashfinancial.atlassian.net/browse/DS-2813
-- SY 20210816 https://dashfinancial.atlassian.net/browse/DS-3805 Added logic to match routed from SOR to ONYX trades. We should not load them into TR/FTR
-- AK 20220912 changed subscription name from 'trade_record_street_lvl_info' to 'trade_record_away_lvl_info'
-- SY 20210920 https://dashfinancial.atlassian.net/browse/DS-4174 The TRAFX exchange has been added to SOR to ONYX mathcing
-- SY 20220422 https://dashfinancial.atlassian.net/browse/DS-4946 Traffix logic has been moved to the very last step of the matching
-- AK 20221018 https://dashfinancial.atlassian.net/browse/DS-5716 : Added new logic for split flow
-- SY 20221102 https://dashfinancial.atlassian.net/browse/DS-5906 Prevent unbust of already busted trade_record
-- AK 20221117 added new condition "and tr.is_busted ='N'" to update statement for blaze_account_alias on 726 line
-- SY 20230323 https://dashfinancial.atlassian.net/browse/DS-6523  and mapping_logic <> 99 condition has been added to update to is_busted
-- SY 20230725 https://dashfinancial.atlassian.net/browse/DS-6911 Strong matching of OMS_EDW flow has been implemented
-- SO 20231005 https://dashfinancial.atlassian.net/browse/DS-6911 489-546 rows. Fuzzy matchings (mapping logic 23 and 25) of OMS_EDW flow have been implemented
-- SY 20231011 https://dashfinancial.atlassian.net/browse/DS-6911 Logics  2, 5, 6, 8, 9, 10, 11  has been commented as useless
-- SY 20231121 https://dashfinancial.atlassian.net/browse/DS-7570 Smart analyze has been added to avoid OMS matching stuck
-- AK 20250130 https://dashfinancial.atlassian.net/browse/DS-8441 due redising away trade flow we create new function
-- OS 20260126 https://dashfinancial.atlassian.net/browse/DS-10962 move logic that inserts Blaze7 Away trades from load_trade_record_inc to lp_load_missed_trades_blaze7

declare
 row_cnt int;
 total_cn int;
 inserted_cnt int=0;
 conflict_count int;
 scr tid;
 date_cursor record;
 l_time timestamp;
 l_step_id	int;
 l_load_id	int;
l_subscr_trade_record_id int8[];

begin
	total_cn:=0;
	row_cnt:=0;
	conflict_count:=0;

	--select nextval('load_timing_seq') into l_load_id;
	if in_load_batch_id is null
		then
			in_load_batch_id:=nextval('load_timing_seq');
		else
			l_load_id:= in_load_batch_id;
	end if ;

	l_load_id:=in_load_batch_id;--nextval('load_timing_seq');
	l_step_id:=0;

	select public.load_log(l_load_id, l_step_id, 'lp_load_missed_trades_blaze7 STARTED <<<<<<<<<< load_batch_id='||in_load_batch_id, 0, 'B')
	into l_step_id;

--======================================================================================
--====================== STEP 1 : Define instrument_id =================================
--======================================================================================

	create temp table instr --on commit drop
	as
		select *
			from genesis2.instrument i
				where i.is_deleted='N'
					--and instrument_type_id='O'
				;
	select public.load_log(l_load_id, l_step_id, 'instr temp table created ', 0, 'U')
		into l_step_id;

		analyze instr;

	select public.load_log(l_load_id, l_step_id, 'analyzed instr', 0, 'U')
		into l_step_id;

	perform db_management.smart_analyze(in_schema_name =>'staging', in_table_name=>'trade_record_blaze7');

	SET enable_nestloop TO off;
	SET enable_mergejoin = OFF;

	update staging.trade_record_blaze7 trml
        set instrument_id=i.instrument_id,
		      load_batch_id=in_load_batch_id
    from instr i--genesis2.instrument i
        where date_id between in_start_date and in_end_date
			and trml.display_instrument_id = i.display_instrument_id2
            --and i.is_deleted='N'
            and trml.instrument_type_id='O'
			and trml.instrument_type_id = i.instrument_type_id
            and trml.instrument_id is null;

     GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'Define instrument 1 ', row_cnt, 'U')
		into l_step_id;

	update staging.trade_record_blaze7 trml
	set instrument_id=i.instrument_id,
		 load_batch_id=in_load_batch_id
	from instr i--genesis2.instrument i
	where date_id between in_start_date and in_end_date
		and trml.display_instrument_id=i.display_instrument_id2
		and is_deleted='N'
		and trml.instrument_type_id='E'
		and trml.instrument_type_id = i.instrument_type_id
		and trml.instrument_id is null;

	 GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'Define instrument 2  ', row_cnt, 'U')
		into l_step_id;

	update staging.trade_record_blaze7 trml
	set instrument_id=i.instrument_id,
	      load_batch_id=in_load_batch_id
	from instr i--genesis2.instrument i
	where date_id between in_start_date and in_end_date
		and trml.activ_symbol=i.activ_symbol
		and is_deleted='N'
		and trml.instrument_type_id='E'
		and trml.instrument_type_id = i.instrument_type_id
		and trml.instrument_id is null;

	 GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'Define instrument 3  ', row_cnt, 'U')
		into l_step_id;


	update staging.trade_record_blaze7 trml
	set exch_exec_id=replace(random()::varchar(20) ,'.','' )
	where date_id between in_start_date and in_end_date
	  and trade_record_id is null
	  and exch_exec_id='0';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'update exch_exec_id  ', row_cnt, 'U')
		into l_step_id;

	 SET enable_nestloop TO on;

	-- we should not match until we sure Oracle version of the trade arrived, The assumption is trade_record ETL takes not more than 10 minutes
	select greatest ( max(trade_record_time)- interval '1 minutes', now() - interval '1 hour')
		into l_time
			from genesis2.trade_record tr
				where date_id = in_end_date
					and is_busted='N'
					and tr.subsystem_id <> 'LPEDW';

  	select public.load_log(l_load_id, l_step_id, 'start_date='||in_start_date::text||' load_batch_id='||in_load_batch_id, 0, 'S')
		into l_step_id;

	/* ======== FIX for https://dashfinancial.atlassian.net/browse/DS-1172  */
	  update staging.trade_record_blaze7 trml
	    set load_batch_id = in_load_batch_id
	    where trml.date_id between in_start_date and in_end_date
	    and trml.load_batch_id = '-1'
	    and trml.trade_record_time <= l_time;

	   GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'Include to matching postponed trades from prev itarration  ', row_cnt, 'U')
		into l_step_id;

	    update staging.trade_record_blaze7 trml
	    set load_batch_id = '-1'
	    where trml.date_id between in_start_date and in_end_date
	    and trml.load_batch_id = in_load_batch_id
	    and trml.trade_record_time > l_time;

	   GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

	select public.load_log(l_load_id, l_step_id, 'Posponed trade matching due to Oracle Delay or so ', row_cnt, 'U')
		into l_step_id;

	update  staging.trade_record_blaze7 trml
		set trade_record_id=tr.trade_record_id,
		    mapping_logic = 1,
		    load_batch_id  = in_load_batch_id
		from genesis2.trade_record tr
	--	join instrument i on i.instrument_id=tr.instrument_id
		where  tr.date_id between in_start_date and in_end_date
		and date_trunc('second',tr.trade_record_time)=date_trunc('second',trml.trade_record_time)
		and	tr.account_id=trml.account_id
		and	coalesce(tr.secondary_order_id, ' ')=coalesce(trml.secondary_order_id, ' ')
		and	tr.secondary_exch_exec_id=trml.secondary_exch_exec_id
		and	tr.last_qty=trml.last_qty
		and tr.date_id=trml.date_id
		and	tr.last_px=trml.last_px
		and	tr.side=trml.side
		and (tr.exchange_id=trml.exchange_id or tr.exchange_id = 'BRKPT')
		and tr.open_close=trml.open_close
		and tr.instrument_id=trml.instrument_id
		and trml.trade_record_id is null
		and tr.is_busted='N'
		and trml.is_busted is null--trml.is_busted='N'
		;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE1', row_cnt, 'U')
		into l_step_id;


		update  staging.trade_record_blaze7 trml
		set trade_record_id=tr.trade_record_id,
		    mapping_logic = 3,
		    load_batch_id  = 3333--in_load_batch_id
		from genesis2.trade_record tr
		where  tr.date_id  between 20250204 and 20250204--in_start_date and in_end_date
		and date_trunc('second',tr.trade_record_time)=date_trunc('second',trml.trade_record_time)
		and	tr.account_id=trml.account_id
		and tr.date_id=trml.date_id
		and	tr.client_order_id=trml.secondary_order_id
		and	tr.exch_exec_id=trml.secondary_exch_exec_id
		and	tr.last_qty=trml.last_qty
		and	tr.last_px=trml.last_px
		and	tr.side=trml.side
	    and tr.instrument_id  = trml.instrument_id
		and trml.trade_record_id is null
		and tr.is_busted='N'
		and trml.is_busted is null--and trml.is_busted='N'
	;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE3', row_cnt, 'U')
		into l_step_id;


		with cte as (select tr.instrument_id
					,tr.secondary_exch_exec_id
	    			,tr.date_id
					,tr.last_qty
					,tr.last_px
					,tr.side
	             	,tr.trade_record_id
	             	,tr.account_id
	             	,tr.exch_exec_id
	    from genesis2.trade_record tr
	    where  tr.date_id  between  in_start_date and in_end_date
		and tr.is_busted='N'
	    )
		update  staging.trade_record_blaze7 trml
		set trade_record_id=tr.trade_record_id,
		    mapping_logic = 4,
		    load_batch_id  = in_load_batch_id
		from cte tr
		where  tr.date_id=trml.date_id
		and	tr.last_qty=trml.last_qty
		and	tr.last_px=trml.last_px
		and	tr.side=trml.side
		and tr.account_id = trml.account_id
		and	tr.exch_exec_id=trml.secondary_exch_exec_id
	--	and tr.display_instrument_id=trml.display_instrument_id
	    and tr.instrument_id  = trml.instrument_id
		and trml.trade_record_id is null
	    and trml.secondary_exch_exec_id <> 'Manual Report'
	    and tr.secondary_exch_exec_id <> 'Manual Report'
		and trml.is_busted is null--and trml.is_busted='N'
	;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE4', row_cnt, 'U')
		into l_step_id;


		update  staging.trade_record_blaze7 trml
		set trade_record_id=tr.trade_record_id,
		    mapping_logic = 7,
		    load_batch_id  = in_load_batch_id
		from genesis2.trade_record tr
	--	join instrument i on i.instrument_id=tr.instrument_id
	--	left join option_contract oc on oc.instrument_id=i.instrument_id
	--	left join option_series os on os.option_series_id=oc.option_series_id
		where  tr.date_id  between in_start_date and in_end_date
		and tr.account_id = trml.account_id
		and	tr.exch_exec_id=trml.secondary_exch_exec_id
		and	tr.last_qty=trml.last_qty
		and tr.date_id=trml.date_id
		and	round(tr.last_px,2)=round(trml.last_px,2)
		and	tr.side=trml.side
		and tr.instrument_id=trml.instrument_id
		and trml.trade_record_id is null
		and tr.is_busted='N'
		and trml.is_busted is null--and trml.is_busted='N'
	;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE7', row_cnt, 'U')
		into l_step_id;

	   select count(1)
	   from staging.trade_record_blaze7 trml
		join genesis2.exchange e on  e.exchange_id=trml.exchange_id
						and e.is_deleted='N'
						and e.exchange_id=e.real_exchange_id
	    where trade_record_id is null
	    and instrument_id is not null
	    and date_id between  in_start_date and in_end_date
	    and load_batch_id=in_load_batch_id
	    and last_qty<=order_qty
	    into inserted_cnt;

		select public.load_log(l_load_id, l_step_id, 'TRADES TO INSERT load_batch_id='||in_load_batch_id, inserted_cnt, 'I')
		into l_step_id;

	/* ======== END of FIX for https://dashfinancial.atlassian.net/browse/DS-1172  */

	-- SY: 20210816 fix for DS-3805
	with dt as (select trml.secondary_exch_exec_id , tr.trade_record_id
				from staging.trade_record_blaze7 trml
				inner join genesis2.trade_record tr on trml.date_id =tr.date_id
												and trml.exch_exec_id = tr.secondary_exch_exec_id
												and not tr.subsystem_id like 'LPEDW%'
												and tr.exchange_id in ('TRAFX','BRKPT')
												and tr.is_busted ='N'
				where trml.date_id between in_start_date and in_end_date
				and tr.date_id between in_start_date and in_end_date
				and trml.is_busted is null--and trml.is_busted ='N'
				and not is_sor_routed
				and trml.trade_record_id is null)
	update  staging.trade_record_blaze7 trm
		set trade_record_id  = dt.trade_record_id,
		    load_batch_id  = in_load_batch_id,
		    mapping_logic = 0
	from dt
	where trm.date_id between in_start_date and in_end_date
	and trm.secondary_exch_exec_id = dt.secondary_exch_exec_id
	and trm.trade_record_id  is null;


		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'SOR=>ONYX=>BLAZE routing matched ', row_cnt, 'U')
		into l_step_id;

	-- OMS_EDW case strong logic secondary_exch_exec_id =tr.exch_exec_id
	--	perform db_management.smart_analyze(in_schema_name =>'staging', in_table_name=>'trade_record_blaze7');


		update  staging.trade_record_blaze7 trml
		set trade_record_id=tr.trade_record_id,
		    mapping_logic = 21,
		    load_batch_id  = in_load_batch_id
		from genesis2.trade_record tr
		where  tr.date_id  between in_start_date and in_end_date
		and trml.date_id between in_start_date and in_end_date
		and trml.subsystem_id ='OMS_EDW'
		and trml.trade_record_id is null
		and trml.is_busted is null--and trml.is_busted ='N'
		and trml.date_id=tr.date_id
		and trml.instrument_id=tr.instrument_id
		and tr.is_busted='N'
		and tr.last_qty=trml.last_qty
		and tr.last_px=trml.last_px
		and tr.exchange_id='BLAZE'
		and trml.secondary_exch_exec_id =tr.exch_exec_id
		and tr.trade_record_id not in (select trade_record_id from staging.trade_record_blaze7 where date_id between in_start_date and in_end_date)
		;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

		select public.load_log(l_load_id, l_step_id, 'OMS_EDW UPDATE secondary_exch_exec_id', row_cnt, 'U')
		into l_step_id;

	-- OMS_EDW case fuzzy matching logic 1

	    update staging.trade_record_blaze7 trml
	    set trade_record_id=tr.trade_record_id,
	        mapping_logic  = 23, -- with no trml.secondary_exch_exec_id =tr.exch_exec_id but with inteval 10 seconds
	        load_batch_id  = in_load_batch_id
	    from genesis2.trade_record tr
	    where tr.date_id between in_start_date and in_end_date
	      and trml.date_id between in_start_date and in_end_date
	      and trml.subsystem_id = 'OMS_EDW'
	      and trml.trade_record_id is null
	      and trml.is_busted is null--and trml.is_busted = 'N'
	      and trml.date_id = tr.date_id
	      and trml.instrument_id = tr.instrument_id
	      and tr.is_busted = 'N'
	      and tr.last_qty = trml.last_qty
	      and tr.last_px = trml.last_px
	      and abs(extract(epoch from (trml.trade_record_time - tr.trade_record_time))) < extract(epoch from '10 seconds'::interval)
	      and tr.exchange_id = 'BLAZE'
	      and tr.trade_record_id not in (select trade_record_id
	                                     from staging.trade_record_blaze7
	                                     where date_id between in_start_date and in_end_date);

	    GET DIAGNOSTICS row_cnt = ROW_COUNT;
	    total_cn := total_cn + row_cnt;

		select public.load_log(l_load_id, l_step_id, 'OMS_EDW UPDATE fuzzy matching 1', row_cnt, 'U')
		into l_step_id;

		update  staging.trade_record_blaze7 trml
		set trade_record_id = trml2.trade_record_id,
		    mapping_logic = 99 -- modified after busting --!!!!!?
		from staging.trade_record_blaze7 trml2
		where trml.order_id_guid = trml2.order_id_guid
		and trml.date_id = trml2.date_id
		and trml.is_busted is null--and trml2.is_busted = 'N'
		and trml.load_batch_id  = in_load_batch_id
		-- two rows below were added within a ticket: https://dashfinancial.atlassian.net/browse/DS-2131
		AND trml.last_qty  = trml2.last_qty
		AND trml.last_px = trml2.last_px
	    and trml.is_busted is not null--and trml.is_busted ='Y'
	   ;



	   --==================================================================================================
	   --======================= Added new mapping logic for splits =======================================
	   --==================================================================================================

	    create temp table orig_trade_record_ids_temp
	    	as
		with cte as(
			select orig_trade_record_id
				from genesis2.trade_record
					where date_id between in_start_date and in_end_date
					and orig_trade_record_id is not null
					and trade_record_reason in('P','L')
			group by orig_trade_record_id
			having count(1)>1
					)
		select tr.*
		from genesis2.trade_record as tr
		join cte as trml  on tr.trade_record_id = trml.orig_trade_record_id
		where date_id between in_start_date and in_end_date
		;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;

		select public.load_log(l_load_id, l_step_id, 'temp table orig_trade_record_ids_temp created for splits flow.', row_cnt, 'C')
		into l_step_id;

		analyze orig_trade_record_ids_temp;

		update staging.trade_record_blaze7 trml
			set trade_record_id = otri.trade_record_id,
				load_batch_id = in_load_batch_id,
				mapping_logic = 45
		from orig_trade_record_ids_temp as otri
			where otri.date_id between in_start_date and in_end_date
			and trml.date_id between in_start_date and in_end_date
			and otri.last_qty = trml.last_qty
			and otri.last_px = trml.last_px
			and otri.exch_exec_id = trml.secondary_exch_exec_id
			and trml.trade_record_id is null
			;

		GET DIAGNOSTICS row_cnt = ROW_COUNT;

		select public.load_log(l_load_id, l_step_id, 'split flow (45) matched', row_cnt, 'U')
		into l_step_id;


		with upd_blaze_account_alias as (
			update genesis2.trade_record tr
				set blaze_account_alias  = coalesce(tr.blaze_account_alias,trml.blaze_account_alias)
			from staging.trade_record_blaze7 trml--cte trml
				where  tr.date_id = trml.date_id
				and  tr.orig_trade_record_id = trml.trade_record_id
				and  tr.date_id = trml.date_id --trml.orig_trade_record_id
				and  tr.date_id between in_start_date and in_end_date
				and trml.load_batch_id = in_load_batch_id
				and trml.mapping_logic = 45
				and tr.blaze_account_alias is null --added this code line since every run this step was updating blaze_account_alias
				returning tr.trade_record_id as trade_record_id, tr.date_id as date_id
				)
		select count(1) into row_cnt
	 	from(
	 		select genesis2.etl_subscribe(in_load_batch_id=> trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'trade_record_away_lvl_info', in_date_id => date_id)
			     from upd_blaze_account_alias
		     ) subsc_creation
		;

		select public.load_log(l_load_id, l_step_id, 'blaze_account_alias splits subscriptions created =', row_cnt, 'U')
		into l_step_id;

	/*
		with upd_busted as (update genesis2.trade_record tr
					set is_busted = case tr.is_busted when 'Y' then tr.is_busted else  trml.is_busted end ,
				      load_batch_id =  trml.load_batch_id::int,
		  			  blaze_account_alias  = coalesce(trml.blaze_account_alias, tr.blaze_account_alias)
					from staging.trade_record_blaze7 trml
					where tr.trade_record_id = trml.trade_record_id
					and tr.date_id = trml.date_id
					and tr.date_id between in_start_date and in_end_date
	--				and tr.is_busted = 'N'
	--				and (trml.is_busted = 'Y' or trml.blaze_account_alias is not null)
	                and ( (tr.is_busted = 'N' and trml.is_busted is not null)
	                    or (trml.blaze_account_alias is not null and tr.blaze_account_alias is null and tr.is_busted ='N' )
                    )
	  				and trml.load_batch_id = in_load_batch_id
	  				and mapping_logic <> 99
	 				returning tr.trade_record_id as trade_record_id, tr.date_id as date_id, tr.is_busted as is_busted,tr.blaze_account_alias as blaze_account_alias)
	 --,ins as (insert into trash.new_blaze_account_alias(trade_record_id,blaze_account_alias)
	 --			select trade_record_id,blaze_account_alias from upd_busted where is_busted ='N'
	 --			)
*/
	with upd_busted as (update genesis2.trade_record tr
	    set is_busted = case tr.is_busted when 'Y' then tr.is_busted else trml.is_busted end ,
	        load_batch_id = trml.load_batch_id::int,
	        blaze_account_alias = coalesce(trml.blaze_account_alias, tr.blaze_account_alias)
	    from staging.trade_record_blaze7 trml
	    where tr.trade_record_id = trml.trade_record_id
	        and tr.date_id = trml.date_id
	        and tr.date_id between in_start_date and in_end_date
	        --				and tr.is_busted = 'N'
	        --				and (trml.is_busted = 'Y' or trml.blaze_account_alias is not null)
	        and case
	                when (tr.is_busted = 'N' and trml.is_busted = 'Y') then true
	                when (trml.blaze_account_alias is not null and tr.blaze_account_alias is null and tr.is_busted = 'N')
	                    then true
	                when (trml.blaze_account_alias is distinct from tr.blaze_account_alias and
	                      trml.blaze_account_alias is not null and tr.is_busted = 'N' and
	                      tr.account_id in (select account_id from genesis2.account where trading_firm_id = 'strategas') and
	                      tr.orig_trade_record_id is null) then true
	                else false end
	        and trml.load_batch_id = in_load_batch_id
	        and mapping_logic <> 99
    returning tr.trade_record_id as trade_record_id, tr.date_id as date_id, tr.is_busted as is_busted,tr.blaze_account_alias as blaze_account_alias)
	 	select count(1) into row_cnt
	 	from( 	select genesis2.etl_subscribe(in_load_batch_id => trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'TRADE_RECORD.BUSTED_TRADES', in_date_id => date_id)
				from upd_busted
				where is_busted = 'Y'
				/* SY second UNION added as part of https://dashfinancial.atlassian.net/browse/DS-1961 */
			     UNION ALL
			     select genesis2.etl_subscribe(in_load_batch_id=> trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'trade_record_away_lvl_info', in_date_id => date_id)
			     from upd_busted
			     where is_busted = 'N'
		     ) upd_busted_y;

		--GET DIAGNOSTICS row_cnt = ROW_COUNT;

		select public.load_log(l_load_id, l_step_id, 'BUST MISSED TRADES INTO TRADE_RECORD load_batch_id='||in_load_batch_id, row_cnt, 'U')
		into l_step_id;


		insert into  genesis2.trade_level_book_record (trade_record_id, book_record_type_id, amount, rate,  book_record_creator_id,load_batch_id, billing_entity, create_time, date_id)
		select distinct on (trade_record_id/*, book_record_type_id, book_record_creator_id, billing_entity*/, date_id) trade_record_id, 'CCRU' as book_record_type_id,
		case
		   	when commission_rate_unit*last_qty is null and a.trading_firm_id ='cornerstn' and i.instrument_type_id = 'E'
		   	then coalesce(commission_rate_unit*last_qty,0) else commission_rate_unit*last_qty
		 end as amount ,
		   	commission_rate_unit as rate, 'GOAT' as book_record_creator_id, in_load_batch_id as load_batch_id, '-1' as billing_entity, clock_timestamp() as create_time, date_id
		from staging.trade_record_blaze7 trml
			left join genesis2.account a on trml.account_id = a.account_id and a.is_deleted = 'N'
			left join genesis2.instrument i on trml.instrument_id = i.instrument_id and i.is_deleted = 'N'
		where  trade_record_id is not null
	    and trml.instrument_id is not null
	    and date_id between  in_start_date and in_end_date
	    and load_batch_id=in_load_batch_id
	    and last_qty<=order_qty
	    and is_busted is null-- ='N'
	    and commission_rate_unit is not null
	    order by trade_record_id desc
	   on conflict (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id)
	 	do update set
	 	amount 			= EXCLUDED.amount,
	 	rate 			= EXCLUDED.rate,
		load_batch_id	= EXCLUDED.load_batch_id,
		user_id			= EXCLUDED.user_id,
		create_time		= EXCLUDED.create_time
	    ;


	    select COUNT(1) into row_cnt
	    from genesis2.trade_level_book_record
	    where date_id between  in_start_date and in_end_date
	    and load_batch_id = in_load_batch_id
	    and book_record_type_id = 'CCRU'
	    and book_record_creator_id = 'GOAT';

		select public.load_log(l_load_id, l_step_id, 'cru INSERTED load_batch_id='||in_load_batch_id, row_cnt, 'I')
		into l_step_id;


	  select count(1) into row_cnt
	  from (select  genesis2.etl_subscribe( load_batch_id, row_cnt, 'big_data.flat_trade_record'::varchar , 'trade_level_book_record'::varchar, date_id)
	        from (select distinct load_batch_id, date_id
				     from genesis2.trade_level_book_record
				        where date_id between  in_start_date and in_end_date
					    and load_batch_id = in_load_batch_id
					    and book_record_type_id = 'CCRU'
					    and book_record_creator_id = 'GOAT') L ) l2 ;


	     select public.load_log(l_load_id, l_step_id, 'etl_subscribe load_batch_id:'||(in_load_batch_id::text) , 1, 'O')
	             into l_step_id;



	--- >>>
	  INSERT INTO genesis2.trade_record
	(trade_record_time
			,date_id
			,is_busted
--			,orig_trade_record_id
			,trade_record_trans_type
			,trade_record_reason
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id
			,load_batch_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias )

select distinct trade_record_time
			,date_id
			,coalesce(is_busted,'N') as is_busted
--			,null::bigint as orig_trade_record_id --SY
			,null as trade_record_trans_type -- SY
			,'A' as trade_record_reason
--			,subsystem_id
			,case when (generation>0  or (is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ))
			            and subsystem_id = 'LPEDW'
				  then 'LPEDW_DUPE'
			 else subsystem_id
			 end as subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,e.exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,e.last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,nullif(left(cmta,3), '') as cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,nullif(street_client_order_id,'') as street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity::int2
			,street_order_price
			,leg_ref_id::varchar
			,l_load_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias
	--from staging.trade_record_missed_lp trml
   from staging.trade_record_blaze7 trml
	join genesis2.exchange e on  e.exchange_id=trml.exchange_id
					and e.is_deleted='N'
					and e.exchange_id=e.real_exchange_id
    where trade_record_id is null
    and instrument_id is not null
   -- and 1=2
--    and subsystem_id not in ('OMS_EDW')
    and (  (subsystem_id not in ('OMS_EDW') and  generation = 0 and not is_sor_routed )/* ordinar case non sor routed trades */
		    or (subsystem_id not in ('OMS_EDW') and  generation = 0 and is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* routed to sor with company name changes*/
		    or (subsystem_id not in ('OMS_EDW') and  generation>0 and is_company_name_changed =1 and not is_sor_routed and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* non-routed to SOR company name chaned in firther generation*/
		    or (subsystem_id not in ('OMS_EDW') and generation>0 and is_company_name_changed =1 and is_sor_routed and mx_gen>generation and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' )
		    or (subsystem_id in ('OMS_EDW') and generation=0 and secondary_exch_exec_id = 'Manual Report' and not is_sor_routed and trml.instrument_type_id not in ('E') )
		)
    and date_id between in_start_date and in_end_date
    and trml.load_batch_id <> -1
    and trml.load_batch_id <= l_load_id
    and last_qty<=order_qty
    and coalesce(trml.is_busted,'N') ='N'
    on conflict (date_id,
    COALESCE(exch_exec_id, (exec_id)::character varying),
    client_order_id, (
    CASE
        WHEN (orig_trade_record_id IS NOT NULL)
            THEN trade_record_id
        ELSE 1
        END)
    )
    do update
    set date_id = coalesce(public.f_insert_etl_reject('trade_record_inc',
                                                      'trade_record_' || substring(excluded.DATE_ID::TEXT, 1, 6) || '_nk',
                                                      '(date_id = ' || EXCLUDED.date_id::text || ' exch_exec_id=' ||
                                                      EXCLUDED.exch_exec_id::text || ', client_order_id = ' ||
                                                      EXCLUDED.client_order_id || ')'),
                           EXCLUDED.date_id);

		GET DIAGNOSTICS row_cnt = ROW_COUNT;
		   total_cn:=total_cn+row_cnt;

    select genesis2.etl_subscribe(in_load_batch_id := trade_record_id, in_row_cnt := row_cnt,
                                  in_subscription_name := 'big_data.flat_trade_record',
                                  in_source_table_name := 'TRADE_RECORD.AWAY_TRADES', in_date_id := date_id)
    FROM genesis2.trade_record
    where load_batch_id = l_load_id;

	--update staging.trade_record_missed_lp trml
    update staging.trade_record_blaze7 trml
	set trade_record_id = tr.trade_record_id ,
		mapping_logic = 20
	from genesis2.trade_record tr
	where tr.date_id between in_start_date and in_end_date
	 and tr.load_batch_id = l_load_id
	 and tr.subsystem_id in ('LPEDW', 'LPEDW_DUPE', 'OMS_EDW')
	 and trml.trade_record_id is null
	 and trml.date_id =tr.date_id
	 and trml.exec_id = tr.exec_id
	 and trml.load_batch_id <> -1
	 and trml.load_batch_id <= l_load_id;

  	GET DIAGNOSTICS row_cnt = ROW_COUNT;

	select load_log(l_load_id, l_step_id, 'missed_trades_blaze7 Matching COMPLETED ===', 0, 'E')
	into l_step_id;


	-- subscription

	--- <<<


	     return total_cn;

		exception when others then

		select load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
	  into l_step_id;
	  RAISE notice '% %', sqlstate, sqlerrm;

	  select load_log(l_load_id, l_step_id, 'lp_load_missed_trades_blaze7  COMPLETED with ERROR ===', 0, 'O')
	  into l_step_id;

	  PERFORM load_error_log('genesis2.lp_load_missed_trades_blaze7',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
		return -1; --RAISE;

end;
    $function$
;



-- DROP FUNCTION genesis2.load_trade_record_inc_dmp(int8, int8, bpchar);

CREATE OR REPLACE FUNCTION genesis2.load_trade_record_inc_dmp_00000(in_dataset_id bigint DEFAULT NULL::numeric, in_orig_trade_record_id bigint DEFAULT NULL::bigint, in_trade_record_reason character DEFAULT NULL::character(1))
 RETURNS integer
 LANGUAGE plpgsql
 SET application_name TO 'ETL_FAST: TRADE_RECORD incremental'
AS $function$
-- AK: 20210322 added "NULLIF" for street_client_order_id field at 559 line
-- SY: 20220217 https://dashfinancial.atlassian.net/browse/DS-4834 Added condition to do not load flex trades. It fixes issue with multyleg when one lag is fex abother not
-- SY: 20220909 https://dashfinancial.atlassian.net/browse/DS-5623 Added immediate  match of Away trade
-- SY: 20220909 Disbale part related to Oracle Billing
-- SY: 20221121 https://dashfinancial.atlassian.net/browse/DS-5997 . Force oracle_fdw disconnect has been added to close serializable session of oracle side
-- SY: 20230125 https://dashfinancial.atlassian.net/browse/DS-6085 processing of Away trades from Dash360 has been added
-- SY: 20230420 https://dashfinancial.atlassian.net/browse/DS-6649. blaze_account_alias field has been introduced on staging.trade_record_v side
-- PD: 20230509 https://dashfinancial.atlassian.net/browse/DS-6421. Commented is_flex_order condition for away trades
-- SY: 20230614 https://dashfinancial.atlassian.net/browse/DS-6846 OMS_EDW trades processing has been blocked (temporary) but correct processing implemented
-- SY: 20230619 https://dashfinancial.atlassian.net/browse/DS-6846 OMS_EDW trades processing has been allowed
-- SY: 20230621 https://dashfinancial.atlassian.net/browse/DS-6846 OMS_EDW trades processing has been disabled for electronic fills
-- SY: 20230623 https://dashfinancial.atlassian.net/browse/DS-6921 Trade_liquidity_indicator needs to be converted to correct value due to Java-2329
-- SY: 20230707 https://dashfinancial.atlassian.net/browse/DS-6988 Equity processing as part of OMS_EDW flow has been disabled
-- SY: 20230821 https://dashfinancial.atlassian.net/browse/DS-7137 blaze_account_alias fix for crosses
-- SY: 20240410 https://dashfinancial.atlassian.net/browse/DS-8193 logic to handle  subscription_name = 'missed_fix_trade' and source_table_name = 'orcl_execution' has been added
-- OS: 20240429 https://dashfinancial.atlassian.net/browse/DS-8134 init
-- OK: 20240911 https://dashfinancial.atlassian.net/browse/DS-8869 changed from incremental value for dataset_id to etl_subsctiptions
-- SO: 20241114 https://dashfinancial.atlassian.net/browse/DS-9091 Added on conflict (moved from the old trigger)
-- SY: 20241216 https://dashfinancial.atlassian.net/browse/DS-9283 street_exec_broker logic reverted to use client_order table instead of function
-- SY: 20241223 https://dashfinancial.atlassian.net/browse/DS-9338 check_environment has been introduced
-- OK: 20250102 https://dashfinancial.atlassian.net/browse/DS-9285 each date is processed separately in a loop and there is a disctinct query for multidays
-- SY: 20250116 https://dashfinancial.atlassian.net/browse/DS-9438 Allocation bofa reporting flag has been added. The is_billed field  has been reused
-- SY: 20250416 https://dashfinancial.atlassian.net/browse/DS-9877 Away trade logic has been fixed to use 20 mapping logic in correct way
--																   is_busted field has been corrcted due to now away trade flow rules
-- AK: 20250714 https://dashfinancial.atlassian.net/browse/DS-10203 v.co_client_leg_ref_id removed from input paremetr of  public.get_message_tag_string_cross_multileg function
-- SY: 20251209 https://dashfinancial.atlassian.net/browse/DS-10410 street_account_name logic has been moved to big_data side
-- OS 20260126 https://dashfinancial.atlassian.net/browse/DS-10962 move logic that inserts Blaze7 Away trades from load_trade_record_inc to lp_load_missed_trades_blaze7
DECLARE
--    l_max_exec_id bigint;
   l_ret	int;
   some_var     varchar;
   l_step_id	int;
   l_load_id	int;
--    l_foreign_max_exec_id bigint; -- max exiscting id
   l_status_message varchar;
   l_scr record;
   l_cnt int;
   l_date_id int;
--   l_date_ids int[];
   l_away_load_batch int;
   l_max_dataset_id         int8; -- dataset_id that is present in the table
   l_foreign_max_dataset_id int8; -- max dataset_id we should load
   l_foreign_dataset_ids_mday int8[]; -- dataset_ids used for trade_record_v_historical_mday
   l_pg_session_id int4;
   l_batch_size int4;
   l_date_total_trade_count int4;
   l_date_mday_trade_count int4;
   l_date_trade_count int4;
   l_minimal_create_date_id int4;



BEGIN
   l_date_id:=to_char(current_date - interval '5 days' ,'YYYYMMDD')::int ;
   l_batch_size:=100;

   if in_dataset_id is null
 then
	select nextval('load_timing_seq') into l_load_id;
--	select nextval('public.load_timing_seq') into l_load_id;
	l_step_id:=1;
	--l_foreign_max_exec_id:=0;

	l_status_message:='Trade_Record_inc STARTED===';
	select public.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
	into l_step_id;

	select pg_backend_pid()::text
	into l_pg_session_id;

	select public.load_log(l_load_id, l_step_id, 'load_trade_record_inc session id:' || l_pg_session_id::varchar, 0, 'S')
	into l_step_id;


 else l_foreign_max_dataset_id:=in_dataset_id ;
	 l_max_dataset_id := in_dataset_id - 1;
end if;

--if public.check_environment() in ('DEV', 'UAT')  -- genesis2.dimension_etl is being called directly from Airflow prior to calling this function
--	then 	select genesis2.dimension_etl() into some_var;
--    else 	select genesis2.dimension_etl(true) into some_var;
--   end if;
--
--
--   l_status_message:='dimension_etl';
--	select genesis2.load_log(l_load_id, l_step_id, l_status_message, 0, 'O')
--	into l_step_id;
 perform public.oracle_close_connections();

   for l_scr in (select load_batch_id, subscription_id
                 from genesis2.etl_subscriptions
                 where subscription_name = 'missed_fix_trade'
                   and source_table_name = 'orcl_execution'
                   and  not is_processed
                 ) loop
    l_status_message:= 'FIX TRADE GAP processing: '||l_scr.load_batch_id;

	select public.load_log(l_load_id, l_step_id, l_status_message, 1, 'O')
	into l_step_id;

     --SY !! perform genesis2.load_trade_record_inc_dmp(l_scr.load_batch_id);

	      update genesis2.etl_subscriptions
     set is_processed = true,
         process_time = clock_timestamp()
     where subscription_id = l_scr.subscription_id;
    end loop;


--IF l_foreign_max_dataset_id > l_max_dataset_id /* 1=1*/ THEN
--if cardinality(l_foreign_max_dataset_ids)>0 THEN

--set enable_hashjoin=off;
--set enable_mergejoin=off;

-- foreach l_loop_date_id in array l_date_ids loop
 for l_scr in (select date_id, array_agg(load_batch_id) as foreign_max_dataset_ids, array_agg(subscription_id) as subs_ids
                 from (select date_id, load_batch_id, subscription_id
		                 from staging.etl_subscriptions
		                 where subscription_name = 'genesis2.trade_record'
							and source_table_name = 'dmp.execution'
		                   	and  not is_processed
		                   	and subscribe_time < now() - interval '10 seconds'
		                    limit l_batch_size
						)
		                  group by date_id
                 ) loop

l_status_message:='date_id='||l_scr.date_id::text||': load_batch_ids size: ';

select public.load_log(l_load_id, l_step_id, l_status_message, cardinality(l_scr.foreign_max_dataset_ids), 'S')
    into l_step_id;

select count(1), count(case when time_in_force_id in ('1', '6') then 1 else null end), count(case when time_in_force_id not in ('1', '6') then 1 else null end)
     ,  array_agg(distinct case when time_in_force_id  in ('1', '6') then a.ds_id else 0 end)
into l_date_total_trade_count, l_date_mday_trade_count, l_date_trade_count, l_foreign_dataset_ids_mday
from (select unnest(l_scr.foreign_max_dataset_ids) as ds_id) a
inner join lateral (select time_in_force_id
                    from  staging.execution ex
                    where a.ds_id = ex.dataset_id and ex.exec_date_id = l_scr.date_id
 					and is_parent_level
                    and exec_type='F'
                    and ex.is_busted='N'
                    limit 10050000 ) E on true;


l_status_message:='l_date_total_trade_count: ';

select public.load_log(l_load_id, l_step_id, l_status_message, l_date_total_trade_count, 'S')
    into l_step_id;
--
--l_status_message:='l_date_trade_count: ';
--
--select public.load_log(l_load_id, l_step_id, l_status_message, l_date_trade_count, 'S')
--    into l_step_id;
--
--l_status_message:='l_foreign_dataset_ids_mday count: ';
--
--select public.load_log(l_load_id, l_step_id, l_status_message, cardinality(l_foreign_dataset_ids_mday), 'S')
--    into l_step_id;

--   l_status_message:='============FIX TRADE GAP =======';

--if l_date_trade_count>0 THEN

	insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, clearing_account_number, sub_account,  multileg_order_id,
		    INTERNAL_COMPONENT_TYPE, street_trade_fix_message_id, pt_basket_id, pt_order_id, Street_Client_Sender_CompID,
		    street_account_name, street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, time_in_force, int_liq_source_type,
		    market_participant_id, ALTERNATIVE_COMPLIANCE_ID, street_trade_record_time, street_order_process_time,leg_ref_id, blaze_account_alias
		    )
	select TRADE_RECORD_TIME
	, now() as db_create_time
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, coalesce(in_trade_record_reason,TRADE_RECORD_REASON::char ) as TRADE_RECORD_REASON
	, COALESCE(SUB_SYSTEM_ID,'PG_DASH') as SUB_SYSTEM_ID
	, null as USER_ID  -- SO hotfix
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, v.INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, staging.get_trade_liquidity_indicator(TRADE_LIQUIDITY_INDICATOR) as TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
-- 	, SUB_STRATEGY
    , sub_strategy_desc
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY
	, MULTILEG_REPORTING_TYPE
	, IS_LARGEST_LEG
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, left(CMTA,3)
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity::int2
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
	, clearing_account
    , left(sub_account,30) as sub_account
    ,  multileg_order_id
    , INTERNAL_COMPONENT_TYPE
    , str_trade_fix_message_id
    , pt_basket_id
    , pt_order_id
    , str_cls_comp_ID
    , street_account_name
    , v.street_exec_broker
    , trade_text
    , branch_seq_num
    , left (frequent_trader_id,6) as frequent_trader_id
    , time_in_force
    , is_ats_or_cons
    , mpid
    , ALTERNATIVE_COMPLIANCE_ID
    , street_trade_record_time
    , street_order_process_time
    , co_client_leg_ref_id as leg_ref_id
    , v.blaze_account_alias
--	, case when v.is_cross_order='Y'
--             then  public.get_message_tag_string_cross_multileg(v.order_fix_message_id, 10445, v.date_id::int,v.client_order_id, NULL,null/*v.co_client_leg_ref_id*/, v.is_cross_order::boolean)
--             else v.blaze_account_alias
--      end
    from staging.trade_record_v_historical v
	where dataset_id = any(l_scr.foreign_max_dataset_ids)
	and v.date_id = l_scr.date_id
--    and v.exec_id not in (344679071267219235, 344679101331990358)
on conflict (date_id,
    COALESCE(exch_exec_id, (exec_id)::character varying),
    client_order_id, (CASE
				        WHEN (orig_trade_record_id IS NOT NULL)
				            THEN trade_record_id
				        ELSE 1
				        END)
				    )
    do update
    set date_id = coalesce(public.f_insert_etl_reject('trade_record_inc',
                                                      'trade_record_' || substring(excluded.DATE_ID::TEXT, 1, 6) || '_nk',
                                                      '(date_id = ' || EXCLUDED.date_id::text || ' exch_exec_id=' ||
                                                      EXCLUDED.exch_exec_id::text || ', client_order_id = ' ||
                                                      EXCLUDED.client_order_id || ')'),
                           EXCLUDED.date_id)
;


GET DIAGNOSTICS l_cnt = ROW_COUNT;

select public.load_log(l_load_id, l_step_id, l_scr.date_id::varchar|| ': insert into genesis2.trade_record', l_cnt, 'I')
into l_step_id;
--end if;

--l_status_message:='l_date_mday_trade_count: ';
--
--select public.load_log(l_load_id, l_step_id, l_status_message, l_date_mday_trade_count, 'S')
--    into l_step_id;

if l_date_mday_trade_count>0 then

select order_create_date_id
into l_minimal_create_date_id
from (select unnest(l_scr.foreign_max_dataset_ids) as ds_id) a
join lateral (select min(order_create_date_id) as order_create_date_id
              from staging.execution ex
              where a.ds_id = ex.dataset_id
              and  is_parent_level
              and ex.time_in_force_id in ('1', '6')
              and ex.exec_date_id = l_scr.date_id
              limit 1) on true
 order by order_create_date_id
 limit 1;

l_status_message:='l_minimal_create_date_id: ';

select public.load_log(l_load_id, l_step_id, l_status_message, l_minimal_create_date_id, 'S')
    into l_step_id;

--raise notice '%', l_foreign_dataset_ids_mday; --debug

insert into genesis2.trade_record (trade_record_time, db_create_time, date_id,
		    is_busted, orig_trade_record_id, trade_record_trans_type, trade_record_reason,
		    subsystem_id, user_id, account_id, client_order_id, instrument_id ,
		    side, open_close, fix_connection_id, exec_id, exchange_id, trade_liquidity_indicator,
		    secondary_order_id, exch_exec_id, secondary_exch_exec_id, last_mkt,
		    last_qty, last_px, ex_destination, sub_strategy, street_order_id,
		    order_id, street_order_qty, order_qty, multileg_reporting_type,
		    is_largest_leg, street_max_floor, exec_broker, cmta,
		    street_time_in_force, street_order_type, opt_customer_firm, street_mpid,
		    is_cross_order, street_is_cross_order, street_cross_type, cross_is_originator,
		    street_cross_is_originator, contra_account, contra_broker, trade_exec_broker,
		    order_fix_message_id, trade_fix_message_id,  street_order_fix_message_id, client_id,
		    street_transaction_id, transaction_id, order_price, street_order_price, order_process_time ,
		    street_client_order_id, fix_comp_id, LEAVES_QTY, street_exec_inst, fee_sensitivity,
		    strategy_decision_reason_code, compliance_id, floor_broker_id, AUCTION_ID,
		    street_opt_customer_firm, clearing_account_number, sub_account,  multileg_order_id,
		    INTERNAL_COMPONENT_TYPE, street_trade_fix_message_id, pt_basket_id, pt_order_id, Street_Client_Sender_CompID,
		    street_account_name, street_exec_broker, trade_text, branch_sequence_number, frequent_trader_id, time_in_force, int_liq_source_type,
		    market_participant_id, ALTERNATIVE_COMPLIANCE_ID, street_trade_record_time, street_order_process_time,leg_ref_id, blaze_account_alias
		    )
	select TRADE_RECORD_TIME
	, now()
	, DATE_ID
	, 'N' as IS_BUSTED
	, IN_ORIG_TRADE_RECORD_ID
	, TRADE_RECORD_TRANS_TYPE
	, coalesce(in_trade_record_reason,TRADE_RECORD_REASON::char ) as TRADE_RECORD_REASON
	, COALESCE(SUB_SYSTEM_ID,'PG_DASH') as SUB_SYSTEM_ID
	, null as USER_ID  -- SO hotfix
	, ACCOUNT_ID
	, CLIENT_ORDER_ID
	, v.INSTRUMENT_ID
	, SIDE
	, OPEN_CLOSE
	, FIX_CONNECTION_ID
	, EXEC_ID
	, CASE WHEN exchange_id in ('C2OXFX','CBOEFX') then substring(exchange_id, 1, length(exchange_id)-2) else exchange_id end as exchange_id
	, staging.get_trade_liquidity_indicator(TRADE_LIQUIDITY_INDICATOR) as TRADE_LIQUIDITY_INDICATOR
	, SECONDARY_ORDER_ID
	, EXCH_EXEC_ID
	, SECONDARY_EXCH_EXEC_ID
	, LAST_MKT
	, LAST_QTY
	, LAST_PX
	, EX_DESTINATION
-- 	, SUB_STRATEGY
    , sub_strategy_desc
	, STREET_ORDER_ID
	, ORDER_ID
	, STREET_ORDER_QTY
	, ORDER_QTY
	, MULTILEG_REPORTING_TYPE
	, IS_LARGEST_LEG
	, STREET_MAX_FLOOR
	, EXEC_BROKER
	, left(CMTA,3)
	, STREET_TIME_IN_FORCE
	, STREET_ORDER_TYPE
	, OPT_CUSTOMER_FIRM
	, STREET_MPID
	, IS_CROSS_ORDER
	, STREET_IS_CROSS_ORDER
	, STREET_CROSS_TYPE
	, CROSS_IS_ORIGINATOR
	, STREET_CROSS_IS_ORIGINATOR
	, CONTRA_ACCOUNT
	, CONTRA_BROKER
	, TRADE_EXEC_BROKER
	, order_fix_message_id
	, trade_fix_message_id
	, street_order_fix_message_id
	, client_id
	, street_transaction_id
	, transaction_id
	, order_price
	, street_order_price
	, order_process_time
	, street_client_order_id
	, fix_comp_id
    , LEAVES_QTY
    , street_exec_inst
    , fee_sensitivity::int2
    , strategy_decision_reason_code
    , compliance_id
    , floor_broker_id
    , AUCTION_ID
    , STR_OPT_CUSTOMER_FIRM
	, clearing_account
    , left(sub_account,30) as sub_account
    ,  multileg_order_id
    , INTERNAL_COMPONENT_TYPE
    , str_trade_fix_message_id
    , pt_basket_id
    , pt_order_id
    , str_cls_comp_ID
    , street_account_name
    , v.street_exec_broker
    , trade_text
    , branch_seq_num
    , left (frequent_trader_id,6) as frequent_trader_id
    , time_in_force
    , is_ats_or_cons
    , mpid
    , ALTERNATIVE_COMPLIANCE_ID
    , street_trade_record_time
    , street_order_process_time
    , co_client_leg_ref_id as leg_ref_id
    , v.blaze_account_alias
--	, case when v.is_cross_order='Y'
--             then  public.get_message_tag_string_cross_multileg(v.order_fix_message_id, 10445, v.date_id::int,v.client_order_id, NULL, v.co_client_leg_ref_id, v.is_cross_order::boolean)
--             else v.blaze_account_alias
--      end
    from staging.trade_record_v_historical_mday v

	where dataset_id = any(l_foreign_dataset_ids_mday)
	and v.date_id = l_scr.date_id
 --   and v.exec_id not in (344679071267219235, 344679101331990358)
	--and v.create_date_id >= l_minimal_create_date_id
on conflict (date_id,
    COALESCE(exch_exec_id, (exec_id)::character varying),
    client_order_id, (
    CASE
        WHEN (orig_trade_record_id IS NOT NULL)
            THEN trade_record_id
        ELSE 1
        END)
    )
    do update
    set date_id = coalesce(public.f_insert_etl_reject('trade_record_inc',
                                                      'trade_record_' || substring(excluded.DATE_ID::TEXT, 1, 6) || '_nk',
                                                      '(date_id = ' || EXCLUDED.date_id::text || ' exch_exec_id=' ||
                                                      EXCLUDED.exch_exec_id::text || ', client_order_id = ' ||
                                                      EXCLUDED.client_order_id || ')'),
                           EXCLUDED.date_id)
;

GET DIAGNOSTICS l_cnt = ROW_COUNT;

select public.load_log(l_load_id, l_step_id, l_scr.date_id::varchar|| ': insert multidays into genesis2.trade_record', l_cnt, 'I')
into l_step_id;
end if;

update staging.etl_subscriptions
set is_processed = true,
process_time = clock_timestamp()
where subscription_id = any(l_scr.subs_ids);

end loop;


set enable_hashjoin=On;
set enable_mergejoin=On;


 if in_dataset_id is null
  then
   /* replicate busted trades without recalculation.
     1. Must be inside in_exec_id is null
     2. MUST be before recalculated */


 /*update trade_record tr
 set is_busted = 'Y'
 where tr.exec_id in (select exec_id from staging.psql_execution psq where psq.is_busted='Y')
   and tr.is_busted='N';*/

 /*======================*/

 -- DISASTER
     with upd as (update staging.etl_subscriptions s
        set is_processed = true,
            process_time = clock_timestamp()
        where is_processed = false
            and subscription_name = 'genesis2.busted_trade'
            and source_table_name = 'dwh.execution'
--            and exists (select null from genesis2.trade_record ft where ft.exec_id=s.load_batch_id  and ft.date_id = s.date_id ) /* We need to be sure trade to bust already there */
                        RETURNING  load_batch_id,  date_id  /*it  contains  exec_id  for  that  specific  source  'dwh.execution'*/),
    tr_upd as (update genesis2.trade_record
        set is_busted = 'Y'
        where (exec_id, date_id) in (select load_batch_id, date_id from upd)
        and is_busted = 'N'
        returning trade_record_id, date_id)
    insert into genesis2.etl_subscriptions (subscription_name, source_table_name, load_batch_id, date_id)
	Select 'big_data.flat_trade_record', 'TRADE_RECORD.BUSTED_TRADES', trade_record_id, date_id FROM tr_upd;


    select public.load_log(l_load_id, l_step_id, 'Busted trades updated ', 0 , 'U')
    into l_step_id;

end if;

/* =============================================================================================================== */
/* ========================================= AWAY TRADE=========================================================== */
/* =============================================================================================================== */

if in_dataset_id is null
 then
     /* SO 20260129
	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES processing started', 0, 'I')
	into l_step_id;

   l_date_id:=to_char(current_date ,'YYYYMMDD')::int ;

/* We take into account last but one completed Missed trade job
 * Missed job has delay 12 minutes to be sure we are not ahead Oracle traffic
 * We can't use last completed ID bacuse aftre completion we have matching process. It update all load_batchIds to -1 to avoid picking up trade too early
 * */

--  select max(load_batch_id)
--	  into l_away_load_batch
--	from genesis2.etl_load_batch
--	where file_name ='Load_Missed_Trades_MSSQL'
--	and process_end_date_time < now()
--	and status ='C';



select max(load_timing_id)
	  into l_away_load_batch
  from public.load_timing lt2
  where table_name = 'missed_trades_blaze7 Matching COMPLETED ==='
	and lt2.log_date < now();


  INSERT INTO genesis2.trade_record
	(trade_record_time
			,date_id
			,is_busted
--			,orig_trade_record_id
			,trade_record_trans_type
			,trade_record_reason
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id
			,load_batch_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias )

select distinct trade_record_time
			,date_id
			,coalesce(is_busted,'N') as is_busted
--			,null::bigint as orig_trade_record_id --SY
			,null as trade_record_trans_type -- SY
			,'A' as trade_record_reason
--			,subsystem_id
			,case when (generation>0  or (is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ))
			            and subsystem_id = 'LPEDW'
				  then 'LPEDW_DUPE'
			 else subsystem_id
			 end as subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,e.exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,e.last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,nullif(left(cmta,3), '') as cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,nullif(street_client_order_id,'') as street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity::int2
			,street_order_price
			,leg_ref_id::varchar
			,l_load_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias
	--from staging.trade_record_missed_lp trml
   from staging.trade_record_blaze7 trml
	join genesis2.exchange e on  e.exchange_id=trml.exchange_id
					and e.is_deleted='N'
					and e.exchange_id=e.real_exchange_id
    where trade_record_id is null
    and instrument_id is not null
    --and 1=2
--    and subsystem_id not in ('OMS_EDW')
    and (  (subsystem_id not in ('OMS_EDW') and  generation = 0 and not is_sor_routed )/* ordinar case non sor routed trades */
		    or (subsystem_id not in ('OMS_EDW') and  generation = 0 and is_sor_routed and num_firms>1 and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* routed to sor with company name changes*/
		    or (subsystem_id not in ('OMS_EDW') and  generation>0 and is_company_name_changed =1 and not is_sor_routed and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' ) /* non-routed to SOR company name chaned in firther generation*/
		    or (subsystem_id not in ('OMS_EDW') and generation>0 and is_company_name_changed =1 and is_sor_routed and mx_gen>generation and coalesce(nullif(secondary_exch_exec_id,''), 'Manual Report') <> 'Manual Report' )
		    or (subsystem_id in ('OMS_EDW') and generation=0 and secondary_exch_exec_id = 'Manual Report' and not is_sor_routed and trml.instrument_type_id not in ('E') )
		)
    and date_id = l_date_id
    and trml.load_batch_id <> -1
    and trml.load_batch_id <= l_away_load_batch
    and last_qty<=order_qty
    and coalesce(trml.is_busted,'N') ='N'
	on conflict (date_id,
    COALESCE(exch_exec_id, (exec_id)::character varying),
    client_order_id, (
    CASE
        WHEN (orig_trade_record_id IS NOT NULL)
            THEN trade_record_id
        ELSE 1
        END)
    )
    do update
    set date_id = coalesce(public.f_insert_etl_reject('trade_record_inc',
                                                      'trade_record_' || substring(excluded.DATE_ID::TEXT, 1, 6) || '_nk',
                                                      '(date_id = ' || EXCLUDED.date_id::text || ' exch_exec_id=' ||
                                                      EXCLUDED.exch_exec_id::text || ', client_order_id = ' ||
                                                      EXCLUDED.client_order_id || ')'),
                           EXCLUDED.date_id);

	--update staging.trade_record_missed_lp trml
    update staging.trade_record_blaze7 trml
	set trade_record_id = tr.trade_record_id ,
		mapping_logic = 20
	from genesis2.trade_record tr
	where tr.date_id = l_date_id
	 and tr.load_batch_id = l_load_id
	 and tr.subsystem_id in ('LPEDW', 'LPEDW_DUPE', 'OMS_EDW')
	 and trml.trade_record_id is null
	 and trml.date_id =tr.date_id
	 and trml.exec_id = tr.exec_id
	 and trml.load_batch_id <> -1
	 and trml.load_batch_id <= l_away_load_batch;

  	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select public.load_log(l_load_id, l_step_id, 'AWAY TRADES INSERT INSERTED load_batch_id='||l_load_id, l_cnt, 'I')
	into l_step_id;
	SO 20260129
      */
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   AWAY TRADES ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/


/*********************************** MANUAL TRADE *********************************************/
	/* SO 20260129
     for l_scr in (select date_id, array_agg(es.load_batch_id) as ids_to_process
					from genesis2.etl_subscriptions es
						where subscription_name = 'trade_record_away_trade'
						and source_table_name='trade_desk'
						and not is_processed
                  group by date_id) loop

  INSERT INTO genesis2.trade_record
	(trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,trade_record_reason
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id
			,load_batch_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias )

select trade_record_time
			,date_id
			,is_busted
			,orig_trade_record_id
			,trade_record_trans_type
			,'A' as trade_record_reason -- To confirm
			,subsystem_id
			,user_id
			,account_id
			,client_order_id
			,instrument_id
			,side
			,open_close
			,fix_connection_id
			,exec_id
			,exchange_id
			,trade_liquidity_indicator
			,secondary_order_id
			,exch_exec_id
			,secondary_exch_exec_id
			,last_mkt
			,last_qty
			,last_px
			,ex_destination
			,sub_strategy
			,street_order_id
			,order_id
			,street_order_qty
			,order_qty
			,multileg_reporting_type
			,is_largest_leg
			,street_max_floor
			,exec_broker
			,nullif(left(cmta,3), '') as cmta
			,street_time_in_force
			,street_order_type
			,opt_customer_firm
			,street_mpid
			,is_cross_order
			,street_is_cross_order
			,street_cross_type
			,cross_is_originator
			,street_cross_is_originator
			,contra_account
			,contra_broker
			,trade_exec_broker
			,order_fix_message_id
			,trade_fix_message_id
			,street_order_fix_message_id
			,client_id
			,street_transaction_id
			,transaction_id
			,order_price
			,order_process_time
			,clearing_account_number
			,sub_account
			,remarks
			,optional_data
			,nullif(street_client_order_id,'') as street_client_order_id
			,fix_comp_id
			,leaves_qty
			,is_billed
			,street_exec_inst
			,fee_sensitivity
			,street_order_price
			,leg_ref_id::varchar
			,l_load_id
			,strategy_decision_reason_code
			,compliance_id
			,floor_broker_id
			,blaze_account_alias
	from staging.trade_record_missed_lp trml
     where trml.load_batch_id = any (l_scr.ids_to_process)
       and date_id = l_scr.date_id
on conflict (date_id,
    COALESCE(exch_exec_id, (exec_id)::character varying),
    client_order_id, (
    CASE
        WHEN (orig_trade_record_id IS NOT NULL)
            THEN trade_record_id
        ELSE 1
        END)
    )
    do update
    set date_id = coalesce(public.f_insert_etl_reject('trade_record_inc',
                                                      'trade_record_' || substring(excluded.DATE_ID::TEXT, 1, 6) || '_nk',
                                                      '(date_id = ' || EXCLUDED.date_id::text || ' exch_exec_id=' ||
                                                      EXCLUDED.exch_exec_id::text || ', client_order_id = ' ||
                                                      EXCLUDED.client_order_id || ')'),
                           EXCLUDED.date_id);

   	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select public.load_log(l_load_id, l_step_id, 'MANUAL TRADES INSERTED load_batch_id='||l_load_id, l_cnt, 'I')
	into l_step_id;

 update genesis2.etl_subscriptions
	set is_processed = true ,
        process_time = clock_timestamp()
   where subscription_name = 'trade_record_away_trade'
	and source_table_name='trade_desk'
	and load_batch_id =  any (l_scr.ids_to_process)
    and date_id = l_scr.date_id;

  	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select public.load_log(l_load_id, l_step_id, 'trade_record_away_trade subscriptions closed', l_cnt, 'U')
	into l_step_id;

	update staging.trade_record_missed_lp trml
	set trade_record_id = tr.trade_record_id ,
		mapping_logic = 20
	from genesis2.trade_record tr
	where tr.date_id = l_scr.date_id
	 and tr.load_batch_id = l_load_id
	 and tr.subsystem_id in ('PG_DASH')
	 and trml.trade_record_id is null
	 and trml.date_id =tr.date_id
	 and trml.exec_id = tr.exec_id
	 and trml.load_batch_id =  any (l_scr.ids_to_process) ;

  	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select public.load_log(l_load_id, l_step_id, 'MANUAL TRADES Matched with logic 20', l_cnt, 'U')
	into l_step_id;


end loop;
     SO 20260129
	 */
/*********************************** MANUAL TRADE *********************************************/

/*=================================================== BOFA Allocation reporting  =================  */
  for l_scr in (select load_batch_id, subscription_id , date_id
                 from genesis2.etl_subscriptions
                 where subscription_name = 'trade_record'
                   and source_table_name = 'bofa_allocation_report'
                   and  not is_processed
                 ) loop

	with cte as materialized (select distinct trade_record_id
								from dash_reporting.bofa_allocation_report alr
								   join genesis2.alloc_instr2trade_record aitr on aitr.date_id = alr.date_id and aitr.alloc_instr_id = alr.alloc_instr_id
								where alr.to_report = 'R'
								  and alr.date_id = l_scr.date_id
								  and alr.dataset = l_scr.load_batch_id )
  update genesis2.trade_record tr
  set is_billed = 'R'
  from cte
  where tr.date_id = l_scr.date_id
   and tr.trade_record_id = cte.trade_record_id
   /*and tr.is_busted='N'*/;

  	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select genesis2.load_log(l_load_id, l_step_id, 'bofa_allocation_report load_batch_id='||l_scr.load_batch_id, l_cnt, 'U')
	into l_step_id;

    update genesis2.etl_subscriptions
    set is_processed=true,
 		process_time = clock_timestamp()
    where subscription_id = l_scr.subscription_id;

 end loop ;

/*=================================================== BOFA trade_reporting    =================  */
  for l_scr in (select load_batch_id, subscription_id , date_id
                 from genesis2.etl_subscriptions
                 where subscription_name = 'trade_record'
                   and source_table_name = 'bofa_trade_record'
                   and  not is_processed
                 ) loop
	with cte as materialized (select distinct trade_record_id
								from dash_reporting.bofa_trade_record btr
								where btr.date_id = l_scr.date_id
								  and btr.dataset = l_scr.load_batch_id )
  update genesis2.trade_record tr
  set is_billed = 'R'
  from cte
  where tr.date_id = l_scr.date_id
   and tr.trade_record_id = cte.trade_record_id
   /*and tr.is_busted='N'*/;

  	GET DIAGNOSTICS l_cnt = ROW_COUNT;

	select genesis2.load_log(l_load_id, l_step_id, 'bofa_trade_record load_batch_id='||l_scr.load_batch_id, l_cnt, 'U')
	into l_step_id;

    update genesis2.etl_subscriptions
    set is_processed=true,
 		process_time = clock_timestamp()
    where subscription_id = l_scr.subscription_id;

 end loop ;


end if;  -- in_exec_id is null




select public.load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
into l_step_id;

 l_ret:=1;

 return l_ret;

 exception when others then
   select public.load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select public.load_log(l_load_id, l_step_id, 'Trade_Record_inc COMPLETED ===', 0, 'O')
  into l_step_id;

  PERFORM public.load_error_log('trade_record',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
  RAISE;



END;
$function$
;
