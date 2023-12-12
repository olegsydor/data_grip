select * from dash_reporting.get_optionsmlpro('2023-05-11')

select * from dash360.report_rps_ml_pro_options(20230511, 20231511);
drop table t_op;

create or replace function dash360.report_rps_ml_pro_options(in_start_date_id int4, in_end_date_id int4)
 returns table (ret_row text)
 language plpgsql
as $function$
-- [NL] 2021/03/29
-- 1. Version 1.1: should correspond Oracle result set
-- 2. to_char with V: put 9 only after V
-- [NL] 2023/05/07: use account instead of snapshot
-- [OS] 20231115: interval of date_ids instead of date_id::date, refursor replaced with table
declare

  l_load_id int;
  l_step_id int;
  row_cnt int;

begin
  	select nextval('public.load_timing_seq') into l_load_id;
  		l_step_id:=1;
	select public.load_log(l_load_id, l_step_id, 'reporting_get_OptionsMLPro STARTED ====', 0, 'O')
		into l_step_id;

-- 	l_date_id:= to_char(in_date, 'YYYYMMDD')::int;
	select public.load_log(l_load_id, l_step_id, 'interval: '||in_start_date_id::text|| '-'||in_end_date_id::text, 1, 'O')
		into l_step_id;

create temp table t_main on commit drop as
			select
				  2 as ORD_FLAG_1,
				  --al.alloc_instr_id as ORD_FLAG_2,
				  tr.order_id as ORD_FLAG_2, --to remove in second phase
				  ae.clearing_account_id as ORD_FLAG_2X,
				  --================================================
				  tr.date_id,
				  tr.open_close,
				  tr.instrument_id,
				  tr.account_id,
				  tr.side,
			      coalesce(al.alloc_instr_id,0) as alloc_instr_id,
			      max(tr.exec_broker) as exec_broker,
			      max(tr.order_process_time) as exec_time,
			      sum(last_qty) as alloc_qty,
			      sum(last_qty*last_px )/nullif(sum(last_qty),0) as avg_px,
			      max(exec_id) as exec_id,
			      --max(tr.order_fix_message_id) as fix_message_id
			      coalesce(fm.t10440,'') as t10440,
			      ca.clearing_account_number,
			      ca.clearing_account_name
			from genesis2.trade_record tr
            inner join instrument i on i.instrument_id = tr.instrument_id
            inner join genesis2.account ac on (tr.account_id = ac.account_id and ac.is_deleted <> 'Y')
			inner join alloc_instr2trade_record atr on (tr.trade_record_id  = atr.trade_record_id and tr.date_id = atr.date_id)
			inner join allocation_instruction al on (al.alloc_instr_id = atr.alloc_instr_id and al.is_deleted <> 'Y')
			inner join allocation_instruction_entry ae
                               on (al.alloc_instr_id = ae.alloc_instr_id and ae.alloc_qty > 0)
            inner join clearing_account ca
                               on (ae.clearing_account_id = ca.clearing_account_id  and
                                   ca.clearing_account_type <> '3')
            left join lateral ( select fix_message->>'10440' as t10440
			                    from staging.fix_message_json fm
			                    where date_id = tr.date_id
			                    and tr.order_fix_message_id = fm.fix_message_id
			                    limit 1
			                   ) as fm on true
			where tr.date_id between in_start_date_id and in_end_date_id and is_busted ='N' and i.instrument_type_id='O'

			and ac.trading_firm_id not in ('vtrader','vtbrokers','vtsterlin','ivycapccm','lkhillccm','monrchccm','jscap','lamberson','summit01','marathon','ctctrad02','clearbm','clearprop','ctctrad01')
			and (ac.opt_report_to_mpid = 'MLCO' or
				(ac.opt_report_to_mpid = 'EXCH' and ca.cmta = '551'
												and ca.clearing_account_number <> '551') )
			and atr.alloc_instr_id is not null
			group by 2, tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, coalesce(al.alloc_instr_id,0), coalesce(fm.t10440,''), ca.clearing_account_number, ca.clearing_account_name, ae.clearing_account_id, tr.order_id

			union all

			select
				  3 as ORD_FLAG_1,
			      tr.order_id as ORD_FLAG_2,
			      1 as ORD_FLAG_2X,
				  --================================================
			      tr.date_id,
				  tr.open_close,
				  tr.instrument_id,
				  tr.account_id,
				  tr.side,
			      coalesce(atr.alloc_instr_id,0) as alloc_instr_id,
			      max(tr.exec_broker) as exec_broker,
			      max(tr.order_process_time) as exec_time,
			      sum(last_qty) as alloc_qty,
			      sum(last_qty*last_px )/nullif(sum(last_qty),0) as avg_px,
			      max(exec_id) as exec_id,
			      --max(tr.order_fix_message_id) as fix_message_id
			      coalesce(fm.t10440,'') as t10440,
			      coalesce(dca.clearing_account_number,'*none*') as clearing_account_number,
			      dca.clearing_account_name
			from genesis2.trade_record tr
            inner join instrument i on i.instrument_id = tr.instrument_id
            inner join genesis2.account ac on (tr.account_id = ac.account_id and ac.is_deleted <> 'Y')
            -- change to inner join
            left join clearing_account dca
                               on (ac.account_id = dca.account_id and dca.is_default = 'Y' and dca.is_deleted <> 'Y' and
                                   dca.market_type = 'O' and dca.clearing_account_type <> '3')
            -- for non-allocated only
			left join alloc_instr2trade_record atr on (tr.trade_record_id  = atr.trade_record_id and tr.date_id = atr.date_id)

            left join lateral ( select fix_message->>'10440' as t10440
			                    from staging.fix_message_json fm
			                    where date_id = tr.date_id
			                    and tr.order_fix_message_id = fm.fix_message_id
			                    limit 1
			                   ) as fm on true
			where tr.date_id between in_start_date_id and in_end_date_id and is_busted ='N' and i.instrument_type_id='O'

			and ac.trading_firm_id not in ('vtrader','vtbrokers','vtsterlin','ivycapccm','lkhillccm','monrchccm','jscap','lamberson','summit01','marathon','ctctrad02','clearbm','clearprop','ctctrad01')
			and (ac.opt_report_to_mpid = 'MLCO' or
				(ac.opt_report_to_mpid = 'EXCH' and dca.cmta = '551'
												and dca.clearing_account_number <> '551') )
			and atr.alloc_instr_id is null
			group by 3, tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, coalesce(atr.alloc_instr_id,0), coalesce(fm.t10440,''), coalesce(dca.clearing_account_number,'*none*'), dca.clearing_account_name, tr.order_id, 1

			union all

			select
				   4 as ORD_FLAG_1,
			       tr.trade_record_id as ORD_FLAG_2,
			       1 as ORD_FLAG_2X,
			       tr.date_id,
				   tr.open_close,
				   tr.instrument_id,
				   tr.account_id,
			       tr.side,
			       coalesce(al.alloc_instr_id,0) as alloc_instr_id,
			       tr.exec_broker as exec_broker,
			       tr.trade_record_time as exec_time,
			       --tr.trade_record_time as trade_record_time,
			       last_qty as alloc_qty,
			       last_px as avg_px,
			       exec_id as exec_id,
			       --tr.order_fix_message_id as fix_message_id
			       '' as t10440,
			       coalesce(dca.clearing_account_number,'*none*') as clearing_account_number,
				   dca.clearing_account_name
			from genesis2.trade_record tr
            join instrument i on i.instrument_id = tr.instrument_id
            inner join genesis2.account ac on (ac.account_id  = tr.account_id)
			left join alloc_instr2trade_record atr on (tr.trade_record_id  = atr.trade_record_id and tr.date_id = atr.date_id)
			left join allocation_instruction al on (al.alloc_instr_id = atr.alloc_instr_id and al.is_deleted <> 'Y')
			left join clearing_account dca
                               on (ac.account_id = dca.account_id and dca.is_default = 'Y' and dca.is_deleted <> 'Y' and
                                   dca.market_type = 'O')

			where tr.date_id between in_start_date_id and in_end_date_id and tr.is_busted ='N' and i.instrument_type_id='O'
			and (ac.opt_report_to_mpid = 'MLCO' or
				(ac.opt_report_to_mpid = 'EXCH' and dca.cmta = '551'
												and dca.clearing_account_number <> '551') )
		    and (ac.trading_firm_id in ('jscap')
					   or (ac.trading_firm_id in ('lamberson') and (tr.exchange_id not in ('ISE','GEMINI','MCRY') or dca.clearing_account_name is null))
					   or (ac.trading_firm_id in ('summit01','ctctrad02','marathon','clearbm','clearprop') and (ac.opt_customer_or_firm not in ('4','5') or tr.exchange_id not in ('ISE','GEMINI','MCRY')))
				)
			and ac.trading_firm_id <> 'ctctrad01'
	  		and tr.trade_record_time::time < '16:40'::time;


       -------------------------------------------------------------------------
