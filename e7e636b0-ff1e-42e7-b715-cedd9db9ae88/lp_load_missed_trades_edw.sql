CREATE OR REPLACE FUNCTION genesis2.lp_load_missed_trades_edw(in_load_batch_id bigint, in_start_date integer, in_end_date integer)
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
-- SO 20231005 https://dashfinancial.atlassian.net/browse/DS-6911 Fuzzy matchings (mapping logic 23 and 25) of OMS_EDW flow have been implemented
declare
 row_cnt int;
 total_cn int=0;
 inserted_cnt int=0;
 conflict_count int;
 scr tid;
 date_cursor record;
 l_time timestamp;
 l_step_id	int;
 l_load_id	int;



--1. In each UPDATE added condition: and trml.is_busted = 'N'
--2. line 382-389: added main condition
--3. line 559-569 - instead of modifying INSERT added UPDATE of trade_record with logs
--
--SY 20200408
--1. Looks good
--2. line 382-389: Commented. Instead Line 393 -400 inserted instead
--3. update statement has been improved a little bit.

begin
	total_cn:=0;
	row_cnt:=0;
	conflict_count:=0;

	--select nextval('load_timing_seq') into l_load_id;
	l_load_id:= in_load_batch_id;
	l_step_id:=1;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE_MATCH STARTED <<<<<<<<<< load_batch_id='||in_load_batch_id, 0, 'B')
	into l_step_id;

-- we should not match until we sure Oracle version of the trade arrived, The assumption is trade_record ETL takes not more than 10 minutes
select greatest ( max(trade_record_time)- interval '1 minutes', now() - interval '1 hour')
	into l_time
	from genesis2.trade_record tr
	where date_id = in_end_date
	and is_busted='N'
	and tr.subsystem_id <> 'LPEDW';

  select genesis2.load_log(l_load_id, l_step_id, 'start_date='||in_start_date::text||' load_batch_id='||in_load_batch_id, 0, 'S')
	into l_step_id;

/* ======== FIX for https://dashfinancial.atlassian.net/browse/DS-1172  */
  update staging.trade_record_missed_lp trml
    set load_batch_id = in_load_batch_id
    where trml.date_id between in_start_date and in_end_date
    and trml.load_batch_id = -1
    and trml.trade_record_time <= l_time;

   GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

select genesis2.load_log(l_load_id, l_step_id, 'Include to matching postponed trades from prev itarration  ', row_cnt, 'U')
	into l_step_id;

    update staging.trade_record_missed_lp trml
    set load_batch_id = -1
    where trml.date_id between in_start_date and in_end_date
    and trml.load_batch_id = in_load_batch_id
    and trml.trade_record_time > l_time;

   GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

select genesis2.load_log(l_load_id, l_step_id, 'Posponed trade matching due to Oracle Delay or so ', row_cnt, 'U')
	into l_step_id;

update  staging.trade_record_missed_lp trml
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
	and trml.is_busted='N';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE1', row_cnt, 'U')
	into l_step_id;

	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 2,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
--	join instrument i on i.instrument_id=tr.instrument_id
	where  tr.date_id  between in_start_date and in_end_date
	and date_trunc('second',tr.trade_record_time)=date_trunc('second',trml.trade_record_time)
	and	tr.account_id=trml.account_id
	and tr.date_id=trml.date_id
	and	coalesce(tr.secondary_order_id, ' ')=coalesce(trml.secondary_order_id, ' ')
	and	tr.secondary_exch_exec_id=trml.secondary_exch_exec_id
	and	tr.last_qty=trml.last_qty
	and	tr.last_px=trml.last_px
	and	tr.side=trml.side
	and tr.instrument_id=trml.instrument_id
	and trml.trade_record_id is null
	and tr.is_busted='N'
	and trml.is_busted='N';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE2', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 3,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
	where  tr.date_id  between in_start_date and in_end_date
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
	and trml.is_busted='N';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE3', row_cnt, 'U')
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
	update  staging.trade_record_missed_lp trml
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
	and trml.is_busted='N';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE4', row_cnt, 'U')
	into l_step_id;



    with cte as (select tr.secondary_exch_exec_id
                        ,tr.date_id
                        ,tr.last_qty
                        ,tr.last_px
                        ,tr.side
                        ,tr.trade_record_id
                        ,tr.account_id
                        ,tr.instrument_id
    from genesis2.trade_record tr
    where  tr.date_id between in_start_date and in_end_date
	   and tr.is_busted='N'
    )
    update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 5,
	    load_batch_id  = in_load_batch_id
	from cte tr
	where tr.last_qty=trml.last_qty
	and tr.date_id=trml.date_id
	and	tr.last_px=trml.last_px
	and	tr.side=trml.side
	and tr.account_id = trml.account_id
	and trml.trade_record_id is null
	and tr.instrument_id=trml.instrument_id
    and trml.secondary_exch_exec_id <> 'Manual Report'
    and tr.secondary_exch_exec_id <> 'Manual Report'
	and trml.is_busted='N'
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
;



	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE5', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 6,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
