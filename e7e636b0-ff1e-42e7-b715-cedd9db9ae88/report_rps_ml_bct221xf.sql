-- DROP FUNCTION dash_reporting.get_mlbccequitieslate(timestamp);
select * from dash360.report_rps_ml_bct221xf(in_start_date_id := 20231201, in_end_date_id := 20231201)

CREATE or replace FUNCTION dash360.report_rps_ml_bct221xf(in_start_date_id int4, in_end_date_id int4)
 RETURNS table (ret_row text)
 LANGUAGE plpgsql
AS $function$

-- [NL] 2021/04/22
-- 1. Added more:
	-- and AC.ACCOUNT_NAME in ('U670015','CBOEU670015','ABRAMSOND','JERROLDE','9585X001','JESS1','JESS1-TRAD','4ZJX1309','4ZJX1209','JESS2','JESS2-TRAD','WBULL')
 	-- and AC.TRADING_FIRM_ID in ('ebseqtc','equitec02')
-- [NL] 2021/05/05: rewitten
-- [NL] 2021/05/05: renamed
-- [SY] 2021/06/11: Added condition order_id > 0 to exclude Blaze manual trades
-- [NL] 2021/07/07: section with non-allocated equity orders ( 88 blotter ) should contain all not allocated trades disregard account/trade time; added misc fees
-- [SY] 2022/10/28: Rec_id field for 'AO' case has been updated due to the fact order_id reached 11 digits in DB https://dashfinancial.atlassian.net/browse/DS-5890
-- [NL] 2022/11/03: when ac.nscc_mpid <> 'DFIN' and coalesce(ae.clearing_account_number,'3Q800806') = '3Q800809' then '3Q800809' (request to use 3Q800809 when configured)
-- [NL] 2022/11/09: when ac.nscc_mpid <> 'DFIN' and coalesce(ae.account_executive_number,'806') = '809' then '3Q800809'
-- [NL] 2023/07/11: start using mv_active_account_snapshot; added eq_rt_allocation_enabled condition
-- [OS] 2023/12/09: DEVREQ-3801 renamed from dash_reporting.get_mlbccequitieslate into dash360.report_rps_ml_bct221xf.
--      returns table instaed of refcursor, interval date_id as an input parameter

declare
  l_load_id int;
  l_step_id int;
  row_cnt int;

begin
	select nextval('public.load_timing_seq') into l_load_id;
	l_step_id:=1;
	select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ml_bct221xf STARTED ====', 0, 'O')
	into l_step_id;


	select public.load_log(l_load_id, l_step_id, 'interval is = ' || concat_ws(' - ', in_start_date_id::text, in_end_date_id::text), 1, 'O')
	into l_step_id;

	--Creating add temporary tables -- begin
    drop table if exists t_misc_fee;
	create temp table t_misc_fee
	as
	select * from staging.misc_fee mf;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'misc_fee', row_cnt, 'I')
	into l_step_id;

	drop table if exists t_active_account_snapshot;
	create temp table t_active_account_snapshot
	as
	select * from mv_active_account_snapshot;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 't_active_account_snapshot', row_cnt, 'I')
	into l_step_id;
	create index "i_account_id" on t_active_account_snapshot using btree(account_id);


	--Creating add temporary tables -- end


