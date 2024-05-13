	     -------------------Option Order Mod.-------------------------
        select in_reporter_imid as CLIENT_MPID, --to take correctly
               'SOR' as FILE_GROUP,
        	   '2'::varchar as ORDER_IND,

		'NEW'||','||
		''||','||
		to_char(cl.process_time,'YYYYMMDD')||'_'||cl.order_id::varchar||'_'||'OBO_OM'||'_'||'1'||','||
		'MOOM'||','||
		in_reporter_imid||','||
		--YYYYMMDD HHMMSS.CCCNNNNNN
		to_char(cl.process_time,'YYYYMMDD')||' 000000.000'||','||
		case
			when in_reporter_imid = 'CTCA' then
				replace(cl.client_order_id,'|','-')||'_'||fc.fix_comp_id
			else
				replace(cl.client_order_id,'|','-')
		end||','||
		oc.opra_symbol||','||
		to_char(orig.process_time,'YYYYMMDD')||' 000000.000'||','||--priorOrderDate
		case
			when in_reporter_imid = 'CTCA' then
				replace(orig.client_order_id,'|','-')||'_'||fc.fix_comp_id
			else
				replace(orig.client_order_id,'|','-')
		end
		--replace(orig.client_order_id,'|','-')
		||','||--priorOrderID[10]
		''||','||--originatingIMID
		to_char(cl.process_time,'YYYYMMDD HH24MISS.US')||','||--event (need to take from execution)
		--
		''||','||--manualOrderKeyDate
		''||','||--manualOrderID
		'false'||','||--manual flag [15]
		--
		'false'||','||--electronicDupFlag - need to check
		''||','||--electronicTimestamp
		--
		case
			when in_reporter_imid = 'MAXM' or (in_reporter_imid = 'PIPR' and aac.cat_fdid like '%:%') then
				--
				--(select coalesce(crd_number||':','') from compliance.crd_number_list where cat_imid = in_reporter_imid and (crd_amount = 1 or is_default = 'Y'))||
				coalesce(tf.cat_crd||':','')||
				in_reporter_imid
				--
			else ''
		end||','||--receiverIMID
		case
			when in_reporter_imid = 'MAXM' then '128605:AOSD'
			when in_reporter_imid = 'PIPR' and aac.cat_fdid like '%:%' then aac.cat_fdid
			else ''
		end||','||--senderIMID
		--
		case
			when in_reporter_imid = 'MAXM' or (in_reporter_imid = 'PIPR' and aac.cat_fdid like '%:%') then 'F'
			--
			else ''
		end||','||--senderType (F=Industry Member)[20]
		case
			when in_reporter_imid = 'PIPR' and aac.cat_fdid like '%:%'
				then coalesce(fxm.tag_8006,replace(cl.client_order_id,'|','-'))
			else
				replace(cl.client_order_id,'|','-')
		end||','||--routedOrderID
		'C' ||','||--initiator
		--
		case cl.side
		  when '1' then 'B'
		  else 'S'
		end||','||--side
		case
		    when cl.order_type_id in ('2','4') then to_char(abs(coalesce(cl.price,0)), 'FM9999999990.09999999')
			else ''
		end||','||
		cl.order_qty||','||--[25]
		''||','||--minQty
		cl.order_qty||','||--leavesQty - to be adjusted
		case
		    when cl.order_type_id in ('2','4') then 'LMT'
			else 'MKT'
		end||','||
		case
			when tif.tif_short_name in ('GTC','IOC') then tif.tif_short_name
			when tif.tif_short_name = 'GTX' then 'GTX='||to_char(cl.create_time,'YYYYMMDD')
			when tif.tif_short_name = 'GTD' and cl.expire_time is not null then 'GTD='||to_char(cl.expire_time,'YYYYMMDD')
			when cl.time_in_force_id in ('C','M') then 'GTC'
			else 'DAY='||to_char(cl.create_time,'YYYYMMDD')
		end||','||
		--compliance.get_sor_trading_session(cl.order_id, 'O', cl.create_date_id)||','||--[30]
		case
			--when fxm.tag_9281 in ('A','D','G') or fxm.tag_22017 = 'A' then 'ALL'
			--when fxm.tag_9281 in ('F','C') or fxm.tag_22017 = 'B' then 'REGPOST'
			when in_reporter_imid in ('FLTU') then 'ALL'
			when fxm.fix_message->>'9281' in ('A','D','G') or fxm.fix_message->>'22017' = 'A' then 'ALL'
			when fxm.fix_message->>'9281' in ('F','C') or fxm.fix_message->>'22017' = 'B' then 'REGPOST'
			else 'REG'
		end||','||--[30]
		--handling instructions
		-----------------------
		--compliance.get_sor_handl_inst_2d(cl.order_id, 'O', cl.create_date_id, fxm.fix_message)||','||
		concat_ws
			('|',
			nullif(compliance.get_sor_handl_inst_2d(cl.order_id, 'O', cl.create_date_id, fxm.fix_message),''),
			case
				when cl.sub_strategy_desc = 'DMA' then 'DIR'
			end
			)||','||
		-----------------------
		case cl.open_close
		  when 'C' then 'Close'
		  when 'O' then 'Open'
		end||','||
		to_char(cl.process_time,'YYYYMMDD HH24MISS.US')||','||
		''||','||--reserved for future use
		''||','||--aggregated orders[35]
		'N'||','||--representativeInd (combined)
		''||','||--[retired]
		''||','||
		''--netPrice


		:: varchar

		as ROE

		from client_order cl
		inner join client_order orig on orig.order_id = cl.orig_order_id
		inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
		inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
		--inner join d_instrument i on cl.instrument_id = i.instrument_id
		inner join d_option_contract oc on oc.instrument_id = cl.instrument_id
		inner join d_option_series os on os.option_series_id  = oc.option_series_id
		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
		left join lateral
	        (select j.fix_message,
	        		j.fix_message->>'9322' as tag_9322,j.fix_message->>'8006' as tag_8006,
	        		j.fix_message->>'432' as tag_432,j.fix_message->>'423' as tag_423
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = cl.fix_message_id
	         and j.date_id = in_date_id
	         limit 1
	        ) fxm on true
	    left join lateral
	    	(select a.cat_fdid
	    	 from d_account a
	    	 where a.account_name = fxm.tag_9322
	    	 and a.trading_firm_id = tf.trading_firm_id
	    	 and a.is_active = true
	    	 and in_reporter_imid = 'PIPR'
	    	 limit 1
	    	) aac on true
		/*
		left join lateral
			(select str.parent_order_id,
			 count(1) cross_cnt
			 from client_order str
			 where str.trans_type <> 'F'
			 and str.parent_order_id is not null
			 and str.create_date_id = in_date_id
			 and str.parent_order_id = cl.order_id
			 group by str.parent_order_id
			 limit 1
			) so on true
		*/
		where cl.create_date_id = in_date_id
		and orig.create_date_id > 20200717
		and (orig.create_date_id = in_date_id or orig.time_in_force_id in ('1','6'))
		and cl.parent_order_id is null
		and cl.trans_type = 'G'
		--and i.instrument_type_id = 'O'
		and cl.multileg_reporting_type = '1'
		--and cl.cross_order_id is null
		--
		--and coalesce(tf.cat_imid,'NONE') = in_reporter_imid
		and ((coalesce(tf.cat_imid,'NONE') = in_reporter_imid and ac.trading_firm_id != 'cowen01')
			or (ac.trading_firm_id = 'cowen01') and in_reporter_imid = ac.broker_dealer_mpid)
		--
		--and ac.cat_report_on_behalf_of = 'Y'
		and (ac.cat_report_on_behalf_of = 'Y' or in_reporter_imid = 'PIPR')
		and tf.cat_report_on_behalf_of = 'Y'
		and (fc.fix_comp_id in ('RTFIXPINT','AOSHUNTER','ACTACCREATIVE','ACTACCREATIVE2','ACTACREATIV','ACTACREATIV2','RBTECH','RBTECH2','RBTECH3','RBTECHP','TETHS4170') or in_reporter_imid <> 'AOSD')
		and (fc.fix_comp_id not in ('REDIMBK1INT') or in_reporter_imid <> 'CTCA')
		and (fc.fix_comp_id not in ('LPOPTP','LPEQP','LQPNCP','LPEQPGTH','LPOPTPGTH') or in_reporter_imid <> 'CNTP')
		and ((fc.fix_comp_id in ('TRAFIXBP','TRAFIXBPINT') and cl.ex_destination = 'BRKPT')
			or in_reporter_imid <> 'PIPR'
			)
		and fc.fix_comp_id not in ('BLAZE7PROD3')
		and os.root_symbol not in (select symbol from dwh.d_test_symbol_list)
		--and cl.order_id not in (select ex.order_id from execution ex where ex.exec_date_id = in_date_id and ex.is_parent_level = true and ex.exec_type = 'T')
		--and (cl.ex_destination <> 'LIQPT' or coalesce(so.cross_cnt,0) > 0 )
		--and ac.trading_firm_id = 'belvcaid'
		--and cl.order_id in (select order_id from compliance.temp_order_id )
		--
		--and fc.fix_comp_id in ('ACTACCREATIVE','ACTACCREATIVE2')
		--recovery start
		and ((is_recovery is true and cl.order_id in (select order_id from dwh.client_order_late col)) or is_recovery is false)
		--recovery end
		order by CLIENT_MPID, ORDER_IND


        select * from get_dateid('2024-05-09 20:03:23.436'::timestamp)