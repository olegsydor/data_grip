/*SELECT nullif('{\"' || listagg(coalesce(coalesce(coalesce(coalesce(case
                                                                       when oemd.OSR_ENUM_MEMBER_NAME is null then null
                                                                       else vl.OSR_PARAM_CODE || '\":\"' || oemd.OSR_ENUM_MEMBER_NAME end,
                                                                   case
                                                                       when pst.OSR_PARAM_VALUE is null then null
                                                                       else vl.OSR_PARAM_CODE || '\":\"' || pst.OSR_PARAM_VALUE end),
                                                          case
                                                              when pfl.OSR_PARAM_VALUE is null then null
                                                              else vl.OSR_PARAM_CODE || '\":\"' || to_char(pfl.OSR_PARAM_VALUE) end),
                                                 case
                                                     when pint.OSR_PARAM_VALUE is null then null
                                                     else vl.OSR_PARAM_CODE || '\":\"' || to_char(pint.OSR_PARAM_VALUE) end),
                                        case
                                            when pbool.OSR_PARAM_VALUE is null then null
                                            else vl.OSR_PARAM_CODE || '\":\"' || pbool.OSR_PARAM_VALUE end), '\",\"')
                               WITHIN GROUP (order by vl.OSR_PARAM_CODE) over (partition by vl.osr_param_set_id) ||
              '\"}', '{\"\"}') AS OSR_PARAM_VALUES
from GENESIS2.OSR_PARAM_VALUE vl --on (st.osr_param_set_id = vl.osr_param_set_id)
         left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                   on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
         left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)
where pint.OSR_PARAM_VALUE LIKE '%string param _-%';

*/

SELECT vl.osr_param_set_id, nullif('{' ||
              listagg(coalesce(coalesce(coalesce(coalesce(case
                                                                       when oemd.OSR_ENUM_MEMBER_NAME is null then null
                                                                       else '"'||vl.OSR_PARAM_CODE||'":"'||oemd.OSR_ENUM_MEMBER_NAME||'"' end,
                                                                   case
                                                                       when pst.OSR_PARAM_VALUE is null then null
                                                                       else '"'||vl.OSR_PARAM_CODE||'":"'||pst.OSR_PARAM_VALUE||'"' end),
                                                          case
                                                              when pfl.OSR_PARAM_VALUE is null then null
                                                              else '"'||vl.OSR_PARAM_CODE||'":"'||pfl.OSR_PARAM_VALUE||'"' end),
                                                 case
                                                     when pint.OSR_PARAM_VALUE is null then null
                                                     else '"'||vl.OSR_PARAM_CODE||'":"'||to_char(pint.OSR_PARAM_VALUE)||'"' end),
                                        case
                                            when pbool.OSR_PARAM_VALUE is null then null
                                            else '"'||vl.OSR_PARAM_CODE||'":"'||pbool.OSR_PARAM_VALUE||'"' end), ',') --
                               WITHIN GROUP (order by vl.OSR_PARAM_CODE) over (partition by vl.osr_param_set_id) || '}', '{}') as jsn
from GENESIS2.OSR_PARAM_VALUE vl --on (st.osr_param_set_id = vl.osr_param_set_id)
                       left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                                 on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and
                                    en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
                       left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool
                                 on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)
              where OSR_PARAM_SET_ID = 130


with base as (
select OSR_PARAM_SET_ID,
--        st.OSR_PARAM_SET_DESC,
--        st.IS_DELETED,
--        st.CREATE_TIME,
--        st.DELETE_TIME,
                     vl.OSR_PARAM_CODE,
                     oemd.OSR_ENUM_MEMBER_NAME,
                     pst.OSR_PARAM_VALUE   as pst_OSR_PARAM_VALUE,
                     pfl.OSR_PARAM_VALUE   as pfl_OSR_PARAM_VALUE,
                     pint.OSR_PARAM_VALUE  as pint_OSR_PARAM_VALUE,
                     pbool.OSR_PARAM_VALUE as pbool_OSR_PARAM_VALUE,
                     'I'                   as OPERATION

              from GENESIS2.OSR_PARAM_VALUE vl --on (st.osr_param_set_id = vl.osr_param_set_id)
                       left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                                 on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and
                                    en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
                       left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
                       left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool
                                 on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)
                where OSR_PARAM_SET_ID = 336359
              )
select OSR_PARAM_SET_ID, count(*)
from base
    group by OSR_PARAM_SET_ID
having count(*) > 3
/*
SELECT OSR_PARAM_SET_ID,
       OSR_PARAM_SET_DESC,
       IS_DELETED,
       CREATE_TIME,
       DELETE_TIME,
       OSR_PARAM_CODE,
       OSR_ENUM_MEMBER_NAME,
       pst_OSR_PARAM_VALUE,
       pfl_OSR_PARAM_VALUE,
       pint_OSR_PARAM_VALUE,
       pbool_OSR_PARAM_VALUE,
       OPERATION,
       null as COMMIT_TIME
from (
*/

select * from staging.v_flat_osr_param_set;
create view staging.v_flat_osr_param_set as
select st.OSR_PARAM_SET_ID,
       st.OSR_PARAM_SET_DESC,
       st.IS_DELETED,
       st.CREATE_TIME,
       st.DELETE_TIME,
       vl.OSR_PARAM_CODE,
       oemd.OSR_ENUM_MEMBER_NAME,
       pst.OSR_PARAM_VALUE   as pst_OSR_PARAM_VALUE,
       pfl.OSR_PARAM_VALUE   as pfl_OSR_PARAM_VALUE,
       pint.OSR_PARAM_VALUE  as pint_OSR_PARAM_VALUE,
       pbool.OSR_PARAM_VALUE as pbool_OSR_PARAM_VALUE,
       'I'                   as OPERATION,
       COMMIT_TIMESTAMP$     as COMMIT_TIME
--      ,row_number() over (partition by st.OSR_PARAM_SET_ID order by CSCN$ desc ) as rn

nullif(  '{\"'||listagg(coalesce(coalesce(coalesce(coalesce(case when oemd.OSR_ENUM_MEMBER_NAME is null then null else vl.OSR_PARAM_CODE||'\":\"'||oemd.OSR_ENUM_MEMBER_NAME end,
                                           case when pst.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||pst.OSR_PARAM_VALUE end)  ,
                                           case when pfl.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||to_char(pfl.OSR_PARAM_VALUE) end),
                                           case when pint.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||to_char(pint.OSR_PARAM_VALUE) end) ,
                                           case when pbool.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||pbool.OSR_PARAM_VALUE end), '\",\"')
                                           WITHIN GROUP (order by vl.OSR_PARAM_CODE) over (partition by st.osr_param_set_id)||'\"}', '{\"\"}') AS OSR_PARAM_VALUES,

from staging.PDWH_OSR_PARAM_SET st
         inner join GENESIS2.OSR_PARAM_VALUE vl on (st.osr_param_set_id = vl.osr_param_set_id)
         left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                   on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
         left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)
where OPERATION$ in ('I', 'UN')
  and exists (select null
              from staging.PDWH_OSR_PARAM_SET i_st
              where st.OSR_PARAM_SET_ID = i_st.OSR_PARAM_SET_ID
                and i_st.OPERATION$ = 'I')
  and not exists (select null
                  from staging.PDWH_OSR_PARAM_SET i_st
                  where st.OSR_PARAM_SET_ID = i_st.OSR_PARAM_SET_ID
                    and i_st.OPERATION$ = 'D')

UNION ALL

select st.OSR_PARAM_SET_ID,
       st.OSR_PARAM_SET_DESC,
       st.IS_DELETED,
       st.CREATE_TIME,
       st.DELETE_TIME,
       vl.OSR_PARAM_CODE,
       oemd.OSR_ENUM_MEMBER_NAME,
       pst.OSR_PARAM_VALUE,
       pfl.OSR_PARAM_VALUE,
       pint.OSR_PARAM_VALUE,
       pbool.OSR_PARAM_VALUE,
       'UN'              as OPERATION,
       COMMIT_TIMESTAMP$ as COMMIT_TIME
from staging.PDWH_OSR_PARAM_SET st
         inner join GENESIS2.OSR_PARAM_VALUE vl on (st.osr_param_set_id = vl.osr_param_set_id)
         left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                   on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
         left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)

where OPERATION$ in ('UN')
  and not exists (select null
                  from staging.PDWH_OSR_PARAM_SET i_st
                  where st.OSR_PARAM_SET_ID = i_st.OSR_PARAM_SET_ID
                    and i_st.OPERATION$ IN ('I', 'D'))

UNION ALL

