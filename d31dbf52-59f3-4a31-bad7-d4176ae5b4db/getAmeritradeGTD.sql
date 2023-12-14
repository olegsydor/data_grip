select * from dash360.report_rps_ofp0011_gtd()
create or replace function dash360.report_rps_ofp0011_gtd()
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$$
declare
    l_account_ids int4[];
    l_row_cnt     int4;

begin
    select array_agg(account_id)
    into l_account_ids
    from dwh.mv_active_account_snapshot ac
    where ac.is_active
      and AC.TRADING_FIRM_ID in ('OFP0011');

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
      and gtc.close_date_id is null;

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

end;
$$;


select * from dwh.gtc_order_status gtc
where true
  and gtc.account_id in (49730,49729,63849,19875,58772,57035,57054,28519,19874,69611)