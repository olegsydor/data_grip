		  select 
			EX.ORDER_ID as rec_type, 
			EX.EXEC_ID as order_status,
			AC.ACCOUNT_NAME, --UserLogin
			FC.FIX_COMP_ID, --SendingUserLogin
			AC.TRADING_FIRM_ID, --EntityCode
			TF.TRADING_FIRM_NAME, --EntityName
			'', --DestinationEntity
			'', --Owner
			'', --Generation
			'', --ChildOrders
			to_char(CL.CREATE_TIME,'YYYYMMDD'), --CreateDate
			to_char(EX.EXEC_TIME,'HH24MISSFF3'), --CreateTime
			'', --StatusDate
			'', --StatusTime
			OC.OPRA_SYMBOL, --OSI
			UI.SYMBOL,--BaseCode
			OS.ROOT_SYMBOL, --Root
			UI.INSTRUMENT_TYPE_ID, --BaseAssetType
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR, --ExpirationDate 
			OC.STRIKE_PRICE,
			case OC.PUT_CALL when '0' then 'P' else 'C' end, --TypeCode
			case 
			  when CL.SIDE = '1' and CL.OPEN_CLOSE = 'C' then 'BC'
			  when CL.SIDE = '1' then 'B'
			      when CL.SIDE = '2' then 'S'
			          when CL.SIDE in ('5', '6') then 'SS'
			end,    -- Side

            (select NO_LEGS from dwh.CLIENT_ORDER where ORDER_ID = CL.MULTILEG_ORDER_ID), --LegCount
            rn.LEG_NUMBER, --LegNumber
            '', --OrderType
            case
                when CL.PARENT_ORDER_ID is null
                    then case
                             when EX.ORDER_STATUS = 'A' then 'Pnd Open'
                             when EX.ORDER_STATUS = 'b' then 'Pnd Cxl'
                             when EX.ORDER_STATUS = 'S' then 'Pnd Rep'
                             when EX.ORDER_STATUS = '1' then 'Partial'
                             when EX.ORDER_STATUS = '2' then 'Filled'
                             when EX.EXEC_TYPE = '4' then 'Canceled'
                             when EX.EXEC_TYPE = 'W' then 'Replaced'
                             else EX.EXEC_TYPE end
                else
                    case
                        when EX.ORDER_STATUS = 'A' then 'Ex Pnd Open'
                        when EX.ORDER_STATUS = '0' then 'Ex Open'
                        when EX.ORDER_STATUS = '8' then 'Ex Rej'
                        when EX.ORDER_STATUS = 'b' then 'Ex Pnd Cxl'
                        when EX.ORDER_STATUS = '1' then 'Ex Partial'
                        when EX.ORDER_STATUS = '2' then 'Ex Rpt Fill'
                        when EX.ORDER_STATUS = '4' then 'Ex Rpt Out'
                        else EX.ORDER_STATUS end
                end, --Status
			to_char(CL.PRICE, 'FM999990D0099'),
			to_char(EX.LAST_PX, 'FM999990D0099'),  --StatusPrice
			CL.ORDER_QTY, --Entered Qty
			-- ask++
			EX.LEAVES_QTY, --StatusQty   
			--Order 
			CL.CLIENT_ORDER_ID,

			case 
			  when EX.EXEC_TYPE in ('S','W') then
				(select ORIG.CLIENT_ORDER_ID from CLIENT_ORDER ORIG where ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
			end, --Replaced Order 

			case
			  when EX.EXEC_TYPE in ('b','4') then
			  (select CXL.CLIENT_ORDER_ID from CLIENT_ORDER CXL where CXL.ORIG_ORDER_ID = CL.ORDER_ID order by CxL.order_id limit 1)
			end, --CancelOrderID
			(select PO.CLIENT_ORDER_ID from CLIENT_ORDER PO where PO.ORDER_ID = CL.PARENT_ORDER_ID),
			CL.ORDER_ID, --SystemOrderID
			EX.EXEC_ID, --ExecutionID
			coalesce(CL.sub_strategy_desc, EXC.MIC_CODE), --ExchangeCode
			'', --ExConnection
-- 			coalesce(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER), --GiveUpFirm
			opx.opt_exec_broker, --GiveUpFirm
           case
               when ac.opt_is_fix_clfirm_processed = 'Y' then cl.clearing_firm_id
               else coalesce(lpad(ca.cmta, 3, '0'), cl.clearing_firm_id)
               end, --CMTAFirm
			'',  --AccountAlias
			'',  --Account
			'',  --SubAccount
			'',  --SubAccount2
			'',  --SubAccount3
			CL.OPEN_CLOSE,
			case (case ac.opt_is_fix_custfirm_processed
				  when 'Y' then coalesce(CL.customer_or_firm_id, ac.opt_customer_or_firm)
				   else ac.opt_customer_or_firm
				  end)
			   when '0' then 'CUST'
			   when '1' then 'FIRM'
			   when '2' then 'BD'
			   when '3' then 'BD-CUST'
			   when '4' then 'MM'
			   when '5' then 'AMM'
			   when '7' then 'BD-FIRM'
			   when '8' then 'CUST-PRO'
			   when 'J' then 'JBO'
			end,  --Range

			OT.ORDER_TYPE_SHORT_NAME, --PriceQualifier
			TIF.TIF_SHORT_NAME, --TimeQualifier
			EX.EXCH_EXEC_ID, --ExchangeTransactionID
			CL.EXCH_ORDER_ID, --ExchangeOrderID
			'',  --MPID
			'',  --Comment
/*
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'AMEX' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'AMEX' and SIDE = '1' and L1_SCOPE = 'E' ), --BidA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'AMEX' and SIDE = '2' and L1_SCOPE = 'E'), --AskA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'AMEX' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BATO' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BATO' and SIDE = '1' and L1_SCOPE = 'E'), --BidZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BATO' and SIDE = '2' and L1_SCOPE = 'E'), --Askz
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BATO' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzZ
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BOX' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BOX' and SIDE = '1' and L1_SCOPE = 'E'), --BidB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BOX' and SIDE = '2' and L1_SCOPE = 'E'), --AskB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'BOX' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'CBOE' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'CBOE' and SIDE = '1' and L1_SCOPE = 'E' ), --BidA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'CBOE' and SIDE = '2' and L1_SCOPE = 'E'), --AskA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'CBOE' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'C2OX' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'C2OX' and SIDE = '1' and L1_SCOPE = 'E'), --BidZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'C2OX' and SIDE = '2' and L1_SCOPE = 'E'), --Askz
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'C2OX' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzZ
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NQBXO' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NQBXO' and SIDE = '1' and L1_SCOPE = 'E'), --BidB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NQBXO' and SIDE = '2' and L1_SCOPE = 'E'), --AskB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NQBXO' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ISE' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ISE' and SIDE = '1' and L1_SCOPE = 'E' ), --BidA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ISE' and SIDE = '2' and L1_SCOPE = 'E'), --AskA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ISE' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ARCA' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ARCA' and SIDE = '1' and L1_SCOPE = 'E'), --BidZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ARCA' and SIDE = '2' and L1_SCOPE = 'E'), --Askz
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'ARCA' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzZ
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MIAX' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MIAX' and SIDE = '1' and L1_SCOPE = 'E'), --BidB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MIAX' and SIDE = '2' and L1_SCOPE = 'E'), --AskB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MIAX' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'GEMINI' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'GEMINI' and SIDE = '1' and L1_SCOPE = 'E' ), --BidA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'GEMINI' and SIDE = '2' and L1_SCOPE = 'E'), --AskA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'GEMINI' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NSDQO' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NSDQO' and SIDE = '1' and L1_SCOPE = 'E'), --BidZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NSDQO' and SIDE = '2' and L1_SCOPE = 'E'), --Askz
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'NSDQO' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzZ
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'PHLX' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'PHLX' and SIDE = '1' and L1_SCOPE = 'E'), --BidB
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'PHLX' and SIDE = '2' and L1_SCOPE = 'E'), --AskB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'PHLX' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzB
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'EDGO' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'EDGO' and SIDE = '1' and L1_SCOPE = 'E' ), --BidA
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'EDGO' and SIDE = '2' and L1_SCOPE = 'E'), --AskA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'EDGO' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzA
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MPRL' and SIDE = '1' and L1_SCOPE = 'E'), --BidSzZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MPRL' and SIDE = '1' and L1_SCOPE = 'E'), --BidZ
			(select to_char(PRICE,'FM999999.0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MPRL' and SIDE = '2' and L1_SCOPE = 'E'), --Askz
			(select QUANTITY from STRATEGY_IN_L1_SNAPSHOT where STRATEGY_IN_ID = SIT.STRATEGY_IN_ID and EXCHANGE_ID = 'MPRL' and SIDE = '2' and L1_SCOPE = 'E'), --AskSzZ
			'', --ULBidSz
			'', --ULBid
			'', --ULAsk
			'', --ULAskSz
*/
			''
			as rec
		  from CLIENT_ORDER CL
		  --left join CLIENT_ORDER ORIG on ORIG.ORDER_ID = CL.ORIG_ORDER_ID
		  inner join dwh.d_FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
		  inner join dwh.EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID and ex.exec_date_id >= cl.create_date_id
		  left join dwh.d_EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID and exc.is_active
		  inner join dwh.d_OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
		  inner join dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		  inner join dwh.d_INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
		  inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID and ac.is_active
		  inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
		  left join dwh.d_CLEARING_ACCOUNT CA on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.is_active and CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
		  left join dwh.d_OPT_EXEC_BROKER OPX on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.is_active)
		  --left join LIQUIDITY_INDICATOR TLI on (TLI.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR and TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID)
		  left join dwh.d_ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE_id
		  left join dwh.d_TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE_id

