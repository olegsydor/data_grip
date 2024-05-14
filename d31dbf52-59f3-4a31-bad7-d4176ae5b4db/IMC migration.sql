create table if not exists trash.matched_cross_trades_pg_2
(
    orig_exec_id   int8,
    contra_exec_id int8,
    constraint matched_cross_trades_pg_2_pk primary key (orig_exec_id, contra_exec_id)
);
call trash.match_cross_trades_pg(in_date_id := 20240513);

CREATE OR REPLACE PROCEDURE trash.match_cross_trades_pg(in_date_id int4)
    language plpgsql
as
$$
declare
    orig_trade     record;
    contra_trade   record;
    v_orig_exec_id int8;
begin

    truncate table trash.matched_cross_trades_pg;

    for orig_trade in (select CL.CROSS_ORDER_ID,
                              CL.ORDER_ID,
                              CL.IS_ORIGINATOR,
                              CL.INSTRUMENT_ID,
                              EX.EXEC_ID,
                              EX.ORDER_STATUS,
                              EX.LAST_QTY,
                              EX.LAST_PX
                       from dwh.CLIENT_ORDER CL
                                inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                                inner join dwh.d_FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
                                inner join dwh.EXECUTION EX
                                           on CL.ORDER_ID = EX.ORDER_ID and ex.exec_date_id >= in_date_id
                                inner join dwh.CROSS_ORDER CRO on CRO.CROSS_ORDER_ID = CL.CROSS_ORDER_ID
                                inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                                inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                       where cl.create_date_id = in_date_id
                         and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
                         and CL.PARENT_ORDER_ID is not null
                         and EX.IS_BUSTED = 'N'
                         and EX.EXEC_TYPE = 'F'
                         and CL.TRANS_TYPE <> 'F'
                         and TF.IS_ELIGIBLE4CONSOLIDATOR = 'Y'
                         and CL.INTERNAL_COMPONENT_TYPE = 'A'
                         and FC.FIX_COMP_ID <> 'IMCCONS'
                       order by CL.CROSS_ORDER_ID, CL.ORDER_ID, EX.EXEC_ID)

        loop


            v_orig_exec_id := orig_trade.exec_id;
            --v_contra_exec_id := 0;
            for contra_trade in (select ex.exec_id
                                 from execution ex
                                          inner join client_order cl on ex.order_id = cl.order_id
                                 where cl.cross_order_Id = orig_trade.cross_order_id
                                   and cl.instrument_id = orig_trade.instrument_id
                                   and cl.is_originator = 'C'
                                   and orig_trade.last_qty = ex.last_qty
                                   and orig_trade.last_px = ex.last_px
                                   and ex.exec_type = 'F')
                loop
                    merge into trash.matched_cross_trades_pg as mct
                    using (select v_orig_exec_id as orig_exec_id, contra_trade.exec_id as contra_exec_id) mt
                    on (mct.orig_exec_id = mt.orig_exec_id or mct.contra_exec_id = mt.contra_exec_id)
                    when not matched then
                        insert (orig_exec_id, contra_exec_id)
                        values (v_orig_exec_id, mt.contra_exec_id);
                end loop;
        end loop;
end;
$$;




CREATE OR REPLACE procedure trash.get_Consolidator_EOD_PG(in_date_id int4)
language plpgsql
    as $$
   declare

  BEGIN
	call trash.match_cross_trades_pg(in_date_id);
