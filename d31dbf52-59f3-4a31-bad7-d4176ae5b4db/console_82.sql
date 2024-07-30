    		select min(TIME_ID) over() as MIN_TIME,
			   max(TIME_ID) over() as MAX_TIME,
			   RECORD_TYPE,
			   REC from t_s3
where order_id = 16453703876;

select * from trash.so_s3(in_date_id := 20240729);

create or replace function trash.so_s3(in_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$$
declare
    l_accounts int4[];
    l_min_time_id int4;
    l_max_time_id int4;

begin
    select array_agg(account_id)
    into l_accounts
    from dwh.d_account ac
             join dwh.d_trading_firm tf using (trading_firm_id)
    where true
      and (AC.ACCOUNT_NAME in
           ('JPMONYX', 'LEKOFP', 'BLJPMPC2352', 'BLJPMPC3352', 'BLJPMPC5352', 'BLJPMPC6352', 'BLJPMPC8352',
            'BLJPMPC1352',
            'BLJPMPC4352', 'BLJPMPC9352') OR TF.TRADING_FIRM_ID = 'OFP0017');

    drop table if exists t_s3;

    create temp table t_s3 as
    select 'NO'                                      as RECORD_TYPE,
           coalesce(CL.PARENT_ORDER_ID, CL.ORDER_ID) as ORDER_ID,
           to_char(CL.PROCESS_TIME, 'HH24MISSFF3')   as TIME_ID,
           CL.CLIENT_ORDER_ID                        as RECORD_ID,
           1                                         as RECORD_TYPE_ID,
           array_to_string(array [
                               'O', --1
                               case
                                   when CL.PARENT_ORDER_ID is null then 'NO'
                                   else 'RO'
                                   end,

                               CL.CLIENT_ORDER_ID,
                               CL.ORDER_ID::text, --SOURCE_ORDER_ID
                               CL.PARENT_ORDER_ID::text, --SOURCE_PARENT_ID
                               CL.ORIG_ORDER_ID::text,
                               --
                               '',
                               case
                                   when CL.PARENT_ORDER_ID is null then case AC.BROKER_DEALER_MPID
                                                                            when 'NONE' then NULL
                                                                            else AC.BROKER_DEALER_MPID end
                                   else 'DFIN'
                                   end,
                               case
                                   when CL.PARENT_ORDER_ID is null then 'DFIN'
                                   else coalesce(EXC.MIC_CODE, EXC.EQ_MPID)
                                   end,
                               --AC.BROKER_DEALER_MPID,
                               --'DFIN',
                               '',
                               '',
                               case
                                   when CL.MULTILEG_REPORTING_TYPE = '3' then ''
                                   else I.INSTRUMENT_TYPE_ID end, --12
                               case I.INSTRUMENT_TYPE_ID
                                   when 'E' then I.DISPLAY_INSTRUMENT_ID
                                   when 'O' then OC.OPRA_SYMBOL end,
                               '', --primary Exchange
                               case CL.SIDE
                                   when '1' then 'B'
                                   when '2' then 'S'
                                   when '5' then 'SS'
                                   when '6' then 'SSE' end, --OrderAction
                               to_char(CL.PROCESS_TIME, 'YYYYMMDD') || 'T' ||
                               to_char(CL.PROCESS_TIME, 'HH24MISSFF3'),
                               OT.ORDER_TYPE_SHORT_NAME, --ORDER_TYPE
                               CL.ORDER_QTY::text, --ORDER_VOLUME
                               to_char(CL.PRICE, 'FM99990D0099'),
                               to_char(CL.STOP_PRICE, 'FM99990D0099'),
                               TIF.TIF_SHORT_NAME,
                               case
                                   when CL.EXPIRE_TIME is not null then
                                       to_char(CL.EXPIRE_TIME, 'YYYYMMDD') || 'T' ||
                                       to_char(CL.EXPIRE_TIME, 'HH24MISSFF3')
                                   when CL.TIME_IN_FORCE_id = '6' then
                                       (select coalesce(fix_message ->> '432', '') || 'T235959000'
                                        from fix_capture.fix_message_json fmj
                                        where fmj.fix_message_id = CL.FIX_MESSAGE_ID
                                          and fmj.date_id = in_date_id)
                                   end, --22
                               '0', --PRE_MARKET_IND
                               '',
                               '0', --POST_MARKET_IND
                               '',
                               case
                                   when CL.PARENT_ORDER_ID is null
                                       then case when CL.SUB_STRATEGY_desc = 'DMA' then '1' else '0' end
                                   else (select case when PO.SUB_STRATEGY_desc = 'DMA' then '1' else '0' end
                                         from CLIENT_ORDER PO
                                         where PO.ORDER_ID = CL.PARENT_ORDER_ID)
                                   end, --DIRECTED_ORDER_IND
                               case
                                   when CL.PARENT_ORDER_ID is null
                                       then case when CL.SUB_STRATEGY_desc = 'SMOKE' then '1' else '0' end
                                   else (select case when PO.SUB_STRATEGY_desc = 'SMOKE' then '1' else '0' end
                                         from CLIENT_ORDER PO
                                         where PO.ORDER_ID = CL.PARENT_ORDER_ID)
                                   end, --NON_DISPLAY_IND
                               '0', --DO_NOT_REDUCE
                               case CL.exec_instruction when 'G' then '1' else '0' end,
                               case CL.exec_instruction when '1' then '1' else '0' end, --NOT_HELD_IND [31]
                               '0', --[32]
                               '0', --[33]
                               '0', --[34]
                               '', --[35]
                               '', --[36]
                               '', --[37]
                               '', --[38]
                               '', --[39]
                               '', --[40]
                               '', --[41]
                               '', --[42]
                               '', --[43]
                               '', --[44]
                               '', --[45]
                               '', --[46]
                               '', --[47]
                               '' --[48]
                               ], '|', '')
                                                     as REC

    from CLIENT_ORDER CL
             inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
             inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
             inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
             left join dwh.d_EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID and exc.is_active
             left join dwh.d_OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
             left join dwh.d_OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
             left join dwh.d_ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE_id
             left join dwh.d_TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE_id
    where true
      and cl.account_id = any (l_accounts)
      and CL.CREATE_date_id = in_date_id
      and CL.TRANS_TYPE <> 'F'
      and CL.MULTILEG_REPORTING_TYPE = '1';

    insert into t_s3
    select 'A'                                       as RECORD_TYPE,
           coalesce(CL.PARENT_ORDER_ID, CL.ORDER_ID) as ORDER_ID,
           to_char(CL.PROCESS_TIME, 'HH24MISSFF3')   as TIME_ID,
           CL.CLIENT_ORDER_ID                        as RECORD_ID,
           3                                         as RECORD_TYPE_ID,
           array_to_string(array [
                               'A',
                               CL.ORDER_ID::text,
                               case EX.EXEC_TYPE when '4' then 'C' when '8' then 'RJ' end, --EVENT
                               '', --SYSTEM_ID
                               case CL.MULTILEG_REPORTING_TYPE when '3' then '' else I.INSTRUMENT_TYPE_ID end,
                               case I.INSTRUMENT_TYPE_ID
                                   when 'E' then I.DISPLAY_INSTRUMENT_ID
                                   when 'O' then OC.OPRA_SYMBOL end,
                               '', --SYMBOL_EXCHANGE
                               to_char(EX.EXEC_TIME, 'YYYYMMDD') || 'T' || to_char(EX.EXEC_TIME, 'HH24MISSFF3'),
                               '', --DESCRIPTION
                               '', --[10]
                               '', --[11]
                               '', --[12]
                               '', --[13]
                               '' --[14]
                               ], '|', '')
                                                     as REC
    from dwh.EXECUTION EX
             inner join lateral (select *
                                 from dwh.CLIENT_ORDER CL
                                 where EX.ORDER_ID = CL.ORDER_ID
                                   and CL.TRANS_TYPE <> 'F'
                                   and CL.MULTILEG_REPORTING_TYPE = '1'
                                   and cl.create_date_id >= ex.exec_date_id
                                   and cl.account_id = any
                                       ('{24011,28515,22774,22770,22771,22772,22768,22775,22767,22769,25711,18497,30650}')
                                 order by create_date_id desc
                                 limit 1) cl on true
             inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
             left join dwh.d_OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
             left join dwh.d_OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
    where true
      and EX.exec_date_id = in_date_id
      and EX.EXEC_TYPE in ('4', '8');


    insert into t_s3
    select 'T'                                       as RECORD_TYPE,
           coalesce(CL.PARENT_ORDER_ID, CL.ORDER_ID) as ORDER_ID,
           to_char(EX.EXEC_TIME, 'HH24MISSFF3')      as TIME_ID,
           CL.CLIENT_ORDER_ID                        as RECORD_ID,
           2                                         as RECORD_TYPE_ID,
           array_to_string(array [
                               'T',
                               CL.ORDER_ID::text,
                               CL.ORDER_ID || '_' || EX.EXEC_ID,
                               '',
                               '',
                               I.INSTRUMENT_TYPE_ID,
                               case I.INSTRUMENT_TYPE_ID
                                   when 'E' then I.DISPLAY_INSTRUMENT_ID
                                   when 'O' then OC.OPRA_SYMBOL end,
                               '', --SYMBOL_EXCHANGE
                               to_char(EX.EXEC_TIME, 'YYYYMMDD') || 'T' ||
                               to_char(EX.EXEC_TIME, 'HH24MISSFF3'), --ACTION_DATETIME
                               EX.LAST_QTY::text,
                               to_char(EX.LAST_PX, 'FM99990D0099'),
                               EX.EXCHANGE_ID,
                               '', --[12]
                               '', --[13]
                               '', --[14]
                               '', --[15]
                               '', --[16]
                               '', --[17]
                               '', --[18]
                               '', --[19]
                               '', --[20]
                               '', --[21]
                               '', --[22]
                               '' --[23]
                               ], '|', '')
                                                     as REC
    from dwh.EXECUTION EX
             inner join lateral (select *
                                 from dwh.CLIENT_ORDER CL
                                 where EX.ORDER_ID = CL.ORDER_ID
                                   and cl.create_date_id >= ex.exec_date_id
                                   and cl.account_id = any
                                       ('{24011,28515,22774,22770,22771,22772,22768,22775,22767,22769,25711,18497,30650}')
                                   and CL.PARENT_ORDER_ID is not null
                                   and CL.TRANS_TYPE <> 'F'
                                   and CL.MULTILEG_REPORTING_TYPE = '1'
                                 order by create_date_id desc
                                 limit 1) cl on true
             inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
             left join dwh.d_OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
             left join dwh.d_OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
    where true
      and EX.exec_date_id = in_date_id
      and EX.EXEC_TYPE in ('F');

    select into l_min_time_id, l_max_time_id min(TIME_ID) over (),
                                             max(TIME_ID) over ()
    from t_s3;

    return query
    select 'H|V2.0.4|'||
				to_char(clock_timestamp(),'YYYYMMDD')||'T'||to_char(clock_timestamp(),'HH24MISSFF3') ||'|'||
    in_date_id::text ||'T'||l_min_time_id ||'|'||
    in_date_id::text ||'T'||l_max_time_id ||'|'||
    'DFIN|DAIN|tradedesk@dashfinancial.com|'
    ;

    return query
        select rec from t_s3
    order by order_id, time_id, record_id, record_type_id;
end;
$$


select 'H|V2.0.4|'||
				to_char(clock_timestamp(),'YYYYMMDD')||'T'||to_char(clock_timestamp(),'HH24MISSFF3') ||'|'||
    :in_date_id::text ||'T'||:l_min_time_id ||'|'||
    :in_date_id::text ||'T'||:l_max_time_id ||'|'||
    'DFIN|DAIN|tradedesk@dashfinancial.com|'
    ;