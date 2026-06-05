-- DROP FUNCTION dash360.report_rps_s3(int4, int4, _int4, bpchar, _varchar, bool, bool);

CREATE OR REPLACE FUNCTION dash360.report_rps_s3(in_start_date_id integer, in_end_date_id integer, in_account_ids integer[] DEFAULT '{}'::integer[], in_is_multi_leg character DEFAULT 'N'::bpchar, in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], in_exclude_blaze boolean DEFAULT true, in_actual_exchange boolean DEFAULT false)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 2024-04-23 SO: https://dashfinancial.atlassian.net/browse/DS-8251 added in_trading_firm_ids as an input parameter
    -- SO 20240523 https://dashfinancial.atlassian.net/browse/DEVREQ-4264 add coalesce to account\trading firm input parameters
    -- SO 20250219 https://dashfinancial.atlassian.net/browse/DS-9608 Performance improvement
    -- SO 20260108 https://dashfinancial.atlassian.net/browse/DEVREQ-7409 Add a new parameter: Exclude S3 EOD Blaze Orders (as well as BLAZE as exchange_id)
    -- SO 20260601 https://dashfinancial.atlassian.net/browse/DS-11581
declare
    l_is_multileg     boolean := case when in_is_multi_leg = 'N' then false else true end;
    l_account_ids     int4[];
    l_load_id         int;
    l_row_cnt         int;
    l_step_id         int;
    l_msg             text;
    l_is_current_date bool    := false;
    l_min_gtc_date_id int4;
begin
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;
    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;
    l_msg := 'report_rps_s3 for ' || in_start_date_id::text || ' - ' || in_end_date_id::text ||
             case when l_is_multileg then '. multilegs' else '. single' end || '. accounts - ' ||
             substr(l_account_ids::text, 1, 50);

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || ' STARTED ===', 0, 'O')
    into l_step_id;

    select --coalesce(min(create_date_id), to_char(current_date, 'YYYYMMDD')::int4)
    to_char(current_date - interval '1 year', 'YYYYMMDD')::int4
    into l_min_gtc_date_id
    from dwh.gtc_order_status gtc
    where case when l_account_ids = '{}' then true else account_id = any (l_account_ids) end;

    raise notice 'l_min_gtc_date_id - %', l_min_gtc_date_id;
    -- header
    drop table if exists t_report;
    create temp table t_report