select st.OSR_PARAM_SET_ID,
       st.OSR_PARAM_SET_DESC,
       st.IS_DELETED,
       st.CREATE_TIME,
       st.DELETE_TIME,
       null              as OSR_PARAM_CODE,
       null              as OSR_ENUM_MEMBER_NAME,
       null              as OSR_PARAM_VALUE,
       null              as OSR_PARAM_VALUE,
       null              as OSR_PARAM_VALUE,
       null              as OSR_PARAM_VALUE,
       'D'               as OPERATION,
       COMMIT_TIMESTAMP$ as COMMIT_TIME
from staging.PDWH_OSR_PARAM_SET st
where OPERATION$ in ('D')



create view staging.v_full_osr_param_set as
select OSR_PARAM_SET_ID,
       vl.OSR_PARAM_CODE,
       oemd.OSR_ENUM_MEMBER_NAME,
       pst.OSR_PARAM_VALUE   as pst_OSR_PARAM_VALUE,
       pfl.OSR_PARAM_VALUE   as pfl_OSR_PARAM_VALUE,
       pint.OSR_PARAM_VALUE  as pint_OSR_PARAM_VALUE,
       pbool.OSR_PARAM_VALUE as pbool_OSR_PARAM_VALUE,
       'I'                   as OPERATION
