-- DROP FUNCTION dash_reporting.get_equitiesmlpro(timestamp);
select * from dash360.report_rps_ml_pro_equities(in_start_date_id := 20231101, in_end_date_id := 20231130)

CREATE or replace FUNCTION dash360.report_rps_ml_pro_equities(in_start_date_id int4, in_end_date_id int4)
    RETURNS table
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$

    -- [NL] 2021/04/02
-- 1. format correction (bundles BB)
-- 2. ftr.trade_record_time::time < '16:55'::time - not actual for this report
-- 3. ftr.trade_record_time::time < '16:40'::time - not actual for this report
-- 4. formatting
-- 5. 'clearbm','clearprop'  - excluded from allocations section

-- [NL] 2021/04/06
-- 1. 'clearbm','clearprop' - more corrections

-- [NL] 2021/04/07
-- 1. date format in the header

-- [NL] 2021/04/16
-- 1. 'logicadca','tiberius','esmark' - removed
-- 2. 'keystne01' - added
-- 3. 'vtrader','vtbrokers','vtsterlin','ivycapccm','lkhillccm','monrchccm' - removed

-- [NL] 2021/04/19
-- 1. 'victormlp','tomsmith','ketchum','cornersto','dashcorne','ebseqtc' - removed
-- [SO] 2023/12/08 https://dashfinancial.atlassian.net/browse/DEVREQ-3802
-- migrated into dash360
-- returns table instead of refcursor
-- interval date_id as an input parameter instead of the single timestamp


declare
    l_load_id int;
    l_step_id int;
    row_cnt   int;


 ----------=======not tested yet=============---------------------