--start
    create temp table t_trade on commit drop as
    select tr.date_id                                                  as trade_date,
           tr.instrument_id,
           tr.side,
           ac.account_name,
           ac.eq_order_capacity,
           ac.trading_firm_id,
           sum(tr.last_qty)                                            as day_cum_qty,
           sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as day_avg_px,
           max(exec_id)                                                as exec_id,
           i.symbol || i.symbol_suffix                                 as symbol_name,
           i.symbol_suffix
    from genesis2.trade_record tr
             inner join genesis2.instrument i on (i.instrument_id = tr.instrument_id and i.symbol not in
                                                                                         (select test_symbol from dash_reporting.test_symbol_tb))
             inner join t_active_account_snapshot ac on (ac.account_id = tr.account_id)
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and i.instrument_type_id = 'E'
      and tr.order_id > 0 /* Exclude Blaze manual trades */
      and (tr.trade_record_time::time >= '17:15'::time
        or ac.account_name in
           ('U670015', 'CBOEU670015', 'ABRAMSOND', 'JERROLDE', '9585X001', 'JESS1', 'JESS1-TRAD', '4ZJX1309',
            '4ZJX1209', 'JESS2', 'JESS2-TRAD', 'WBULL')
        or ac.trading_firm_id in ('ebseqtc', 'equitec02', 'ioniccap', 'ionicap02')
        )
      and ac.eq_mpid = 'BELZ'
      and ac.eq_report_to_mpid = 'MLCB'
      and ac.eq_real_time_report_to_mpid is NULL
      and (tr.last_mkt <> 'W' or ac.account_name <> 'Stifel')
    group by tr.date_id, tr.instrument_id, tr.side, ac.account_name, ac.eq_order_capacity, ac.trading_firm_id, i.symbol,
             i.symbol_suffix;

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 't_trade', row_cnt, 'I')
    into l_step_id;


	-- allocations and orders
    create temp table t_eq_alloc on commit drop as
    select 3                                                                                                as ord_flag_1,
           al.alloc_instr_id                                                                                as ord_flag_2,
           'ALLOC'                                                                                          as rec_type,
           al.date_id                                                                                       as trade_date,
           ac.account_id,
           ca.clearing_account_number,
           i.symbol,
           i.symbol_suffix,
           0                                                                                                as order_id,
           al.avg_px,
           ae.alloc_qty                                                                                     as alloc_qty,
           al.side,
           ca.account_executive_number,
           al.create_time                                                                                   as create_time,
           'A' || lpad(abs(ae.alloc_instr_id)::text, 9, '0') || lpad(ae.clearing_account_id::text, 10, '0') as rec_id
    from genesis2.allocation_instruction_entry ae
             inner join genesis2.allocation_instruction al
                        on (al.alloc_instr_id = ae.alloc_instr_id and al.is_deleted <> 'Y')
             inner join genesis2.instrument i on (al.instrument_id = i.instrument_id and i.instrument_type_id = 'E' and
                                                  i.symbol not in
                                                  (select test_symbol from dash_reporting.test_symbol_tb))
             inner join genesis2.clearing_account ca
                        on (ae.clearing_account_id = ca.clearing_account_id and ca.is_deleted = 'N' and
                            ca.clearing_account_type <> '3')
             inner join t_active_account_snapshot ac on ca.account_id = ac.account_id and
                                                        (ac.eq_report_to_mpid = 'MLCB' or
                                                         (ac.nscc_mpid <> 'DFIN' and ac.eq_real_time_report_to_mpid = 'MLCB'))

    where ae.alloc_qty > 0
      and al.date_id between in_start_date_id and in_end_date_id
      and (al.create_time::time >= '17:15'::time
        or ac.account_name in
           ('U670015', 'CBOEU670015', 'ABRAMSOND', 'JERROLDE', '9585X001', 'JESS1', 'JESS1-TRAD', '4ZJX1309',
            '4ZJX1209', 'JESS2', 'JESS2-TRAD', 'WBULL')
        or ac.trading_firm_id in ('ebseqtc', 'equitec02', 'ioniccap', 'ionicap02')
        )
      and ae.alloc_instr_id in (select alloc_instr_id
                                from genesis2.alloc_instr2trade_record atr
                                where atr.date_id between in_start_date_id and in_end_date_id)
      and coalesce(ac.eq_rt_allocation_enabled, 'N') <> 'Y'

    union all

    select 4                                                           as ord_flag_1,
           tr.order_id                                                 as ord_flag_2,
           'ALLOC'                                                     as rec_type,
           tr.date_id                                                  as trade_date,
           ac.account_id,
           dca.clearing_account_number,
           i.symbol,
           i.symbol_suffix,
           tr.order_id,
           sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
           sum(tr.last_qty)                                            as alloc_qty,
           tr.side,
           dca.account_executive_number,
           max(tr.order_process_time)                                  as create_time,
