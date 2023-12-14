

create function dash360.report_rps_ofp0011_gtd()
    returns table(ret_row text)
    language plpgsql
    as $$

    begin

    create temp table tmp_ameri /*on commit drop*/ as

    select CL.ORDER_ID, -- || '|' ||--Order Number
           CL.MULTILEG_REPORTING_TYPE,
           cl.no_legs,            --||'|'|| --Order Leg ID
           CL.CREATE_TIME,        --||'|'|| --Order Entry Date
           CL.SIDE,               --||'|'||--Action
           CL.ORDER_TYPE_id,      --||'|'||--Type
           CL.ORDER_QTY,          --||'|'||
           EX.LEAVES_QTY,         --||'|'||
           di.INSTRUMENT_TYPE_ID, --||'|'||
           di.INSTRUMENT_TYPE_ID,
           di.SYMBOL,             --||'|'||
           os.ROOT_SYMBOL,        --||'|'||
           oc.PUT_CALL,           --||'|'||
           CL.OPEN_CLOSE,         --||'|'||
           di.INSTRUMENT_TYPE_ID,
           di.LAST_TRADE_DATE,    --||'|'||
           oc.STRIKE_PRICE,       --||'|'||
           CL.PRICE,              --||'|'||
           CL.STOP_PRICE,         --||'|'||
           CL.TIME_IN_FORCE_id,   --||'|'||
           CL.EXPIRE_TIME,        --||'|'||
           fmj.t432,
           cl.exec_instruction
    from dwh.gtc_order_status gtc
             join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id
             join lateral (select ex.exec_id as exec_id,
                                  ex.avg_px,
                                  ex.leaves_qty,
                                  ex.order_status
                           from dwh.execution ex
                           where gtc.order_id = ex.order_id
                             and ex.order_status <> '3'
                             and ex.exec_date_id >= gtc.create_date_id
                           order by ex.exec_time desc
                           limit 1) ex on true
             left join lateral (select fix_message ->> '432' as t432
                                from fix_capture.fix_message_json fmj
                                where true
                                  and fmj.fix_message_id = cl.fix_message_id
                                  and fmj.date_id = cl.create_date_id
                                  and fix_message ->> '432' is not null
                                limit 1) fmj on true
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join d_option_series os on (oc.option_series_id = os.option_series_id)
    where true
		  and gtc.account_id in (select account_id from dwh.mv_active_account_snapshot ac where ac.is_active and AC.TRADING_FIRM_ID in ('OFP0011'))
		  and CL.PARENT_ORDER_ID is NULL
		  and gtc.TIME_IN_FORCE_id = '6'
		  and CL.TRANS_TYPE <> 'F'
		  and CL.MULTILEG_REPORTING_TYPE <> '3'
       and not exists (select null from dwh.execution ex where ex.order_id = gtc.order_id and ex.exec_date_id >= gtc.create_date_id and ex.order_status in ('2','4','8'))
and gtc.close_date_id is null;



/*	select
		case
			when REC_TYPE = 'TRL' then REC||'|'||to_char(REC_NUM-2)
			else REC
		end
	from (
	  select REC, REC_TYPE, OUT_ORD_FLAG, rownum as REC_NUM
	  from (


		  select  'HDR' as REC_TYPE, 1 as OUT_ORD_FLAG,
		  'LIQUID2A'||'|'||to_char(systimestamp, 'MMDDYYYY') as REC
		  from dual

		  union all

   select 'DET' as REC_TYPE, 2 as OUT_ORD_FLAG,
			 CL.ORDER_ID||'|'||--Order Number
			 decode(CL.MULTILEG_REPORTING_TYPE,'1','0','2',OLN.LEG_NUMBER)||'|'|| --Order Leg ID
			 to_char(CL.CREATE_TIME,'MMDDYYYY')||'|'|| --Order Entry Date
			 decode(CL.SIDE,'1','B','2','S','5','SS','6','SS')||'|'||--Action
			 decode(CL.ORDER_TYPE,'1','M','2','L','3','S','4','SL','L')||'|'||--Type
			 CL.ORDER_QTY||'|'||
			 EX.LEAVES_QTY||'|'||
			 I.INSTRUMENT_TYPE_ID||'|'||
			 decode(I.INSTRUMENT_TYPE_ID,'E',I.SYMBOL)||'|'||
			 decode(I.INSTRUMENT_TYPE_ID,'O',DO.ROOT_SYMBOL)||'|'||
			 decode(DO.PUT_CALL,'0','P','1','C')||'|'||
			 CL.OPEN_CLOSE||'|'||
			 decode(I.INSTRUMENT_TYPE_ID,'O',to_char(I.LAST_TRADE_DATE,'MMDDYY'))||'|'||
			 to_char(DO.STRIKE_PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
			 to_char(CL.PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
			 to_char(CL.STOP_PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
			 decode(CL.TIME_IN_FORCE,'1','GTC','6','GTD',CL.TIME_IN_FORCE)||'|'||
			 to_char(NVL(CL.EXPIRE_TIME, to_date((select FIELD_VALUE from FIX_MESSAGE_FIELD where FIX_MESSAGE_ID = CL.FIX_MESSAGE_ID and TAG_NUM = 432),'YYYYMMDD')),'MMDDYYYY')||'|'||
			 case
			  when CL.EXEC_INST like '%G%' then 'AON'
			  when CL.EXEC_INST like '%1%' then 'NH'
			 end;

   union all

		  select  'TRL' as REC_TYPE, 3 as OUT_ORD_FLAG,
		  'Total Number of  Records' as REC
		  from dual

	  )
	)
	order by OUT_ORD_FLAG;
*/
	RETURN rs;
  END getAmeritradeGTD;
$$