create temp table t_op on commit drop as
		  select distinct ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3, REC_TYPE, REC
          from
             	   (select 1      as ORD_FLAG_1,
                           0      as ORD_FLAG_2,
                           0      as ORD_FLAG_2X,
                           0      as ORD_FLAG_3,
                           'UHDR' as REC_TYPE,
                           --to_char(systimestamp at time zone DBTIMEZONE_GENESIS2, 'YYYYDDD')||
                           to_char(current_timestamp, 'YYYYDDD') ||
                           rpad(' ', 12) ||--13-24
                           --to_char(systimestamp at time zone DBTIMEZONE_GENESIS2, 'HH24MI')||
                           '1700' ||
                           rpad('SDS', 20, ' ') ||
                           rpad(' ', 152)--filler
                                  as REC
                    union all
                    select 5      as ORD_FLAG_1,
                           99999  as ORD_FLAG_2,
                           1      as ORD_FLAG_2X,
                           1      as ORD_FLAG_3,
                           'UTRL' as REC_TYPE,
                           ''     as REC
                   ) HT;


      ----------------------options(bundles, orders, trades)-----------------------------

insert into t_op (ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3, REC_TYPE, REC)

		  select  OP.ORD_FLAG_1, OP.ORD_FLAG_2, OP.ORD_FLAG_2X, 1 as ORD_FLAG_3,  'AA' as REC_TYPE,
		  OP.DATE_ID::varchar||
		  case
			when OP.OPT_CUSTOMER_OR_FIRM in ('4','5') then rpad(coalesce(OP.CLEARING_ACCOUNT_NAME, OP.CLEARING_ACCOUNT_NUMBER, ''), 10, ' ')
			else rpad(coalesce(OP.CLEARING_ACCOUNT_NUMBER, ''), 10, ' ')
		  end||--real value should be used
		  case
			 when OP.SIDE = '1' then 'B'
			 when OP.SIDE in ('2', '5', '6') then 'S'
		  end||
		  '0551'||--rpad(' ', 4) - executing broker 27-30
		  rpad(' ',4)||--Receive/Deliver Broker 31-34
		  lpad(coalesce(OP.EXEC_BROKER, '')::varchar,4,'0')||--Receive/Deliver Broker Number
		  'E'||--Exchange 39
		  --'0000'||--
		  to_char(OP.EXEC_TIME, 'HH24MI')||
		  --'0000'||--
		  to_char(OP.EXEC_TIME, 'SSss')||
		  rpad(' ', 6)||--filler
		  lpad(OP.ALLOC_QTY::varchar, 9, '0' )||--rpad(TR.LAST_QTY, 9, ' ' )||
		  rpad(coalesce(OP.ROOT_SYMBOL,''), 10, ' ')||
		  'O'||--73 sec type
		  case
			when OP.PUT_CALL = '0' then 'OP'
			when OP.PUT_CALL = '1' then 'OC'
		  end||--Blotter Code or Put/Call 74-75
		  ' '||--Bill/No Bill Code
		  rpad(' ', 4)||--Receive/Deliver badge
		  ' '||--Agency
		  'N'||--Contract Code
		  ' '||--Misc.trade type indicator 1 (P = Prime broker Trade)
		  ' '||--Multi-contra flag - are we?
		  to_char(OP.AVG_PX, 'FM099999V9999999')||
		  rpad(' ', 4)||--Executing Badge
		  rpad(' ', 4)||rpad(' ', 4)||rpad(' ', 4)||--QSR Branch, QSR Seq Num, Customer Mnemonic
		  rpad(' ', 13)--Reserved
		  --Filler, External RefNo, Action Code, Exception Code - filled by MLPRO
		  --filler
		  --total length must be 200
		  as REC
		  from
		  (
		    select cl.ord_flag_1, cl.ord_flag_2, cl.ord_flag_2x, cl.date_id, cl.exec_time, cl.alloc_qty, cl.avg_px,

                   case
                       when ac.account_name = 'CUTLERFIRM' then coalesce(cl.t10440, cl.clearing_account_number)
                       else cl.clearing_account_number
                   end as clearing_account_number,
                   cl.clearing_account_name,
                   ac.opt_report_to_mpid,
                   ac.trading_firm_id,
                   ac.eq_mpid,
                   ac.opt_executing_service,
                   ac.opt_is_fix_execbrok_processed,
                   ac.opt_penny_commission,
                   ac.opt_nickel_commission,
                   ac.opt_customer_or_firm,
                   cl.exec_broker,
                   cl.side,
                   cl.open_close,
                   os.root_symbol,
                   oc.put_call,
                   oc.maturity_year,
                   oc.maturity_month,
                   oc.maturity_day,
                   oc.strike_price,
                   case os.min_tick_increment when 0.01 then 'P' when 0.05 then 'N' else 'P' end as opt_incr_type
		  	from t_main cl
            inner join option_contract oc on (oc.instrument_id = cl.instrument_id)
            inner join option_series os on (oc.option_series_id = os.option_series_id)
            inner join genesis2.account ac on (cl.account_id = ac.account_id and ac.is_deleted <> 'Y')

		  )  op;