begin
      select nextval('public.load_timing_seq') into l_load_id;
      l_step_id := 1;
      select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ml_pro_equities STARTED ====', 0, 'O')
      into l_step_id;


   select public.load_log(l_load_id, l_step_id,
                          'interval is = ' || concat_ws(' - ', in_start_date_id::text, in_end_date_id::text), 1, 'O')
   into l_step_id;

   --Creating add temporary tables -- begin

   drop table if exists t_misc_fee;
   create temp table t_misc_fee
   as
   select * from staging.misc_fee mf;

   get diagnostics row_cnt = row_count;
   select public.load_log(l_load_id, l_step_id, 'misc_fee', row_cnt, 'I')
   into l_step_id;

   create index "i_misc_fee_name_id" on t_misc_fee using btree (misc_fee_name_id);


	drop table if exists t_active_account_snapshot;
	create temp table t_active_account_snapshot
	as select * from genesis2.mv_active_account_snapshot
   where eq_report_to_mpid = 'MLCO';

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 't_active_account_snapshot', row_cnt, 'I')
	into l_step_id;
	create index "i_account_id" on t_active_account_snapshot using btree(account_id);

	--Creating add temporary tables -- end

      create temp table t_t on commit drop as
      select 2                     as ord_flag_1,
             ftr.exec_id           as ord_flag_2,
             1                     as ord_flag_2x,
             ftr.trade_record_time as exec_time,
             ftr.last_qty          as last_qty,
             ftr.last_px           as last_px,
             ac.account_name,
             ac.account_id,
             ac.trading_firm_id,
             ac.eq_order_capacity,
             dca.clearing_account_number,
             ac.eq_mpid,
             ac.eq_executing_service,
             ac.eq_commission_type,
             ac.eq_commission,
             ftr.side,
             i.symbol,
             i.symbol_suffix
      from genesis2.trade_record ftr
               inner join t_active_account_snapshot ac on (ac.account_id = ftr.account_id)
               inner join genesis2.clearing_account as dca
                          on (dca.account_id = ac.account_id and dca.is_deleted = 'N' and dca.market_type = 'E' and
                              dca.is_default = 'Y')
               inner join genesis2.instrument i on (i.instrument_id = ftr.instrument_id and i.symbol not in
                                                                                            (select test_symbol from dash_reporting.test_symbol_tb))
      where ftr.date_id between in_start_date_id and in_end_date_id
        and ftr.is_busted = 'N'
        and ac.eq_report_to_mpid = 'MLCO'
        and ac.trading_firm_id <> 'ctctrad01'
        and i.instrument_type_id = 'E';

      create temp table t_main_cte on commit drop as
      select ftr.date_id,
             ftr.open_close,
             ftr.order_id                                       as order_id,
             ftr.instrument_id,
             ftr.account_id,
             ftr.side,
             coalesce(al.alloc_instr_id, 0)                     as alloc_instr_id,
             max(ftr.order_process_time)                        as process_time,
             sum(last_qty)                                      as day_cum_qty,
             sum(last_qty * last_px) / nullif(sum(last_qty), 0) as day_avg_px,
             max(exec_id)                                       as exec_id
      from genesis2.trade_record ftr
               left join genesis2.alloc_instr2trade_record atr
                         on (ftr.trade_record_id = atr.trade_record_id and ftr.date_id = atr.date_id)
               left join genesis2.allocation_instruction al
                         on (al.alloc_instr_id = atr.alloc_instr_id and AL.IS_DELETED <> 'Y' and
                             al.date_id between in_start_date_id and in_end_date_id)
               join genesis2.instrument I on ftr.instrument_id = I.instrument_id
      where ftr.date_id between in_start_date_id and in_end_date_id
        and is_busted = 'N'
        and I.instrument_type_id = 'E'
      group by ftr.date_id, ftr.open_close, order_id, ftr.instrument_id, ftr.account_id, ftr.side, al.alloc_instr_id;


      return query
	    select rpad(REC_TYPE||
					case
						when REC_TYPE = 'UHDR' then ' '
						when REC_TYPE in ('AA','BB') then lpad((REC_NUM/2)::text,5,'0')
						else ' '||REC_NUM
					end||
				REC, 200, ' ') from
		(
		select ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3, row_number() over() as REC_NUM, REC, REC_TYPE
		from
		 (select distinct ORD_FLAG_1, ORD_FLAG_2,  ORD_FLAG_2X, ORD_FLAG_3, REC_TYPE, REC
			from
				 ( select 1 as ORD_FLAG_1, 0 as ORD_FLAG_2, 0 as ORD_FLAG_2X, 0 as ORD_FLAG_3, 'UHDR' as REC_TYPE,
					  to_char(current_timestamp, 'YYYYDDD')||
					  rpad(' ', 12)||--13-24
					  --to_char(systimestamp at time zone DBTIMEZONE_GENESIS2, 'HH24MI')||
					  '1700'||
					  rpad('SDS', 20, ' ')||
					  rpad(' ', 152)--filler
					  as REC
				   union all
				   select 6 as ORD_FLAG_1, 99999 as ORD_FLAG_2,  1 as ORD_FLAG_2X, 1 as ORD_FLAG_3,  'UTRL' as REC_TYPE,
				   '' as REC
				  ) HT
		union all

			  ---------------------------Equities trades fill by fill (from T)-----------------------

          select t_t.ORD_FLAG_1,
                 t_t.ORD_FLAG_2,
                 t_t.ORD_FLAG_2X,
                 1    as ORD_FLAG_3,
                 'AA' as REC_TYPE,

                 to_char(t_t.EXEC_TIME, 'YYYYMMDD') ||
                     --suppressed allocations:
                     --('vtrader','vtbrokers','vtsterlin', 'victormlp','tomsmith','ketchum','cornersto','dashcorne','ebseqtc','bluefin','ivycapccm','lkhillccm','monrchccm','marathon','ctctrad01','LPTF51','lamberson','ctctrad02')
                 case
                     when t_t.ACCOUNT_NAME in ('EVRMIAEMS', 'IAEJERICA', 'EVRIBIAEMS', 'IAEMSTUNG')
                         then '53966666D5' --'iaems'
                     when t_t.ACCOUNT_NAME in
                          ('TWINIAEHS', 'LAFERIAEHS', 'LAFERDESKHS', 'TWINDESKHS', 'OPUSIAEHS', 'OPUSDESKHS',
                           'JVLIAEHS', 'JVLDESKHS') then '53966665D7' --'iaehs'
                     when t_t.TRADING_FIRM_ID in
                          ('bluefin', 'marathon', 'summit01', 'ctctrad01', 'lamberson', 'clearbm', 'clearprop',
                           'keystne01') then rpad(t_t.CLEARING_ACCOUNT_NUMBER, 10, ' ')
                     when t_t.TRADING_FIRM_ID in ('LPTF51') then '60313300D6'
                     else rpad(t_t.CLEARING_ACCOUNT_NUMBER, 10, ' ')
                     --83078665D9
                     end ||--] Clearing Account
                 case
                     when t_t.SIDE = '1' then 'B'
                     when t_t.SIDE in ('2', '5', '6') then 'S'
                     end ||
                 case
                     when t_t.TRADING_FIRM_ID in ('bluefin') then 'BFIN'
                     when t_t.TRADING_FIRM_ID in ('marathon') then 'MARA'
                     when t_t.TRADING_FIRM_ID in ('summit01', 'clearbm', 'clearprop') then 'WBPX'
                     when t_t.TRADING_FIRM_ID in ('ctctrad01') then 'CTCA'
                     when t_t.TRADING_FIRM_ID in ('LPTF51', 'lamberson') then 'CONS'
                     when t_t.TRADING_FIRM_ID in ('keystne01') then 'MLCO'
                     else 'IAEC'
                     end || -- executing broker 27-30
                 case
                     when t_t.TRADING_FIRM_ID in ('LPTF51', 'lamberson') then 'DFIN'
                     else rpad(' ', 4)
                     end ||--Receive/Deliver Broker 31-34

                 case
                     when t_t.EQ_MPID = 'BELZ' then '0627' --!
                     when t_t.EQ_MPID = 'DFIN' then '0161' --!
                     else rpad(' ', 4)
                     end ||--Receive/Deliver Broker Number
                 'N' ||--Exchange 39
                 to_char(t_t.EXEC_TIME, 'HH24MI') ||
                 to_char(t_t.EXEC_TIME, 'SSss') ||
                 rpad(' ', 6) ||--filler
                 lpad(t_t.LAST_QTY::text, 9, '0') ||
                 rpad(coalesce(t_t.SYMBOL, '') || coalesce(t_t.SYMBOL_SUFFIX, ''), 10, ' ') ||
                     --rpad(T.SYMBOL||
                     --case
                     --	when T.SYMBOL_SUFFIX is not null then ' '||T.SYMBOL_SUFFIX
                     -- end, 10, ' ')||
                 case
                     when t_t.SYMBOL_SUFFIX is not null then 'S'
                     else ' '
                     end ||--73
                 'TH' ||--Blotter Code or Put/Call 74-75
                 ' ' ||--Bill/No Bill Code
                 rpad(' ', 4) ||--Receive/Deliver badge
                 coalesce(t_t.EQ_ORDER_CAPACITY, ' ') ||--Agency
                 'N' ||--Contract Code
                 ' ' ||--Misc.trade type indicator 1 (P = Prime broker Trade)
                 ' ' ||--Multi-contra flag - are we?
                 to_char(round(t_t.LAST_PX, 6), 'FM09999V99999990') ||
                 rpad(' ', 4) ||--Executing Badge
                 rpad(' ', 4) || rpad(' ', 4) || rpad(' ', 4) ||--QSR Branch, QSR Seq Num, Customer Mnemonic
                 rpad(' ', 13) --Reserved
                 --Filler, External RefNo, Action Code, Exception Code - filled by MLPRO
                 --filler
                 --total length must be 200
                      as REC
          from t_t

		union all

          select t_t.ORD_FLAG_1,
                 t_t.ORD_FLAG_2,
                 t_t.ORD_FLAG_2X,
                 2    as ORD_FLAG_3,
                 'BB' as REC_TYPE,
                 to_char(t_t.EXEC_TIME, 'YYYYMMDD') ||--trade date
                 rpad(' ', 5) ||--filler
                 ' ' ||--Rate Id calculated from executing service --blank
                 rpad(' ', 8) ||--Commission Rate/Amount   - spaces according to orig spec
                 -----------------------------------------------
                 case
                     when t_t.TRADING_FIRM_ID in ('') then '05' || to_char(t_t.EQ_COMMISSION, 'FM099V99990')
                     else '  ' || rpad(' ', 8)
                     end ||
                     --'  '||--misc. rate id1; if rate id = 1 - cents per share;
                     --rpad(' ', 8)||--misc rate 1; if rate id = b;
                     -----------------------------------------------
                 rpad(coalesce(t_t.EQ_EXECUTING_SERVICE, ' '), 4, ' ') ||--executing service
                 rpad(' ', 8) ||--settle date
                 case
                     when t_t.SIDE in ('5', '6') then 'S'
                     else ' '
                     end ||--short sale
                 rpad(' ', 3) ||--RR/BRANCH
                 ' ' ||--option code
                 rpad(' ', 14) ||--options parameters
                 'DASH' ||--Client Id
                 '  ' || rpad(' ', 15) ||--misc rate id2, misc rate 2
                 'H' ||--House/Both
                 '01' ||--Firm
                 '   ' ||--filler
                 rpad(' ', 10) ||--markup
                 case
                     when t_t.TRADING_FIRM_ID not in
                          ('bluefin', 'marathon', 'summit01', 'LPTF51', 'lamberson', 'clearbm', 'clearprop',
                           'keystne01')
                         then to_char(t_t.LAST_QTY * t_t.LAST_PX, 'FM09999999V990')--principal amount
                     else rpad(' ', 11)
                     end ||
                 rpad(' ', 2) || rpad(' ', 8) ||--misc rate id 3, misc rate 3;
                 case
                     when t_t.TRADING_FIRM_ID in ('') then '55' || rpad('0', 15, '0')
                     else rpad(' ', 2) || rpad(' ', 15)
                     end ||--misc rate id 4, misc rate 4;
                 rpad(' ', 2) || rpad(' ', 10) ||--misc rate id 5, misc rate 5;
                 rpad(' ', 2) || rpad(' ', 15) ||--misc rate id 6, misc rate 6
                 rpad(' ', 10) --filler
                 --External RefNo, Action Code, Exception Code
                 --filler
                 --total length must be 200
                      as REC
          from t_t

				-------------------------------bundles-----------------------------------------
		  union all


          select 4                      as ORD_FLAG_1,
                 AL.ALLOC_INSTR_ID      as ORD_FLAG_2,
                 AE.CLEARING_ACCOUNT_ID as ORD_FLAG_2X,
                 1                      as ORD_FLAG_3,
                 'AA'                   as REC_TYPE,

                 AL.DATE_ID::text ||
                 rpad(CA.CLEARING_ACCOUNT_NUMBER, 10, ' ') ||
                 case
                     when AL.SIDE = '1' then 'B'
                     when AL.SIDE in ('2', '5', '6') then 'S'
                     end ||
                 '0551' ||--rpad(' ', 4) - executing broker 27-30
                 rpad(' ', 4) ||--Receive/Deliver Broker 31-34
                 '0551' ||--Receive/Deliver Broker Number
                 case
                     when AC.TRADING_FIRM_ID in ('vtbrokers', 'vtsterlin') then 'R'
                     else 'X'
                     end ||--Exchange 39
                 '0000' ||--to_char(TR.EXEC_TIME, 'HH24MI')||
                 '0000' ||--to_char(TR.EXEC_TIME, 'SSss')||
                 rpad(' ', 6) ||--filler
                 lpad(AE.ALLOC_QTY::text, 9, '0') ||
                 rpad(coalesce(I.symbol, '') || coalesce(I.symbol_suffix, ''), 10, ' ') ||
                 case
                     when I.SYMBOL_SUFFIX is not null then 'S'
                     else ' '
                     end ||--73
                 'SA' ||--Blotter Code or Put/Call 74-75
                 ' ' ||--Bill/No Bill Code
                 rpad(' ', 4) ||--Receive/Deliver badge
                 coalesce(AC.EQ_ORDER_CAPACITY, ' ') ||--Agency
                 'N' ||--Contract Code
                 'J' ||--Misc.trade type indicator 1 (P = Prime broker Trade)
                 ' ' ||--Multi-contra flag - are we?
                 to_char(AL.AVG_PX, 'FM09999V99999990') ||--DS.DAY_AVG_PX||','||
                 rpad(' ', 4) ||--Executing Badge
                 rpad(' ', 4) || rpad(' ', 4) || rpad(' ', 4) ||--QSR Branch, QSR Seq Num, Customer Mnemonic
                 rpad(' ', 13) --Reserved
                 --Filler, External RefNo, Action Code, Exception Code - filled by MLPRO
                 --filler
                 --total length must be 200
                                        as REC
--select *
          from genesis2.allocation_instruction_entry AE
                   inner join genesis2.allocation_instruction AL
                              on (AE.ALLOC_INSTR_ID = AL.ALLOC_INSTR_ID and AL.IS_DELETED <> 'Y' and
                                  AE.date_id between in_start_date_id and in_end_date_id)
--		  inner join BUNDLE BO on (BO.BUNDLE_ID = AL.BUNDLE_ID)
                   inner join genesis2.instrument I
                              on (AL.INSTRUMENT_ID = I.INSTRUMENT_ID and I.INSTRUMENT_TYPE_ID = 'E' and
                                  I.SYMBOL not in (select TEST_SYMBOL from dash_reporting.test_symbol_tb))
                   inner join genesis2.clearing_account CA
                              on (AE.CLEARING_ACCOUNT_ID = CA.CLEARING_ACCOUNT_ID and ca.is_deleted = 'N' and
                                  CA.MARKET_TYPE = 'E' and CA.CLEARING_ACCOUNT_TYPE <> '3')
                   inner join t_ACTIVE_ACCOUNT_SNAPSHOT AC
                              on (AC.ACCOUNT_ID = CA.ACCOUNT_ID and AC.IS_DELETED <> 'Y' and
                                  AC.EQ_REPORT_TO_MPID = 'MLCO')
          --------------------------------------------
          where AE.ALLOC_QTY > 0
            and AC.TRADING_FIRM_ID not in
                ('bluefin', 'marathon', 'ctctrad01', 'LPTF51', 'lamberson', 'summit01', 'clearbm', 'clearprop',
                 'keystne01')
            and al.date_id between in_start_date_id and in_end_date_id


		union all

          select 4                      as ORD_FLAG_1,
                 AL.ALLOC_INSTR_ID      as ORD_FLAG_2,
                 AE.CLEARING_ACCOUNT_ID as ORD_FLAG_2X,
                 2                      as ORD_FLAG_3,
                 'BB'                   as REC_TYPE,
                 AL.DATE_ID::text ||
                 rpad(' ', 5) ||--filler
                 ' ' ||--Rate Id calculated from executing service --blank
                 rpad(' ', 8) ||--Commission Rate/Amount   - spaces according to orig spec
                 '  ' ||--misc. rate id1; if rate id = 1 - cents per share;
                 rpad(' ', 8) ||--misc rate 1; if rate id = b;
                 rpad(coalesce(AC.EQ_EXECUTING_SERVICE, ' '), 4, ' ') ||
                 rpad(' ', 8) ||--settle date
                 case
                     when AL.SIDE in ('5', '6') then 'S'
                     else ' '
                     end ||--short sale
                 rpad(' ', 3) ||--RR/BRANCH
                 case
                     when AL.OPEN_CLOSE = 'O' then 'O'
                     when AL.OPEN_CLOSE = 'C' then 'X'
                     else ' '
                     end ||--option code: needs to be adjusted
                 rpad(' ', 14) ||--options parameters
                 'DASH' ||--Client Id
                 '  ' || rpad(' ', 15) ||--misc rate id2, misc rate 2
                 'H' ||--House/Both
                 '01' ||--Firm
                 '   ' ||--filler
                 rpad(' ', 10) ||--markup
                 case
                     when AC.TRADING_FIRM_ID not in ('tomsmith', 'ketchum')
                         then to_char(AE.ALLOC_QTY * AL.AVG_PX, 'FM09999999V990')
                     else rpad(' ', 10)
                     end ||
                 rpad(' ', 2) || rpad(' ', 8) ||--misc rate id 3, misc rate 3;
                 rpad(' ', 2) || rpad(' ', 15) ||--misc rate id 4, misc rate 4;
                 -----------SEC Fee-----------------------------------------
                 rpad(' ', 2) || rpad(' ', 10) ||--misc rate id 5, misc rate 5;
                 rpad(' ', 2) || rpad(' ', 15) ||--misc rate id 6, misc rate 6
                 rpad(' ', 10) --filler
                 --External RefNo, Action Code, Exception Code
                 --filler
                 --total length must be 200
                                        as REC
--select *
          from genesis2.allocation_instruction_entry AE
                   inner join genesis2.allocation_instruction AL
                              on (AE.ALLOC_INSTR_ID = AL.ALLOC_INSTR_ID and AL.IS_DELETED <> 'Y')
--		  inner join BUNDLE BO on (BO.BUNDLE_ID = AL.BUNDLE_ID)
                   inner join genesis2.instrument I
                              on (AL.INSTRUMENT_ID = I.INSTRUMENT_ID and I.INSTRUMENT_TYPE_ID = 'E' and
                                  I.SYMBOL not in (select TEST_SYMBOL from dash_reporting.test_symbol_tb))
                   inner join genesis2.clearing_account CA
                              on (AE.CLEARING_ACCOUNT_ID = CA.CLEARING_ACCOUNT_ID and ca.is_deleted = 'N' and
                                  CA.MARKET_TYPE = 'E' and CA.CLEARING_ACCOUNT_TYPE <> '3')
                   inner join t_ACTIVE_ACCOUNT_SNAPSHOT AC
                              on (AC.ACCOUNT_ID = CA.ACCOUNT_ID and AC.IS_DELETED <> 'Y' and
                                  AC.EQ_REPORT_TO_MPID = 'MLCO')
          --------------------------------------------
          where AE.ALLOC_QTY > 0
            and AC.TRADING_FIRM_ID not in
                ('bluefin', 'marathon', 'ctctrad01', 'LPTF51', 'lamberson', 'summit01', 'clearbm', 'clearprop',
                 'keystne01')
            and al.date_id between in_start_date_id and in_end_date_id


		------------------------------------single orders------------------------------
		  union all

          select 5           as ORD_FLAG_1,
                 CL.ORDER_ID as ORD_FLAG_2,
                 1           as ORD_FLAG_2X,
                 1           as ORD_FLAG_3,
                 'AA'        as REC_TYPE,
                 CL.DATE_ID::text ||
                 rpad(coalesce(CA.CLEARING_ACCOUNT_NUMBER, DCA.CLEARING_ACCOUNT_NUMBER), 10, ' ') ||
                 case
                     when CL.SIDE = '1' then 'B'
                     when CL.SIDE in ('2', '5', '6') then 'S'
                     end ||
                 '0551' ||--rpad(' ', 4) - executing broker 27-30
                 rpad(' ', 4) ||--Receive/Deliver Broker 31-34
                 '0551' ||--Receive/Deliver Broker Number
                 case
                     when AC.TRADING_FIRM_ID in ('vtbrokers', 'vtsterlin') then 'R'
                     else 'X'
                     end ||--Exchange 39
                 '0000' ||--to_char(TR.EXEC_TIME, 'HH24MI')||
                 '0000' ||--to_char(TR.EXEC_TIME, 'SSss')||
                 rpad(' ', 6) ||--filler
                 lpad(coalesce(AE.ALLOC_QTY, CL.DAY_CUM_QTY)::text, 9, '0') ||
                 rpad(coalesce(I.symbol, '') || coalesce(I.symbol_suffix, ''), 10, ' ') ||
                     --		  rpad(I.SYMBOL||
--		  case
--			when I.SYMBOL_SUFFIX is not null then ' '||I.SYMBOL_SUFFIX
--		  end, 10, ' ')||
                 case
                     when I.SYMBOL_SUFFIX is not null then 'S'
                     else ' '
                     end ||--73
                 'SA' ||--Blotter Code or Put/Call 74-75
                 ' ' ||--Bill/No Bill Code
                 rpad(' ', 4) ||--Receive/Deliver badge
                 AC.EQ_ORDER_CAPACITY ||--Agency
                 'N' ||--Contract Code
                 'J' ||--Misc.trade type indicator 1 (P = Prime broker Trade)
                 ' ' ||--Multi-contra flag - are we?
                 to_char(CL.DAY_AVG_PX, 'FM09999V99999990') ||--!!!!
                 rpad(' ', 4) ||--Executing Badge
                 rpad(' ', 4) || rpad(' ', 4) || rpad(' ', 4) ||--QSR Branch, QSR Seq Num, Customer Mnemonic
                 rpad(' ', 13) --Reserved
                 --Filler, External RefNo, Action Code, Exception Code - filled by MLPRO
                 --filler
                 --total length must be 200
                             as REC
          from t_main_cte CL
                   inner join t_ACTIVE_ACCOUNT_SNAPSHOT AC
                              on (CL.ACCOUNT_ID = AC.ACCOUNT_ID and AC.IS_DELETED <> 'Y' and
                                  AC.EQ_REPORT_TO_MPID = 'MLCO')
                   inner join genesis2.instrument I
                              on (I.INSTRUMENT_ID = CL.INSTRUMENT_ID and I.INSTRUMENT_TYPE_ID = 'E' and
                                  I.SYMBOL not in (select TEST_SYMBOL from dash_reporting.test_symbol_tb))
                   left join genesis2.clearing_account DCA
                             on (CL.ACCOUNT_ID = DCA.ACCOUNT_ID and DCA.IS_DEFAULT = 'Y' and dca.is_deleted = 'N' and
                                 DCA.MARKET_TYPE = 'E' and DCA.CLEARING_ACCOUNT_TYPE <> '3')
              ---------------single allocated orders-----------------------------------
              --left join ALLOCATION_INSTRUCTION AL on (AL.ORDER_ID = CL.ORDER_ID and AL.ALLOC_SCOPE = 'S' and AL.IS_DELETED <> 'Y')
                   left join genesis2.allocation_instruction_entry AE
                             on (CL.ALLOC_INSTR_ID = AE.ALLOC_INSTR_ID and AE.ALLOC_QTY > 0)
                   left join genesis2.clearing_account CA
                             on (AE.CLEARING_ACCOUNT_ID = CA.CLEARING_ACCOUNT_ID and ca.is_deleted = 'N' and
                                 CA.CLEARING_ACCOUNT_TYPE <> '3')
			-------------------------------------------------------------------------

          where true
            --CL.PARENT_ORDER_ID IS NULL
            --and CL.IS_LATE_HOURS_ORDER <> 'Y'
            and CL.DAY_CUM_QTY > 0
            and not exists (select 1
                            from genesis2.alloc_instr2trade_record atr
                            where atr.alloc_instr_id = cl.alloc_instr_id)
--			  and ( NVL((select max(ORDER_ALLOC_QTY) from ORDER_ALLOC_QTY AQ where AQ.ORDER_ID = CL.ORDER_ID and AQ.TRADE_DATE = trunc(p_date)), 0 ) = 0
--					OR not exists (select 1 from BUNDLED_ORDER where ORDER_ID = CL.ORDER_ID )
--				  ) -- order should not be allocated or it should not be bundled if it is allocated
            and coalesce(CA.CLEARING_ACCOUNT_ID, DCA.CLEARING_ACCOUNT_ID) is not NULL -- Used clearing account or default clearing account
            -------------------------------------------------------------------------
            and AC.TRADING_FIRM_ID not in
                ('bluefin', 'marathon', 'ctctrad01', 'LPTF51', 'lamberson', 'summit01', 'clearbm', 'clearprop',
                 'keystne01')

		  union all


          select 5           as ORD_FLAG_1,
                 CL.ORDER_ID as ORD_FLAG_2,
                 1           as ORD_FLAG_2X,
                 2           as ORD_FLAG_3,
                 'BB'        as REC_TYPE,
                 CL.DATE_ID::text ||--trade date
                 rpad(' ', 5) ||--filler
                 ' ' ||--Rate Id calculated from executing service --blank
                 rpad(' ', 8) ||--Commission Rate/Amount   - spaces according to orig spec
                 '  ' ||--misc. rate id1; if rate id = 1 - cents per share;
                 rpad(' ', 8) ||--misc rate 1; if rate id = b;
                 rpad(coalesce(AC.EQ_EXECUTING_SERVICE, ' '), 4, ' ') ||--executing service
                 rpad(' ', 8) ||--settle date
                 case
                     when CL.SIDE in ('5', '6') then 'S'
                     else ' '
                     end ||--short sale
                 rpad(' ', 3) ||--RR/BRANCH
                 case
                     when CL.OPEN_CLOSE = 'O' then 'O'
                     when CL.OPEN_CLOSE = 'C' then 'X'
                     else ' '
                     end ||--option code: needs to be adjusted
                 rpad(' ', 14) ||--options parameters
                 'DASH' ||--Client Id
                 '  ' || rpad(' ', 15) ||--misc rate id2, misc rate 2
                 'H' ||--House/Both
                 '01' ||--Firm
                 '   ' ||--filler
                 rpad(' ', 10) ||--markup
                 case
                     when AC.TRADING_FIRM_ID not in ('tomsmith', 'ketchum') then to_char(
                                 coalesce(AE.ALLOC_QTY, cl.DAY_CUM_QTY) * cl.DAY_AVG_PX, 'FM09999999V990')--principal amount
                     else rpad(' ', 10)
                     end ||
                 rpad(' ', 2) || rpad(' ', 8) ||--misc rate id 3, misc rate 3;
                 rpad(' ', 2) || rpad(' ', 15) ||--misc rate id 4, misc rate 4;
                 -----------SEC Fee-----------------------------------------
                 rpad(' ', 2) || rpad(' ', 10) ||--misc rate id 5, misc rate 5;
                 rpad(' ', 2) || rpad(' ', 15) ||--misc rate id 6, misc rate 6
                 rpad(' ', 10) --filler
                 --External RefNo, Action Code, Exception Code
                 --filler
                 --total length must be 200
                             as REC
          from t_main_cte CL
                   inner join t_ACTIVE_ACCOUNT_SNAPSHOT AC
                              on (CL.ACCOUNT_ID = AC.ACCOUNT_ID and AC.IS_DELETED <> 'Y' and
                                  AC.EQ_REPORT_TO_MPID = 'MLCO')
                   inner join genesis2.instrument I
                              on (I.INSTRUMENT_ID = CL.INSTRUMENT_ID and I.INSTRUMENT_TYPE_ID = 'E' and
                                  I.SYMBOL not in (select TEST_SYMBOL from dash_reporting.test_symbol_tb))
                   left join genesis2.clearing_account DCA
                             on (CL.ACCOUNT_ID = DCA.ACCOUNT_ID and DCA.IS_DEFAULT = 'Y' and dca.is_deleted = 'N' and
                                 DCA.MARKET_TYPE = 'E' and DCA.CLEARING_ACCOUNT_TYPE <> '3')
              ---------------single allocated orders-----------------------------------
              --left join ALLOCATION_INSTRUCTION AL on (AL.ORDER_ID = CL.ORDER_ID and AL.ALLOC_SCOPE = 'S' and AL.IS_DELETED <> 'Y')
                   left join genesis2.allocation_instruction_entry AE
                             on (CL.ALLOC_INSTR_ID = AE.ALLOC_INSTR_ID and AE.ALLOC_QTY > 0)
                   left join genesis2.clearing_account CA
                             on (AE.CLEARING_ACCOUNT_ID = CA.CLEARING_ACCOUNT_ID and ca.is_deleted = 'N' and
                                 CA.CLEARING_ACCOUNT_TYPE <> '3')
          -------------------------------------------------------------------------

          where true
            --CL.PARENT_ORDER_ID IS NULL
            --and CL.IS_LATE_HOURS_ORDER <> 'Y'
            and CL.DAY_CUM_QTY > 0
            and not exists (select 1
                            from genesis2.alloc_instr2trade_record atr
                            where atr.alloc_instr_id = cl.alloc_instr_id)
--			  and ( NVL((select max(ORDER_ALLOC_QTY) from ORDER_ALLOC_QTY AQ where AQ.ORDER_ID = CL.ORDER_ID and AQ.TRADE_DATE = trunc(p_date)), 0 ) = 0
--					OR not exists (select 1 from BUNDLED_ORDER where ORDER_ID = CL.ORDER_ID )
--				  ) -- order should not be allocated or it should not be bundled if it is allocated
            and coalesce(CA.CLEARING_ACCOUNT_ID, DCA.CLEARING_ACCOUNT_ID) is not NULL -- Used clearing account or default clearing account
            -------------------------------------------------------------------------
            and AC.TRADING_FIRM_ID not in
                ('bluefin', 'marathon', 'ctctrad01', 'LPTF51', 'lamberson', 'summit01', 'clearbm', 'clearprop',
                 'keystne01')

          order by ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3

	) A ) B;


      GET DIAGNOSTICS row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
      into l_step_id;

-- Finish


  end;
$function$
;