--			'AO'||lpad(dca.clearing_account_id::text,8,'0')||lpad(tr.order_id::text,10,'0') as rec_id
           'AT' || lpad(tr.order_id::text, 18, '0')                    as rec_id
    from genesis2.trade_record tr
             inner join genesis2.instrument i on (i.instrument_id = tr.instrument_id and i.symbol not in
                                                                                         (select test_symbol from dash_reporting.test_symbol_tb))
             inner join t_active_account_snapshot ac on (ac.account_id = tr.account_id)
             inner join genesis2.clearing_account dca
                        on (tr.account_id = dca.account_id and dca.is_default = 'Y' and dca.is_deleted = 'N' and
                            dca.market_type = 'E' and dca.clearing_account_type <> '3')
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and i.instrument_type_id = 'E'
      and tr.order_id > 0 /* Exclude Blaze manual trades */
      -- if trade is not allocated it is reported in this file anyway
      --and (tr.trade_record_time::time >= '17:15'::time
      --	 or ac.account_name in ('U670015','CBOEU670015','ABRAMSOND','JERROLDE','9585X001','JESS1','JESS1-TRAD','4ZJX1309','4ZJX1209','JESS2','JESS2-TRAD','WBULL')
      --	 or ac.trading_firm_id in ('ebseqtc','equitec02','ioniccap','ionicap02')
      --	)
      and (ac.eq_report_to_mpid = 'MLCB' or (ac.nscc_mpid <> 'DFIN' and ac.eq_real_time_report_to_mpid = 'MLCB'))
      and not exists (select 1
                      from genesis2.alloc_instr2trade_record atr
                      where atr.trade_record_id = tr.trade_record_id)
    group by tr.date_id, ac.account_id, dca.clearing_account_number, dca.clearing_account_id,
             dca.account_executive_number, tr.instrument_id, tr.side, i.symbol, i.symbol_suffix, tr.order_id;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 't_eq_alloc', row_cnt, 'I')
    into l_step_id;

	return query
		select
		rpad(case
				when REC_TYPE = 'TRL' then REC||lpad((REC_NUM-2)::text, 10, '0')
				else REC
			 end, 1000, ' ')
		from
		(
		 select ORD_FLAG_1, ORD_FLAG_2, row_number() over() as REC_NUM, REC, REC_TYPE
		 from
		 	(
            select 1 as ord_flag_1, 0 as ord_flag_2, 'HDR' as rec_type,

             'BCT221XF' ||--1-8
             '  ' ||--9-10
             'ENTRY DATE: ' ||--11-22
             to_char(current_timestamp, 'YYYYMMDD') ||--23-30
             ' ' ||--31-31
             to_char(current_timestamp, 'HH24MI') ||--32-35
             rpad(' ', 14) ||--36-49
             'E' ||--50 File type
             '  1'--File seq nbr 51-53

            as REC

            union all

            select 5 as ord_flag_1, 99999 as ord_flag_2, 'TRL' as rec_type,

             '99999999' ||--1-8
             ' ' ||
             'RECORD COUNT: '--10-23

            as REC

            union all

            select  2 as ord_flag_1, t.exec_id as ord_flag_2, 'TRADE' as rec_type,
			--#1
            '3Q800797'||--CA.CLEARING_ACCOUNT_NUMBER||

			'S'||--SEC_ID_TYPE -9
			rpad(coalesce(t.symbol_name,''), 22, ' ')||--10-31
			'  '||--32-33
			'4'||--34 Price code type
			to_char(round(t.day_avg_px,6), 'FM0999V9999990')||--35-45
			lpad((t.day_cum_qty)::text, 9, '0' )||--46-54 Qty
			case
			  when t.symbol_suffix = 'WI' then '00000000'
			  --else to_char(public.get_business_date(t.trade_date::text::date, 2), 'YYYYMMDD')
			  else to_char(public.get_settle_date_by_instrument_type(t.trade_date::text::date, 'E'), 'YYYYMMDD')
			end||--55-62 Settle Date
			to_char(t.trade_date, 'YYYYMMDD')||--63-70 Trade Date
			case
			  when t.side = '1' then '1'
			  when t.side in ('2','5','6') then '2'
			  else '1'
			end||
			case
			  when t.side in ('5','6') then '1'
			  else ' '
			end||--SHORT IND -72
			rpad(' ', 5)||--73-77
			'M3'||--78-79
			rpad(' ', 10)||--filler 80-89
			'0'||--Trade Action --90
			'2'||--Commission Type 91
			'000000000'||--Commission Amount 92-100
			'0000BELZ'||--Opposing Account 101-108
			'0'||--109: no data in pos 214-333
			'   '||--110, 111, 112
			'2'||--113
			rpad(' ', 17)||--114-122;123-126;127-130;
			case
			  when t.symbol_suffix = 'WI' then '1'
			  else ' '
			end||--131;
			'   '||--132;133-134 (exch 1)
			'   '||--135;136-137 (exch 2)
			'   '||--138;139-140 (exch 3)
			' '||--141
			rpad(' ', 6)||--142-147 alt sec num
			t.eq_order_capacity||--148
			'A'||--149
			rpad(' ', 189)||--150-338
			'CC2'||--339-341
			' '|| --342
			case
				when t.account_name in ('dashtest','dasherror') then 'C'
				else 'A'
			end||--343
			rpad(' ', 9)||--344;345-352;
			to_char(t.trade_date, 'HH24MISS')||--353-358
			rpad(' ', 161)||--359-519
			' '||--SECT-31-FEE 520
			'Y'||--521 TBD
			rpad(' ', 197)||--522-718
			' '||--719
			rpad(' ', 20)||--720-739
			rpad(' ', 66)||--740-805
			lpad((t.exec_id)::text, 20,'0') --806-825

			as REC
			from t_trade t


            ----------------------equities allocations-----------------------------
			-----------------------------------------------------------------------
			union all


			select ae.ord_flag_1,ae.ord_flag_2,ae.rec_type,
			case
				when ac.eq_report_to_mpid = 'MLCB' then lpad(ae.clearing_account_number, 8, '0')
				when ac.nscc_mpid <> 'DFIN' and coalesce(ae.clearing_account_number,'3Q800806') = '3Q800809' then '3Q800809'
				when ac.nscc_mpid <> 'DFIN' and coalesce(ae.account_executive_number,'806') = '809' then '3Q800809'
				else '3Q800806'
			end||--Clearing Account#
			'S'||--SEC_ID_TYPE -9
			rpad(coalesce(ae.symbol,'')||coalesce(ae.symbol_suffix,''), 22, ' ')||--10-31
			'  '||--32-33
			'4'||--34 Price code type

			to_char(round(ae.avg_px,ac.eq_reporting_avgpx_precision), 'FM0999V9999990')||--35-45 --BO -> AL

			lpad((ae.alloc_qty)::text, 9, '0' )||--46-54 Qty
			case
			  when ae.symbol_suffix = 'WI' then '00000000'
			  --else to_char(public.get_business_date(l_date_id::text::date, 2), 'YYYYMMDD')
			  else to_char(public.get_settle_date_by_instrument_type(ae.trade_date::text::date, 'E'), 'YYYYMMDD')
			end||--55-62 Settle Date

			ae.trade_date::text||--63-70 Trade Date

		    case
		    	when ae.side in ('5','6') then '2'
		    	when ae.side in ('1','2') then ae.side
		    	else '1'
		    end||
			case
			  when ae.side in ('5','6') then '1'
			  else ' '
			end||--SHORT IND -72
			rpad(' ', 5)||--73-77
			case
			  --#3
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then '88'
			  --BO
			  else '8Z'
			end||--78-79
			rpad(' ', 10)||--filler 80-89
			'0'||--Trade Action --90
			case
			  --#4
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then '2'
			  when  round(ac.eq_commission * ae.alloc_qty, 2) > 0 then '7'
			  else '2'
			end||--Commission Type 91
			case
			  --#5
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then '000000000'
              --
			  when ac.eq_commission_type = '1' then to_char(coalesce(ac.eq_commission,0) * ae.alloc_qty + coalesce(mf.misc_fee_rate,0)
			  												, 'FM099999V990')
			  when ac.eq_commission_type = '7' then to_char(coalesce(ac.eq_commission,0) * 0.0001 * ae.avg_px * ae.alloc_qty + coalesce(mf.misc_fee_rate,0)
			  												, 'FM099999V990')
			end||--Commission Amount 92-100
			case
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then '3Q800797'
			  else '3Q800797'
			end||--Opposing Account 101-108
			'4'||--109, all accounts
			'   '||--110, 111, 112
			'2'||--113
			rpad(' ', 9)||--114-122;
			lpad(coalesce(ae.account_executive_number, '0')::text, 4, '0')||--123-126;
			rpad(' ', 4)||--127-130;
			case
			  when ae.symbol_suffix = 'WI' then '1'
			  else ' '
			end||--131;
			case
			  --#6
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then '100'
			  --
			  else '100'
			end||--132;133-134 (exch 1)
			'   '||--135;136-137 (exch 2)
			'   '||--138;139-140 (exch 3)
			' '||--141
			rpad(' ', 6)||--142-147 alt sec num
			ac.eq_order_capacity||--148
			' '||--149
			 --150-213 should be empty
			rpad(' ', 64)||--150-213 (64)

			'Dash may receive(pay) rebates(fees) related to this trade. Details can be found via DASH360 or upon written request.    '||--214-333, all accounts
			rpad(' ', 5)||--334-338 (5)
			--decode(AC.TRADING_FIRM_ID, 'russell', 'CC1', 'greenstrt', 'CC4', 'fbrcm', 'CC2', '   ')||--339-341
			case
				when ac.trading_firm_id = 'russell' then 'CC1'
				when ac.trading_firm_id = 'greenstrt' then 'CC4'
				when ac.trading_firm_id = 'fbrcm' then 'CC2'
			else '   '
			end ||
			' '|| --342
			case
			  --#7
			  	when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then 'A'
			  --
			  	else ' '
			end||--343
			rpad(' ', 9)||--344;345-352;
			to_char(ae.create_time, 'HH24MISS')||--to_char(TR.EXEC_TIME, 'HH24MISS')||--353-358
			rpad(' ', 161)||--359-519
			case
			  --#8
			  when ac.nscc_mpid <> 'DFIN' and ac.nscc_mpid is not NULL then ' '
			  else ' ' --Flip/Default
			end||--SECT-31-FEE 520
			'Y'||--521 TBDl
			rpad(' ', 197)||--522-718
			' '||--719
			rpad(' ', 20)||--720-739
			rpad(' ', 66)||--740-805
			ae.rec_id--806-825

                as REC

            from t_eq_alloc ae
                     inner join t_active_account_snapshot ac on ac.account_id = ae.account_id
                -- commissions !!!
                     left join staging.commission_set cse
                               on (cse.account_id = ae.account_id and cse.instrument_type_id = 'E' and cse.is_deleted = 'N'
                                       and coalesce(to_char(end_date, 'YYYYMMDD')::int, ae.trade_date + 1) > ae.trade_date)
                     left join t_misc_fee mf
                               on (mf.commission_set_id = cse.commission_set_id and mf.misc_fee_name_id = 4 and
                                   mf.is_deleted = 'N')

		order by  ord_flag_1, ord_flag_2
		) A
	) B;

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
    into l_step_id;

-- Finish


end;
$function$
;
