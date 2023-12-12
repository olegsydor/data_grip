select STR.CLIENT_ORDER_ID||'|'||
       CL.CLIENT_ORDER_ID ||'|'||   
       ''||'|'||   
       to_char(STR.PROCESS_TIME,'YYYY-MM-DD HH24:MI:SS.MS') ||'|'||
       coalesce(to_char(EX0.EXEC_TIME,'YYYY-MM-DD HH24:MI:SS.MS'),'')||'|'||--Ack
       
       coalesce((select min(to_char(EXF.EXEC_TIME,'YYYY-MM-DD HH24:MI:SS.MS')) from EXECUTION EXF where EXF.ORDER_ID = STR.ORDER_ID and EXF.EXEC_TYPE = 'F'),'')||'|'||--FirstExec
       --to_char(EX1.EXEC_TIME at time zone DBTIMEZONE_GENESIS2,'YYYY-MM-DD HH24:MI:SS.MS') ||'|'||--FirstExec
       coalesce((select max(to_char(EXL.EXEC_TIME,'YYYY-MM-DD HH24:MI:SS.MS')) from EXECUTION EXL where EXL.ORDER_ID = STR.ORDER_ID and EXL.EXEC_TYPE in ('4','F')),'')||'|'||--FinalFill/Cancel
       
       case 
         when CL.SUB_STRATEGY_DESC  = 'SENSOR' and (CL.AGGRESSION_LEVEL = '5' or CL.AGGRESSION_LEVEL is NULL) then 'LIMIT'
         when CL.SUB_STRATEGY_DESC  = 'SENSOR' and CL.AGGRESSION_LEVEL in ('1','2','3','4') then 'BSM'
         when CL.SUB_STRATEGY_DESC  = 'SMOKE' then 'HideAndSweep'
         else CL.SUB_STRATEGY_DESC
       end||'|'||
       
       coalesce(CL.AGGRESSION_LEVEL::varchar,'')||'|'||--RiskFactor
       case STR.ORDER_TYPE_ID
       	when '1' then 'Market'
       	when '2' then 'Limit'
       	when 'P' then 'Peg'
       	else STR.ORDER_TYPE_ID
       end||'|'||
       coalesce(STR.EXEC_INSTRUCTION::varchar,'') ||'|'||
       -- no field in the table
       --decode(CL.HIDDEN_FLAG,'Y','N')||'|'||--DisplayInst
       ''||'|'|| 
       --
       ''||'|'|| 
       ''||'|'|| 
       
       I.DISPLAY_INSTRUMENT_ID ||'|'|| 
       coalesce(CL.TIME_IN_FORCE_ID::varchar,'') ||'|'||
       case STR.SIDE
        when '2' then 'S'
        when '5' then 'SS'
        when '6' then 'SS'
        else 'B' 
       end||'|'||
       coalesce(STR.PRICE::varchar,'')||'|'||
       STR.ORDER_QTY||'|'||
       ''||'|'|| 
       
       (SELECT coalesce(SUM(EX.LAST_QTY)::varchar,'')     
                FROM EXECUTION EX
                WHERE EX.EXEC_TYPE IN ('F', 'G')
                AND EX.IS_BUSTED ='N'
                and EX.ORDER_ID = STR.ORDER_ID) ||'|'||     
       coalesce(to_char(round((SELECT SUM(EX.LAST_QTY*EX.LAST_PX)/SUM(EX.LAST_QTY)    
                FROM EXECUTION EX
                WHERE EX.EXEC_TYPE IN ('F', 'G')
                AND EX.IS_BUSTED ='N'
                and EX.ORDER_ID = STR.ORDER_ID),4),'FM9999990.0000'), '') ||'|'|| 
                
       'DASH'||'|'||--Broker
       ''||'|'||--ClientID
       coalesce(EXC.MIC_CODE::varchar,'')||'|'||--Dest
       coalesce(EXR.DISPLAY_EXCHANGE_NAME::varchar,'')||'|'||--Dest Name
       'USD'||'|'||
       
       (select coalesce(sum(EX.LAST_QTY)::varchar,'') from EXECUTION EX
        inner join D_EXCHANGE EXC1 on EXC1.EXCHANGE_ID = EX.EXCHANGE_ID
        inner join D_LIQUIDITY_INDICATOR LIN ON (LIN.EXCHANGE_ID = EXC1.REAL_EXCHANGE_ID AND LIN.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR)
        where EX.ORDER_ID = CL.ORDER_ID and
          EX.SECONDARY_ORDER_ID = STR.CLIENT_ORDER_ID and
          EX.EXEC_TYPE  = 'F' and
          EX.IS_BUSTED = 'N' and 
          --trunc(EX.EXEC_TIME) = trunc(p_date) and
          LIN.LIQUIDITY_INDICATOR_TYPE_ID in ('1','4')
        )||'|'||--Add
       (select coalesce(sum(EX.LAST_QTY)::varchar,'') from EXECUTION EX
        inner join D_EXCHANGE EXC1 on EXC1.EXCHANGE_ID = EX.EXCHANGE_ID
        left join D_LIQUIDITY_INDICATOR LIN ON (LIN.EXCHANGE_ID = EXC1.REAL_EXCHANGE_ID AND LIN.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR)
        where EX.ORDER_ID = CL.ORDER_ID and
          EX.SECONDARY_ORDER_ID = STR.CLIENT_ORDER_ID and
          EX.EXEC_TYPE  = 'F' and
          EX.IS_BUSTED = 'N' and 
          --trunc(EX.EXEC_TIME) = trunc(p_date) and
          (LIN.LIQUIDITY_INDICATOR_TYPE_ID = '2' or LIN.LIQUIDITY_INDICATOR_TYPE_ID  is NULL)
        )||'|'||--Take
        
       (select coalesce(sum(EX.LAST_QTY)::varchar,'') from EXECUTION EX
        inner join D_EXCHANGE EXC1 on EXC1.EXCHANGE_ID = EX.EXCHANGE_ID
        inner join D_LIQUIDITY_INDICATOR LIN ON (LIN.EXCHANGE_ID = EXC1.REAL_EXCHANGE_ID AND LIN.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR)
        where EX.ORDER_ID = CL.ORDER_ID and
          EX.SECONDARY_ORDER_ID = STR.CLIENT_ORDER_ID and
          EX.EXEC_TYPE  = 'F' and
          EX.IS_BUSTED = 'N' and 
          --trunc(EX.EXEC_TIME) = trunc(p_date) and
          LIN.LIQUIDITY_INDICATOR_TYPE_ID = '3'
        )||'|'||--Route 
        
       
        '0.0000'||'||'--Fee--TestingStatus
        
        
      as REC   
  	from D_ACCOUNT AC
    inner join CLIENT_ORDER CL on CL.ACCOUNT_ID = AC.ACCOUNT_ID  
    inner join D_INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
    inner join CLIENT_ORDER STR on STR.PARENT_ORDER_ID = CL.ORDER_ID
    inner join D_EXCHANGE EXC on EXC.EXCHANGE_ID = STR.EXCHANGE_ID and EXC.IS_ACTIVE = true
    inner join D_EXCHANGE EXR on EXC.REAL_EXCHANGE_ID = EXR.EXCHANGE_ID and EXR.IS_ACTIVE = true

    left join EXECUTION EX0 on (EX0.ORDER_ID = STR.ORDER_ID and EX0.EXEC_TYPE = '0')   

  	where AC.TRADING_FIRM_ID = :in_trading_firm_id
    and CL.PARENT_ORDER_ID is null 
    and CL.CREATE_DATE_ID = :in_date_id
    and I.INSTRUMENT_TYPE_ID = 'E' 
    and STR.CREATE_DATE_ID = :in_date_id
    and STR.TRANS_TYPE in ('D','G')
    and EX0.EXEC_DATE_ID = :in_date_id;


select * from dwh.client_order
    where account_id in (32970,32971)
and create_date_id between 20230101 and 20231101


select * from d_account
where TRADING_FIRM_ID = :in_trading_firm_id