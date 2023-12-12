select * from dwh.d_account
         join dwh.d_trading_firm using (trading_firm_id)
where true
     and trading_firm_id = 'OFP0011'
and trading_firm_name ilike '%LPL%';

OFP0057
/*
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
*/

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

select cl.order_id,                                                                                                --Order Number
       case cl.multileg_reporting_type when '1' then '0' when '2' then cl.no_legs end,                             --Order Leg ID
       to_char(cl.create_time, 'MMDDYYYY'),                                                                        --Order Entry Date
       case cl.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end,                 --Action
       case cl.order_type_id when '1' then 'M' when '2' then 'L' when '3' then 'S' when '4' then 'SL' else 'L' end,--Type
       cl.order_qty,
       ex.leaves_qty,
       di.instrument_type_id,
       case when di.instrument_type_id = 'E' then di.symbol end,
       case when di.instrument_type_id = 'O' then os.root_symbol end,
       case oc.put_call when '0' then 'P' when '1' then 'C' end,
       cl.open_close,
       case when di.instrument_type_id = 'O' then to_char(di.last_trade_date, 'MMDDYY') end,
       to_char(oc.strike_price, 'FM99990D0099'),
       to_char(cl.price, 'FM99990D0099'),
       to_char(cl.stop_price, 'FM99990D0099'),
       case cl.time_in_force_id when '1' then 'GTC' when '6' then 'GTD' else cl.time_in_force_id end,
       coalesce(to_char(cl.expire_time, 'MMDDYYYY'), to_char(to_date(fmj.t432, 'YYYYMMDD'), 'YYYYMMDD')),
       case
           when cl.exec_instruction like '%G%' then 'AON'
           when cl.exec_instruction like '%1%' then 'NH'
           end
from dwh.gtc_order_status gtc
         join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id
--          inner join dwh.d_account ac on (cl.account_id = ac.account_id)
--          left join dwh.client_order orig on (orig.order_id = cl.orig_order_id)
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
--          inner join dwh.d_order_status ors on ors.order_status = ex.order_status
--          left join lateral (select sum(ex.last_qty) as ex_qty
--                             from dwh.execution ex
--                             where ex.exec_date_id >= gtc.create_date_id
--                               and ex.order_id = cl.order_id
--                               and ex.exec_type in ('F', 'G')
--                               and ex.is_busted = 'N'
--                             limit 1) exl on true
         left join lateral (select fix_message ->> '432' as t432
                            from fix_capture.fix_message_json fmj
                            where true
                              and fmj.fix_message_id = cl.fix_message_id
                              and fmj.date_id = cl.create_date_id
                              and fix_message ->> '432' is not null
                            limit 1) fmj on true
         left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
         left join d_option_series os on (oc.option_series_id = os.option_series_id)
--          left join dwh.client_order_leg leg on leg.order_id = cl.order_id
--          left join dwh.d_sub_system ss on ss.sub_system_unq_id = cl.sub_system_unq_id
--          left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
where true
  and cl.parent_order_id is null
  and gtc.close_date_id is null
  and cl.trans_type in ('D', 'G')
  and cl.time_in_force_id in ('1', '6')
  and cl.multileg_reporting_type in ('1', '2')
  and gtc.account_id = any ('{49730,57054,49729,68488,63849,19875,58772,57035,28519,19874}')

12634835091|0|07262023|B|SL|1|1|O||BAC|C|O|081823|30.00|5.00|5.00|GTD|08182023|;

select * from dash360.get_ameritrade_gtd(in_trading_firm_id := '{"OFP0011"}');
create or replace function dash360.get_ameritrade_gtd(in_date_id int4 default null::int4,
                                                      in_trading_firm_id text[] default null::text[])
    returns table
            (
                rec text
            )
    language plpgsql
