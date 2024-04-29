-- DROP FUNCTION dash_reporting.get_restricted_short(timestamp);
select to_char(public.get_business_date_back(:in_date::date, 4), 'YYYYMMDD')::int;

select * from trash.get_restricted_short(in_date := '2024-04-12')

CREATE or replace FUNCTION trash.get_restricted_short(in_date timestamp without time zone)
    RETURNS table
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_date_id_end   int;
    l_date_id_begin int;
    l_load_id       int;
    l_step_id       int;
    row_cnt         int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'reporting_get_restricted_short csv STARTED ====', 0, 'O')
    into l_step_id;

    l_date_id_end := to_char(in_date, 'YYYYMMDD')::int;
    l_date_id_begin := to_char(public.get_business_date_back(in_date::date, 4), 'YYYYMMDD')::int;

--    raise notice '%, %', l_date_id_begin, l_date_id_end;

    select public.load_log(l_load_id, l_step_id, 'l_date_id size is =' || l_date_id_begin || '-' || l_date_id_end, 1,
                           'O')
    into l_step_id;


    -- Start
--         select case
--                    when cnt > 1
--                        then rec
--                    else 'No orders were found to be in violation'
--                    end
--         from (select rec, COUNT(*) OVER () as cnt
--               from (
--
    return query
        select 'Date,Trading Firm Name,Account,Routed Time,Parent Cl Ord ID,Cl Ord ID,Ex Destination,Side,Symbol,Symbol Sfx,OrdQty,Price,OrdType,TIF,MaxFloor,ExecInst,Display Instruction,Display Indicator,ExQty,AvgPx,NBBO BidPx,EventTime,Ord Status';

    return query
        select to_char(STR.CREATE_TIME, 'YYYY-MM-DD') || ',' ||--Date
               TF.TRADING_FIRM_NAME || ',' ||
               AC.ACCOUNT_NAME || ',' ||
               to_char(STR.CREATE_TIME, 'YYYY-MM-DD HH24:MI:SS:FF3') || ',' ||
               CL.CLIENT_ORDER_ID || ',' ||
               STR.CLIENT_ORDER_ID || ',' ||
               STR.EXCHANGE_ID || ',' ||
               case STR.SIDE when '5' then 'Sell Short' when '6' then 'Sell Short Exempt' else '' end ||
               ',' ||
               coalesce(i.symbol, '') || ',' ||
               coalesce(i.symbol_suffix, '') || ',' ||
               coalesce(str.order_qty::text, '') || ',' ||
               coalesce(staging.trailing_dot(str.price), '') || ',' ||
               coalesce(ot.order_type_short_name, '') || ',' ||
               coalesce(tif.tif_name, '') || ',' ||
               coalesce(str.max_floor::text, '') || ',' ||
               coalesce(str.exec_instruction, '') || ',' ||
               coalesce(fmj.tag_9140, '') || ',' || --Disp Inst
               coalesce(fmj.tag_9479, '') || ',' || --Disp Ind
               coalesce(staging.trailing_dot(s_qty.sum_last_qty), '') || ',' || --Ex Qty
               coalesce(staging.trailing_dot(s_qty.avg_px), '') || ',' || --Ex Qty
--                             coalesce(staging.trailing_dot(BN_BID.bid_price), '') || ',' ||--NBBO Bid
               coalesce(to_char(trim_scale(BN_BID.bid_price), 'FM999990.0099'), '') || ',' ||--NBBO Bid
               to_char(LE.EXEC_TIME, 'YYYY-MM-DD HH24:MI:SS:FF3') || ',' || -- Final execution ExecTime
               case le.order_status
                   when '2' then 'Filled'
                   when '4' then 'Cancelled'
                   when '3' then 'Done For Day'
                   else coalesce(le.order_status, '') end || ',' ||--ord status

               '' as rec
        from dwh.client_order str
                 inner join lateral (select client_order_id,
                                            account_id,
                                            parent_order_id,
                                            instrument_id,
                                            transaction_id,
                                            multileg_reporting_type
                                     from dwh.client_order cl
                                     where str.parent_order_id = cl.order_id
                                     limit 1) cl on true
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
                 inner join dwh.d_time_in_force tif on tif.tif_id = str.time_in_force_id and tif.is_active
                 inner join dwh.d_order_type ot on ot.order_type_id = str.order_type_id
                 inner join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
                 inner join dwh.d_trading_firm tf
                            on tf.trading_firm_id = ac.trading_firm_id and tf.is_active
                 inner join lateral (select order_status, exec_time
                                     from execution le
--                                                   where exec_date_id between l_date_id_begin and l_date_id_end
                                     where le.exec_date_id = str.create_date_id
                                       and le.order_id = str.order_id
                                     order by le.exec_time desc, exec_id desc
                                     limit 1) le on true
                 left join lateral (select ll.bid_price
                                    from dwh.l1_snapshot ll
                                    where ll.transaction_id = coalesce(str.transaction_id, cl.transaction_id)
                                      and ll.exchange_id = 'NBBO'
                                      and ll.start_date_id = to_char(str.create_time, 'YYYYMMDD')::int4
                                      and ll.start_date_id between l_date_id_begin and l_date_id_end
                                    limit 1) bn_bid on true
                 left join lateral (select fix_message ->> '9140' as tag_9140,
                                           fix_message ->> '9479' as tag_9479
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = str.fix_message_id
                                      and date_id = str.create_date_id
                                      and date_id between l_date_id_begin and l_date_id_end
                                    limit 1) fmj on true
                 left join lateral (select sum(last_qty)                                                as sum_last_qty,
                                           round(sum(last_qty * last_px) / nullif(sum(last_qty), 0), 4) as avg_px
                                    from execution
                                    where exec_type in ('F', 'G')
                                      and is_busted = 'N'
                                      and order_id = str.order_id
                                      and exec_date_id between l_date_id_begin and l_date_id_end
                     limit 1
            ) s_qty on true
        where true
          and str.create_date_id between l_date_id_begin and l_date_id_end
          and cl.parent_order_id is null
          and str.trans_type <> 'F'
          and i.instrument_type_id = 'E'
          and str.side in ('5', '6')
          and STR.strtg_decision_reason_code in ('68', '69');

    get diagnostics row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
    into l_step_id;

-- Finish

end;
$function$
;


-- DROP FUNCTION dash360.report_fintech_adh_active_liquidity_indicators(_varchar, bpchar);

select *
from dash360.report_fintech_adh_active_liquidity_indicators(in_exchange_ids := null,
                                                                       in_instrument_type_id := 'E');