-- 		  left join dwh.CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID
-- 		  left join dwh.d_STRATEGY_IN SIT on (SIT.TRANSACTION_ID = CL.TRANSACTION_ID and SIT.STRATEGY_IN_TYPE_ID in ('Ab','H'))
             left join lateral (
select leg_number
        from (select order_id, dense_rank() over (partition by co.multileg_order_id order by co.order_id) as leg_number
              from dwh.client_order co
              where co.multileg_order_id = cl.multileg_order_id
                and co.create_date_id >= cl.create_date_id) x
        where x.order_id = cl.order_id
          and cl.multileg_order_id is not null
        limit 1
        ) rn on true
		  where true
--     and trunc(CL.CREATE_TIME) = date '2024-08-27'
		    and cl.create_date_id = 20240827
		  and AC.TRADING_FIRM_ID = 'LPTF286'
		  --and CL.PARENT_ORDER_ID is null -- all orders
		  and CL.MULTILEG_REPORTING_TYPE in ('1','2')
		  --and EX.EXEC_TYPE = 'F'
		  and EX.IS_BUSTED = 'N'
		  and EX.EXEC_TYPE not in ('3','a','5','E')
		  and CL.TRANS_TYPE <> 'F'
		  and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
and cl.order_id in  (16861524498, 16862144103)