--          on commit drop
    as
    select 'H'                                                                                        as record_type,
           0::int8                                                                                    as order_id,
           null                                                                                       as time_id,
           'A'                                                                                        as record_id,
           0                                                                                          as record_type_id,
           'H' || '|' ||
           'V2.0.4' || '|' ||
           to_char(clock_timestamp(), 'YYYYMMDD') || 'T' || to_char(clock_timestamp(), 'HH24MISSFF3') as rec;

    raise notice 'temp table created - %', clock_timestamp();
    select count(*)
    into l_row_cnt
    from t_report;
    raise notice 't_report has - %', l_row_cnt;
    ----Parent/Street orders----
    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
    select 'NO'                                      as record_type,
           coalesce(cl.parent_order_id, cl.order_id) as order_id,
           to_char(cl.process_time, 'HH24MISSFF3')   as time_id,
           cl.client_order_id                        as record_id,
           1                                         as record_type_id,

           array_to_string(ARRAY [
                               'O', --
                               case
                                   when ((l_is_multileg and cl.multileg_reporting_type = '3') or
                                         (not l_is_multileg and cl.parent_order_id is null)) then 'NO'
                                   else 'RO'
                                   end, --
                               cl.client_order_id, --
                               cl.order_id::text, --  --source_order_id
                               case
                                   when l_is_multileg and cl.multileg_reporting_type = '2' then cl.client_order_id::text
                                   when not l_is_multileg then coalesce(cl.parent_order_id::text, '')
                                   end, --  --source_parent_id
                               cl.orig_order_id::text, --
               --
                               case
                                   when not l_is_multileg
                                       then ''
                                   else
                                       case
                                           when cl.multileg_reporting_type = '3' then cl.order_id::text
                                           when cl.multileg_reporting_type = '2' then cl.multileg_order_id::text
                                           end
                                   end, --  --
                               case
                                   when not l_is_multileg then ac.broker_dealer_mpid
                                   else
                                       case
                                           when cl.parent_order_id is null and ac.broker_dealer_mpid = 'NONE' then ''
                                           when cl.parent_order_id is null then ac.broker_dealer_mpid
                                           else 'DFIN'
                                           end
                                   end, --
                               case
--                when not l_is_multileg then coalesce(exc.mic_code, 'DFIN')
                                   when not l_is_multileg and in_actual_exchange then exc.mic_code
                                   when not l_is_multileg and not in_actual_exchange then 'DFIN'
                                   else
                                       case
                                           when cl.parent_order_id is null then 'DFIN'
                                           else coalesce(exc.mic_code, exc.eq_mpid) end
                                   end, --
                               null,
                               null,
                               case cl.multileg_reporting_type when '3' then '' else i.instrument_type_id end, --
                               case i.instrument_type_id
                                   when 'E' then i.display_instrument_id
                                   when 'O' then oc.opra_symbol end,
                               null, --primary Exchange
                               case cl.side
                                   when '1' then 'B'
                                   when '2' then 'S'
                                   when '5' then 'SS'
                                   when '6' then 'SSE' end, --OrderAction
                               to_char(cl.process_time, 'YYYYMMDD') || 'T' ||
                               to_char(cl.process_time, 'HH24MISSFF3'), --
                               ot.order_type_short_name, --  --order_type
                               case
                                   when not l_is_multileg then cl.order_qty::text
                                   else
                                       case when cl.multileg_reporting_type = '3' then '' else cl.order_qty::text end
                                   end, --  --order_volume
                               to_char(cl.price, 'FM99990D0099'), --
                               to_char(cl.stop_price, 'FM99990D0099'), --
                               tif.tif_short_name, --
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
                                           end
                                   end, --  --22
                               '0', --  --PRE_MARKET_IND
                               null,
                               '0', --  --POST_MARKET_IND
                               null,
                               case
                                   when cl.parent_order_id is null
                                       then case cl.sub_strategy_desc when 'DMA' then '1' else '0' end
                                   else case po.sub_strategy_desc when 'DMA' then '1' else '0' end
                                   end, --  --DIRECTED_ORDER_IND
                               case
                                   when (cl.parent_order_id is null or l_is_multileg)
                                       then case cl.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                                   else case po.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                                   end, --  --NON_DISPLAY_IND
                               '0', --  --DO_NOT_REDUCE
                               case cl.exec_instruction when 'G' then '1' else '0' end, --
                               case cl.exec_instruction when '1' then '1' else '0' end, --  --NOT_HELD_IND [31]
                               '0', --  --[32]
                               '0', --  --[33]
                               '0', --  --[34]
                               null, --[35]
                               null, --[36]
                               null, --[37]
                               null, --[38]
                               case
                                   when l_is_multileg then cl.ex_destination
                                   end, --  --[39]
                               case
                                   when (l_is_multileg and cl.multileg_reporting_type = '3') then cl.no_legs::text
                                   end, --  --[40]
                               null, --[41]
                               null, --[42]
                               null, --[43]
                               null, --[44]
                               null, --[45]
                               null, --[46]
                               null, --[47]
                               null --[48]
                               ], '|', '')           as REC
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
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
    where true
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id between in_start_date_id and in_end_date_id
      and cl.trans_type <> 'F'
      and case when l_is_multileg then cl.parent_order_id is null else true end
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
              else cl.multileg_reporting_type = '1' end
      and case when in_exclude_blaze then coalesce(cl.ex_destination, '') not ilike 'blaze' else true end
      and case when in_exclude_blaze then coalesce(cl.exchange_id, '') not ilike 'blaze' else true end;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg || ' Parent/Street added', l_row_cnt, 'O')
    into l_step_id;

    select count(*)
    into l_row_cnt
    from t_report;
    raise notice 't_report has - %', l_row_cnt;


    drop table if exists t_orders;
    create temp table t_orders
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
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F'
      and case when in_exclude_blaze then coalesce(cl.ex_destination, '') not ilike 'blaze' else true end
      and case when in_exclude_blaze then coalesce(cl.exchange_id, '') not ilike 'blaze' else true end
      and cl.time_in_force_id not in ('1', '6');

    get diagnostics l_row_cnt = row_count;
    analyze t_orders;

    select public.load_log(l_load_id, l_step_id, l_msg || ' daily added', l_row_cnt, 'O')
    into l_step_id;

