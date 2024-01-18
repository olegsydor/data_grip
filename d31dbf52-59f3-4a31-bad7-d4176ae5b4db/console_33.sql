/*
-- DROP FUNCTION dash360.report_rps_ofp0016_gtc();

CREATE or replace FUNCTION trash.so_report_rps_ofp0016_gtc(in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                           in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_account_ids int4[];
    l_date        date := in_end_date_id::text::date;
    l_row_cnt     int4;
    l_load_id     int4;
    l_step_id     int4;
    l_is_current_date bool := false;
begin

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ofp0016_gtc for '  || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.mv_active_account_snapshot ac
    where ac.trading_firm_id = 'OFP0016'
      and is_active;

    create temp table tmp_etrade on commit drop as
    select 'DET'                           as REC_TYPE,
           2                               as OUT_ORD_FLAG,
           array_to_string(ARRAY [
                               'DET', --||'|'|| --[1]
                               case cl.multileg_reporting_type
                                   when '1' then 'SIMPLE'
                                   when '2' then 'COMPLEX' end, --||'|'||--[2]
                               'Dash', --||'|'||--[3]
                               case I.instrument_type_id when 'O' then 'OP' when 'E' then 'EQ' end, --||'|'||--[4]
                               case I.instrument_type_id
                                   when 'O' then os.ROOT_SYMBOL
                                   when 'E' then I.SYMBOL end, --||'|'||--[5]
                               case I.instrument_type_id
                                   when 'O' then replace(oc.opra_symbol, ' ', '-') end, --||'|'|| --[6]
                               case CL.multileg_reporting_type
                                   when '1' then '0'
                                   when '2' then cl.co_client_leg_ref_id end, --||'|'|| --[7]
                               case cl.side
                                   when '1' then 'Buy'
                                   when '2' then 'Sell'
                                   when '5' then 'Short Sell'
                                   when '6' then 'Short Sell' end, --||'|'||--[8]
                               case oc.put_call when '0' then 'Put' when '1' then 'Call' end, --||'|'|| --[9]
                               case cl.open_close when 'O' then 'Open' when 'C' then 'Close' end, --||'|'|| --[10]
                               ot.order_type_short_name, --||'|'||--Order Type --[11]
               --CL.ORDER_QTY||'|'||
                               (cl.order_qty - coalesce(ex.cum_qty, 0::int))::text, --||'|'|| --[12]
                               to_char(cl.price, 'FM99990D0000'), --||'|'||
                               to_char(oc.strike_price, 'FM99990D0000'), --||'|'||
                               to_char(cl.stop_price, 'FM99990D0000'), --||'|'||
                               case
                                   when I.instrument_type_id = 'O' and cl.order_type_id in ('2', '4')
                                       then to_char(cl.price, 'FM99990D0000')
                                   end, --||'|'||--[16]
                               '', --||'|'||
                               to_char(cl.create_time, 'YYYYMMDD'), --||'|'||
                               to_char(i.last_trade_date, 'YYYYMMDD'), --||'|'||
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'||
               --
                               cl.order_id::text, --||'|'|| --23
               --
                               '', --||'|'||
                               cl.client_order_id, --||'|'|| --25
                               '', --||'|'|| --26
               --
                               '', --||'|'|| --Covererd/Uncovered
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'|| --Record type
                               ac.broker_dealer_mpid -- --mpid
                               ], '|', '') as rec
    from dwh.gtc_order_status gtc
             join dwh.client_order cl using (create_date_id, order_id)
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
        ---------------------------------------------------------------------------------------------------------
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
             inner join dwh.d_order_type ot on (cl.order_type_id = ot.order_type_id)
             inner join dwh.mv_active_account_snapshot ac on (cl.account_id = ac.account_id)
             left join lateral (
        select sum(case when exc.exec_type = 'F' then exc.last_qty else 0 end) as cum_qty
        from dwh.execution exc
        where exc.exec_date_id >= gtc.create_date_id
          and exc.order_id = gtc.order_id
          and exc.is_busted = 'N'
        group by exc.order_id
        limit 1
        ) ex on true
    where true
      and gtc.create_date_id <= in_start_date_id
      and gtc.account_id = any (l_account_ids)
      and cl.parent_order_id is null
      and cl.trans_type <> 'F'
      and coalesce(gtc.last_trade_date, l_date + '1 day'::interval) > l_date
      and gtc.time_in_force_id = '1'
      and cl.multileg_reporting_type <> '3'
      and (gtc.close_date_id is null
        or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
      and not exists(select null
                     from dwh.execution ex
                     where ex.order_id = cl.order_id
                       and ex.exec_date_id >= cl.create_date_id
                       and order_status in ('2', '4', '8'));

    get diagnostics l_row_cnt = row_count;

    return query
        select case
                   when REC_TYPE = 'TRL' then rec || '|' || l_row_cnt::text
                   else rec
                   end
        from (select rec, rec_type, out_ord_flag
              from tmp_etrade
              union all
              select 'HDR' || '|' || to_char(clock_timestamp(), 'YYYYMMDD') || '|' ||
                     to_char(clock_timestamp(), 'HH24:MM:SS') || '|' || 'Dash OPTIONS' as rec,
                     'HDR'                                                             as rec_type,
                     1                                                                 as out_ord_flag
              union all
              select 'TRL' || '|' || to_char(clock_timestamp(), 'YYYYMMDD') || '|' ||
                     to_char(clock_timestamp(), 'HH24:MM:SS') as rec,
                     'TRL'                                    as rec_type,
                     3                                        as out_ord_flag
              order by out_ord_flag) y;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_rps_ofp0016_gtc for ' || l_date::text || ' finished===',
                           l_row_cnt, 'O')
    into l_step_id;
end;

$function$
;

select * from trash.so_report_rps_ofp0016_gtc();
select * from dash360.report_rps_ofp0016_gtc(20240114, 20240114);
select * from dash360.report_rps_ofp0016_gtc();


select * from dash360.report_rps_ofp0016_gtc();

alter function dash360.report_rps_ofp0016_gtc rename to report_rps_ofp0016_gtc_old;
alter function dash360.report_rps_ofp0016_gtc_old set schema trash;
alter function trash.so_report_rps_ofp0016_gtc set schema dash360;
alter function dash360.so_report_rps_ofp0016_gtc rename to report_rps_ofp0016_gtc;


*/
drop function dash360.report_rps_ofp0011_gtd;
create function dash360.report_rps_ofp0011_gtd(in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare
    l_account_ids int4[];
    l_row_cnt     int4;
    l_load_id     int4;
    l_step_id     int4;
    l_is_current_date bool := false;

begin
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ofp0011_gtd for '  || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.mv_active_account_snapshot ac
    where ac.is_active
      and ac.trading_firm_id in ('OFP0011');

--     select '{64998}' into l_account_ids;

    create temp table tmp_ameri on commit drop as
    select cl.order_id,
           cl.multileg_reporting_type,
           cl.no_legs,
           cl.create_time,
           cl.side,
           cl.order_type_id,
           cl.order_qty,
           ex.leaves_qty,
           di.instrument_type_id,
           di.symbol,
           os.root_symbol,
           oc.put_call,
           cl.open_close,
           di.last_trade_date,
           oc.strike_price,
           cl.price,
           cl.stop_price,
           cl.time_in_force_id,
           cl.expire_time,
           fmj.t432,
           cl.exec_instruction
    from dwh.gtc_order_status gtc
             join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
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
      and gtc.account_id = any (l_account_ids)
      and cl.parent_order_id is null
      and gtc.time_in_force_id = '6'
      and cl.trans_type <> 'F'
      and cl.multileg_reporting_type <> '3'
      and not exists (select null
                      from dwh.execution ex
                      where ex.order_id = gtc.order_id
                        and ex.exec_date_id >= gtc.create_date_id
                        and ex.order_status in ('2', '4', '8'))
      and gtc.create_date_id <= in_start_date_id
      and (gtc.close_date_id is null
        or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end));

    get diagnostics l_row_cnt = row_count;

    return query
        select 'LIQUID2A' || '|' || to_char(current_date, 'MMDDYYYY');

    return query
        select array_to_string(array [
                                   order_id::text,
                                   case multileg_reporting_type
                                       when '1' then '0'::text
                                       when '2' then no_legs::text end, --order leg id
                                   to_char(create_time, 'MMDDYYYY'), --Order Entry Date
                                   case side
                                       when '1' then 'B'
                                       when '2' then 'S'
                                       when '5' then 'SS'
                                       when '6' then 'SS' end, --Action
                                   case order_type_id
                                       when '1' then 'M'
                                       when '2' then 'L'
                                       when '3' then 'S'
                                       when '4' then 'SL'
                                       else 'L' end, --Type
                                   order_qty::text,
                                   leaves_qty::text,
                                   instrument_type_id::text,
                                   case instrument_type_id when 'E' then symbol end,
                                   case instrument_type_id when 'O' then root_symbol end,
                                   case put_call when '0' then 'P' when '1' then 'C' end,
                                   open_close,
                                   case instrument_type_id when 'O' then to_char(last_trade_date, 'MMDDYY') end,
                                   to_char(strike_price, 'FM99990D0099'),
                                   to_char(price, 'FM99990D0099'),
                                   to_char(stop_price, 'FM99990D0099'),
                                   case time_in_force_id
                                       when '1' then 'GTC'
                                       when '6' then 'GTD'
                                       else time_in_force_id end,
                                   to_char(coalesce(expire_time, to_date(t432, 'YYYYMMDD')), 'MMDDYYYY'),
                                   case
                                       when exec_instruction like '%G%' then 'AON'
                                       when exec_instruction like '%1%' then 'NH'
                                       end
                                   ], '|', '') as rec
        from tmp_ameri;

    return query
        select 'Total Number of Records' || '|' || l_row_cnt::text;
    select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ofp0011_gtd for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' FINISHED===', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;

select * from dash360.report_rps_ofp0011_gtd(20231201, 20231210);
select * from dash360.report_rps_ofp0011_gtd();


select * from dwh.d_account
where account_name = '5CG05455'