--	join instrument i on i.instrument_id=tr.instrument_id
	where  tr.date_id between in_start_date and in_end_date
	and	tr.last_qty=trml.last_qty
	and tr.date_id=trml.date_id
	and	tr.last_px=trml.last_px
	and	tr.side=trml.side
	and tr.account_id = trml.account_id
	and tr.instrument_id=trml.instrument_id
	and trml.trade_record_id is null
	and tr.is_busted='N'
	and trml.is_busted='N'
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
	;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE6', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
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
	and trml.is_busted='N';

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE7', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 8,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
--	join instrument i on i.instrument_id=tr.instrument_id
--	left join option_contract oc on oc.instrument_id=i.instrument_id
--	left join option_series os on os.option_series_id=oc.option_series_id
	where  tr.date_id  between in_start_date and in_end_date
	and tr.account_id = trml.account_id
	and	tr.last_qty=trml.last_qty
	and tr.date_id=trml.date_id
	and	tr.last_px=trml.last_px
	and	tr.side=trml.side
--	and oc.strike_price=trml.strike_price
--	and oc.put_call=trml.put_or_call
--	and os.root_symbol=trml.symbol
	and trml.trade_record_id is null
	and tr.instrument_id  = trml.instrument_id
	and tr.is_busted='N'
    and trml.secondary_exch_exec_id <> 'Manual Report'
    and tr.secondary_exch_exec_id <> 'Manual Report'
	and trml.is_busted='N'
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
	;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE8', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 9,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
--	join instrument i on i.instrument_id=tr.instrument_id
--	left join option_contract oc on oc.instrument_id=i.instrument_id
--	left join option_series os on os.option_series_id=oc.option_series_id
	where  tr.date_id  between in_start_date and in_end_date
	and tr.account_id = trml.account_id
--	and oc.strike_price=trml.strike_price
--	and oc.put_call=trml.put_or_call
--	and os.root_symbol=trml.symbol
    and tr.instrument_id = trml.instrument_id
	and tr.last_px=trml.last_px
	and	tr.side=trml.side
	and tr.date_id=trml.date_id
	and trml.trade_record_id is null
	and tr.is_busted='N'
    and trml.secondary_exch_exec_id <> 'Manual Report'
    and tr.secondary_exch_exec_id <> 'Manual Report'
	and trml.is_busted='N'
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
	;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE9', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 10,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
	where  tr.date_id  between in_start_date and in_end_date
	and tr.account_id = trml.account_id
	and	tr.last_qty=trml.last_qty
	and tr.last_px=trml.last_px
	and tr.instrument_id = trml.instrument_id
	and (tr.exchange_id=trml.exchange_id or tr.exchange_id = 'BRKPT')
	and tr.date_id=trml.date_id
	and trml.trade_record_id is null
	and tr.is_busted='N'
    and trml.secondary_exch_exec_id <> 'Manual Report'
    and tr.secondary_exch_exec_id <> 'Manual Report'
    and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
   ;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE10', row_cnt, 'U')
	into l_step_id;


	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 11,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
	where  tr.date_id  between in_start_date and in_end_date
	and tr.account_id = trml.account_id
	and tr.instrument_id = trml.instrument_id
	and	tr.last_qty=trml.last_qty
	and tr.last_px=trml.last_px
	and tr.date_id=trml.date_id
	and trml.trade_record_id is null
	and tr.is_busted='N'
    and trml.secondary_exch_exec_id <> 'Manual Report'
    and tr.secondary_exch_exec_id <> 'Manual Report'
	and trml.is_busted='N'
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
	;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'EDW_TRADE UPDATE11 LAST!!!', row_cnt, 'U')
	into l_step_id;


   select count(1)
   from staging.trade_record_missed_lp trml
	join exchange e on  e.exchange_id=trml.exchange_id
					and e.is_deleted='N'
					and e.exchange_id=e.real_exchange_id
    where trade_record_id is null
    and instrument_id is not null
    and date_id between  in_start_date and in_end_date
    and load_batch_id=in_load_batch_id
    and last_qty<=order_qty
    into inserted_cnt;
	select genesis2.load_log(l_load_id, l_step_id, 'TRADES TO INSERT load_batch_id='||in_load_batch_id, inserted_cnt, 'I')
	into l_step_id;

