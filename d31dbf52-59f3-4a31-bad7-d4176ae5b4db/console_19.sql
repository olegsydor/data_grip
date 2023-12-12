-- FUNCTION getETradeGTC(p_date IN DATE) RETURN REF_CURSOR IS
--   rs REF_CURSOR;
--   BEGIN
--     OPEN rs FOR
--
-- 	select
-- 	case
-- 		when REC_TYPE = 'TRL' then REC||'|'||to_char(REC_NUM-1)
-- 		else REC
-- 	  end
-- 	from
-- 	(
-- 	  select REC, REC_TYPE, OUT_ORD_FLAG, rownum as REC_NUM
-- 	  from (
		 select 'DET' as REC_TYPE, 2 as OUT_ORD_FLAG,
         'DET'||'|'|| --[1]
         decode(CL.MULTILEG_REPORTING_TYPE,'1','SIMPLE','2','COMPLEX')||'|'||--[2]
         'Dash'||'|'||--[3]
         decode(I.INSTRUMENT_TYPE_ID,'O','OP','E','EQ')||'|'||--[4]
         decode(I.INSTRUMENT_TYPE_ID,'O',DO.ROOT_SYMBOL,'E',I.SYMBOL)||'|'||--[5]
         decode(I.INSTRUMENT_TYPE_ID,'O',replace(DO.OPRA_SYMBOL,' ','-'))||'|'|| --[6]
         decode(CL.MULTILEG_REPORTING_TYPE,'1','0','2',CL.CO_CLIENT_LEG_REF_ID)||'|'|| --[7]
         decode(CL.SIDE,'1','Buy','2','Sell','5','Short Sell','6','Short Sell')||'|'||--[8]
         decode(DO.PUT_CALL,'0','Put','1','Call')||'|'|| --[9]
         decode(CL.OPEN_CLOSE,'O','Open','C','Close')||'|'|| --[10]
         OT.ORDER_TYPE_SHORT_NAME||'|'||--Order Type --[11]
         --CL.ORDER_QTY||'|'||
         (CL.ORDER_QTY - NVL((select sum(EX.LAST_QTY) from EXECUTION EX where EX.ORDER_ID = CL.ORDER_ID and EX.EXEC_TYPE = 'F' and trunc(EX.EXEC_TIME)>=trunc(CL.CREATE_TIME)),0))||'|'|| --[12]
         to_char(CL.PRICE, 'FM99990D0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
         to_char(DO.STRIKE_PRICE, 'FM99990D0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
         to_char(CL.STOP_PRICE, 'FM99990D0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
         case
            when I.INSTRUMENT_TYPE_ID = 'O' and CL.ORDER_TYPE in ('2','4') then to_char(CL.PRICE, 'FM99990D0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
         end||'|'||--[16]
         ''||'|'||
         to_char(CL.CREATE_TIME,'YYYYMMDD')||'|'||
         to_char(I.LAST_TRADE_DATE,'YYYYMMDD')||'|'||
         ''||'|'||
         ''||'|'||
         ''||'|'||
         --
         CL.ORDER_ID||'|'|| --23
         --
         ''||'|'||
         CL.CLIENT_ORDER_ID||'|'|| --25
         ''||'|'|| --26
         --
         ''||'|'|| --Covererd/Uncovered
         ''||'|'||
         ''||'|'||
         ''||'|'||
		 ''||'|'|| --Record type
		 AC.BROKER_DEALER_MPID --MPID

		 as REC;
create temp table t_os_gtc as

select cl.order_id, cl.instrument_id, gtc.last_trade_date
		from dwh.gtc_order_status gtc
		    join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
         inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		---------------------------------------------------------------------------------------------------------
-- 		left join dwh.d_DRV_OPTION DO on (DO.INSTRUMENT_ID = CL.INSTRUMENT_ID)
         left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
         left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
		inner join dwh.d_ORDER_TYPE OT on (CL.ORDER_TYPE_id = OT.ORDER_TYPE_ID)
-- 		inner join dwh.mv_ACTIVE_ACCOUNT_SNAPSHOT AC on (CL.ACCOUNT_ID = AC.ACCOUNT_ID )


		where 1=1
  		  and gtc.order_id = 13939235748
		and gtc.account_id in (select account_id from dwh.mv_ACTIVE_ACCOUNT_SNAPSHOT AC where AC.TRADING_FIRM_ID = 'OFP0016')
	    --and trunc(CL.CREATE_TIME) = trunc(sysdate-1)
		and CL.PARENT_ORDER_ID is NULL
		and CL.TRANS_TYPE <> 'F'
--         and coalesce(I.LAST_TRADE_DATE, '2023-12-09') > '2023-12-08'
 		  and coalesce(gtc.last_trade_date, '2023-12-09') > '2023-12-08'
-- 		  and gtc.last_trade_date >= '2023-12-08'
        and gtc.TIME_IN_FORCE_id = '1'
        and CL.MULTILEG_REPORTING_TYPE <> '3'

		and gtc.close_date_id is null
		and not exists(select null from dwh.execution ex where ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id and ORDER_STATUS in ('2','4','8'))
order by 1 desc



	    union all

	    select  'HDR' as REC_TYPE, 1 as OUT_ORD_FLAG,
	    'HDR'||'|'||to_char(systimestamp, 'YYYYMMDD')||'|'||to_char(systimestamp, 'HH24:MM:SS')||'|'||'Dash OPTIONS' as REC
	    from dual

        union all

		select  'TRL' as REC_TYPE, 3 as OUT_ORD_FLAG,
		'TRL'||'|'||to_char(systimestamp, 'YYYYMMDD')||'|'||to_char(systimestamp, 'HH24:MM:SS') as REC
		from dual


	  )
	)
	order by OUT_ORD_FLAG;

	RETURN rs;
  END getETradeGTC;


select * from dwh.client_order
         where order_id = 13939235748