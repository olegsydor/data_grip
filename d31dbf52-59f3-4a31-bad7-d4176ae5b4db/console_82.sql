with base as (select 'NO'                                      as RECORD_TYPE,
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
                                                    and fmj.date_id = :in_date_id)
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
                       inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID and ac.is_active
                       inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                       inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                       left join dwh.d_EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID
                       left join dwh.d_OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
                       left join dwh.d_OPTION_SERIES OS on OS.OPTION_SERIES_ID = OC.OPTION_SERIES_ID
                       left join dwh.d_ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE_id
                       left join dwh.d_TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE_id
              where 1 = 1
                --and CL.PARENT_ORDER_ID is null
                and (AC.ACCOUNT_NAME in
                     ('JPMONYX', 'LEKOFP', 'BLJPMPC2352', 'BLJPMPC3352', 'BLJPMPC5352', 'BLJPMPC6352', 'BLJPMPC8352',
                      'BLJPMPC1352', 'BLJPMPC4352', 'BLJPMPC9352') OR TF.TRADING_FIRM_ID = 'OFP0017')
                --and TF.TRADING_FIRM_ID not in ('OFP0010','regalse01')
                and CL.CREATE_date_id = :in_date_id
                and CL.TRANS_TYPE <> 'F'
                and CL.MULTILEG_REPORTING_TYPE = '1'
		and cl.order_id = 16452181673
    --order by CL.CREATE_TIME, CL.CLIENT_ORDER_ID
)
select order_id, count(*)
from base
group by order_id
having count(*) > 1

		;

select sub_strategy_id, sub_strategy_desc, time_in_force_id, *
from dwh.client_order
where true
--   and order_id = 16457341960
-- and time_in_force_id = '6'
  and create_date_id = 20240729
and sub_strategy_desc = 'DMA'
limit 21