/* ======== END of FIX for https://dashfinancial.atlassian.net/browse/DS-1172  */

-- SY: 20210816 fix for DS-3805
with dt as (select trml.secondary_exch_exec_id , tr.trade_record_id
			from staging.trade_record_missed_lp trml
			inner join genesis2.trade_record tr on trml.date_id =tr.date_id
											and trml.exch_exec_id = tr.secondary_exch_exec_id
											and not tr.subsystem_id like 'LPEDW%'
											and tr.exchange_id in ('TRAFX','BRKPT')
											and tr.is_busted ='N'
			where trml.date_id between in_start_date and in_end_date
			and tr.date_id between in_start_date and in_end_date
			and trml.is_busted ='N'
			and not is_sor_routed
			and trml.trade_record_id is null)
update  staging.trade_record_missed_lp trm
	set trade_record_id  = dt.trade_record_id,
	    load_batch_id  = in_load_batch_id,
	    mapping_logic = 0
from dt
where trm.date_id between in_start_date and in_end_date
and trm.secondary_exch_exec_id = dt.secondary_exch_exec_id
and trm.trade_record_id  is null;


	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'SOR=>ONYX=>BLAZE routing matched ', row_cnt, 'U')
	into l_step_id;

-- OMS_EDW case strong logic secondary_exch_exec_id =tr.exch_exec_id

	update  staging.trade_record_missed_lp trml
	set trade_record_id=tr.trade_record_id,
	    mapping_logic = 21,
	    load_batch_id  = in_load_batch_id
	from genesis2.trade_record tr
	where  tr.date_id  between in_start_date and in_end_date
	and trml.date_id between in_start_date and in_end_date
	and trml.subsystem_id ='OMS_EDW'
	and trml.trade_record_id is null
	and trml.is_busted ='N'
	and trml.date_id=tr.date_id
	and trml.instrument_id=tr.instrument_id
	and tr.is_busted='N'
	and tr.last_qty=trml.last_qty
	and tr.last_px=trml.last_px
	and tr.exchange_id='BLAZE'
	and trml.secondary_exch_exec_id =tr.exch_exec_id
	and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between in_start_date and in_end_date)
	;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	   total_cn:=total_cn+row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'OMS_EDW UPDATE secondary_exch_exec_id', row_cnt, 'U')
	into l_step_id;