from GENESIS2.OSR_PARAM_VALUE vl --on (st.osr_param_set_id = vl.osr_param_set_id)
         left join GENESIS2.OSR_ENUM_PARAM_VALUE en on (vl.OSR_PARAM_VALUE_ID = en.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_ENUM_MEMBER_DEFINITION oemd
                   on vl.OSR_PARAM_CODE = oemd.OSR_PARAM_CODE and
                      en.OSR_PARAM_VALUE = oemd.OSR_ENUM_MEMBER_CODE
         left join GENESIS2.OSR_STRING_PARAM_VALUE pst on (vl.OSR_PARAM_VALUE_ID = pst.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_FLOAT_PARAM_VALUE pfl on (vl.OSR_PARAM_VALUE_ID = pfl.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_INT_PARAM_VALUE pint on (vl.OSR_PARAM_VALUE_ID = pint.OSR_PARAM_VALUE_ID)
         left join GENESIS2.OSR_BOOL_PARAM_VALUE pbool
                   on (vl.OSR_PARAM_VALUE_ID = pbool.OSR_PARAM_VALUE_ID)

SELECT to_char(TRUNC(CL.CREATE_TIME), 'MM/DD/YYYY')||','||
       AC.ACCOUNT_NAME||','||
       to_char(STR.PROCESS_TIME, 'HH24:MI:SS')||','||
       CL.CLIENT_ORDER_ID ||','||
       I.DISPLAY_INSTRUMENT_ID ||','||
       case when I.INSTRUMENT_TYPE_ID = 'O'
          then
            to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||substr(OC.MATURITY_YEAR, 3)
          else
            ''
       end ||','||
       DECODE(I.INSTRUMENT_TYPE_ID,'O','Option','Equity') ||','||
       EXC.EX_DESTINATION_CODE_NAME ||','||
       CL.SUB_STRATEGY ||','||
       decode(CL.SIDE, '2','Sell', '5','Sell Short', '6','Sell Short', 'Buy') ||','||
       to_char(CL.PRICE ,'FM9999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''') ||','||
       CL.ORDER_QTY ||','||
       CRO.CROSS_TYPE ||','||
       STR.ORDER_QTY ||','||
       to_char(STR.PRICE ,'FM9999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''') ||','||
       (select sum(LAST_QTY) from EXECUTION EX where EX.ORDER_ID = STR.ORDER_ID and EX.EXEC_TYPE = 'F') ||','||
       EXCH.MIC_CODE
from CLIENT_ORDER CL
	inner join CLIENT_ORDER STR on (CL.ORDER_ID = STR.PARENT_ORDER_ID)
 	inner join CROSS_ORDER CRO on (CRO.CROSS_ORDER_ID = CL.CROSS_ORDER_ID)
 	inner join ACCOUNT AC on CL.ACCOUNT_ID = AC.ACCOUNT_ID
	inner join INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
	inner join EX_DESTINATION_CODE EXC on (EXC.EX_DESTINATION_CODE = CL.EX_DESTINATION)
	inner join EXCHANGE EXCH on (EXCH.EXCHANGE_ID = STR.EXCHANGE_ID)
	left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
	left join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
	where
		CL.PARENT_ORDER_ID is null and
		CL.MULTILEG_REPORTING_TYPE <> '3' and
		TRUNC(CL.CREATE_TIME) = date '2023-10-17' and
		CL.SUB_STRATEGY = 'SWEEPX'
	  and		STR.STRATEGY_DECISION_REASON_CODE = '77' and
		AC.TRADING_FIRM_ID = 'wellsfarg';


SELECT count(*)
FROM ALERT al
where DBMS_LOB.getlength (al.ALERT_TEXT) <= 2000 AND EXTRACT(YEAR from CREATE_TIME) in (2016, 2017, 2018, 2019, 2020, 2021, 2022);

select *
from CLIENT_ORDER CL
		  --left join CLIENT_ORDER ORIG on ORIG.ORDER_ID = CL.ORIG_ORDER_ID
		  inner join FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
		  inner join EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID
		  left join EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID
		  inner join OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
		  inner join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		  inner join INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
		  inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		  inner join TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
		  left join CLEARING_ACCOUNT CA on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.IS_DELETED <> 'Y' and CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
		  left join OPT_EXEC_BROKER OPX on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.IS_DELETED <>'Y')
		  --left join LIQUIDITY_INDICATOR TLI on (TLI.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR and TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID)
		  left join ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE
		  left join TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE
		  left join CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID
		  left join STRATEGY_IN SIT on (SIT.TRANSACTION_ID = CL.TRANSACTION_ID and SIT.STRATEGY_IN_TYPE_ID in ('Ab','H'))
		  where trunc(CL.CREATE_TIME) = date '2023-10-17'
		  and AC.TRADING_FIRM_ID = 'baycrest'
		  --and CL.PARENT_ORDER_ID is null -- all orders
		  and CL.MULTILEG_REPORTING_TYPE in ('1','2')
		  --and EX.EXEC_TYPE = 'F'
		  and EX.IS_BUSTED = 'N'
		  and EX.EXEC_TYPE not in ('3','a','5','E')
		  and CL.TRANS_TYPE <> 'F'
		  and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)


		  select 2 as rec_type,
		         cl.ORDER_ID,
			to_char(CL.CREATE_TIME,'YYYYMMDD'), --||','||
			to_char(EX.EXEC_TIME,'HH24:MI:SS:FF3'), --||','||
			AC.TRADING_FIRM_ID, --||','||
			--CL.CLIENT_ID, --||','||
			AC.ACCOUNT_NAME, --||','||
			CL.CLIENT_ORDER_ID, --||','||
			UI.SYMBOL, --||','||
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR, --||','||
			OC.STRIKE_PRICE, --||','||
			decode(OC.PUT_CALL,'0','P','C'), --||','||
			decode(CL.SIDE,'1','B','S'), --||','||
			ODCS.DAY_CUM_QTY, --||','||
			EX.LAST_QTY, --||','||
			CL.OPEN_CLOSE, --||','||
			--AvgPx
			to_char(ODCS.DAY_AVG_PX, 'FM999990D0099', 'NLS_NUMERIC_CHARACTERS = ''. '''), --||','||
			decode(EX.EXCHANGE_ID, 'AMEX','A', 'BATO','Z', 'BOX','B', 'CBOE','C', 'C2OX','W', 'NQBXO','T', 'ISE','I', 'ARCA','P', 'MIAX','M', 'GMNI','H', 'NSDQO','Q', 'PHLX','X', 'EDGO','E', 'MCRY','J', 'MPRL','R',''), --||','||
			NVL(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER), --||','||
			case
			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CL.OPT_CLEARING_FIRM_ID
			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
			end, --||','||
			case (case
					when AC.OPT_IS_FIX_CUSTFIRM_PROCESSED = 'Y' and CL.OPT_CUSTOMER_FIRM is not null
					  then CL.OPT_CUSTOMER_FIRM
					when AC.OPT_IS_FIX_CUSTFIRM_PROCESSED = 'Y' and CL.EQ_ORDER_CAPACITY is not null
					  then (select min(CUSTOMER_OR_FIRM_ID)
								  from EXCHANGE2CUSTOMER_OR_FIRM where EXCHANGE_ID = EXC.REAL_EXCHANGE_ID
								  AND CL.EQ_ORDER_CAPACITY = EXCH_CUSTOMER_OR_FIRM_ID)
					when AC.OPT_IS_FIX_CUSTFIRM_PROCESSED = 'Y'
					  then NVL(F204.FIELD_VALUE,
								 (select min (CUSTOMER_OR_FIRM_ID )
								  from EXCHANGE2CUSTOMER_OR_FIRM where EXCHANGE_ID = EXC.REAL_EXCHANGE_ID
								  AND F47.FIELD_VALUE = EXCH_CUSTOMER_OR_FIRM_ID))
					 else AC.OPT_CUSTOMER_OR_FIRM
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
			end
			as rec


		  from CLIENT_ORDER CL
		  inner join EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID
		  left join EXCHANGE EXC on EXC.EXCHANGE_ID = EX.EXCHANGE_ID
		  inner join OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
		  inner join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		  inner join INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
		  --inner join DAILY_FINAL_EXECUTION FE on (FE.ORDER_ID = CL.ORDER_ID and FE.STATUS_DATE = trunc(sysdate-1))
		  inner join ORDER_DAILY_CUM_STATS_NEW ODCS on (ODCS.ORDER_ID = CL.ORDER_ID and ODCS.TRADE_DATE = date '2023-10-23')

		  inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		  left join CLEARING_ACCOUNT CA on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.IS_DELETED <> 'Y' and CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
		  left join OPT_EXEC_BROKER OPX on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.IS_DELETED <>'Y')
		  left join FIX_MESSAGE_FIELD F204 on (CL.FIX_MESSAGE_ID = F204.FIX_MESSAGE_ID and F204.TAG_NUM = 204)
		  left join FIX_MESSAGE_FIELD F47 on (CL.FIX_MESSAGE_ID = F47.FIX_MESSAGE_ID and F47.TAG_NUM = 47)

		  where trunc(CL.CREATE_TIME) = date '2023-10-23'
-- 		  and AC.TRADING_FIRM_ID = 'LPTF49'
		  and CL.PARENT_ORDER_ID is null
		  and EX.EXEC_TYPE = 'F'
		  and EX.IS_BUSTED = 'N'
		              and ac.trading_firm_id = 'mpsglobal'
            and cl.parent_order_id is null
            and cl.client_order_id = '20231023EDFM50'


SELECT
        TRUNC(EX.EXEC_TIME) TRADE_DATE,
        EX.ORDER_ID,
        SUM(EX.LAST_QTY) DAY_CUM_QTY,
        SUM(EX.LAST_QTY * EX.LAST_PX)/SUM(EX.LAST_QTY) DAY_AVG_PX
    FROM EXECUTION EX
      join LAST_EXECUTION LE
        ON LE.ORDER_ID = EX.ORDER_ID
        AND TRUNC(LE.STATUS_DATE) = TRUNC(EX.EXEC_TIME)
      join CLIENT_ORDER CO
        ON CO.ORDER_ID = EX.ORDER_ID
        AND MULTILEG_REPORTING_TYPE IN ('1','2')
    WHERE 1=1 --TRUNC(EX.EXEC_TIME) = TRUNC(sysdate -1)
   EX.EXEC_TYPE in ('F', 'G')
   AND EX.IS_BUSTED <> 'Y'
    GROUP BY TRUNC(EX.EXEC_TIME), EX.ORDER_ID

		  select * from ORDER_DAILY_CUM_STATS_NEW
where ORDER_ID in ( 12043890101,
12043890102,
10726468116,
10726468122,
10726468114);


FUNCTION getLPEODExchFees(p_date IN DATE, p_firm VARCHAR2) RETURN REF_CURSOR IS
  rs REF_CURSOR;
  BEGIN
    OPEN rs FOR
		select rec from  (
		  select 1 as rec_type,
			'CreateDate,CreateTime,EntityCode,Login,BuySell,Underlying,Quantity,Price,ExpirationDate,Strike,TypeCode,ExchangeCode,SystemOrderID,GiveUpFirm,CMTA,Range,isSpread,isALGO,isPennyName,RouteName,LiquidityTag,Handling,'||
			'StandardFee,MakeTakeFee,LinkageFee,SurchargeFee,Total'
			as rec
		  from dual

		  union all

		  select
		 	to_char(CL.CREATE_TIME,'YYYYMMDD')||','||
		    to_char(EX.EXEC_TIME,'HH24MISSFF3')||','||
			AC.TRADING_FIRM_ID||','||
			--CL.CLIENT_ID||','||
			AC.ACCOUNT_NAME||','||
			decode(CL.SIDE,'1','B','S')||','||
			UI.SYMBOL||','||
			EX.LAST_QTY||','||
			to_char(EX.LAST_PX, 'FM999990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||
			to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||OC.MATURITY_YEAR||','||
			OC.STRIKE_PRICE||','||
			decode(OC.PUT_CALL,'0','P','C')||','||
			--ODCS.DAY_CUM_QTY||','||
			--CL.OPEN_CLOSE||','||
			decode(EX.EXCHANGE_ID, 'AMEX','A', 'BATO','Z', 'BOX','B', 'CBOE','C', 'C2OX','W', 'NQBXO','T', 'ISE','I', 'ARCA','P', 'MIAX','M', 'GMNI','H', 'NSDQO','Q', 'PHLX','X', 'EDGO','E', 'MCRY','J', 'MPRL','R', '')||','||
			CL.CLIENT_ORDER_ID||','||
			NVL(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER)||','||
			case
			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CL.OPT_CLEARING_FIRM_ID
			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
			end||','||
			case (case AC.OPT_IS_FIX_CUSTFIRM_PROCESSED
				  when 'Y' then NVL(CL.OPT_CUSTOMER_FIRM, AC.OPT_CUSTOMER_OR_FIRM)
				   else AC.OPT_CUSTOMER_OR_FIRM
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
			end||','||
			decode(CL.MULTILEG_REPORTING_TYPE,'1','N','Y')||','|| --isSpread
			decode(CL.SUB_STRATEGY, 'DMA','N','Y')||','|| --isALGO
			decode(OS.MIN_TICK_INCREMENT, 0.01, 'Y', 'N')||','||
			CL.SUB_STRATEGY||','||
			EX.TRADE_LIQUIDITY_INDICATOR||','||
			decode(TLI.LIQUIDITY_INDICATOR_TYPE_ID, '1','128', '2', '129', '3', '140')||','|| --Handling Code
			to_char(ROUND(BEX.TRANSACTION_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--StandardFee
			to_char(ROUND(BEX.MAKER_TAKER_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--MakeTakeFee
			''||','||--LinkageFee
			to_char(ROUND(BEX.ROYALTY_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--SurchargeFee
			to_char(ROUND(NVL(BEX.TRANSACTION_FEE,0)+NVL(BEX.MAKER_TAKER_FEE,0)+NVL(BEX.ROYALTY_FEE,0), 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')--Total

			as rec
-- select cl.order_id, ex.exec_id
		  from CLIENT_ORDER CL
		  inner join EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID
		  inner join EXCHANGE EXC on EXC.EXCHANGE_ID = EX.EXCHANGE_ID
		  inner join OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
		  inner join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
		  inner join INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
		  inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		  left join CLEARING_ACCOUNT CA on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.IS_DELETED <> 'Y' and CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
		  left join OPT_EXEC_BROKER OPX on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.IS_DELETED <>'Y')
		  left join LIQUIDITY_INDICATOR TLI on (TLI.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR and TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID)
		  left join BILLED_EXECUTION BEX ON (EX.EXEC_ID = BEX.EXEC_ID )
		  where trunc(CL.CREATE_TIME) = date '2023-10-19'
-- 		  and AC.TRADING_FIRM_ID = 'triadsc01'
		  and CL.PARENT_ORDER_ID is null
		  and EX.EXEC_TYPE = 'F'
		  and EX.IS_BUSTED = 'N'
-- 		   and cl.client_order_id = '20231019EDFM218'
		    and cl.ACCOUNT_ID in (13687,13411,9374,68613,13686)
		)
		order by rec_type
		;
	RETURN rs;

  END getLPEODExchFees;
select * from BILLING_ENTRY;



  FUNCTION getS3forRBC(p_date IN DATE) RETURN REF_CURSOR IS
  rs REF_CURSOR;
  BEGIN
    OPEN rs FOR

	select
		case
		  when RECORD_TYPE = 'H' then REC||'|'||
			   to_char(date '2023-10-25','YYYYMMDD')||'T'||MIN_TIME||'|'|| --Starting Event
			   to_char(date '2023-10-25','YYYYMMDD')||'T'||MAX_TIME||'|'|| --Ending Event
				'DFIN'||'|'||
				'DAIN'||'|'||
				'tradedesk@dashfinancial.com'||'|'||
				 ''
		  else REC
		end
	from
	(
		select min(TIME_ID) over() as MIN_TIME,
			   max(TIME_ID) over() as MAX_TIME,
			   RECORD_TYPE,
			   REC from
		(
		----Parent/Street orders----
		select 'NO' as RECORD_TYPE, NVL(CL.PARENT_ORDER_ID,CL.ORDER_ID) as ORDER_ID, to_char(CL.PROCESS_TIME,'HH24MISSFF3') as TIME_ID, CL.CLIENT_ORDER_ID as RECORD_ID, 1 as RECORD_TYPE_ID,
				'O'||'|'||
				case
				  when CL.PARENT_ORDER_ID is null then 'NO'
				  else 'RO'
				end||'|'||

				CL.CLIENT_ORDER_ID||'|'||
				CL.ORDER_ID||'|'||  --SOURCE_ORDER_ID
				to_char(CL.PARENT_ORDER_ID)||'|'|| --SOURCE_PARENT_ID
				CL.ORIG_ORDER_ID||'|'||
				--
				''||'|'||
				AC.BROKER_DEALER_MPID||'|'||
				'DFIN'||'|'||
				''||'|'||
				''||'|'||
				decode(CL.MULTILEG_REPORTING_TYPE,'3','',I.INSTRUMENT_TYPE_ID)||'|'||
				decode(I.INSTRUMENT_TYPE_ID, 'E',I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL)||'|'||
				''||'|'|| --primary Exchange
				decode(CL.SIDE,'1','B','2','S','5','SS','6','SSE')||'|'|| --OrderAction
				to_char(CL.PROCESS_TIME,'YYYYMMDD')||'T'||to_char(CL.PROCESS_TIME,'HH24MISSFF3')||'|'||
				OT.ORDER_TYPE_SHORT_NAME||'|'|| --ORDER_TYPE
				CL.ORDER_QTY||'|'|| --ORDER_VOLUME
				to_char(CL.PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
				to_char(CL.STOP_PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
				TIF.TIF_SHORT_NAME||'|'||
				to_char(CL.EXPIRE_TIME,'YYYYMMDD')||'T'||to_char(CL.EXPIRE_TIME,'HH24MISSFF3')||'|'||
				'0'||'|'|| --PRE_MARKET_IND
				''||'|'||
				'0'||'|'||  --POST_MARKET_IND
				''||'|'||
				case
				  when CL.PARENT_ORDER_ID is null then decode(CL.SUB_STRATEGY, 'DMA','1','0')
				  else (select decode(PO.SUB_STRATEGY, 'DMA','1','0') from CLIENT_ORDER PO where PO.ORDER_ID = CL.PARENT_ORDER_ID)
				end||'|'|| --DIRECTED_ORDER_IND
				case
				  when CL.PARENT_ORDER_ID is null then decode(CL.SUB_STRATEGY, 'SMOKE','1','0')
				  else (select decode(PO.SUB_STRATEGY, 'SMOKE','1','0') from CLIENT_ORDER PO where PO.ORDER_ID = CL.PARENT_ORDER_ID)
				end||'|'|| --NON_DISPLAY_IND
				'0'||'|'|| --DO_NOT_REDUCE
				decode(CL.EXEC_INST, 'G','1', '0')||'|'||
				decode(CL.EXEC_INST, '1','1', '0')||'|'|| --NOT_HELD_IND [31]
				'0'||'|'|| --[32]
				'0'||'|'|| --[33]
				'0'||'|'|| --[34]
				''||'|'|| --[35]
				''||'|'|| --[36]
				''||'|'|| --[37]
				''||'|'|| --[38]
				''||'|'|| --[39]
				''||'|'|| --[40]
				''||'|'|| --[41]
				''||'|'|| --[42]
				''||'|'|| --[43]
				''||'|'|| --[44]
				''||'|'|| --[45]
				''||'|'|| --[46]
				''||'|'|| --[47]
				'' --[48]

		as REC
		from CLIENT_ORDER CL
		inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
		left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
		left join ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE
		left join TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE
		where 1=1
		and AC.TRADING_FIRM_ID = 'ebsrbc'
		and trunc(CL.CREATE_TIME) = date '2023-10-25'
		and CL.TRANS_TYPE <> 'F'
		and CL.MULTILEG_REPORTING_TYPE = '1'

		union all

		--order activity: cancel
		select 'A' as RECORD_TYPE, NVL(CL.PARENT_ORDER_ID,CL.ORDER_ID) as ORDER_ID, to_char(CL.PROCESS_TIME,'HH24MISSFF3') as TIME_ID, CL.CLIENT_ORDER_ID as RECORD_ID, 3 as RECORD_TYPE_ID,
			   'A'||'|'||
			   CL.ORDER_ID||'|'||
			   decode(EX.EXEC_TYPE, '4','C','8','RJ')||'|'|| --EVENT
			   ''||'|'||  --SYSTEM_ID
			   decode(CL.MULTILEG_REPORTING_TYPE,'3','',I.INSTRUMENT_TYPE_ID)||'|'||
			   decode(I.INSTRUMENT_TYPE_ID, 'E',I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL)||'|'||
			   ''||'|'|| --SYMBOL_EXCHANGE
			   to_char(EX.EXEC_TIME,'YYYYMMDD')||'T'||to_char(EX.EXEC_TIME,'HH24MISSFF3')||'|'||
			   ''||'|'|| --DESCRIPTION
			   ''||'|'|| --[10]
			   ''||'|'|| --[11]
			   ''||'|'|| --[12]
			   ''||'|'|| --[13]
			   '' --[14]


		as REC
		from CLIENT_ORDER CL
		inner join EXECUTION EX on EX.ORDER_ID = CL.ORDER_ID
		inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
		left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
		where 1=1
		and AC.TRADING_FIRM_ID = 'ebsrbc'
		and trunc(EX.EXEC_TIME) = date '2023-10-25'
		and CL.TRANS_TYPE <> 'F'
		and EX.EXEC_TYPE in ('4','8')
		and CL.MULTILEG_REPORTING_TYPE = '1'

		union all
		--trade: street level only
		select 'T' as RECORD_TYPE, NVL(CL.PARENT_ORDER_ID,CL.ORDER_ID) as ORDER_ID, to_char(EX.EXEC_TIME,'HH24MISSFF3') as TIME_ID, CL.CLIENT_ORDER_ID as RECORD_ID, 2 as RECORD_TYPE_ID,
			   'T'||'|'||
			   CL.ORDER_ID||'|'||
			   CL.ORDER_ID||'_'||EX.EXEC_ID||'|'||
			   ''||'|'||
			   ''||'|'||
			   I.INSTRUMENT_TYPE_ID||'|'||
			   decode(I.INSTRUMENT_TYPE_ID, 'E',I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL)||'|'||
			   ''||'|'|| --SYMBOL_EXCHANGE
			   to_char(EX.EXEC_TIME,'YYYYMMDD')||'T'||to_char(EX.EXEC_TIME,'HH24MISSFF3')||'|'|| --ACTION_DATETIME
			   EX.LAST_QTY||'|'||
			   to_char(EX.LAST_PX, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''')||'|'||
			   EX.EXCHANGE_ID||'|'||
			   ''||'|'|| --[12]
			   ''||'|'|| --[13]
			   ''||'|'|| --[14]
			   ''||'|'|| --[15]
			   ''||'|'|| --[16]
			   ''||'|'|| --[17]
			   ''||'|'|| --[18]
			   ''||'|'|| --[19]
			   ''||'|'|| --[20]
			   ''||'|'|| --[21]
			   ''||'|'|| --[22]
			   '' --[23]

		as REC
		select *
		from CLIENT_ORDER CL
		inner join EXECUTION EX on EX.ORDER_ID = CL.ORDER_ID
		inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
		inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
		left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
		where 1=1
 		and CL.PARENT_ORDER_ID is not null
-- 		and AC.TRADING_FIRM_ID = 'ebsrbc'
-- 		and trunc(EX.EXEC_TIME) = date '2023-10-25'
-- 		and CL.TRANS_TYPE <> 'F'
-- 		and EX.EXEC_TYPE in ('F')
-- 		and CL.MULTILEG_REPORTING_TYPE = '1'
		and exec_id = 44922360291

		union all
		--Header
		select  'H' as RECORD_TYPE, 0 as ORDER_ID, NULL as TIME_ID, 'A' as RECORD_ID, 0 as RECORD_TYPE_ID,
				'H'||'|'||
				'V2.0.4'||'|'||
				to_char(systimestamp,'YYYYMMDD')||'T'||to_char(systimestamp,'HH24MISSFF3')

		as REC
		from DUAL

		)
		order by ORDER_ID, TIME_ID, RECORD_ID, RECORD_TYPE_ID
	);

    RETURN rs;

  END getS3forRBC;

  select * from execution
where exec_id = 44922360291


select rec from (select 'NO'                                    as RECORD_TYPE,
                      NVL(CL.PARENT_ORDER_ID, CL.ORDER_ID)    as ORDER_ID,
                      to_char(CL.PROCESS_TIME, 'HH24MISSFF3') as TIME_ID,
                      CL.CLIENT_ORDER_ID                      as RECORD_ID,
                      1                                       as RECORD_TYPE_ID,
                      'O' || '|' ||
                      case
                          when CL.MULTILEG_REPORTING_TYPE = '3' then 'NO'
                          else 'RO'
                          end || '|' ||
                      CL.CLIENT_ORDER_ID || '|' ||
                      CL.ORDER_ID || '|' || --SOURCE_ORDER_ID

                      case
                          when CL.MULTILEG_REPORTING_TYPE = '2'
                              then --(select CLIENT_ORDER_ID from CLIENT_ORDER where ORDER_ID = CL.PARENT_ORDER_ID)
                              CL.CLIENT_ORDER_ID
                          end || '|' || --SOURCE_PARENT_ID
                      CL.ORIG_ORDER_ID || '|' ||
                          --
                      case
                          when CL.MULTILEG_REPORTING_TYPE = '3' then CL.ORDER_ID
                          when CL.MULTILEG_REPORTING_TYPE = '2'
                              then CL.CO_MULTILEG_ORDER_ID --(select CO_MULTILEG_ORDER_ID from CLIENT_ORDER where ORDER_ID = CL.PARENT_ORDER_ID)
                          end || '|' ||
                      case
                          when CL.PARENT_ORDER_ID is null
                              then decode(AC.BROKER_DEALER_MPID, 'NONE', NULL, AC.BROKER_DEALER_MPID)
                          else 'DFIN'
                          end || '|' ||
                      case
                          when CL.PARENT_ORDER_ID is null then 'DFIN'
                          else NVL(EXC.MIC_CODE, EXC.EQ_MPID)
                          end || '|' ||
                          --AC.BROKER_DEALER_MPID||'|'||
                          --'DFIN'||'|'||
                      '' || '|' ||
                      '' || '|' ||
                      decode(CL.MULTILEG_REPORTING_TYPE, '3', '', I.INSTRUMENT_TYPE_ID) || '|' ||
                      decode(I.INSTRUMENT_TYPE_ID, 'E', I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL) || '|' ||
                      '' || '|' || --primary Exchange
                      decode(CL.SIDE, '1', 'B', '2', 'S', '5', 'SS', '6', 'SSE') || '|' || --OrderAction
                      to_char(CL.PROCESS_TIME, 'YYYYMMDD') || 'T' || to_char(CL.PROCESS_TIME, 'HH24MISSFF3') || '|' ||
                      OT.ORDER_TYPE_SHORT_NAME || '|' || --ORDER_TYPE
                      decode(CL.MULTILEG_REPORTING_TYPE, '3', '', CL.ORDER_QTY) || '|' || --ORDER_VOLUME
                      to_char(CL.PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') || '|' ||
                      to_char(CL.STOP_PRICE, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') || '|' ||
                      TIF.TIF_SHORT_NAME || '|' ||
                      case
                          when CL.EXPIRE_TIME is not null then
                                  to_char(CL.EXPIRE_TIME, 'YYYYMMDD') || 'T' || to_char(CL.EXPIRE_TIME, 'HH24MISSFF3')
                          when CL.TIME_IN_FORCE = '6' then
                              (select max(FIELD_VALUE) || 'T235959000'
                               from FIX_MESSAGE_FIELD
                               where FIX_MESSAGE_ID = CL.FIX_MESSAGE_ID and TAG_NUM = 432)
                          end || '|' || --22
                      '0' || '|' || --PRE_MARKET_IND
                      '' || '|' ||
                      '0' || '|' || --POST_MARKET_IND
                      '' || '|' ||
                      case
                          when CL.PARENT_ORDER_ID is null then decode(CL.SUB_STRATEGY, 'DMA', '1', '0')
                          else (select decode(PO.SUB_STRATEGY, 'DMA', '1', '0')
                                from CLIENT_ORDER PO
                                where PO.ORDER_ID = CL.PARENT_ORDER_ID)
                          end || '|' ||
                      case
                          when CL.SUB_STRATEGY = 'SMOKE' then '1'
                          else '0'
                          end || '|' || --N|ON_DISPLAY_IND
                      '0' || '|' || --DO_NOT_REDUCE
                      decode(CL.EXEC_INST, 'G', '1', '0') || '|' ||
                      decode(CL.EXEC_INST, '1', '1', '0') || '|' || --NOT_HELD_IND [31]
                      '0' || '|' || --[32]
                      '0' || '|' || --[33]
                      '0' || '|' || --[34]
                      '' || '|' || --[35]
                      '' || '|' || --[36]
                      '' || '|' || --[37]
                      '' || '|' || --[38]
                      CL.EX_DESTINATION || '|' || --[39]
                      case
                          when CL.MULTILEG_REPORTING_TYPE = '3' then CL.CO_NO_LEGS
                          --(select sum(CO_NO_LEGS) from CLIENT_ORDER where PARENT_ORDER_ID = CL.ORDER_ID and TRANS_TYPE = 'D')
                          end || '|' || --[40]
                      '' || '|' || --[41]
                      '' || '|' || --[42]
                      '' || '|' || --[43]
                      '' || '|' || --[44]
                      '' || '|' || --[45]
                      '' || '|' || --[46]
                      '' || '|' || --[47]
                      '' --[48]

                                                              as REC
               from CLIENT_ORDER CL
                        inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                        inner join TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                        inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                        left join EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID
                        left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
                        left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
                        left join ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE
                        left join TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE
               where 1 = 1
                 and CL.PARENT_ORDER_ID is null
                 and AC.TRADING_FIRM_ID = 'ebsrbc'
                 and trunc(CL.CREATE_TIME) = date '2023-10-25'
                 and CL.TRANS_TYPE <> 'F'
                 and CL.MULTILEG_REPORTING_TYPE in ('2', '3')
               --order by CL.CREATE_TIME, CL.CLIENT_ORDER_ID

               union all

               --order activity: cancel
               select 'A'                                     as RECORD_TYPE,
                      NVL(CL.PARENT_ORDER_ID, CL.ORDER_ID)    as ORDER_ID,
                      to_char(CL.PROCESS_TIME, 'HH24MISSFF3') as TIME_ID,
                      CL.CLIENT_ORDER_ID                      as RECORD_ID,
                      3                                       as RECORD_TYPE_ID,
                      'A' || '|' ||
                      CL.ORDER_ID || '|' ||
                      decode(EX.EXEC_TYPE, '4', 'C', '8', 'RJ') || '|' || --EVENT
                      '' || '|' || --SYSTEM_ID
                      decode(CL.MULTILEG_REPORTING_TYPE, '3', '', I.INSTRUMENT_TYPE_ID) || '|' ||
                      decode(I.INSTRUMENT_TYPE_ID, 'E', I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL) || '|' ||
                      '' || '|' || --SYMBOL_EXCHANGE
                      to_char(EX.EXEC_TIME, 'YYYYMMDD') || 'T' || to_char(EX.EXEC_TIME, 'HH24MISSFF3') || '|' ||
                      '' || '|' || --DESCRIPTION
                      '' || '|' || --[10]
                      '' || '|' || --[11]
                      '' || '|' || --[12]
                      '' || '|' || --[13]
                      '' --[14]


                                                              as REC
               from CLIENT_ORDER CL
                        inner join EXECUTION EX on EX.ORDER_ID = CL.ORDER_ID
                        inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                        inner join TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                        inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                        left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
                        left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
               where 1 = 1
                 and CL.PARENT_ORDER_ID is null
                 and AC.TRADING_FIRM_ID = 'ebsrbc'
                 and trunc(EX.EXEC_TIME) = date '2023-10-25'
                 and CL.TRANS_TYPE <> 'F'
                 and EX.EXEC_TYPE in ('4', '8')
                 and CL.MULTILEG_REPORTING_TYPE in ('2', '3')
               --and ((CL.MULTILEG_REPORTING_TYPE = '2' and CL.PARENT_ORDER_ID is not null) or (CL.MULTILEG_REPORTING_TYPE = '3' and CL.PARENT_ORDER_ID is null))

               union all
               --trade: street level only
               select 'T'                                  as RECORD_TYPE,
                      NVL(CL.PARENT_ORDER_ID, CL.ORDER_ID) as ORDER_ID,
                      to_char(EX.EXEC_TIME, 'HH24MISSFF3') as TIME_ID,
                      CL.CLIENT_ORDER_ID                   as RECORD_ID,
                      2                                    as RECORD_TYPE_ID,
                      'T' || '|' ||
                      CL.ORDER_ID || '|' ||
                      CL.ORDER_ID || '_' || EX.EXEC_ID || '|' ||
                      '' || '|' ||
                      '' || '|' ||
                      I.INSTRUMENT_TYPE_ID || '|' ||
                      decode(I.INSTRUMENT_TYPE_ID, 'E', I.DISPLAY_INSTRUMENT_ID, 'O', OC.OPRA_SYMBOL) || '|' ||
                      '' || '|' || --SYMBOL_EXCHANGE
                      to_char(EX.EXEC_TIME, 'YYYYMMDD') || 'T' || to_char(EX.EXEC_TIME, 'HH24MISSFF3') ||
                      '|' || --ACTION_DATETIME
                      EX.LAST_QTY || '|' ||
                      to_char(EX.LAST_PX, 'FM99990D0099', 'NLS_NUMERIC_CHARACTERS = ''. ''') || '|' ||
                      EX.EXCHANGE_ID || '|' ||
                      '' || '|' || --[12]
                      '' || '|' || --[13]
                      case
                          when CL.MULTILEG_REPORTING_TYPE = '2' then 'COMPLEX'
                          end || '|' || --[14]
                      '' || '|' || --[15]
                      '' || '|' || --[16]
                      '' || '|' || --[17]
                      '' || '|' || --[18]
                      '' || '|' || --[19]
                      '' || '|' || --[20]
                      '' || '|' || --[21]
                      '' || '|' || --[22]
                      '' --[23]


                                                           as REC
               from CLIENT_ORDER CL
                        inner join EXECUTION EX on EX.ORDER_ID = CL.ORDER_ID
                        inner join ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                        inner join TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                        inner join INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                        left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
                        left join OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
               where 1 = 1
                 and CL.PARENT_ORDER_ID is null
                 and AC.TRADING_FIRM_ID = 'ebsrbc'
                 and trunc(EX.EXEC_TIME) = date '2023-10-25'
                 and CL.TRANS_TYPE <> 'F'
                 and EX.EXEC_TYPE in ('F')
                 and CL.MULTILEG_REPORTING_TYPE = '2')
order by ORDER_ID, TIME_ID, RECORD_ID, RECORD_TYPE_ID;



-- FUNCTION getAuctionSurveillance(p_date IN DATE) RETURN REF_CURSOR IS
--   rs REF_CURSOR;
--   BEGIN
--     OPEN rs FOR

	select 'Trading Firm,Account,Ord Type,Ord Status,Event Date,Routed Time,Cl Ord ID,Side,Ord Qty,Ex Qty,Symbol,Price,Avg Px,Ex Dest,Sub Strategy,TIF,Client ID'
	from dual

	union all

	select
		  TF.TRADING_FIRM_NAME||','||
		  AC.ACCOUNT_NAME||','||
		  OT.ORDER_TYPE_SHORT_NAME||','||
		  decode(LE.ORDER_STATUS,'2','Filled','4','Cancelled','3','Done For Day',LE.ORDER_STATUS)||','||--ord status
		  to_char(CL.CREATE_TIME, 'YYYY-MM-DD')||','||--Date
		  to_char(CL.CREATE_TIME, 'YYYY-MM-DD HH24:MI:SS:FF3')||','||
		  CL.CLIENT_ORDER_ID||','||
		  decode(CL.SIDE,'1','Buy','2','Sell','5','Sell Short','6','Sell short')||','||
		  CL.ORDER_QTY||','||
		  DS.DAY_CUM_QTY||','|| --Ex Qty
		  I.SYMBOL||','||
		  CL.PRICE||','||
		  round(DS.DAY_AVG_PX,4)||','|| --Avg Px
		  decode(CL.EX_DESTINATION,'39','ARCA','54','BATS','XNYS','NYSE','O','NASDAQ','XASE','AMEX','A','AMEX')||','||
		  CL.SUB_STRATEGY||','||
		  TIF.TIF_NAME||','||
		  CL.CLIENT_ID
	select *
		from CLIENT_ORDER CL
-- 		inner join INSTRUMENT I on I.INSTRUmENT_ID = CL.INSTRUMENT_ID
-- 		inner join TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE
-- 		inner join ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE
-- 		left join FIX_MESSAGE_FIELD F9355 on (F9355.FIX_MESSAGE_ID = CL.FIX_MESSAGE_ID and F9355.TAG_NUM = 9355)
-- 		inner join ACCOUNT AC on CL.ACCOUNT_ID = AC.ACCOUNT_ID
-- 		inner join TRADING_FIRM Tf on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
-- 		inner join DAILY_FINAL_EXECUTION DFE on (DFE.ORDER_ID = CL.ORDER_ID and DFE.STATUS_DATE = date '2023-06-05')
-- 		inner join EXECUTION LE on LE.EXEC_ID = DFE.LAST_EXEC_ID
		left join
			(SELECT EX.ORDER_ID,
					SUM(EX.LAST_QTY*EX.LAST_PX)/SUM(EX.LAST_QTY) DAY_AVG_PX,
					SUM(EX.LAST_QTY) DAY_CUM_QTY
				  FROM EXECUTION EX
				  WHERE EX.EXEC_TYPE IN ('F', 'G')
				  AND EX.IS_BUSTED ='N'
				  and trunc(EX.EXEC_TIME) = date '2023-06-05'
			  GROUP BY EX.ORDER_ID
			) DS ON DS.ORDER_ID = CL.ORDER_ID
		where trunc(CL.CREATE_TIME) = date '2023-06-05'
		and CL.PARENT_ORDER_ID is null
		and CL.TRANS_TYPE <> 'F'
		and CL.MULTILEG_REPORTING_TYPE in ('1','2')
		    and cl.client_order_id = 'NHS.RT.rujq9.27k'
		and ((CL.EX_DESTINATION in ('39','54','O','XNYS','A','XASE') and CL.ORDER_TYPE in ('B','5') and CL.TIME_IN_FORCE = '0')
			  or
			 (CL.EX_DESTINATION = '39' and CL.ORDER_TYPE in ('1','2') and CL.TIME_IN_FORCE = '7')
			 or
			 (CL.EX_DESTINATION = '54' and CL.ORDER_TYPE in ('1','2') and CL.TIME_IN_FORCE = '7' and CL.ROUTING_INST = 'B')
			 or
			 (CL.EX_DESTINATION = 'O' and CL.ORDER_TYPE in ('1','2') and CL.TIME_IN_FORCE = '3' and F9355.FIELD_VALUE = 'C')
			 )
		and ((CL.EX_DESTINATION in ('A','XNYS','XASE') and to_char(CL.CREATE_TIME, 'HH24:MI:SS')> '15:44:59')
			  or
			 (CL.EX_DESTINATION = 'O' and to_char(CL.CREATE_TIME, 'HH24:MI:SS')> '15:49:59')
			  or
			 (CL.EX_DESTINATION = '54' and to_char(CL.CREATE_TIME, 'HH24:MI:SS')> '15:54:59')
			  or
			 (CL.EX_DESTINATION = '39' and to_char(CL.CREATE_TIME, 'HH24:MI:SS')> '15:58'));

select * from all_source where upper(text) like '%DAILY_FINAL_EXECUTION%'


      SELECT to_char(TRUNC(DS.TRADE_DATE), 'MM/DD/YYYY')||','||
             AC.ACCOUNT_NAME||','||
             CL.CLIENT_ID ||','||
             CL.CLIENT_ORDER_ID ||','||
             ORIG.CLIENT_ORDER_ID ||','||
             decode(CL.SIDE, '2','SLD', '5','SLD SHORT', '6','SLD SHORT', 'BOT') ||','||
             I.DISPLAY_INSTRUMENT_ID ||','||
             I.SYMBOL_SUFFIX ||','||
             DECODE(I.INSTRUMENT_TYPE_ID,'O','Option','Equity') ||','||
             TIF.TIF_NAME ||','||
             OT.ORDER_TYPE_SHORT_NAME ||','||
             DS.DAY_CUM_QTY ||','||
             to_char(round(DS.DAY_AVG_PX,4),'FM9999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''') ||','||

             NVL(OS.ROOT_SYMBOL, I.SYMBOL) ||','||
             NVL(UI.SYMBOL, I.SYMBOL) ||','||
             DECODE(CL.MULTILEG_REPORTING_TYPE,'1','N','Y') ||','||
             OL.CLIENT_LEG_REF_ID ||','||
             EXC.EX_DESTINATION_CODE_NAME ||','||
             CL.SUB_STRATEGY ||','||

             case when I.INSTRUMENT_TYPE_ID = 'O'
                then
                  to_char(OC.MATURITY_MONTH, 'FM00')||'/'||to_char(OC.MATURITY_DAY, 'FM00')||'/'||substr(OC.MATURITY_YEAR, 3)
                else
                  ''
             end ||','||

             CL.MPID ||','||
             CF.CUSTOMER_OR_FIRM_NAME ||','||
             DECODE(AC.OPT_IS_FIX_EXECBROK_PROCESSED, 'Y', NVL(CL.OPT_EXEC_BROKER,TO_CHAR(OPX.OPT_EXEC_BROKER)),TO_CHAR(OPX.OPT_EXEC_BROKER) ) ||','||

             DECODE(CL.OPEN_CLOSE,'O','Open','C','Close') ||','||
             to_char(ROUND(DS.DAY_CUM_QTY*DS.DAY_AVG_PX*NVL(OS.CONTRACT_MULTIPLIER,1), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||

             (
                SELECT to_char(ROUND(SUM(BEX.MAKER_TAKER_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                )||','||
             (
                SELECT to_char(ROUND(SUM(BEX.MAKER_TAKER_FEE)/DS.DAY_CUM_QTY, 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                )||','||
             (
                SELECT to_char(ROUND(SUM(BEX.TRANSACTION_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||

            (
                SELECT to_char(ROUND(SUM(BEX.TRADE_PROCESSING_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
                --
            (
                SELECT to_char(ROUND(SUM(BEX.ROYALTY_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||

            (
                SELECT to_char(ROUND(SUM(BEX.OPTION_REGULATORY_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(MAX(ROUND(BEX.ORDER_OCC_FEE_AMOUNT, 4)),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                )  ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.SEC_FEE), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                 SELECT to_char(ROUND(SUM(BEX.ACCOUNT_DASH_COMMISSION), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.ACCOUNT_EXECUTION_COST), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.ACCOUNT_EXECUTION_COST)/DS.DAY_CUM_QTY, 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.FIRM_DASH_COMMISSION), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.FIRM_EXECUTION_COST), 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
            (
                SELECT to_char(ROUND(SUM(BEX.FIRM_EXECUTION_COST)/DS.DAY_CUM_QTY, 4),'FM9999999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')
                FROM BILLED_EXECUTION BEX
                WHERE BEX.ORDER_ID = CL.ORDER_ID
                AND BEX.TRADE_DATE = date '2023-11-09'
                ) ||','||
             OC.OPRA_SYMBOL ||','||
             FC.FIX_COMP_ID ||','||
             TF.TRADING_FIRM_NAME

      as rec

--       select cl.order_id, cl.CREATE_TIME, cl.*
      from CLIENT_ORDER CL
          inner join ACTIVE_ACCOUNT_SNAPSHOT AC on CL.ACCOUNT_ID = AC.ACCOUNT_ID
      inner join
          (SELECT EX.ORDER_ID,
                  TRUNC(EX.EXEC_TIME) TRADE_DATE,
                  SUM(EX.LAST_QTY*EX.LAST_PX)/decode(SUM(EX.LAST_QTY),0,1)  DAY_AVG_PX,
                  SUM(EX.LAST_QTY) DAY_CUM_QTY,
                  SUM(EX.LAST_QTY*EX.LAST_PX) PRINCIPAL

                FROM EXECUTION EX
                WHERE EX.EXEC_TYPE IN ('F', 'G')
                AND EX.IS_BUSTED <> 'Y'
                and trunc(EX.EXEC_TIME) = date '2023-11-09'
            GROUP BY EX.ORDER_ID,
            TRUNC(EX.EXEC_TIME)
          ) DS ON DS.ORDER_ID = CL.ORDER_ID


      left join CLIENT_ORDER ORIG on (ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
      inner join FIX_CONNECTION FC on (CL.FIX_CONNECTION_ID = FC.FIX_CONNECTION_ID)
      inner join TRADING_FIRM TF ON TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
      inner join INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
      inner join TIME_IN_FORCE TIF on (TIF.TIF_ID = CL.TIME_IN_FORCE)
      inner join ORDER_TYPE OT on (OT.ORDER_TYPE_ID = CL.ORDER_TYPE)
      inner join EX_DESTINATION_CODE EXC on (EXC.EX_DESTINATION_CODE = CL.EX_DESTINATION)
      left join OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
      left join OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
      left join INSTRUMENT UI on (OS.UNDERLYING_INSTRUMENT_ID = UI.INSTRUMENT_ID)
      left join CLIENT_ORDER_LEG OL on (OL.ORDER_ID = CL.ORDER_ID)
      LEFT JOIN OPT_EXEC_BROKER OPX ON (OPX.ACCOUNT_ID  = AC.ACCOUNT_ID AND OPX.IS_DELETED <> 'Y' AND OPX.IS_DEFAULT  = 'Y')
      left join CUSTOMER_OR_FIRM CF on (CF.CUSTOMER_OR_FIRM_ID = CL.OPT_CUSTOMER_FIRM)

select order_id, account_id, mpid from CLIENT_ORDER cl
where cl.account_id in (28549,20505,19993,38549,30213,64810,64809,12410,64808,12909)
      and CL.PARENT_ORDER_ID is null
    and trunc(cl.CREATE_TIME) = date '2023-11-09'
    and MPID = 'CMPXCROSS'
--           and cl.ORDER_ID = 13664305271
      --TF.TRADING_FIRM_NAME = 'BMO Capital Markets';
      and AC.TRADING_FIRM_ID = 'wellsfarg';


select account_id from ACCOUNT
    where TRADING_FIRM_ID = 'wellsfarg'

select *
FROM EXECUTION EX
WHERE 1 = 1
--   and EX.EXEC_TYPE IN ('F', 'G')
  AND EX.IS_BUSTED <> 'Y'
  and trunc(EX.EXEC_TIME) = date '2023-11-09'
  and ex.ORDER_ID = 13664305271;


----- MLBCCEquitiesPHLX
with T as
		(
		  select
			 EX.SECONDARY_ORDER_ID as STR_ORDER_ID,
			 EX.EXEC_ID,
			 --max(EX.EXEC_ID) as EXEC_ID,
			 --CL.FIX_MESSAGE_ID,
			 AC.ACCOUNT_NAME,
			 AC.EQ_ORDER_CAPACITY,
			 AC.TRADING_FIRM_ID,
			 CL.SIDE,
			 EX.EXEC_TIME as EXEC_TIME,
			 date '2023-11-09' as TRADE_DATE,
			 EX.LAST_QTY as DAY_CUM_QTY,
			 EX.LAST_PX as DAY_AVG_PX,
			 --sum(EX.LAST_QTY) as DAY_CUM_QTY,
			 --round(sum(EX.LAST_QTY*EX.LAST_PX)/sum(EX.LAST_QTY), 6) as DAY_AVG_PX,
			 I.SYMBOL||I.SYMBOL_SUFFIX as SYMBOL_NAME,
			 I.SYMBOL_SUFFIX,
			 F9076.FIELD_VALUE as T9076,
			 AC.CLIENT_DTC_NUMBER
		  from CLIENT_ORDER CL
		  inner join ACTIVE_ACCOUNT_SNAPSHOT AC on (AC.ACCOUNT_ID  = CL.ACCOUNT_ID)
		  inner join EXECUTION EX on (EX.ORDER_ID = CL.ORDER_ID and EX.EXEC_TYPE in ('F','G'))
		  --inner join CLIENT_ORDER STR on STR.CLIENT_ORDER_ID = EX.SECONDARY_ORDER_ID and STR.INSTRUMENT_ID = CL.INSTRUMENT_ID
		  inner join INSTRUMENT I on (I.INSTRUMENT_ID = CL.INSTRUMENT_ID and I.SYMBOL not in (select TEST_SYMBOL from TEST_SYMBOL))
		  left join FIX_MESSAGE_FIELD F9076 on (CL.FIX_MESSAGE_ID = F9076.FIX_MESSAGE_ID and F9076.TAG_NUM = 9076)
		  where CL.PARENT_ORDER_ID IS  NULL
		  and EX.IS_BUSTED = 'N'
		  and trunc(EX.EXEC_TIME) = date '2023-11-10'
		  and exists (select 1 from DAILY_FINAL_EXECUTION where ORDER_ID = CL.ORDER_ID and trunc(STATUS_DATE) = date '2023-11-10')
		  and NVL(AC.EQ_REPORT_TO_MPID,'NONE') = 'NONE'
		  and NVL(AC.EQ_REAL_TIME_REPORT_TO_MPID,'NONE') = 'NONE'
		  and AC.TRADING_FIRM_ID <> 'baml'
 		  and I.INSTRUMENT_TYPE_ID = 'E'
		  and EX.EXCHANGE_ID = 'PHLX'
		  --group by AC.ACCOUNT_NAME, AC.EQ_ORDER_CAPACITY, AC.TRADING_FIRM_ID, CL.SIDE, trunc(EX.EXEC_TIME), I.SYMBOL, I.SYMBOL_SUFFIX, EX.SECONDARY_ORDER_ID, F9076.FIELD_VALUE, AC.CLIENT_DTC_NUMBER
		)

	select
	  rpad(
		case
			when REC_TYPE = 'TRL' then REC||lpad(to_char(REC_NUM-2), 10, '0')
			else REC
		end, 1000, ' ')
		from
		(
		 select ORD_FLAG_1, ORD_FLAG_2, rownum as REC_NUM, REC, REC_TYPE
		 from

			( select 1 as ORD_FLAG_1, 'A0' as ORD_FLAG_2, 'HDR' as REC_TYPE,
            'BCT221XD'||--1-8
            '  '||--9-10
            'ENTRY DATE: '||--11-22
			to_char(systimestamp at time zone DBTIMEZONE_GENESIS2, 'YYYYMMDD')||--23-30
			' '||--31-31
			to_char(systimestamp at time zone DBTIMEZONE_GENESIS2, 'HH24MI')||--32-35
            rpad(' ', 14)||--36-49
			'E'||--50 File type
            '  1'--File seq nbr 51-53
			as REC from DUAL

			union all

			select 5 as ORD_FLAG_1, 'Z0' as ORD_FLAG_2, 'TRL' as REC_TYPE,
			'99999999'||--1-8
			' '||
			'RECORD COUNT: '--10-23
			as REC from DUAL

			union all

			--68, drop
			select  2 as ORD_FLAG_1, 'A'||to_char(T.EXEC_ID) as ORD_FLAG_2, 'TRADE' as REC_TYPE,
			--#1
            '3Q800797'||--Avg Px

			'S'||--SEC_ID_TYPE -9
			rpad(T.SYMBOL_NAME, 22, ' ')||--10-31
			'  '||--32-33
			'4'||--34 Price code type
			to_char(round(T.DAY_AVG_PX,6), 'FM09999V999990')||--35-45

			lpad(T.DAY_CUM_QTY, 9, '0' )||--46-54 Qty
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '00000000'
			  else to_char(reporting.getBusinessDate(trunc(T.TRADE_DATE),2), 'YYYYMMDD')
			end||--55-62 Settle Date
			to_char(T.TRADE_DATE, 'YYYYMMDD')||--63-70 Trade Date
			case
			  when T.SIDE = '1' then '1'
			  when T.SIDE in ('2','5','6') then '2'
			  else '1'
			end||
			case
			  when T.SIDE in ('5','6') then '1'
			  else ' '
			end||--SHORT IND -72
			rpad(' ', 5)||--73-77
			'68'||--78-79
			rpad(' ', 10)||--filler 80-89
			'0'||--Trade Action --90
			'2'||--Commission Type 91
			'000000000'||--Commission Amount 92-100
			'0520PHLY'||--Opposing Account 101-108
			'0'||--109: no data in pos 214-333
			'   '||--110, 111, 112
			'2'||--113
			rpad(' ', 17)||--114-122;123-126;127-130;
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '1'
			  else ' '
			end||--131;
			'   '||--132;133-134 (exch 1)
			'   '||--135;136-137 (exch 2)
			'   '||--138;139-140 (exch 3)
			' '||--141
			rpad(' ', 6)||--142-147 alt sec num
			T.EQ_ORDER_CAPACITY||--148
			'A'||--149
			rpad(' ', 189)||--150-338
			'   '||--339-341 CC<1..4>
			' '|| --342
			case
				when T.ACCOUNT_NAME in ('dashtest','dasherror') then 'C'
				else 'A'
			end||--343
			rpad(' ', 9)||--344;345-352;
			to_char(T.EXEC_TIME, 'HH24MISS')||--353-358
			rpad(' ', 161)||--359-519
			' '||--SECT-31-FEE 520
			'Y'||--521 TBD
			rpad(' ', 197)||--522-718
			' '||--719
			rpad(' ', 20)||--720-739
			rpad(' ', 66)||--740-805
			lpad('A'||to_char(T.EXEC_ID), 20,'0') --806-825

			as REC
			from  T

            union all
            ----------------
            ----------------
            --88, allocation
            select  3 as ORD_FLAG_1, 'B'||to_char(T.EXEC_ID) as ORD_FLAG_2, 'TRADE' as REC_TYPE,
			--#1
            '3Q800806'||--Clearing Acc

			'S'||--SEC_ID_TYPE -9
			rpad(T.SYMBOL_NAME, 22, ' ')||--10-31
			'  '||--32-33
			'4'||--34 Price code type
			to_char(round(T.DAY_AVG_PX,6), 'FM09999V999990')||--35-45

			lpad(T.DAY_CUM_QTY, 9, '0' )||--46-54 Qty
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '00000000'
			  else to_char(reporting.getBusinessDate(trunc(T.TRADE_DATE),2), 'YYYYMMDD')
			end||--55-62 Settle Date
			to_char(T.TRADE_DATE, 'YYYYMMDD')||--63-70 Trade Date
			case
			  when T.SIDE = '1' then '1'
			  when T.SIDE in ('2','5','6') then '2'
			  else '1'
			end||
			case
			  when T.SIDE in ('5','6') then '1'
			  else ' '
			end||--SHORT IND -72
			rpad(' ', 5)||--73-77
			'88'||--78-79
			rpad(' ', 10)||--filler 80-89
			'0'||--Trade Action --90
			'2'||--Commission Type 91
			'000000000'||--Commission Amount 92-100
			'3Q800797'||--Opposing Account 101-108
			'0'||--109: no data in pos 214-333
			'   '||--110, 111, 112
			'2'||--113
			rpad(' ', 17)||--114-122;123-126;127-130;
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '1'
			  else ' '
			end||--131;
			'100'||--132;133-134 (exch 1)
			'   '||--135;136-137 (exch 2)
			'   '||--138;139-140 (exch 3)
			' '||--141
			rpad(' ', 6)||--142-147 alt sec num
			T.EQ_ORDER_CAPACITY||--148
			'A'||--149
			rpad(' ', 189)||--150-338
			'   '||--339-341 CC<1..4>
			' '|| --342
			case
				when T.ACCOUNT_NAME in ('dashtest','dasherror') then 'C'
				else 'A'
			end||--343
			rpad(' ', 9)||--344;345-352;
			to_char(T.EXEC_TIME, 'HH24MISS')||--353-358
			rpad(' ', 161)||--359-519
			' '||--SECT-31-FEE 520
			'Y'||--521 TBD
			rpad(' ', 197)||--522-718
			' '||--719
			rpad(' ', 20)||--720-739
			rpad(' ', 66)||--740-805
			lpad('B'||to_char(T.EXEC_ID), 20,'0') --806-825

			as REC
			from  T

            union all

			--M8, drop
			select  4 as ORD_FLAG_1, 'C'||to_char(T.EXEC_ID) as ORD_FLAG_2, 'TRADE' as REC_TYPE,
			--#1
            '3Q800806'||--Avg Px

			'S'||--SEC_ID_TYPE -9
			rpad(T.SYMBOL_NAME, 22, ' ')||--10-31
			'  '||--32-33
			'4'||--34 Price code type
			to_char(round(T.DAY_AVG_PX,6), 'FM09999V999990')||--35-45

			lpad(T.DAY_CUM_QTY, 9, '0' )||--46-54 Qty
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '00000000'
			  else to_char(reporting.getBusinessDate(trunc(T.TRADE_DATE),2), 'YYYYMMDD')
			end||--55-62 Settle Date
			to_char(T.TRADE_DATE, 'YYYYMMDD')||--63-70 Trade Date
			case
			  when T.SIDE = '1' then '2'
			  when T.SIDE in ('2','5','6') then '1'
			  else '2'
			end||
			' '||--SHORT IND -72
			rpad(' ', 5)||--73-77
			decode(T.TRADING_FIRM_ID,'cornerstn','98','M8')||--78-79
			rpad(' ', 10)||--filler 80-89
			'0'||--Trade Action --90
			'2'||--Commission Type 91
			'000000000'||--Commission Amount 92-100
			NVL(T.CLIENT_DTC_NUMBER,'0000')||NVL(T.T9076,'NONE')||--Opposing Account 101-108
			'0'||--109: no data in pos 214-333
			'   '||--110, 111, 112
			'2'||--113
			rpad(' ', 17)||--114-122;123-126;127-130;
			case
			  when T.SYMBOL_SUFFIX = 'WI' then '1'
			  else ' '
			end||--131;
			'   '||--132;133-134 (exch 1)
			'   '||--135;136-137 (exch 2)
			'   '||--138;139-140 (exch 3)
			' '||--141
			rpad(' ', 6)||--142-147 alt sec num
			T.EQ_ORDER_CAPACITY||--148
			'A'||--149
			rpad(' ', 189)||--150-338
			'   '||--339-341 CC<1..4>
			' '|| --342
			'A'||--343
			rpad(' ', 9)||--344;345-352;
			to_char(T.EXEC_TIME, 'HH24MISS')||--353-358
			rpad(' ', 161)||--359-519
			' '||--SECT-31-FEE 520
			'Y'||--521 TBD
			rpad(' ', 197)||--522-718
			' '||--719
			rpad(' ', 20)||--720-739
			rpad(' ', 66)||--740-805
			lpad('C'||to_char(T.EXEC_ID), 20,'0') --806-825

			as REC
			from  T

			order by  ORD_FLAG_1, ORD_FLAG_2
			)
		);

select to_char(round(123.45678,6), 'FM09999V999990') from dual

00123456780
00123456780