insert into t_op (ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3, REC_TYPE, REC)

		  select  OP.ORD_FLAG_1, OP.ORD_FLAG_2, OP.ORD_FLAG_2X, 2 as ORD_FLAG_3,  'BB' as REC_TYPE,
		  OP.DATE_ID::varchar||--trade date
		  rpad(' ', 5)||--filler
		  ' '||--Rate Id calculated from executing service  --blank
		  rpad(' ', 8)||--Commission Rate/Amount   - spaces according to orig spec
		  ----------------------------------------------
		  case
		    when OP.TRADING_FIRM_ID in ('logicadca','tiberius','esmark') then '06'||to_char(case OP.OPT_INCR_TYPE when 'P' then OP.OPT_PENNY_COMMISSION when 'N' then OP.OPT_NICKEL_COMMISSION end, 'FM0999V9999')
		    else '  '||rpad(' ', 8)
		  end||
		  --'  '||--misc. rate id1; if rate id = 1 - cents per share;
		  --rpad(' ', 8)||--misc rate 1; if rate id = b;
		  ----------------------------------------------
		  case
		    when OP.TRADING_FIRM_ID in ('opesbrdg') and OP.ROOT_SYMBOL in ('SPX','SPXPM','SPXW','NDX','VIX','VXX','DJX','RUT') then 'SING'
	        when OP.OPT_EXECUTING_SERVICE is not NULL then rpad(OP.OPT_EXECUTING_SERVICE,4,' ')
			when OP.TRADING_FIRM_ID in ('ebseqtc') then 'BELZ'
			when OP.OPT_REPORT_TO_MPID in ('EXCH') then coalesce(rpad(OP.OPT_EXECUTING_SERVICE,4,' '),'CMTA')
			else '    '
		  end||--executing service: mandatory!!!
		  rpad(' ', 8)||--settle date
		  case
			when OP.SIDE in ('5','6') then 'S'
			else ' '
		  end||--short sale
		  rpad(' ', 3)||--RR/BRANCH
		  case
			when OP.OPEN_CLOSE = 'O' then 'O'
			when OP.OPEN_CLOSE = 'C' then 'X'
			else ' '
			--else decode(CL.SIDE, '1', 'O', '2', 'X')
		  end||--option code: needs to be adjusted
		  substr(OP.MATURITY_YEAR::varchar, 3)||to_char(OP.MATURITY_MONTH, 'FM00')||to_char(OP.MATURITY_DAY, 'FM00')||to_char(OP.STRIKE_PRICE, 'FM09999V999')||
		  'DASH'||--Client Id
		  '  '||rpad (' ', 15)||--misc rate id2, misc rate 2
		  'H'||--House/Both
		  '01'||--Firm
		  '   '||--filler
		  rpad (' ', 10)||--markup
		  case
			when OP.TRADING_FIRM_ID not in ('tomsmith','cornersto','dashcorne','ketchum','ebseqtc','iaeips') then to_char(OP.ALLOC_QTY*OP.AVG_PX, 'FM099999999V99')--principal amount
			else rpad(' ', 11)
		  end||
		  rpad(' ', 2)||rpad(' ', 8)||--misc rate id 3, misc rate 3;
		  rpad(' ', 2)||rpad(' ', 15)||--misc rate id 4, misc rate 4;
		  rpad(' ', 2)||rpad(' ', 10)||--misc rate id 5, misc rate 5;
		  rpad(' ', 2)||rpad(' ', 15)||--misc rate id 6, misc rate 6
		  rpad(' ', 10)--filler
		  --External RefNo, Action Code, Exception Code
		  --filler
		  --total length must be 200
		  as REC
		  from (
		    select cl.ord_flag_1, cl.ord_flag_2, cl.ord_flag_2x, cl.date_id, cl.exec_time, cl.alloc_qty, cl.avg_px,

                   case
                       when ac.account_name = 'CUTLERFIRM' then coalesce(cl.t10440, cl.clearing_account_number)
                       else cl.clearing_account_number
                   end as clearing_account_number,
                   cl.clearing_account_name,
                   ac.opt_report_to_mpid,
                   ac.trading_firm_id,
                   ac.eq_mpid,
                   ac.opt_executing_service,
                   ac.opt_is_fix_execbrok_processed,
                   ac.opt_penny_commission,
                   ac.opt_nickel_commission,
                   ac.opt_customer_or_firm,
                   cl.exec_broker,
                   cl.side,
                   cl.open_close,
                   os.root_symbol,
                   oc.put_call,
                   oc.maturity_year,
                   oc.maturity_month,
                   oc.maturity_day,
                   oc.strike_price,
                   case os.min_tick_increment when 0.01 then 'P' when 0.05 then 'N' else 'P' end as opt_incr_type
		  	from t_main cl
            inner join option_contract oc on (oc.instrument_id = cl.instrument_id)
            inner join option_series os on (oc.option_series_id = os.option_series_id)
            inner join genesis2.account ac on (cl.account_id = ac.account_id and ac.is_deleted <> 'Y')
		  	) op;

    return query
        select rpad(REC_TYPE ||
                    case
                        when REC_TYPE = 'UHDR' then ' '
                        when REC_TYPE in ('AA', 'BB') then lpad(trunc(REC_NUM / 2)::varchar, 5, '0')
                        else ' ' || REC_NUM
                        end ||
                    REC, 200, ' ')
        from (select ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3, row_number() over () as REC_NUM, REC, REC_TYPE
              from t_op
              order by ORD_FLAG_1, ORD_FLAG_2, ORD_FLAG_2X, ORD_FLAG_3) X0;

  	select count(*) into row_cnt from t_op;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
	into l_step_id;

-- Finish

end;
$function$
;