-- OMS_EDW case fuzzy logic 1
/*
    update staging.trade_record_missed_lp trml
    set trade_record_id=tr.trade_record_id,
        mapping_logic  = 23,
        load_batch_id  = in_load_batch_id
    from genesis2.trade_record tr
    where tr.date_id between in_start_date and in_end_date
      and trml.date_id between in_start_date and in_end_date
      and trml.subsystem_id = 'OMS_EDW'
      and trml.trade_record_id is null
      and trml.is_busted = 'N'
      and trml.date_id = tr.date_id
      and trml.instrument_id = tr.instrument_id
      and tr.is_busted = 'N'
      and tr.last_qty = trml.last_qty
      and tr.last_px = trml.last_px
      and abs(extract(epoch from (trml.trade_record_time - tr.trade_record_time))) < extract(epoch from '10 seconds'::interval)
      and tr.exchange_id = 'BLAZE'
      and tr.trade_record_id not in (select trade_record_id
                                     from staging.trade_record_missed_lp
                                     where date_id between in_start_date and in_end_date);

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    total_cn := total_cn + row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'OMS_EDW UPDATE fuzzy matching 1', row_cnt, 'U')
	into l_step_id;


-- OMS_EDW case fuzzy logic 2

    update staging.trade_record_missed_lp trml
    set trade_record_id=tr.trade_record_id,
        mapping_logic  = 23,
        load_batch_id  = in_load_batch_id
    from genesis2.trade_record tr
    where tr.date_id between in_start_date and in_end_date
      and trml.date_id between in_start_date and in_end_date
      and trml.subsystem_id = 'OMS_EDW'
      and trml.trade_record_id is null
      and trml.is_busted = 'N'
      and trml.date_id = tr.date_id
      and trml.instrument_id = tr.instrument_id
      and tr.is_busted = 'N'
      and tr.last_px = trml.last_px
      and abs(extract(epoch from (trml.trade_record_time - tr.trade_record_time))) < extract(epoch from '10 seconds'::interval)
      and tr.exchange_id = 'BLAZE'
      and tr.trade_record_id not in (select trade_record_id
                                     from staging.trade_record_missed_lp
                                     where date_id between in_start_date and in_end_date);

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    total_cn := total_cn + row_cnt;

	select genesis2.load_log(l_load_id, l_step_id, 'OMS_EDW UPDATE fuzzy matching 2', row_cnt, 'U')
	into l_step_id;
*/
	update  staging.trade_record_missed_lp trml
	set trade_record_id = trml2.trade_record_id,
	    mapping_logic = 99 -- modified after busting --!!!!!?
	from staging.trade_record_missed_lp trml2
	where trml.order_id_guid = trml2.order_id_guid
	and trml.date_id = trml2.date_id
	and trml2.is_busted = 'N'
	and trml.load_batch_id  = in_load_batch_id
	-- two rows below were added within a ticket: https://dashfinancial.atlassian.net/browse/DS-2131
	AND trml.last_qty  = trml2.last_qty
	AND trml.last_px = trml2.last_px
	--
    and trml.is_busted ='Y';



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

	select genesis2.load_log(l_load_id, l_step_id, 'temp table orig_trade_record_ids_temp created for splits flow.', row_cnt, 'C')
	into l_step_id;

	analyze orig_trade_record_ids_temp;

	update staging.trade_record_missed_lp trml
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

	select genesis2.load_log(l_load_id, l_step_id, 'split flow (45) matched', row_cnt, 'U')
	into l_step_id;


	with upd_blaze_account_alias as (
		update genesis2.trade_record tr
			set blaze_account_alias  = coalesce(tr.blaze_account_alias,trml.blaze_account_alias)
		from staging.trade_record_missed_lp trml--cte trml
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
 		select genesis2.etl_subscribe(in_load_batch_id => trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'trade_record_away_lvl_info', in_date_id => date_id)
		     from upd_blaze_account_alias
	     ) subsc_creation
	;

	select genesis2.load_log(l_load_id, l_step_id, 'blaze_account_alias splits subscriptions created =', row_cnt, 'U')
	into l_step_id;


	with upd_busted as (update genesis2.trade_record tr
				set is_busted = case tr.is_busted when 'Y' then tr.is_busted else  trml.is_busted end ,
			      load_batch_id =  trml.load_batch_id,
	  			  blaze_account_alias  = coalesce(trml.blaze_account_alias, tr.blaze_account_alias)
				from staging.trade_record_missed_lp trml
				where tr.trade_record_id = trml.trade_record_id
				and tr.date_id = trml.date_id
				and tr.date_id between in_start_date and in_end_date
--				and tr.is_busted = 'N'
--				and (trml.is_busted = 'Y' or trml.blaze_account_alias is not null)
                and ( (tr.is_busted = 'N' and trml.is_busted = 'Y')
                    or (trml.blaze_account_alias is not null and tr.blaze_account_alias is null and tr.is_busted ='N' ) )
  				and trml.load_batch_id = in_load_batch_id
  				and mapping_logic <> 99
 				returning tr.trade_record_id as trade_record_id, tr.date_id as date_id, tr.is_busted as is_busted,tr.blaze_account_alias as blaze_account_alias)
 ,ins as (insert into trash.new_blaze_account_alias(trade_record_id,blaze_account_alias)
 			select trade_record_id,blaze_account_alias from upd_busted where is_busted ='N'
 			)
 	select count(1) into row_cnt
 	from( 	select genesis2.etl_subscribe(in_load_batch_id => trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'TRADE_RECORD.BUSTED_TRADES', in_date_id => date_id)
			from upd_busted
			where is_busted = 'Y'
			/* SY second UNION added as part of https://dashfinancial.atlassian.net/browse/DS-1961 */
		     UNION ALL
		     select genesis2.etl_subscribe(in_load_batch_id => trade_record_id, in_row_cnt => 1, in_subscription_name => 'big_data.flat_trade_record', in_source_table_name => 'trade_record_away_lvl_info', in_date_id => date_id)
		     from upd_busted
		     where is_busted = 'N'
	     ) upd_busted_y;

	--GET DIAGNOSTICS row_cnt = ROW_COUNT;

	select genesis2.load_log(l_load_id, l_step_id, 'BUST MISSED TRADES INTO TRADE_RECORD load_batch_id='||in_load_batch_id, row_cnt, 'U')
	into l_step_id;


	insert into  genesis2.trade_level_book_record (trade_record_id, book_record_type_id, amount, rate,  book_record_creator_id,load_batch_id, billing_entity, create_time, date_id)
	select distinct on (trade_record_id/*, book_record_type_id, book_record_creator_id, billing_entity*/, date_id) trade_record_id, 'CCRU' as book_record_type_id,
	case
	   	when commision_rate_unit*last_qty is null and a.trading_firm_id ='cornerstn' and i.instrument_type_id = 'E'
	   	then coalesce(commision_rate_unit*last_qty,0) else commision_rate_unit*last_qty
	 end as amount ,
	   	commision_rate_unit as rate, 'GOAT' as book_record_creator_id, in_load_batch_id as load_batch_id, '-1' as billing_entity, clock_timestamp() as create_time, date_id
	from staging.trade_record_missed_lp trml
		left join genesis2.account a on trml.account_id = a.account_id and a.is_deleted = 'N'
		left join genesis2.instrument i on trml.instrument_id = i.instrument_id and i.is_deleted = 'N'
	where  trade_record_id is not null
    and trml.instrument_id is not null
    and date_id between  in_start_date and in_end_date
    and load_batch_id=in_load_batch_id
    and last_qty<=order_qty
    and is_busted ='N'
    and commision_rate_unit is not null
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

   -- GET DIAGNOSTICS row_cnt = ROW_COUNT;

	select genesis2.load_log(l_load_id, l_step_id, 'cru INSERTED load_batch_id='||in_load_batch_id, row_cnt, 'I')
	into l_step_id;

 --  PERFORM genesis2.etl_subscribe(in_load_batch_id,inserted_cnt, 'big_data.flat_trade_record', 'liquid_point_trade_record', in_start_date);

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

