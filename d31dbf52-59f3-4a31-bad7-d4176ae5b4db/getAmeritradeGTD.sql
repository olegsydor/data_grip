


 FUNCTION getAmeritradeGTD(p_date IN DATE) RETURN REF_CURSOR IS
  rs REF_CURSOR;
  BEGIN
    OPEN rs FOR

	select
		case
			when REC_TYPE = 'TRL' then REC||'|'||to_char(REC_NUM-2)
			else REC
		end
	from (
	  select REC, REC_TYPE, OUT_ORD_FLAG, rownum as REC_NUM
	  from (
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
			 end

		as REC

		  from CLIENT_ORDER CL
		  inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		  inner join EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID
		  left join
				(select ORDER_ID,
					CO_MULTILEG_ORDER_ID MULTILEG_ORDER_ID,
					dense_rank() over (partition by CO_MULTILEG_ORDER_ID order by ORDER_ID) LEG_NUMBER
		  from CLIENT_ORDER
		  where MULTILEG_REPORTING_TYPE = '2') OLN on (OLN.ORDER_ID = CL.ORDER_ID)
		  left join DRV_OPTION DO on (DO.INSTRUMENT_ID = CL.INSTRUMENT_ID)
		  inner join ACTIVE_ACCOUNT_SNAPSHOT AC on (CL.ACCOUNT_ID = AC.ACCOUNT_ID )


		  where 1=1
		  and AC.TRADING_FIRM_ID in ('OFP0011')
		  and CL.PARENT_ORDER_ID is NULL
		  and CL.TIME_IN_FORCE = '6'
		  and CL.TRANS_TYPE <> 'F'
		  and CL.MULTILEG_REPORTING_TYPE <> '3'
		  and CL.ORDER_ID not in (select ORDER_ID from EXECUTION where ORDER_STATUS in ('2','4','8'))
		  and EX.EXEC_ID = (select max(EXEC_ID) from EXECUTION where ORDER_ID = CL.ORDER_ID and ORDER_STATUS <> '3')
		  and to_char(NVL(CL.EXPIRE_TIME, to_date((select FIELD_VALUE from FIX_MESSAGE_FIELD where FIX_MESSAGE_ID = CL.FIX_MESSAGE_ID and TAG_NUM = 432),'YYYYMMDD')),'YYYYMMDD') > to_char(p_date, 'YYYYMMDD')

		  union all

		  select  'HDR' as REC_TYPE, 1 as OUT_ORD_FLAG,
		  'LIQUID2A'||'|'||to_char(systimestamp, 'MMDDYYYY') as REC
		  from dual

		  union all

		  select  'TRL' as REC_TYPE, 3 as OUT_ORD_FLAG,
		  'Total Number of  Records' as REC
		  from dual

	  )
	)
	order by OUT_ORD_FLAG;

	RETURN rs;
  END getAmeritradeGTD;