--    insert into t_orders (create_date_id, parent_order_id, order_id, process_time, client_order_id, instrument_id, account_id, trans_type, multileg_reporting_type)
    drop table if exists t_orders_gtc;
    create temp table t_orders_gtc
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
             join dwh.gtc_order_status gtc using (order_id, create_date_id)
    where true
      and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end
      and cl.create_date_id < in_start_date_id
      and case
              when gtc.close_date_id is null then true
              when gtc.close_date_id >= in_end_date_id then true
              else false end
      and cl.trans_type <> 'F'
      and case when in_exclude_blaze then coalesce(cl.ex_destination, '') not ilike 'blaze' else true end
      and case when in_exclude_blaze then coalesce(cl.exchange_id, '') not ilike 'blaze' else true end
      and create_date_id >= l_min_gtc_date_id
      and cl.time_in_force_id in ('1', '6');

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' open gtc added', l_row_cnt, 'O')
    into l_step_id;

    insert into t_orders
    select * from t_orders_gtc;

    create index on t_orders (create_date_id);
    create index on t_orders (order_id);

    select public.load_log(l_load_id, l_step_id, l_msg || ' indexed', 0, 'O')
    into l_step_id;

    drop table if exists t_base;
    create temp table t_base as
    select case when ex.exec_type in ('4', '8') then 2 else 3 end as tp,
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
        (select *
         from t_orders cl
         where cl.create_date_id <= ex.exec_date_id
           and cl.order_id = ex.order_id
         limit 1) cl on true
        and case
                when l_is_multileg then cl.parent_order_id is null
                else cl.parent_order_id is not null end
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
             left join lateral (select opra_symbol, option_series_id
                                from dwh.d_option_contract oc
                                where oc.instrument_id = i.instrument_id
                                limit 1) oc on true
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id
    where true
      and ex.exec_date_id between in_start_date_id and in_end_date_id
      and ex.exec_type in ('4', '8', 'F')
--                     and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F'
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
              else cl.multileg_reporting_type = '1' end;

    select public.load_log(l_load_id, l_step_id, l_msg || ' t_base created', 0, 'O')
    into l_step_id;

    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
    --order activity: cancel
    select 'A'                                  as record_type,
           coalesce(parent_order_id, order_id)  as order_id,
           to_char(process_time, 'HH24MISSFF3') as time_id,
           client_order_id                      as record_id,
           3                                    as record_type_id,
           array_to_string(ARRAY [
                               'A' , --
                               order_id::text , --
                               case exec_type when '4' then 'c' when '8' then 'RJ' end , -- --EVENT
                               null , -- --SYSTEM_ID
                               case multileg_reporting_type
                                   when '3' then ''
                                   else coalesce(instrument_type_id, '') end , --
                               case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol end,
                               null , -- --SYMBOL_EXCHANGE
                               coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
                               coalesce(to_char(exec_time, 'HH24MISSFF3'), '') , --
                               null , -- --DESCRIPTION
                               null , -- --[10]
                               null , -- --[11]
                               null , -- --[12]
                               null , -- --[13]
                               null --[14]
                               ], '|', '')
    from t_base
    where tp = 2
      and case when l_is_multileg then parent_order_id is null else true end;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' Cancels added', l_row_cnt, 'O')
    into l_step_id;

    insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)

    select 'T'                                 as record_type,
           coalesce(parent_order_id, order_id) as order_id,
           to_char(exec_time, 'HH24MISSFF3')   as time_id,
           client_order_id                     as record_id,
           2                                   as record_type_id,
           array_to_string(ARRAY [
                               'T' , --
                               order_id::text , --
                               order_id::text || '_' || exec_id::text , --
                               null , --
                               null , --
                               instrument_type_id , --
                               case instrument_type_id
                                   when 'E' then display_instrument_id
                                   when 'O' then opra_symbol
                                    end , --
                               null , -- --SYMBOL_EXCHANGE
                               coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
                               coalesce(to_char(exec_time, 'HH24MISSFF3'), '') , -- --ACTION_DATETIME
                               last_qty::text , --
                               to_char(last_px, 'FM99990d0099') , --
                               exchange_id , --
                               null , -- --[12]
                               null , -- --[13]
                               case when l_is_multileg and multileg_reporting_type = '2' then 'COMPLEX' end , -- --[14]
                               null , -- --[15]
                               null , -- --[16]
                               null , -- --[17]
                               null , -- --[18]
                               null , -- --[19]
                               null , -- --[20]
                               null , -- --[21]
                               null , -- --[22]
                               null --[23]
                               ], '|', '')
    from t_base
    where tp = 3
      and case
              when l_is_multileg then (multileg_reporting_type = '2' and parent_order_id is null)
              else multileg_reporting_type = '1' end;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' Trades added', l_row_cnt, 'O')
    into l_step_id;

    select count(*)
    into l_row_cnt
    from t_report;
    raise notice 't_report has - %', l_row_cnt;

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
                                                where true
                                                  and case
                                                          when l_account_ids = '{}' then true
                                                          else account_id = any (l_account_ids) end
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
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;