-- No need to delete dta anymore . Tha table has been added to table_retention table. So it will be deleted automatically
  --  delete from staging.trade_record_missed_lp where trade_record_id is not null;

--	  GET DIAGNOSTICS row_cnt = ROW_COUNT;
--
--	 select genesis2.load_log(l_load_id, l_step_id, 'delete from staging.trade_record_missed_lp', row_cnt, 'D')
--	into l_step_id;
--
--	 total_cn:=total_cn+row_cnt;

	  select load_log(l_load_id, l_step_id, 'EDW_TRADE_MATCH  COMPLETED ===', 0, 'E')
      into l_step_id;

     return total_cn;

	exception when others then

	select load_log(l_load_id, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E')
  into l_step_id;
  RAISE notice '% %', sqlstate, sqlerrm;

  select load_log(l_load_id, l_step_id, 'EDW_TRADE_MATCH  COMPLETED with ERROR ===', 0, 'O')
  into l_step_id;

  PERFORM load_error_log('genesis2.lp_load_missed_trades_edw',  'I', REPLACE(sqlerrm, ''::text, ''::text), l_load_id);
	return -1; --RAISE;

end;$function$
;


------------------------------------------------------

with strong as (select trml.secondary_exch_exec_id,
                       tr.secondary_exch_exec_id,
                       trml.exec_id as edw_exec_id,
                       tr.exec_id,
                       trml.trade_record_time,
                       tr.trade_record_time,
                       trml.exchange_id,
                       tr.exchange_id,
                       trml.exch_exec_id,
                       tr.exch_exec_id,
                       trml.order_id,
                       tr.order_id,
                       trml.client_order_id,
                       tr.client_order_id,
                       trml.secondary_order_id,
                       tr.secondary_order_id,
                       trml.last_qty,
                       tr.last_qty,
                       trml.last_px,
                       tr.last_px,
                       trml.instrument_id,
                       tr.instrument_id,
                       tr.side,
                       trml.side
                from staging.trade_record_missed_lp trml
                         join genesis2.trade_record tr
                              on (trml.date_id = tr.date_id and trml.instrument_id = tr.instrument_id and
                                  tr.is_busted = 'N' and tr.last_qty = trml.last_qty and tr.last_px = trml.last_px and
                                  tr.exchange_id = 'BLAZE' and
                                  trml.secondary_exch_exec_id = tr.exch_exec_id) -- strong matching
                where trml.date_id = 20231002
                  and trml.subsystem_id = 'OMS_EDW'
                  and trml.trade_record_id is null
                  and trml.is_busted = 'N')
   , fuz1 as (select trml.secondary_exch_exec_id,
                     tr.secondary_exch_exec_id,
                     trml.exec_id as edw_exec_id,
                     tr.exec_id,
                     trml.trade_record_time as trml_trt,
                     tr.trade_record_time as tr_trt,
                     trml.exchange_id,
                     tr.exchange_id,
                     trml.exch_exec_id,
                     tr.exch_exec_id,

                     trml.order_id,
                     tr.order_id,
                     trml.client_order_id,
                     tr.client_order_id,
                     trml.secondary_order_id,
                     tr.secondary_order_id,
                     trml.last_qty,
                     tr.last_qty,
                     trml.last_px,
                     tr.last_px,
                     trml.instrument_id,
                     tr.instrument_id,
                     tr.side,
                     trml.side
              from staging.trade_record_missed_lp trml
                       join genesis2.trade_record tr
                            on (trml.date_id = tr.date_id and trml.instrument_id = tr.instrument_id and
                                tr.is_busted = 'N' and tr.last_qty = trml.last_qty and tr.last_px = trml.last_px
                                and tr.exchange_id = 'BLAZE'
                                --and trml.secondary_exch_exec_id = tr.exch_exec_id) -- fuzzy matching #1
                                and trml.side = tr.side
                                )
              where trml.date_id = 20231002
                and trml.subsystem_id = 'OMS_EDW'
                and trml.trade_record_id is null
                and trml.is_busted = 'N'

              )