-- 	truncate table trash.cons_eod_permanent;

	/*
      insert into trash.CONS_EOD_permanent (TRANSACTION_ID,
                      REC_TYPE,
                      ORDER_STATUS,
                      TRADING_FIRM_ID,
                      CREATE_TIME,
                      EXEC_TIME,
                      OPRA_SYMBOL,
                      BASE_CODE,
                      ROOT_SYMBOL,
                      BASE_ASSET_TYPE,
                      EXPIRATION_DATE,
                      STRIKE_PRICE,
                      TYPE_CODE,
                      SIDE,
                      LEG_COUNT,
                      LEG_NUMBER,
                      ORD_STATUS,
                      PRICE,
                      LAST_PX,
                      ORDER_QTY,
                      LAST_QTY,
                      RFR_ID,
                      ORIG_RFR_ID,
                      CLIENT_ORDER_ID,
                      REPLACED_ORDER_ID,
                      CANCEL_ORDER_ID,
                      PARENT_ORDER_ID,
                      ORDER_ID,
                      EXCHANGE_CODE,
                      EX_CONNECTION,
                      GIVE_UP_FIRM,
                      CMTA_FIRM,
                      CLEARING_ACCOUNT,
                      SUB_ACCOUNT,
                      OPEN_CLOSE,
                      RANGE,
                      COUNTERPARTY_RANGE,
                      ORDER_TYPE,
                      TIME_IN_FORCE,
                      EXEC_INST,
                      TRADE_LIQUIDITY_INDICATOR,
                      EXCH_EXEC_ID,
                      EXCH_ORDER_ID,
                      CROSS_ORDER_ID,
                      AUCTION_TYPE,
                      REQUEST_COUNT,
                      BILLING_CODE,
                      CONTRA_BROKER,
                      CONTRA_TRADER,
                      WHITE_LIST,
                      CONS_PAYMENT_PER_CONTRACT,
                      CONTRA_CROSS_EXEC_QTY,
					  CONTRA_CROSS_LP_ID)
      */
     with white as (select SS.SYMBOL, CLP.INSTRUMENT_TYPE_ID
               from SYMBOL2LP_SYMBOL_LIST SS
                        inner join CONS_LP_SYMBOL_LIST CLP on CLP.LP_SYMBOL_LIST_ID = SS.LP_SYMBOL_LIST_ID
               where CLP.LIQUIDITY_PROVIDER_ID = 'IMC')
   , black as (select SS.SYMBOL, CLP.INSTRUMENT_TYPE_ID
               from SYMBOL2LP_SYMBOL_LIST SS
                        inner join CONS_LP_SYMBOL_BLACK_LIST CLP on CLP.LP_SYMBOL_LIST_ID = SS.LP_SYMBOL_LIST_ID
               where CLP.LIQUIDITY_PROVIDER_ID = 'IMC')
		select  /*+  MONITOR LEADING(EX CL AC TF FC ) USE_NL(EX CL FC )
                CARDINALITY (EX 10)*/
		CL.TRANSACTION_ID,
		EX.ORDER_ID as REC_TYPE,
		EX.EXEC_ID as ORDER_STATUS,
		AC.TRADING_FIRM_ID, --EntityCode
		CL.CREATE_TIME,
		EX.EXEC_TIME,
		OC.OPRA_SYMBOL, --OSI
		decode(I.INSTRUMENT_TYPE_ID,'E',I.SYMBOL, 'O',UI.SYMBOL) as BASE_CODE,
		decode(I.INSTRUMENT_TYPE_ID,'E',I.SYMBOL, 'O',OS.ROOT_SYMBOL) as ROOT_SYMBOL,
		--ETF - use file?
		decode(UI.INSTRUMENT_TYPE_ID,'E','EQUITY','I','INDEX') as BASE_ASSET_TYPE,
		--
		OC.MATURITY_YEAR||to_char(OC.MATURITY_MONTH, 'FM00')||to_char(OC.MATURITY_DAY, 'FM00') as EXPIRATION_DATE,
		OC.STRIKE_PRICE,
		decode(OC.PUT_CALL,'0','P','1','C','S') as TYPE_CODE, -- (S - stock)
		decode(CL.SIDE,'1','B','2','S', '5','SS', '6', 'SS'), --SIDE

		NVL((select CO_NO_LEGS from CLIENT_ORDER where ORDER_ID = CL.CO_MULTILEG_ORDER_ID),1), --LEG_COUNT
		LN.LEG_NUMBER,
		case
		 when EX.EXEC_TYPE in ('4','5') then decode(EX.EXEC_TYPE,'4','Canceled','5','Replaced')
		 when EX.EXEC_TYPE = 'F' and EX.ORDER_STATUS = '6' then
			case
			  when EX.CUM_QTY = CL.ORDER_QTY then 'Filled'
			  else 'Partial Fill'
			end
		else decode(EX.ORDER_STATUS,'A','Pending New','0','New','8','Rejected', 'a','Pending Replace','b','Pending Cancel','1','Partial Fill','2','Filled','3','Done For Day', EX.ORDER_STATUS )  --Status
		end, --ORD_STATUS
		CL.PRICE,
		EX.LAST_PX,
		CL.ORDER_QTY, --Entered Qty
		-- ask++
		EX.LAST_QTY, --StatusQty

		case
		  when CL.PARENT_ORDER_ID is null then CL.EXCH_ORDER_ID
		  when AC.TRADING_FIRM_ID <> 'imc01' then (select EXCH_ORDER_ID from CLIENT_ORDER where ORDER_ID = CL.PARENT_ORDER_ID)
		  else (select EXCH_ORDER_ID from CLIENT_ORDER where ORDER_ID = (select max(PARENT_ORDER_ID) from CLIENT_ORDER where CROSS_ORDER_ID = CL.CROSS_ORDER_ID and IS_ORIGINATOR <> CL.IS_ORIGINATOR))
		end,--RFR_ID
		case
		  when CL.PARENT_ORDER_ID is null then (select ORIG.EXCH_ORDER_ID from CLIENT_ORDER ORIG where ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
		  when AC.TRADING_FIRM_ID <> 'imc01' then (select ORIG.EXCH_ORDER_ID from CLIENT_ORDER ORIG, CLIENT_ORDER CO where ORIG.ORDER_ID = CO.ORIG_ORDER_ID and CO.ORDER_ID =  CL.PARENT_ORDER_ID)
		  else (select ORIG.EXCH_ORDER_ID from CLIENT_ORDER ORIG, CLIENT_ORDER CO where ORIG.ORDER_ID = CO.ORIG_ORDER_ID and CO.ORDER_ID =  (select max(PARENT_ORDER_ID) from CLIENT_ORDER where CROSS_ORDER_ID = CL.CROSS_ORDER_ID and IS_ORIGINATOR <> CL.IS_ORIGINATOR))
		end,--ORIG_RFR_ID

		CL.CLIENT_ORDER_ID,

		case
		  when EX.EXEC_TYPE in ('S','W') then
			(select ORIG.CLIENT_ORDER_ID from CLIENT_ORDER ORIG where ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
		end,--REPLACED_ORDER_ID

		case
		  when EX.EXEC_TYPE in ('b','4') then
		  (select min(CXL.CLIENT_ORDER_ID) from CLIENT_ORDER CXL where CXL.ORIG_ORDER_ID = CL.ORDER_ID)
		end,--CANCEL_ORDER_ID

		PRO.CLIENT_ORDER_ID AS PARENT_CLIENT_ORDER_ID,

		CL.ORDER_ID, --SystemOrderID

		case
			when CL.EXCHANGE_ID = 'ALGOWX' then 'WEX_SWEEP'
			else NVL(CL.SUB_STRATEGY, EXC.MIC_CODE)
		end,-- EXCHANGE_CODE
		--
		--
		--
		case
		  when CL.PARENT_ORDER_ID is null then FC.ACCEPTOR_ID
		  when CL.SUB_SYSTEM_ID like '%CONS%' then 'CONS'
		  when CL.SUB_SYSTEM_ID like '%OSR%' then 'SOR'
		  when CL.SUB_SYSTEM_ID like '%ATLAS%' or CL.SUB_SYSTEM_ID like '%ATS%' then 'ATS'
		  else CL.SUB_SYSTEM_ID
		end, --EX_CONNECTION
		--
		--
		--

		NVL(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER), --GIVE_UP_FIRM
		case
		  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CL.OPT_CLEARING_FIRM_ID
		  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
		end, --CMTA_FIRM

		CL.CO_CLEARING_ACCOUNT,
		CL.CO_SUB_ACCOUNT,
		CL.OPEN_CLOSE,
		case
			  when (CL.PARENT_ORDER_ID is null or CL.OPT_CUSTOMER_FIRM is not null)
				then decode(NVL(CL.OPT_CUSTOMER_FIRM, AC.OPT_CUSTOMER_OR_FIRM)
				 , '0' , 'CUST'
				 , '1' , 'FIRM'
				 , '2' , 'BD'
				 , '3' , 'BD-CUST'
				 , '4' , 'MM'
				 , '5' , 'AMM'
				 , '7' , 'BD-FIRM'
				 , '8' , 'CUST-PRO'
				 , 'J' , 'JBO')
			  else coalesce(CL.OPT_CUSTOMER_FIRM,CL.EQ_ORDER_CAPACITY,cl.OPT_CUSTOMER_FIRM_STREET)
		end, --RANGE
		case when EX.EXEC_TYPE = 'F' then
		  case
			when CL.PARENT_ORDER_ID is not null then EX.CONTRA_ACCOUNT_CAPACITY
			else ES.CONTRA_ACCOUNT_CAPACITY
		  end
		end, --COUNTERPARTY_RANGE
		OT.ORDER_TYPE_SHORT_NAME,
		TIF.TIF_SHORT_NAME,
		CL.EXEC_INST,
		EX.TRADE_LIQUIDITY_INDICATOR,

		EX.EXCH_EXEC_ID,
		CL.EXCH_ORDER_ID,
		CL.CROSS_ORDER_ID,
		case
			when NVL(CL.STRATEGY_DECISION_REASON_CODE,STR.STRATEGY_DECISION_REASON_CODE) in ('32', '62', '96', '99') then 'FLASH'
			else decode(CRO.CROSS_TYPE,'P','PIM','Q','QCC','F','Facilitation','S','Solicitation',CRO.CROSS_TYPE)
		end,--AUCTION_TYPE
--       case
--           when NVL(CL.STRATEGY_DECISION_REASON_CODE, STR.STRATEGY_DECISION_REASON_CODE) in ('74') and
--                ex.exchange_id in ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
--               and exists (select null
--                           from liquidity_indicator li
--                           where (upper(description) like '%FLASH%' or upper(description) like '%EXPOSURE%')
--                             and li.trade_liquidity_indicator = ex.trade_liquidity_indicator)
--               then 'FLASH'
--           when NVL(CL.STRATEGY_DECISION_REASON_CODE, STR.STRATEGY_DECISION_REASON_CODE) in ('32', '62', '96', '99')
--               then 'FLASH'
--           else decode(CRO.CROSS_TYPE, 'P', 'PIM', 'Q', 'QCC', 'F', 'Facilitation', 'S', 'Solicitation', CRO.CROSS_TYPE)
--           end,--AUCTION_TYPE;

		--decode(CL.REQUEST_NUMBER,99,'',CL.REQUEST_NUMBER), --Req.count
		case
		  when CL.REQUEST_NUMBER >= 99 then ''
		  else to_char(CL.REQUEST_NUMBER)
		end, --REQUEST_COUNT

		case when EX.EXEC_TYPE = 'F' then
		  case
		  --
			when NVL(PRO.SUB_STRATEGY,CL.SUB_STRATEGY) = 'DMA' then 'DMA'
			when NVL(PRO.SUB_STRATEGY,CL.SUB_STRATEGY) in ('CSLDTR','RETAIL') and (coalesce(CL.REQUEST_NUMBER,STR.REQUEST_NUMBER,-1) between 0 and 99) then 'IMC'
            when NVL(PRO.SUB_STRATEGY,CL.SUB_STRATEGY) in ('CSLDTR','RETAIL') and coalesce(CL.REQUEST_NUMBER,STR.REQUEST_NUMBER,-1) > 99 then 'Exhaust'
			when ( NVL(PRO.SUB_STRATEGY,CL.SUB_STRATEGY) not in ('DMA','CSLDTR','RETAIL')
				   or
				   coalesce(CL.REQUEST_NUMBER,STR.REQUEST_NUMBER,-1) = -1
				  )
			  then
				case
				  when NVL(PRO.ORDER_TYPE,CL.ORDER_TYPE) in ('3','4','5','B') or NVL(PRO.TIME_IN_FORCE,CL.TIME_IN_FORCE) in ('2','7') then 'Exhaust_IMC'
				  --when getLPList(AC.ACCOUNT_ID,I.SYMBOL, trunc(p_date)) is null then 'Exhaust_IMC'
				  when getLPList(AC.ACCOUNT_ID, I.SYMBOL, trunc(p_date)) is null and getLPListLite(AC.ACCOUNT_ID,OS.ROOT_SYMBOL,decode(CL.MULTILEG_REPORTING_TYPE,'1','O','2','M')) is null then 'Exhaust_IMC'
				  else 'Exhaust'
				end
			else 'Other'
		  --
		  end
		end, --BILLING_CODE
		case when EX.EXEC_TYPE = 'F' then
		  case
			when CL.PARENT_ORDER_ID is not null then decode(EX.EXCHANGE_ID,'CBOE',ltrim(EX.CONTRA_BROKER,'CBOE:'),EX.CONTRA_BROKER)
			else decode(ES.EXCHANGE_ID,'CBOE',ltrim(ES.CONTRA_BROKER,'CBOE:'),ES.CONTRA_BROKER)
		  end
		end, --CONTRA_BROKER
		case when EX.EXEC_TYPE = 'F' then
		  case
			when CL.PARENT_ORDER_ID is not null then EX.CONTRA_TRADER
			else ES.CONTRA_TRADER
		  end
		end, --CONTRA_TRADER
        case
           when decode(I.INSTRUMENT_TYPE_ID, 'E', I.SYMBOL, 'O', OS.ROOT_SYMBOL) in
                (select SYMBOL
                from black
                where INSTRUMENT_TYPE_ID = case when cl.multileg_reporting_type = '1' then 'O' else 'M' end) then 'N'
           when decode(I.INSTRUMENT_TYPE_ID, 'E', I.SYMBOL, 'O', OS.ROOT_SYMBOL) in
                (select SYMBOL
                from white
                where INSTRUMENT_TYPE_ID = case when cl.multileg_reporting_type = '1' then 'O' else 'M' end) then 'Y'
           when (select count(*) from white where INSTRUMENT_TYPE_ID = case when cl.multileg_reporting_type = '1' then 'O' else 'M' end) = 0 then 'Y'
           else 'N'
           end, --as white_list --WHITE_LIST
		case when EX.EXEC_TYPE = 'F' then
			case
				when CL.PARENT_ORDER_ID is not null then NVL(CL.CONS_PAYMENT_PER_CONTRACT,'')
				else NVL(STR.CONS_PAYMENT_PER_CONTRACT,'')
			end
		end as CONS_PAYMENT_PER_CONTRACT,
		case when EX.EXEC_TYPE = 'F' then
			(select LAST_QTY from EXECUTION where EXEC_ID = MCT.CONTRA_EXEC_ID)
		end as CONTRA_CROSS_EXEC_QTY,
		--getContraCrossLPID(NVL(STR.ORDER_ID,CL.ORDER_ID))-- ALP.LP_DEMO_MNEMONIC
		case
            when CL.PARENT_ORDER_ID is null and STR.CROSS_ORDER_ID is not null
                then getContraCrossLPID_2(STR.ORDER_ID,STR.CROSS_ORDER_ID)
			when CL.PARENT_ORDER_ID is not null and CL.CROSS_ORDER_ID is not null
				then getContraCrossLPID_2(CL.ORDER_ID,CL.CROSS_ORDER_ID)
        end
select ex.order_id, *
	  from dwh.execution ex
	  inner join dwh.client_order cl on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
      inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
	  left join dwh.client_order pro on cl.parent_order_id = pro.order_id and pro.create_date_id >= cl.create_date_id
	  inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
	  inner join dwh.d_account ac on ac.account_id = cl.account_id
	  inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
/*      left join dwh.client_order str on (cl.order_id = str.parent_order_id and ex.secondary_order_id = str.client_order_id and ex.exec_type = 'F') --street order for this trade
	  left join dwh.execution es on (es.order_id = str.order_id and es.exch_exec_id = ex.secondary_exch_exec_id and es.exec_date_id >= str.create_date_id)
	  left join dwh.cross_order cro on cro.cross_order_id = cl.cross_order_id
	  left join trash.matched_cross_trades_pg mct on mct.orig_exec_id = coalesce(es.exec_id, ex.exec_id)

	  left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id
	  left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
	  left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
	  left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id



	  left join dwh.d_clearing_account ca on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1')
	  left join dwh.d_opt_exec_broker opx on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
	  left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
	  left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
	  left join dwh.client_order_leg_num ln on ln.order_id = cl.order_id
*/
      where ex.exec_date_id = :in_date_id
      and cl.multileg_reporting_type in ('1','2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E','S','D','y')
      and cl.trans_type <> 'F'
      and tf.is_eligible4consolidator = 'Y'
	  and fc.fix_comp_id <> 'IMCCONS'
      and ex.order_id in (15540506881,15540506885,15540506892,15540506879,15540506885,15540506892,15540506879,15540506890,15540506890,15540506887)
	limit 100
--      and 1=2
      ;
commit;

end;
$$


select ex.order_id, *
	  from dwh.execution ex
where ex.exec_date_id = :in_date_id

      and ex.is_busted = 'N'
      and ex.exec_type not in ('E','S','D','y')
      and ex.order_id in ()