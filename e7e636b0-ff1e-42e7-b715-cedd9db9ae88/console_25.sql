select
	real_exch.exchange_name as exchange_name,
	i.display_instrument_id2 as symbol,
	i.last_trade_date as expiration_date,
	tr.side,
	cie.open_close,
	cie.last_px as last_px,
	cie.exec_broker as gup,
	cie.cmta,
	cie.opt_customer_firm,
	cie.clearing_account_number,
	cie.sub_account,
	cie.account_id,
	tr.client_id,
	sum(cie.last_qty) as last_qty, -- affected qty
    sum(cie.last_qty) + sum(coalesce(t.last_qty, 0))::bigint total_qty, -- total qty
    cie.electronic_report_status report_status,
    cie.street_account_name,
    cie.street_exec_broker,
    cie.client_commission_rate,
    real_exch.exchange_id as exchange_id,
    i.instrument_type_id,
    cie.branch_sequence_number,
    cie.trade_text,
    cie.frequent_trader_id
	from clearing_instruction_entry cie
	--inner join clearing_instruction ci on ci.clearing_instr_id = cie.clearing_instr_id
    inner join trade_record tr on tr.trade_record_id = cie.trade_record_id
	left join instrument i on i.instrument_id = tr.instrument_id
    left join exchange exch on 	exch.exchange_id = tr.exchange_id
    left join exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
-- Commented due to performnce improvement https://dashfinancial.atlassian.net/browse/DS-284
--    left join lateral (select sum(total.last_qty) last_qty
--	                   from trade_record total
--						where total.date_id = tr.date_id
--						  and date_id = l_date_id
--						  and total.is_busted = 'N'
--						  and total.trade_record_id not in (select	trade_record_id
--															from clearing_instruction_entry
--															where clearing_instr_id = cie.clearing_instr_id)
--						  and total.orig_trade_record_id not in (select	trade_record_id
--																 from clearing_instruction_entry
--																 where clearing_instr_id = cie.clearing_instr_id)
--						  and total.account_id = cie.account_id
--						  and total.instrument_id = tr.instrument_id
--						  and total.side = tr.side
--						  and total.last_px = cie.last_px
--						  and coalesce(total.open_close, '')= coalesce(cie.open_close, '')
--						  and coalesce(total.client_id, '')= coalesce(tr.client_id, '')
--						  and coalesce(total.exec_broker, '')= coalesce(cie.exec_broker, '')
--						  and coalesce(total.cmta, '')= coalesce(cie.cmta, '')
--						  and coalesce(total.opt_customer_firm, '')= coalesce(cie.opt_customer_firm, '') ) t on
--						1 = 1
    left join  (select total.account_id, total.instrument_id , total.side, total.last_px,
						coalesce(total.open_close, '') as open_close
					  , coalesce(total.client_id, '') as client_id
					  , coalesce(total.exec_broker, '') as exec_broker
					  , coalesce(total.cmta, '') cmta
					  , coalesce(total.opt_customer_firm, '') opt_customer_firm
				      , sum(total.last_qty)last_qty
	                   from trade_record total
						where total.date_id = :l_date_id
						  and date_id = :l_date_id
						  and total.is_busted = 'N'
						  and total.trade_record_id not in (select	trade_record_id
															from clearing_instruction_entry
															where clearing_instr_id = :in_clearing_instr_id)
						  and total.orig_trade_record_id not in (select	trade_record_id
																 from clearing_instruction_entry
																 where clearing_instr_id = :in_clearing_instr_id)

			             group by total.account_id, total.instrument_id , total.side, total.last_px,
						coalesce(total.open_close, '')
					  , coalesce(total.client_id, '')
					  , coalesce(total.exec_broker, '')
					  , coalesce(total.cmta, '')
					  , coalesce(total.opt_customer_firm, '')) t on	(t.account_id = cie.account_id
																  and t.instrument_id = tr.instrument_id
																  and t.side = tr.side
																  and t.last_px = cie.last_px
																  and t.open_close= coalesce(cie.open_close, '')
																  and t.client_id= coalesce(tr.client_id, '')
																  and t.exec_broker= coalesce(cie.exec_broker, '')
																  and t.cmta= coalesce(cie.cmta, '')
																  and t.opt_customer_firm= coalesce(cie.opt_customer_firm, ''))

	where cie.clearing_instr_id = :in_clearing_instr_id
	and tr.date_id =:l_date_id
	group by cie.account_id,
			real_exch.exchange_id,
			i.instrument_id,
			i.instrument_type_id,
			i.last_trade_date,
			tr.side,
			tr.client_id,
			cie.open_close,
			cie.last_px,
			cie.exec_broker,
			cie.cmta,
			cie.opt_customer_firm,
			cie.clearing_account_number,
			cie.sub_account,
			real_exch.exchange_name,
		    cie.electronic_report_status,
		    cie.street_account_name,
            cie.street_exec_broker,
            cie.client_commission_rate,
            cie.branch_sequence_number,
            cie.trade_text,
            cie.frequent_trader_id;