select *
from fuz1
where trml_trt - tr_trt > '60 seconds'::interval
except
select *
from strong trml;

select blaze_account_alias, trml.secondary_exch_exec_id, *
from staging.trade_record_missed_lp trml
where date_id = 20231002
and instrument_id = 99444929
and last_px = 30.38
and last_qty = 160
and side = '1'
and exec_id = -1385506569;

select tr.exch_exec_id, *
from genesis2.trade_record tr
where date_id = 20231002
and instrument_id = 99444929
and last_px = 30.38
and last_qty = 160
and side = '1'
and row_to_json(tr)::text ilike '%716001344268%';


select * from genesis2.trade_record
where exec_id = 44152114148
and date_id;


select trml.secondary_exch_exec_id,
       tr.secondary_exch_exec_id,
       trml.exec_id           as edw_exec_id,
       tr.exec_id,
       trml.trade_record_time as trml_trt,
       tr.trade_record_time   as tr_trt,
       trml.exchange_id,
       tr.exchange_id,
       trml.exch_exec_id,
       tr.exch_exec_id,

       trml.order_id,
       tr.order_id,
       trml.client_order_id,
       tr.client_order_id,
       trml.secondary_order_id,
       tr.secondary_order_id,
       trml.last_qty,
       tr.last_qty,
       trml.last_px,
       tr.last_px,
       trml.instrument_id,
       tr.instrument_id,
       tr.side,
       trml.side
from staging.trade_record_missed_lp trml
         join genesis2.trade_record tr
              on (trml.date_id = tr.date_id and trml.instrument_id = tr.instrument_id and
                  tr.is_busted = 'N'
                      and tr.last_qty = trml.last_qty
                      and tr.last_px = trml.last_px
                  and tr.exchange_id = 'BLAZE'
                  --and trml.secondary_exch_exec_id = tr.exch_exec_id) -- fuzzy matching #1
                  and trml.side = tr.side
                  )
where trml.date_id between :start_date_id and :end_date_id
  and tr.date_id between :start_date_id and :end_date_id
  and trml.subsystem_id = 'OMS_EDW'
  and trml.trade_record_id is null
  and trml.is_busted = 'N'
and tr.trade_record_id not in (select trade_record_id from staging.trade_record_missed_lp where date_id between :start_date_id and :end_date_id)


select abs(('2023-10-05'::timestamp - clock_timestamp())::interval) < '30 seconds'::interval


select abs(extract(epoch from ('2023-10-05 00:01'::timestamp - '2023-10-05 00:00:55'::timestamp))) > extract(epoch from '10 seconds'::interval)

select distinct mapping_logic from staging.trade_record_missed_lp
where date_id > 20230301;

select min(date_id) from staging.trade_record_missed_lp
where date_id > 20230301;

select  from genesis2.trade_record


2, 5, 6, 8, 9, 10, 11