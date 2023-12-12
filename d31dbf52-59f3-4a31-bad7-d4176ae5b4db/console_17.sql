select ret_row
from dash360.report_rps_s3(
        in_start_date_id := 20231117,
        in_end_date_id := 20231117,
        in_account_ids := array [68590,28411,23421,63904,64929],
        in_is_multi_leg := 'N'
     );

select ret_row
from dash360.report_rps_s3(
        in_start_date_id := 20231117,
        in_end_date_id := 20231117,
        in_account_ids := array [25711,28515,30650],
        in_is_multi_leg := 'N'
     );



insert into so_delete_tutge (ret_row, knd)
select ret_row, 'new' as knd
from trash.report_rps_s3(in_start_date_id := 20231025, in_end_date_id := 20231025, in_account_ids := '{54855}', in_is_multi_leg := 'Y');

select ret_row from so_delete_tutge
where knd = 'new'
except
select ret_row from so_delete_tutge
where knd = 'old'

select * from dwh.d_account
         join dwh.d_trading_firm using (trading_firm_id)
where trading_firm_id = 'OFP - Etrade'

select * from dwh.d_account
where account_name ilike '%Etrade%'

-- DROP FUNCTION dash360.report_rps_s3(int4, int4, _int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.report_rps_s3(in_start_date_id integer, in_end_date_id integer, in_account_ids integer[], in_is_multi_leg character DEFAULT 'N'::bpchar)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
declare
    l_is_multileg boolean := case when in_is_multi_leg = 'N' then false else true end;
begin
    -- header
    create temp table t_report on commit drop as
    select 'H'                                                                                        as record_type,
           0::int8                                                                                    as order_id,
           null                                                                                       as time_id,
           'A'                                                                                        as record_id,
           0                                                                                          as record_type_id,
           'H' || '|' ||
           'V2.0.4' || '|' ||
           to_char(clock_timestamp(), 'YYYYMMDD') || 'T' || to_char(clock_timestamp(), 'HH24MISSFF3') as rec;

    raise notice 'temp table created - %', clock_timestamp();
      ----Parent/Street orders----
      insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
      select 'NO'                                      as record_type,
             coalesce(cl.parent_order_id, cl.order_id) as order_id,
             to_char(cl.process_time, 'HH24MISSFF3')   as time_id,
             cl.client_order_id                        as record_id,
             1                                         as record_type_id,
             'O' || '|' ||
             case
                 when ((l_is_multileg and cl.multileg_reporting_type = '3') or
                    (not l_is_multileg and cl.parent_order_id is null)) then 'NO'
                 else 'RO'
                 end || '|' ||
             cl.client_order_id || '|' ||
             cl.order_id::text || '|' || --source_order_id
             case when l_is_multileg and cl.multileg_reporting_type = '2' then cl.client_order_id::text
             when not l_is_multileg then coalesce(cl.parent_order_id::text, '')
             else ''
             end|| '|' || --source_parent_id
             coalesce(cl.orig_order_id::text, '') || '|' ||
                 --
             case
                 when not l_is_multileg
                     then ''
                 else
                     case
                         when cl.multileg_reporting_type = '3' then cl.order_id::text
                         when cl.multileg_reporting_type = '2' then cl.multileg_order_id::text
                         end
                 end || '|' || --
             case
                 when not l_is_multileg then ac.broker_dealer_mpid
                 else
                     case
                         when cl.parent_order_id is null and ac.broker_dealer_mpid = 'NONE' then ''
                         when cl.parent_order_id is null then ac.broker_dealer_mpid
                         else 'DFIN'
                         end
                 end || '|' ||
             case
                 when not l_is_multileg then 'DFIN'
                 else
                     case
                         when cl.parent_order_id is null then 'DFIN'
                         else coalesce(exc.mic_code, exc.eq_mpid, '') end
                 end
                 ||'|'||
             '' || '|' ||
             '' || '|' ||
             case cl.multileg_reporting_type when '3' then '' else i.instrument_type_id end || '|' ||
             case i.instrument_type_id when 'E' then i.display_instrument_id when 'O' then oc.opra_symbol else '' end ||
             '|' ||
             '' || '|' || --primary Exchange
             case cl.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SSE' else '' end ||
             '|' || --OrderAction
             to_char(cl.process_time, 'YYYYMMDD') || 'T' || to_char(cl.process_time, 'HH24MISSFF3') || '|' ||
             ot.order_type_short_name || '|' || --order_type
             case
                 when not l_is_multileg then cl.order_qty::text
                 else
                     case when cl.multileg_reporting_type = '3' then '' else cl.order_qty::text end
                 end || '|' || --order_volume
             to_char(cl.price, 'FM99990D0099') || '|' ||
             coalesce(to_char(cl.stop_price, 'FM99990D0099'), '') || '|' ||
             tif.tif_short_name || '|' ||
             case
                 when not l_is_multileg then
                                 coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                 coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                 else
                     case
                         when cl.expire_time is not null then
                                 coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                 coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                         when cl.time_in_force_id = '6' then
                             (select coalesce(fmj.fix_message ->> '432', '') || 'T235959000'
                              from fix_capture.fix_message_json fmj
                              where fix_message_id = cl.fix_message_id
                                and fmj.date_id = cl.create_date_id
                              limit 1)
                         else ''
                         end
                 end || '|' || --22
             '0' || '|' || --PRE_MARKET_IND
             '' || '|' ||
             '0' || '|' || --POST_MARKET_IND
             '' || '|' ||
             case
                 when cl.parent_order_id is null then case cl.sub_strategy_desc when 'DMA' then '1' else '0' end
                 else case po.sub_strategy_desc when 'DMA' then '1' else '0' end
                 end || '|' || --DIRECTED_ORDER_IND
             case
                 when (cl.parent_order_id is null or l_is_multileg)
                     then case cl.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                 else case po.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                 end || '|' || --NON_DISPLAY_IND
             '0' || '|' || --DO_NOT_REDUCE
             case cl.exec_instruction when 'G' then '1' else '0' end || '|' ||
             case cl.exec_instruction when '1' then '1' else '0' end || '|' || --NOT_HELD_IND [31]
             '0' || '|' || --[32]
             '0' || '|' || --[33]
             '0' || '|' || --[34]
             '' || '|' || --[35]
             '' || '|' || --[36]
             '' || '|' || --[37]
             '' || '|' || --[38]
             case
                 when l_is_multileg then coalesce(cl.ex_destination, '')
                 else '' end || '|' || --[39]
             case
                 when (l_is_multileg and cl.multileg_reporting_type = '3') then coalesce(cl.no_legs::text, '')
                 else '' end || '|' || --[40]
             '' || '|' || --[41]
             '' || '|' || --[42]
             '' || '|' || --[43]
             '' || '|' || --[44]
             '' || '|' || --[45]
             '' || '|' || --[46]
             '' || '|' || --[47]
             '' --[48]
                      as REC
      from dwh.client_order cl
               inner join dwh.d_account ac on ac.account_id = cl.account_id
               inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
               left join lateral (select po.sub_strategy_desc
                                  from dwh.client_order po
                                  where po.order_id = cl.parent_order_id
                                    and po.create_date_id <= cl.create_date_id
                                  limit 1) po on true
               left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
               left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
               left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
               left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
      left join lateral (select * from dwh.d_exchange exc where exc.exchange_id = cl.exchange_id and exc.is_active limit 1) exc on true
      where true
        and cl.account_id = any (in_account_ids)
        and cl.create_date_id between in_start_date_id and in_end_date_id
        and cl.trans_type <> 'F'
        and case when l_is_multileg then cl.parent_order_id is null else true end
        and case
                when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
                else cl.multileg_reporting_type = '1' end;

raise notice 'Parent/Street added - %', clock_timestamp();

    create temp table t_orders
        on commit drop
    as
    select cl.create_date_id,
           cl.parent_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           cl.instrument_id,
           cl.account_id,
           cl.trans_type,
           cl.multileg_reporting_type
    from dwh.client_order cl
    where true
      and cl.create_date_id between in_start_date_id and in_end_date_id
--                           and cl.order_id = ex.order_id
      and cl.account_id = any (in_account_ids)
      and cl.account_id = any (in_account_ids)
      and cl.trans_type <> 'F'
    union all
    select cl.create_date_id,
           cl.parent_order_id,
           cl.order_id,
           cl.process_time,
           cl.client_order_id,
           cl.instrument_id,
           cl.account_id,
           cl.trans_type,
           cl.multileg_reporting_type
    from dwh.client_order cl
             join dwh.gtc_order_status gtc using (order_id, create_date_id)
    where gtc.account_id = any (in_account_ids)
      and cl.create_date_id < in_start_date_id
      and coalesce(gtc.close_date_id, 23000101) > in_end_date_id
      and cl.account_id = any (in_account_ids)
      and cl.trans_type <> 'F'
--                                  and ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id
    ;
    create index on t_orders (create_date_id);
    create index on t_orders (order_id);

      insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
      with base as (select case when ex.exec_type in ('4', '8') then 2 else 3 end as tp,
                           cl.parent_order_id,
                           cl.order_id,
                           cl.process_time,
                           cl.client_order_id,
                           ex.exec_type,
                           cl.multileg_reporting_type,
                           i.instrument_type_id,
                           i.display_instrument_id,
                           oc.opra_symbol,
                           ex.exec_time,
                           ex.exec_id,
                           ex.last_qty,
                           ex.last_px,
                           ex.exchange_id
                    from dwh.execution ex
                             join lateral
                         (select * from t_orders cl
                          where cl.create_date_id <= ex.exec_date_id
                          and cl.order_id = ex.order_id
                                 limit 1) cl                                  on true
                        and case when l_is_multileg then cl.parent_order_id is null else cl.parent_order_id is not null end
                             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                             left join lateral (select opra_symbol, option_series_id from dwh.d_option_contract oc where oc.instrument_id = i.instrument_id limit 1) oc on true
                             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id
                    where true
                      and ex.exec_date_id between in_start_date_id and in_end_date_id
                      and ex.exec_type in ('4', '8', 'F')
                      and cl.account_id = any (in_account_ids)
                      and cl.trans_type <> 'F'
                      and case
                              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
                              else cl.multileg_reporting_type = '1' end
          )
      --order activity: cancel
            select 'A'                                  as record_type,
                   coalesce(parent_order_id, order_id)  as order_id,
                   to_char(process_time, 'HH24MISSFF3') as time_id,
                   client_order_id                      as record_id,
                   3                                    as record_type_id,
                   'A' || '|' ||
                   order_id::text || '|' ||
                   case exec_type when '4' then 'c' when '8' then 'RJ' else '' end || '|' || --EVENT
                   '' || '|' || --SYSTEM_ID
                   case multileg_reporting_type when '3' then '' else coalesce(instrument_type_id, '') end || '|' ||
                   case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol else '' end ||
                   '|' ||
                   '' || '|' || --SYMBOL_EXCHANGE
                   coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
                   coalesce(to_char(exec_time, 'HH24MISSFF3'), '') || '|' ||
                   '' || '|' || --DESCRIPTION
                   '' || '|' || --[10]
                   '' || '|' || --[11]
                   '' || '|' || --[12]
                   '' || '|' || --[13]
                   '' --[14]
            from base
            where tp = 2
            and case when l_is_multileg then parent_order_id is null else true end

            union all

      select 'T'                                 as record_type,
             coalesce(parent_order_id, order_id) as order_id,
             to_char(exec_time, 'HH24MISSFF3')   as time_id,
             client_order_id                     as record_id,
             2                                   as record_type_id,
             'T' || '|' ||
             order_id::text || '|' ||
             order_id::text || '_' || exec_id::text || '|' ||
             '' || '|' ||
             '' || '|' ||
             instrument_type_id || '|' ||
             case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol else '' end ||
             '|' ||
             '' || '|' || --SYMBOL_EXCHANGE
             coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
             coalesce(to_char(exec_time, 'HH24MISSFF3'), '') || '|' || --ACTION_DATETIME
             last_qty || '|' ||
             to_char(last_px, 'fm99990d0099') || '|' ||
             exchange_id || '|' ||
             '' || '|' || --[12]
             '' || '|' || --[13]
             case when l_is_multileg and multileg_reporting_type = '2' then 'COMPLEX' else '' end || '|' || --[14]
             '' || '|' || --[15]
             '' || '|' || --[16]
             '' || '|' || --[17]
             '' || '|' || --[18]
             '' || '|' || --[19]
             '' || '|' || --[20]
             '' || '|' || --[21]
             '' || '|' || --[22]
             '' --[23]
      from base
      where tp = 3
        and case
                when l_is_multileg then (multileg_reporting_type = '2' and parent_order_id is null)
                else multileg_reporting_type = '1' end;
raise notice 'Cancels added - %', clock_timestamp();
    return query
        select case
                   when record_type = 'H' then rec || '|' ||
                                               in_start_date_id::text || 'T' || min_time || '|' || --Starting Event
                                               in_end_date_id::text || 'T' || max_time || '|' || --Ending Event
                                               'DFIN' || '|' ||
--                                                'DAIN' || '|' ||
                                               (select coalesce(cat_imid, '')
                                                from dwh.d_account
                                                         join dwh.d_trading_firm using (trading_firm_id)
                                                where account_id = any (in_account_ids)
                                                  and cat_imid is not null
                                                limit 1) || '|' ||
                                               'dashtradedesk@iongroup.com' || '|' ||
                                               ''
                   else rec
                   end
        from (select min(time_id) over () as min_time,
                     max(time_id) over () as max_time,
                     record_type,
                     rec
              from t_report

              order by order_id, time_id, record_id, record_type_id) x;

end;
$function$
;
select cat_imid from dwh.d_account
         join dwh.d_trading_firm using (trading_firm_id)

create temp table t_os_etrade as
select ret_row
from dash360.report_rps_s3(
        in_start_date_id := 20231201,
        in_end_date_id := 20231201,
        in_account_ids := array [28411,23421,68590,63904,64929],
        in_is_multi_leg := 'N'
     );





select book_record_type_id, sum(amount)
from (
     ) x
where rn = 1
group by book_record_type_id