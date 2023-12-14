/*select * from report_tmp

create temp table report_tmp as
    select 'DET' as REC_TYPE,
           2     as out_ord_flag,
           'DET' || '|' || --[1]
           case cl.multileg_reporting_type when '1' then 'SIMPLE' when '2' then 'COMPLEX' else '' end || '|' ||--[2]
           'Dash' || '|' ||--[3]
           case i.instrument_type_id when 'O' then 'OP' when 'E' then 'EQ' else '' end || '|' ||--[4]
           case i.instrument_type_id when 'O' then os.root_symbol when 'E' then i.symbol else '' end || '|' ||--[5]
           case i.instrument_type_id when 'O' then replace(oc.opra_symbol, ' ', '-') else '' end || '|' || --[6]
           case cl.multileg_reporting_type when '1' then '0' when '2' then cl.co_client_leg_ref_id else '' end ||
           '|' || --[7]
           case cl.side
               when '1' then 'Buy'
               when '2' then 'Sell'
               when '5' then 'Short Sell'
               when '6' then 'Short Sell'
               else '' end || '|' ||--[8]
           case oc.put_call when '0' then 'Put' when '1' then 'Call' else '' end || '|' || --[9]
           case cl.open_close when 'O' then 'Open' when 'C' then 'Close' else '' end || '|' || --[10]
           coalesce(ot.order_type_short_name, '') || '|' ||--Order Type --[11]
           --cl.ORDER_QTY||'|'||
           (cl.order_qty - cum_qty)::text || '|' || --[12]
           coalesce(to_char(cl.price, 'FM99990D0000'), '') || '|' ||
           coalesce(to_char(oc.strike_price, 'FM99990D0000'), '') || '|' ||
           coalesce(to_char(cl.stop_price, 'FM99990D0000'), '') || '|' ||
           case
               when i.instrument_type_id = 'O' and cl.order_type_id in ('2', '4') then to_char(cl.PRICE, 'FM99990D0000')
               else '' end || '|' ||--[16]
           '' || '|' ||
           to_char(cl.create_time, 'YYYYMMDD') || '|' ||
           coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), '') || '|' ||
           '' || '|' ||
           '' || '|' ||
           '' || '|' ||
               --
           cl.order_id || '|' || --23
           --
           '' || '|' ||
           cl.client_order_id || '|' || --25
           '' || '|' || --26
           --
           '' || '|' || --Covererd/Uncovered
           '' || '|' ||
           '' || '|' ||
           '' || '|' ||
           '' || '|' || --Record type
           AC.BROKER_DEALER_MPID --MPID
                 as REC
-- select gtc.*
   		from dwh.gtc_order_status gtc
   		    join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
        inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		---------------------------------------------------------------------------------------------------------
                   inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                   inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
		inner join dwh.d_ORDER_TYPE OT on (CL.ORDER_TYPE_id = OT.ORDER_TYPE_ID)
		inner join dwh.mv_ACTIVE_ACCOUNT_SNAPSHOT AC on (CL.ACCOUNT_ID = AC.ACCOUNT_ID )

   		left join lateral
            (
              select
                sum(case when exc.exec_type = 'F' then exc.last_qty else 0 end) as cum_qty
              from dwh.execution exc
              where exc.exec_date_id >= gtc.create_date_id
                and exc.order_id = gtc.order_id
                and exc.is_busted = 'N'
              group by exc.order_id
              limit 1
            ) ex on true


		where true
		and AC.TRADING_FIRM_ID in ('OFP0016')
	    --and trunc(CL.CREATE_TIME) = trunc(sysdate-1)
		and CL.PARENT_ORDER_ID is NULL
		and CL.TRANS_TYPE <> 'F'
        and coalesce(gtc.LAST_TRADE_DATE, '2023-12-12'::date + '1 day'::interval) > '2023-12-12'::date
        and CL.TIME_IN_FORCE_id = '1'
        and CL.MULTILEG_REPORTING_TYPE <> '3'
        and not exists (select null from dwh.EXECUTION exc where exc.order_id = gtc.order_id and exc.exec_date_id >= gtc.create_date_id and exc.ORDER_STATUS in ('2','4','8'))
		and gtc.close_date_id is null
except
*/
create function dash360.report_rps_ofp0016_gtc()
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_account_ids int4[];
    l_date        date := current_date;
    l_row_cnt     int4;
    l_load_id     int4;
    l_step_id     int4;
begin


    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_rps_ofp0016_gtc for ' || l_date::text || ' STARTED===',
                           0, 'O')
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
      and gtc.account_id = any (l_account_ids)
      and cl.parent_order_id is null
      and cl.trans_type <> 'f'
      and coalesce(gtc.last_trade_date, l_date + '1 day'::interval) > l_date
      and gtc.time_in_force_id = '1'
      and cl.multileg_reporting_type <> '3'
      and gtc.close_date_id is null
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

$fx$;

select * from dash360.report_rps_ofp0016_gtc()