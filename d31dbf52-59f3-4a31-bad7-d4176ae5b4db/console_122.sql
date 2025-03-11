select trade_record_id,date_id,ask_price,ask_qty,bid_price,bid_qty,street_order_qty,street_time_in_force,
		street_is_cross_order,street_cross_is_originator,strategy_decision_reason_code,auction_id,exch_order_id,
		is_busted,cross_order_id,exec_instruction,allocation_avg_price,account_nickname,price_limit,order_type,
		multileg_reporting_type,exchange_id,open_close,fix_comp_id,blaze_account_alias,cons_lite_rfid,trade_text,
		compliance_id,alternative_compliance_id,multileg_order_id,secondary_order_id,street_order_type,street_cross_type,
		street_exec_broker,street_opt_customer_firm,pt_basket_id,exec_broker,cons_payment_per_contract,street_client_id,
		box_transactions_breakups,arcaex_id,contra_capacity,street_account_name,opt_customer_firm,
		case when pre_ftr.multileg_reporting_type = '2' and   first_value (pre_ftr.trade_liquidity_indicator) over(partition by pre_ftr.multileg_order_id,pre_ftr.secondary_order_id order by pre_ftr.trade_liquidity_indicator nulls last ) is not null
				then coalesce(pre_ftr.trade_liquidity_indicator,'T')
			 when pre_ftr.multileg_reporting_type = '2' and pre_ftr.exchange_id = 'BOX' and pre_ftr.trade_liquidity_indicator is null then 'R'
			 when pre_ftr.multileg_reporting_type = '1' and pre_ftr.exchange_id = 'BOX' and pre_ftr.open_close = 'O' and pre_ftr.trade_liquidity_indicator is null then 'O'
			 else pre_ftr.trade_liquidity_indicator
		end as trade_liquidity_indicator,
		street_on_behalf_of_sub_id,cross_type,street_order_id,leg_ref_id,on_behalf_of_sub_id,billing_code,no_legs,on_behalf_of_comp_id,
		alloc_instr_id,bundle_id,cmta
	from (
		select ftr.trade_record_id, ftr.date_id, ftr.ask_price, ftr.ask_qty, ftr.bid_price, ftr.bid_qty, ftr.street_order_qty,
			   ftr.street_time_in_force, ftr.street_is_cross_order, ftr.street_cross_is_originator, ftr.strategy_decision_reason_code,
			   ftr.auction_id, ftr.exch_order_id, ftr.is_busted, ftr.cross_order_id, ftr.exec_instruction, ftr.allocation_avg_price,
			   ftr.account_nickname, ftr.price_limit, ftr.order_type, ftr.multileg_reporting_type, ftr.exchange_id, ftr.open_close,
			   ftr.fix_comp_id, ftr.blaze_account_alias, ftr.cons_lite_rfid, ftr.trade_text, ftr.compliance_id, ftr.alternative_compliance_id,
			   ftr.multileg_order_id, ftr.secondary_order_id,
			   case when coalesce(ftr.exchange_id,ex1.exchange_id) in ('ARCAE', 'XASE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'
						and coalesce(fmjso.fix_message->>'386',fmjso_co.fix_message->>'386',fmj.fix_message->>'386')='1'
						and coalesce(fmjso.fix_message->>'336',fmjso_co.fix_message->>'336',fmj.fix_message->>'336')='2' then 'O'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('ARCAE', 'XASE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'
						and coalesce(fmjso.fix_message->>'386',fmjso_co.fix_message->>'386',fmj.fix_message->>'386')='1'
						and coalesce(fmjso.fix_message->>'336',fmjso_co.fix_message->>'336',fmj.fix_message->>'336')='2' then 'L'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('ARCAE', 'XASE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='7'
						and coalesce(fmjso.fix_message->>'386',fmjso_co.fix_message->>'386',fmj.fix_message->>'386')='1'
						and coalesce(fmjso.fix_message->>'336',fmjso_co.fix_message->>'336',fmj.fix_message->>'336')='2' then '5'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('ARCAE', 'XASE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='7'
						and coalesce(fmjso.fix_message->>'386',fmjso_co.fix_message->>'386',fmj.fix_message->>'386')='1'
						and coalesce(fmjso.fix_message->>'336',fmjso_co.fix_message->>'336',fmj.fix_message->>'336')='2' then 'B'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('BATS')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'
						and coalesce(fmjso.fix_message->>'9303',fmjso_co.fix_message->>'9303',fmj.fix_message->>'9303')='B' then 'O'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('BATS')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'
						and coalesce(fmjso.fix_message->>'9303',fmjso_co.fix_message->>'9303',fmj.fix_message->>'9303')='B'  then 'L'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('BATS')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='7'
						and coalesce(fmjso.fix_message->>'9303',fmjso_co.fix_message->>'9303',fmj.fix_message->>'9303')='B'  then '5'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('BATS')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='7'
						and coalesce(fmjso.fix_message->>'9303',fmjso_co.fix_message->>'9303',fmj.fix_message->>'9303')='B'  then 'B'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='O'
						and coalesce(fmjso.fix_message->>'9140',fmjso_co.fix_message->>'9140',fmj.fix_message->>'9140')='I' then 'K'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='C'
						and coalesce(fmjso.fix_message->>'9140',fmjso_co.fix_message->>'9140',fmj.fix_message->>'9140')='I' then 'M'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='O' then 'O'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='O'  then 'L'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='C'  then '5'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NSDQE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='3'
						and coalesce(fmjso.fix_message->>'9355',fmjso_co.fix_message->>'9355',fmj.fix_message->>'9355')='C'  then 'B'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40') in ('1','2')
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='0'
						and coalesce(fmjso.fix_message->>'57',fmjso_co.fix_message->>'57',fmj.fix_message->>'57')='4' then  'S'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='1'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'  then  'O'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='2'  then  'L'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='5'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='0'  then  '5'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='B'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='0'  then  'B'
					when coalesce(ftr.exchange_id,ex1.exchange_id) in ('NYSE')
						and coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40')='2'
						and coalesce(fmjso.fix_message->>'59',fmjso_co.fix_message->>'59',fmj.fix_message->>'59')='0'
						and coalesce(fmjso.fix_message->>'9487',fmjso_co.fix_message->>'9487',fmj.fix_message->>'9487')='CO'  then  'N'
						else coalesce(fmjso.fix_message->>'40',fmjso_co.fix_message->>'40',fmj.fix_message->>'40',ftr.street_order_type )
					end  as street_order_type
					,case when ftr.street_cross_type='C' then 'Customer Match'
						when ftr.street_cross_type in ('F','2') then 'Facilitation'
						when ftr.street_cross_type in ('P','4') then 'Price Improvement Mechanism'
						when ftr.street_cross_type='S' then 'Solicitation'
						when ftr.street_cross_type='Q' then 'Qualified Contingent Cross'
						when ftr.street_cross_type='1' then 'Solicitation or Customer Match Order'
						else ftr.street_cross_type
					end street_cross_type
					,coalesce(ftr.street_exec_broker,
						case
							when ftr.street_is_cross_order = 'Y' then null
							else coalesce( (fmjso.fix_message->>rex.exec_broker_tag::varchar)::text, (fmjso_co.fix_message->>rex.exec_broker_tag::varchar)::text)
						end
					) as street_exec_broker
					,case
						  when ftr.exchange_id = 'MXOP' then fmjso.fix_message->>'1815'
						  else  coalesce(fmj.fix_message->>'204',ftr.street_opt_customer_firm,  fmj.fix_message->>'47')
					end as street_opt_customer_firm
					,case
						when ftr.pt_basket_id like 'PT_%-%'||to_char(ftr.trade_record_time,'MMDDYYYY')||'-%:%:%' then ftr.pt_basket_id
						else null
					end as pt_basket_id
					,case
						when ftr.instrument_type_id='E' and ftr.exchange_id='NSDQE' then coalesce(fmjso.fix_message->>'76','INET')
						else ftr.exec_broker
					end as exec_broker
					,case ftr.multileg_reporting_type
						 when '1' then ftr.str_cons_payment_per_contract
						 else (ftr.str_cons_payment_per_contract*COALESCE((fmjpo.fix_message->>'38')::NUMERIC,1))::NUMERIC / coalesce(NULLIF(ml.qty,0),1)
					end  as cons_payment_per_contract
					,coalesce(fmjso.fix_message->>'109',fmjso_co.fix_message->>'109') as street_client_id
					,case
						when ftr.is_cross_order = 'Y' then fmjso_box.fix_message->>'375'
						else  case
								when ftr.street_is_cross_order ='Y' then fmjso_box.fix_message->>'375'
							    else null
							  end
					end as box_transactions_breakups
					,case
						when ftr.exchange_id = 'ARCAP' and ftr.subsystem_id != 'HFTDMA' then fmjso_box.fix_message->>'9483'
						when ftr.exchange_id = 'ARCAP' and ftr.subsystem_id = 'HFTDMA' then fmjtr.fix_message->>'9483'
						when ftr.exchange_id = 'AMEXP' and ftr.subsystem_id != 'HFTDMA' then fmjso_box.fix_message->> '9483'
						when ftr.exchange_id = 'AMEXP' and ftr.subsystem_id = 'HFTDMA' then fmjtr.fix_message->>'9483'
						when ftr.exchange_id in('ARCAE', 'XASE', 'XCHI', 'NSX', 'NYSE', 'XPSX') and ftr.instrument_type_id = 'E'  then fmjso_box.fix_message->> '9483'
						else fmjso_box.fix_message->>'9731'
					end as ArcaEx_id
					,coalesce(fmjtr.fix_message->>'6005',fmj.fix_message->>'6005',substring(fmjtr.fix_message->>'9730',2,1), substring(fmj.fix_message->>'9730',2,1)) as contra_capacity
					,coalesce(fmj.fix_message->>'1',fmjso.fix_message->>'1',fmjso_co.fix_message->>'1',fmj.fix_message->>'440',fmjso.fix_message->>'440',fmjso_co.fix_message->>'440',ftr.street_account_name) as street_account_name
					,coalesce(ftr.opt_customer_firm, fmjpo.fix_message->>'204', fmjpo.fix_message->>'47') as opt_customer_firm
					,case
						when coalesce(ftr.exchange_id,ex1.exchange_id)='NYSE' then coalesce(ftr.trade_liquidity_indicator,left(fmj.fix_message->>'9426', coalesce(nullif(position('/' in fmj.fix_message->>'9426')-1,-1),5)))
						when  coalesce(ftr.exchange_id,ex1.exchange_id) in ('ARCA','AMEX') then coalesce(ftr.trade_liquidity_indicator,fmj.fix_message->>'9730',fmjtr.fix_message->>'9730')
						when coalesce (ftr.exchange_id,ex1.exchange_id) in ('MEMXML','BARX','MXOP') then coalesce (ftr.trade_liquidity_indicator,fmjso_box.fix_message->>'851')
						when coalesce (ftr.exchange_id,ex1.exchange_id) = 'SPHR' and ftr.trade_liquidity_indicator is not null then SUBSTRING(ftr.trade_liquidity_indicator  FROM 4 FOR 1)
						else ftr.trade_liquidity_indicator
					end as trade_liquidity_indicator
					,case
						when ftr.exchange_id = 'JLEQ' then fmjso.fix_message->>'116'
						when ftr.exchange_id = 'CGXS' then fmjso_box.fix_message->>'20008'
						when ftr.exchange_id = 'IMPX' then fmjso.fix_message->>'7453'
						else fmjso.fix_message->>'115'
					end as street_on_behalf_of_sub_id
					,case
						when ftr.cross_type='C' then 'Customer Match'
						when ftr.cross_type in ('F','2') then 'Facilitation'
						when ftr.cross_type in ('P','4') then 'Price Improvement Mechanism'
						when ftr.cross_type='S' then 'Solicitation'
						when ftr.cross_type='Q' then 'Qualified Contingent Cross'
						when ftr.cross_type='1' then 'Solicitation or Customer Match Order'
						else ftr.cross_type
					end as cross_type
					,fmj.fix_message->>'37' as street_order_id
					,coalesce(ftr.leg_ref_id,case when ftr.multileg_reporting_type ='2' then fmjtr.fix_message->>'654'  else null end  ) as leg_ref_id
					,fmjpo.fix_message->>'116' as on_behalf_of_sub_id
					,case
						 when ftr.fix_comp_id = 'BLPINT' then fmjpo.fix_message->>'9300'
						 else  fmjpo.fix_message->>'10153'
					end  as billing_code
					,(fmjpo.fix_message->>'555')::int as no_legs
					,fmjpo.fix_message->>'115' as on_behalf_of_comp_id
					,coalesce (a2t.alloc_instr_id,alloc_id.alloc_instr_id) as alloc_instr_id
					,coalesce (a2t.alloc_instr_id,alloc_id.alloc_instr_id) as bundle_id
					,coalesce(cie.cmta, ca.cmta, ftr.cmta) as cmta
		from pre_ftr ftr
			left join lateral (
						select fix_message
							from fix_capture.fix_message_json fmjso_coi
							     where  fmjso_coi.date_id = ftr.create_date_id
							           and fmjso_coi.date_id >= l_min_order_process_time
							           and fmjso_coi.traffic_source=('D')
							           and fmjso_coi.message_type not in ('8','9')
							           and fmjso_coi.fix_message_id = ftr.order_fix_message_id
							           and fmjso_coi.client_order_id=ftr.secondary_order_id
						limit 1 ) fmjso_co on true
			left join lateral (
						select fix_message
							from fix_capture.fix_message_json as fmjso
							    where fmjso.date_id = ftr.str_create_date_id
							    	and fmjso.date_id >= l_min_order_process_time
							        and fmjso.fix_message_id=ftr.street_order_fix_message_id
							        and fmjso.traffic_source in('D')
						limit 1	) fmjso on true
			left join lateral (
						select fix_message
							from fix_capture.fix_message_json as fmjpo
							    where  fmjpo.date_id = ftr.create_date_id
							    	and fmjpo.date_id >= l_min_order_process_time
							        and fmjpo.fix_message_id=ftr.order_fix_message_id
							        and fmjpo.traffic_source='D'
						limit 1 ) fmjpo on true
			left join lateral (
						select fix_message
							from fix_capture.fix_message_json fmjso_box
							    where fmjso_box.date_id = ftr.date_id
							    	and fmjso_box.date_id between l_prev_date_id and l_end_date_id
							        and fmjso_box.traffic_source='D'
							        and fmjso_box.fix_message_id=ftr.street_trade_fix_message_id
						limit 1 ) fmjso_box on true
			left join lateral (
						select fix_message
							from fix_capture.fix_message_json fmjtr
							    where  fmjtr.date_id = ftr.date_id
							    	and fmjtr.date_id between l_prev_date_id and l_end_date_id
							        and fmjtr.traffic_source='D'
							        and fmjtr.fix_message_id=ftr.trade_fix_message_id
							limit 1 )fmjtr on true
			left  join lateral (
						select fix_message
							from fix_capture.fix_message_json fmj_i
							    where fmj_i.date_id = ftr.date_id
							        and fmj_i.date_id between l_prev_date_id and l_end_date_id
							        and fmj_i.traffic_source='D'
							        and fmj_i.client_order_id=ftr.secondary_order_id
							        and fmj_i.fix_message->>'17'=ftr.secondary_exch_exec_id
						limit 1 ) fmj on true
			left join lateral (
						select  sum(cl.order_qty) as qty
							from  dwh.client_order cl
							   where cl.multileg_order_id = ftr.multileg_order_id
							     and cl.create_date_id between l_prev_date_id and l_end_date_id
							          ) ml on true
			left join dwh.allocation2trade_record a2t on a2t.trade_record_id = ftr.trade_record_id
													and a2t.date_id = ftr.date_id
													and a2t.date_id between l_prev_date_id and l_end_date_id
													and coalesce(ftr.trade_record_reason, '') not in ('L','U')
			left join lateral(
						select alloc_instr_id
							from  dwh.allocation2trade_record as  al
								where al.trade_record_id = ftr.trade_record_id
									and al.date_id = ftr.date_id
									and al.date_id between l_prev_date_id and l_end_date_id
									and coalesce(ftr.trade_record_reason, '') in ('L','U')
								limit 1 )alloc_id on true
			left join lateral(
						select cie2.cmta
							from dwh.clearing_instruction_entry cie2
								inner join dwh.clearing_instruction ci 	on cie2.clearing_instr_id = ci.clearing_instr_id
									and cie2.date_id=ci.date_id
									and cie2.date_id between l_prev_date_id and l_end_date_id
									and cie2.cmta is not null
									and ci.status = 'D'
									and ci.is_active
									and ftr.trade_record_id = coalesce (cie2.new_trade_record_id,cie2.trade_record_id )
						limit 1	) cie on true
			left join dwh.d_clearing_account ca on a2t.clearing_account_id  = ca.clearing_account_id
			left  join dwh.d_exchange ex   on ftr.exchange_id = ex.exchange_id
											and ex.is_active
											and ex.instrument_type_id = 'O'
			left  join  dwh.d_exchange ex1  on ftr.last_mkt = ex1.last_mkt and ex1.exchange_id=ex1.real_exchange_id and ex1.is_active
			left  join dwh.d_exchange rex on rex.exchange_id = ex.real_exchange_id	and rex.is_active
			) pre_ftr
			;