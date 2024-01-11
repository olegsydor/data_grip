select  'TRADE' as REC_TYPE, 3 as OUT_ORD_FLAG, --tr.*,
	to_char(tr.trade_record_time,'MM/DD/YY')||'|'||
	coalesce(exc.mic_code,'')||'|'||
	coalesce(tr.side,'')||'|'||
	coalesce(tr.open_close,'')||'|'||
	tr.last_qty||'|'||
	coalesce(tr.street_order_qty,tr.order_qty,0)||'|'||
	coalesce(to_char(tr.last_px, 'FM99999990.0099'),'')||'|'||
	oc.opra_symbol||'|'||
	ui.symbol||'|'||
	to_char(tr.order_process_time, 'hh24:mi:ss')||'|'||
	to_char(tr.trade_record_time, 'hh24:mi:ss')||'|'||
	coalesce(acc.eq_order_capacity,'')||'|'||
	coalesce(tr.street_order_id::varchar,tr.order_id::varchar,'')||'|'||
	coalesce(tr.exec_id::varchar,'')||'|'|| -- column 14
	'DASH'||'|'||
	'DASH'||'|'||
	--coalesce(tr.sub_account,'')||'|'|| -- OCC cust Account (440)
	case tr.subsystem_id
	  when 'HFTDMA' then 'BEBS949C'
	  --else coalesce(fm.fix_message ->> '440', fm.fix_message ->> '1', '')
-- 	  else coalesce(fm.t440, fm.t1, '')
	  else coalesce(trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id , in_tag_number=>440, in_start_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
	                tr.street_account_name
	                , '' )
	end||'|'|| -- OCC cust Account Column 17
	coalesce(tr.street_client_order_id,tr.secondary_order_id,tr.client_order_id)||'|'||
	coalesce(tr.cmta, case acc.is_auto_allocate when 'Y' then ca.cmta end,  '')||'|'|| -- Column 19
	''||'|'|| --mnemonic
	''||'|'|| --MM ID
coalesce(trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id, in_tag_number=>7901, in_start_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
	     trash.get_message_tag_string(in_fix_message_id=>tr.street_order_fix_message_id, in_tag_number=>9324, in_start_date_id=>to_char(tr.order_process_time, 'YYYYMMDD')::int),
	     '')||'|'||--preferenced LP
	case
		when acc.trading_firm_id  = 'marathon' and tr.exchange_id = 'CBOE' then 'M'
		when acc.trading_firm_id  = 'walleye' and tr.exchange_id = 'PHLX' then 'M'
		when tr.opt_customer_firm = '0' then 'C'
		when tr.opt_customer_firm = '1' then 'F'
		when tr.opt_customer_firm = '2' then 'B'
		when tr.opt_customer_firm = '3' then 'B'
		when tr.opt_customer_firm = '4' then 'M'
		when tr.opt_customer_firm = '5' then 'N'
		when tr.opt_customer_firm = '7' then 'F'
		when tr.opt_customer_firm = '8' then 'P'
		else ''
	end||'|'||
	coalesce(tr.trade_liquidity_indicator,'')||'|'||
	''||'|'||
	coalesce(tr.ex_destination,'')||'|'||
	''||'|'||--Exchange Access Fee
	case
		when tr.exchange_id = 'BATS' then coalesce(tr.contra_broker,'')
		when tr.exchange_id in ('ARCA','AMEX') then coalesce(tr.trade_exec_broker,'')
		else ''
	end||'|'||
	case
		when tr.multileg_reporting_type = '1' then 'N' else 'Y' --check if par and str are the same!!
	end||'|'||
	'Y'||'|'||--BD Flag
	case
		when acc.opt_customer_or_firm = '8' then 'Y' else 'N'
	end||'|'||--Professional Flag
	case tr.street_order_type
		when '1' then 'MKT'
		when '2' then 'LMT'
		when '3' then 'STP'
		when '4' then 'STL'
		when '5' then 'MOC'
		when '7' then 'LOB'
		when 'B' then 'LOC'
		when 'J' then 'MIT'
		when 'P' then 'PEG'
		when 'O' then 'MOO'
		when '6' then 'WOW'
		else '' -- coalesce(tr.street_order_type,'')
	end||'|'||--Order Type
	case
		when tr.time_in_force = '0' then 'DAY' --par.time_in_force_id
		when tr.time_in_force = '1' then 'GTC'
		when tr.time_in_force = '2' then 'OPG'
		when tr.time_in_force = '3' then 'IOC'
		when tr.time_in_force = '4' then 'FOK'
		when tr.time_in_force = '5' then 'GTX'
		when tr.time_in_force = '6' then 'GTD'
		when tr.time_in_force = '7' then 'At the Close'
		else ''-- as time_in_force
	 end||'|'||
	 ''||'|' --Record type
 	 ||tr.exec_broker  --exec_firm
	 as REC
from genesis2.trade_record as tr
inner join genesis2.option_contract as oc on tr.instrument_id = oc.instrument_id
inner join genesis2.option_series as os on os.option_series_id = oc.option_series_id
inner join genesis2.instrument as ui on (os.underlying_instrument_id = ui.instrument_id)
inner join genesis2.account as acc on acc.account_id = tr.account_id
left join genesis2.exchange as exc on exc.exchange_id = tr.exchange_id and exc.is_deleted = 'N'
left join genesis2.clearing_account ca on ca.account_id =tr.account_id and CA.IS_DELETED = 'N'  and CA.MARKET_TYPE = 'O' and CA.IS_DEFAULT = 'Y'
where tr.date_id = 20240103--l_date_id --to_char(in_date,'YYYYMMDD')::int
and (acc.opt_report_to_mpid = 'MLCB' or acc.opt_report_to_mpid = 'EXCH')
and tr.exec_broker in ('792', '733')
--and (acc.opt_report_to_mpid = 'MLCB' or (acc.opt_report_to_mpid = 'EXCH' and tr.exec_broker in ('792', '733')))
--and (acc.opt_report_to_mpid = 'MLCB' or (acc.opt_report_to_mpid = 'EXCH' and tr.exec_broker = '792'))
and ( tr.subsystem_id ='HFTDMA' or (acc.trading_firm_id <> 'nomura' or tr.exchange_id <> 'CBOE') and acc.trading_firm_id <> 'baml')
and tr.is_busted = 'N'
and tr.order_id>0