as
$fx$
declare
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
             join dwh.d_trading_firm using (trading_firm_id)
    where case
              when in_trading_firm_id is null then trading_firm_id = 'OFP0011'
              else trading_firm_id = any (in_trading_firm_id) end;

    select public.load_log(l_load_id, l_step_id,
                           'get_ameritrade_gtd for accounts ' || l_account_ids::text || ' STARTED ====', in_date_id,
                           'O')
    into l_step_id;

    return query
        select "Order Number"::text || '|' ||
               coalesce("Order Leg ID", '') || '|' ||
               coalesce("Order Entry Date", '') || '|' ||
               coalesce("Action", '') || '|' ||
               coalesce("Type", '') || '|' ||
               coalesce(order_qty::text, '') || '|' ||
               coalesce(leaves_qty::text, '') || '|' ||
               coalesce(instrument_type_id::text, '') || '|' ||
               coalesce("Symbol", '') || '|' ||
               coalesce("Root Symbol", '') || '|' ||
               coalesce("Put or Call", '') || '|' ||
               coalesce("O/C", '') || '|' ||
               coalesce(last_trade_date, '') || '|' ||
               coalesce(strike_price, '') || '|' ||
               coalesce(price, '') || '|' ||
               coalesce(stop_price, '') || '|' ||
               coalesce(gtc, '') || '|' ||
               coalesce(expire_date, '') || '|' ||
               coalesce(notheld, '')
        from (select cl.order_id                                                   as "Order Number",
                     case cl.multileg_reporting_type
                         when '1' then '0'
                         when '2'
                             then cl.no_legs::text end                             as "Order Leg ID",
                     to_char(cl.create_time, 'MMDDYYYY')                           as "Order Entry Date",
                     case cl.side
                         when '1' then 'B'
                         when '2' then 'S'
                         when '5' then 'SS'
                         when '6'
                             then 'SS' end                                         as "Action",
                     case cl.order_type_id
                         when '1' then 'M'
                         when '2' then 'L'
                         when '3' then 'S'
                         when '4' then 'SL'
                         else 'L' end                                              as "Type",
                     cl.order_qty                                                  as order_qty,
                     ex.leaves_qty                                                 as leaves_qty,
                     di.instrument_type_id                                         as instrument_type_id,
                     case when di.instrument_type_id = 'E' then di.symbol end      as "Symbol",
                     case when di.instrument_type_id = 'O' then os.root_symbol end as "Root Symbol",
                     case oc.put_call when '0' then 'P' when '1' then 'C' end      as "Put or Call",
                     cl.open_close                                                 as "O/C",
                     case
                         when di.instrument_type_id = 'O'
                             then to_char(di.last_trade_date, 'MMDDYY') end        as last_trade_date,
                     to_char(oc.strike_price, 'FM99990D0099')                      as strike_price,
                     to_char(cl.price, 'FM99990D0099')                             as price,
                     to_char(cl.stop_price, 'FM99990D0099')                        as stop_price,
                     case cl.time_in_force_id
                         when '1' then 'GTC'
                         when '6' then 'GTD'
                         else cl.time_in_force_id end                              as gtc,
                     coalesce(to_char(cl.expire_time, 'MMDDYYYY'),
                              to_char(to_date(fmj.t432, 'YYYYMMDD'), 'YYYYMMDD'))  as expire_date,
                     case
                         when cl.exec_instruction like '%G%' then 'AON'
                         when cl.exec_instruction like '%1%' then 'NH'
                         end                                                       as notheld
              from dwh.gtc_order_status gtc
                       join dwh.client_order cl
                            on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
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
                and cl.parent_order_id is null
                and gtc.close_date_id is null
                and cl.trans_type in ('D', 'G')
                and cl.time_in_force_id in ('1', '6')
                and cl.multileg_reporting_type in ('1', '2')
                and gtc.account_id = any (l_account_ids)) x;

    select public.load_log(l_load_id, l_step_id,
                           'get_ameritrade_gtd for accounts FINISHED ====', in_date_id,
                           'O')
    into l_step_id;
end;
$fx$;

alter function dash360.get_ameritrade_gtd(int4, text[]) rename to report_gtd_open_order_recon;