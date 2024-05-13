select cl.CREATE_DATE_ID, cl.CREATE_TIME,
    ex.exchange_id,
       NVL(CL.STRATEGY_DECISION_REASON_CODE, STR.STRATEGY_DECISION_REASON_CODE),
       case

           when NVL(CL.STRATEGY_DECISION_REASON_CODE, STR.STRATEGY_DECISION_REASON_CODE) in ('74') and
                ex.exchange_id in ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
               and exists (select null
                           from liquidity_indicator li
                           where (upper(description) like '%FLASH%' or upper(description) like '%EXPOSURE%')
                             and li.trade_liquidity_indicator = ex.trade_liquidity_indicator)
               then 'FLASH'
           when NVL(CL.STRATEGY_DECISION_REASON_CODE, STR.STRATEGY_DECISION_REASON_CODE) in ('32', '62', '96', '99')
               then 'FLASH'
           else decode(CRO.CROSS_TYPE, 'P', 'PIM', 'Q', 'QCC', 'F', 'Facilitation', 'S', 'Solicitation', CRO.CROSS_TYPE)
           end,--AUCTION_TYPE;
       ex.trade_liquidity_indicator
from CLIENT_ORDER CL
         inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
         left join CLIENT_ORDER PRO on (CL.PARENT_ORDER_ID = PRO.ORDER_ID)
         inner join FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
         inner join EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID
         left join CLIENT_ORDER STR
                   on (CL.ORDER_ID = STR.PARENT_ORDER_ID and EX.SECONDARY_ORDER_ID = STR.CLIENT_ORDER_ID and
                       EX.EXEC_TYPE = 'F') --street order for this trade
         left join EXECUTION ES on (ES.ORDER_ID = STR.ORDER_ID and ES.EXCH_EXEC_ID = EX.SECONDARY_EXCH_EXEC_ID)
         left join CROSS_ORDER CRO on CRO.CROSS_ORDER_ID = CL.CROSS_ORDER_ID
         left join MATCHED_CROSS_TRADES_PG MCT on NVL(ES.EXEC_ID, EX.EXEC_ID) = MCT.ORIG_EXEC_ID

         left join EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID
         left join OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
         left join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
         left join INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
         inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID

         inner join TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
         left join CLEARING_ACCOUNT CA
                   on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.IS_DELETED <> 'Y' and
                       CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
         left join OPT_EXEC_BROKER OPX
                   on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.IS_DELETED <> 'Y')
         left join ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE
         left join TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE
         left join CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID

where CL.MULTILEG_REPORTING_TYPE in ('1', '2')
  and EX.IS_BUSTED = 'N'
  and EX.EXEC_TYPE not in ('E', 'S', 'D', 'y')
  and CL.TRANS_TYPE <> 'F'
  and TF.IS_ELIGIBLE4CONSOLIDATOR = 'Y'
  and FC.FIX_COMP_ID <> 'IMCCONS'
  and cl.client_order_id = 'ZifIUVIEQ/yLfioLOoHy0w==_5u075uN'


select * from cons_eod_permanent
where client_order_id = 'ZifIUVIEQ/yLfioLOoHy0w==_5u075uN'