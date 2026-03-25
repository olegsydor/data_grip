-- https://dashfinancial.atlassian.net/browse/DS-11295
-- DROP FUNCTION dash360.report_fintech_s3_master_file(int4, int4, _int4, bpchar, _varchar, bool);
create temp table tmp_os as
select * from dash360.report_fintech_s3_master_file(20260323, 20260323, in_account_ids := '{9374}');

1183
2928
6331
6670
7670
7671
8112
9234
9374
9880

CREATE or replace FUNCTION dash360.report_fintech_s3_master_file(in_start_date_id integer, in_end_date_id integer,
                                                                 in_account_ids int8[] DEFAULT '{}'::int8[],
                                                                 in_instrument_type character DEFAULT null,
                                                                 in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2024-04-23 SO: https://dashfinancial.atlassian.net/browse/DS-8251 added in_trading_firm_ids as an input parameter
    -- SO 20240523 https://dashfinancial.atlassian.net/browse/DEVREQ-4264 add coalesce to account\trading firm input parameters
    -- SO 20250219 https://dashfinancial.atlassian.net/browse/DS-9608 Performance improvement
    -- SO 20260108 https://dashfinancial.atlassian.net/browse/DEVREQ-7409 Add a new parameter: Exclude S3 EOD Blaze Orders (as well as BLAZE as exchange_id)
    -- SO 20260324 https://dashfinancial.atlassian.net/browse/DEVREQ-7857 Based on S3 report
declare

    l_account_ids int8[];
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_msg         text;
begin

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
                  when coalesce(in_account_ids, '{}') <> '{}'::int8[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;
    l_msg := 'report_fintech_s3_master_file for ' || in_start_date_id::text || '-' || in_end_date_id::text ||
             case in_instrument_type
                 when 'E' then '. Equities'
                 when 'O' then '. Options'
                 else '. All instrument types' end || '. accounts - ' || substr(l_account_ids::text, 1, 50);

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg || ' STARTED ===', 0, 'O')
    into l_step_id;

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
           -- REC --
           array_to_string(array [
                               'O', -- RECORD_TYPE
                               case
                                   when cl.multileg_reporting_type = '3' then 'NO'
                                   when cl.parent_order_id is null then 'NO'
                                   else 'RO'
                                   end , -- EVENT
                               cl.client_order_id, -- ORDER_ID
                               cl.order_id::text, --SOURCE_ORDER_ID
                               case
                                   when cl.multileg_reporting_type = '2' then cl.client_order_id
                                   else cl.parent_order_id::text end, -- SOURCE_PARENT_ID
                               cl.orig_order_id::text, -- SOURCE_PREDECESSOR_ID
                               null, -- SOURCE_COMPLEX_ID
                               case when ac.is_broker_dealer = 'Y' then ac.broker_dealer_mpid end, -- ORIG_FIRM
                               case
                                   when cl.multileg_reporting_type = '3' then ac.eq_mpid
                                   when cl.parent_order_id is null then ac.eq_mpid
                                   else coalesce(exc.mic_code, exc.eq_mpid, '')
                                   end , -- FIRM_MPID
                               fmj.tag_109, -- FIRM_TRADER_ID
                               ac.account_name, -- ORDER_ACCOUNT_ID
                               case
                                   when cl.multileg_reporting_type != '3' then di.instrument_type_id
                                   end, -- SECURITY_TYPE
                               case
                                   when di.instrument_type_id = 'E' then di.instrument_type_id
                                   when di.instrument_type_id = 'O' then oc.opra_symbol end, -- SYMBOL
                               null, -- SYMBOL_EXCHANGE
                               case cl.side
                                   when '1' then 'B'
                                   when '2' then 'S'
                                   when '5' then 'SS'
                                   when '6' then 'SSE' end, -- ORDER_ACTION
                               to_char(cl.process_time, 'YYYYMMDD') || 'T' ||
                               to_char(cl.process_time, 'HH24MISSFF3'), -- ORDER_DATETIME
                               ot.order_type_short_name, -- ORDER_TYPE
                               case when cl.multileg_reporting_type != '3' then cl.order_qty::text end, -- ORDER_VOLUME
                               to_char(cl.price, 'FM99990D0099'), -- LIMIT_PRICE
                               to_char(cl.stop_price, 'FM99990D0099'), -- STOP_PRICE
                               tif.tif_short_name, -- TIME_IN_FORCE
                               case
                                   when cl.time_in_force_id = '6' then concat_ws('T',
                                                                                 to_char(cl.expire_time, 'YYYYMMDD'),
                                                                                 to_char(cl.expire_time, 'HH24MISSFF3')) end, -- EXPIRATION_DATETIME
                               case when session_eligibility = 'G' then '1' else '0' end, -- PRE_MARKET_IND
                               null, -- PRE_MARKET_TIME
                               case when cl.time_in_force_id = '5' then '1' else '0' end, -- POST_MARKET_IND
                               null, -- POST_MARKET_TIME
                               '0', -- DIRECTED_ORDER_IND
                               null, --	NON_DISPLAY_IND -- ??
                               '0', --	DO_NOT_REDUCE_IND
                               case cl.exec_instruction when 'G' then '1' else '0' end, --	ALL_OR_NONE_IND
                               case
                                   when cl.exec_instruction = '1' then '1'
                                   when cl.is_held = 'Y' then '1'
                                   else '0' end, --	NOT_HELD_IND
                               '0', --	FILL_AT_OPEN_IND
                               '0', --	FILL_AT_CLOSE_IND
                               '0', --	MANUAL_IND
                               null, --	OPTION_STRIKE_PRICE
                               null, --	OPTIONS_UNDER_SYMBOL
                               null, --	OPTION_EXPIRATION_DATETIME
                               case
                                   when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
                                   when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
                                   end , --	OPTION_TYPE
                               tf.trading_firm_demo_mnemonic, --	CLIENT_TEXT1
                               sdr.wave_type_name, --	CLIENT_TEXT2
                               null, --	CLIENT_TEXT3
                               null, --	CLIENT_TEXT4
                               null, --	CLIENT_TEXT5
                               'US', --	TARGET_COUNTRY_CODE
                               'USD', --	CURRENCYCODE
                               tag_9000, --	ALGO
                               tag_9003, --	ORDER_START_TIME
                               tag_9004, --	ORDER_REQUIRED_TIME
                               null, --	CURRENCY_PAIR
                               null, --	EXCHANGE_RATE
                               null, --	HOUSEHOLD_ID
                               '0', --	FURTHER_ROUTABLE
                               null, --	CL_ORD_ID
                               case trading_firm_name when '2' then '1' when '1' then '0' end, --	IS_BD

                               null, --	CAT_NEW_ORDER_IND
                               null, --	CAT_FDID
                               null, --	CAT_ACCOUNT_TYPE
                               null, --	CAT_SENDER_IMID
                               null, --	CAT_RECEIVIER_IMID
                               null, --	CAT_DESTINATION
                               null, --	CAT_DESTINATION_TYPE
                               null, --	CAT_SESSION
                               null, --	CAT_ORDER_ID
                               null, --	CAT_ROUTED_ORDER_ID
                               null, --	CAT_EXCHANGE_ORIGIN_CODE
                               null, --	CAT_REJECTED_IND
                               null, --	CAT_PREDESSOR_ORDER_DATE
                               null, --	CAT_PREDESSOR_ORDER_ID
                               null, --	CAT_PREDESSOR_ROUTE_ORDER_ID
                               null, --	CAT_ATS_SEQ_NUM
                               null, --	CAT_ATS_DISPLAY_IND
                               null, --	CAT_ATS_DISPLAY_PRICE
                               null, --	CAT_ATS_WORKING_PRICE
                               null, --	CAT_ATS_DISPLAY_QUANTITY
                               null, --	CAT_ATS_ORDER_TYPE
                               null, --	CAT_ATS_NBB_PRICE
                               null, --	CAT_ATS_NBB_QUANTITY
                               null, --	CAT_ATS_NBO_PRICE
                               null, --	CAT_ATS_NBO_QUANTITY
                               null, --	CAT_ATS_NBBO_SOURCE
                               null, --	CAT_ATS_NBBO_TIMESTAMP
                               null, --	CAT_CHILD_IND
                               null --	CAT_MODIFY_REQ_DATETIME
                               ], ',', '')           as REC
    from dwh.client_order cl
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             inner join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join lateral (select po.sub_strategy_desc
                                from dwh.client_order po
                                where po.order_id = cl.parent_order_id
                                  and po.create_date_id <= cl.create_date_id
                                limit 1) po on true
             left join dwh.d_option_contract oc on oc.instrument_id = di.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
             left join lateral (select fmj.fix_message ->> '109'  as tag_109,
                                       fmj.fix_message ->> '9000' as tag_9000,
                                       fmj.fix_message ->> '9003' as tag_9003,
                                       fmj.fix_message ->> '9004' as tag_9004
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.fix_message_id
                                  and fmj.date_id between in_start_date_id and in_end_date_id
                                limit 1) fmj on true
             left join dwh.d_strategy_decision_reason_code sdr
                       on sdr.strategy_decision_reason_code = cl.strtg_decision_reason_code
    where true
      and case when l_account_ids = '{}'::int8[] then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id between in_start_date_id and in_end_date_id
      and cl.trans_type <> 'F';

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
      and cl.trans_type <> 'F';

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg || ' daily added', l_row_cnt, 'O')
    into l_step_id;

    insert into t_orders
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
      and gtc.close_date_id is null
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F'
    --       and case when in_exclude_blaze then coalesce(cl.ex_destination, '') not ilike 'blaze' else true end
--       and case when in_exclude_blaze then coalesce(cl.exchange_id, '') not ilike 'blaze' else true end
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' open gtc added', l_row_cnt, 'O')
    into l_step_id;

    insert into t_orders
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
      and gtc.close_date_id is not null
      and gtc.close_date_id > in_end_date_id
      and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.trans_type <> 'F';

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' close today gtc added', l_row_cnt, 'O')
    into l_step_id;

    create index on t_orders (create_date_id);
    create index on t_orders (order_id);

    select public.load_log(l_load_id, l_step_id, l_msg || ' indexed', 0, 'O')
    into l_step_id;

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
                      (select *
                       from t_orders cl
                       where cl.create_date_id <= ex.exec_date_id
                         and cl.order_id = ex.order_id
                       limit 1) cl on true
                      --                       and case
--                               when l_is_multileg then cl.parent_order_id is null
--                               else cl.parent_order_id is not null end
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
--                     and case
--                             when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
--                             else cl.multileg_reporting_type = '1' end
    )
    --order activity: cancel
    select 'A'                                  as record_type,
           coalesce(parent_order_id, order_id)  as order_id,
           to_char(process_time, 'HH24MISSFF3') as time_id,
           client_order_id                      as record_id,
           3                                    as record_type_id,
           array_to_string(array [
                               'A',
                               order_id::text,
                               case exec_type when '4' then 'c' when '8' then 'RJ' else '' end, --EVENT
                               null, --SYSTEM_ID
                               case multileg_reporting_type when '3' then null else instrument_type_id end,
                               case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol end,
                               null, --SYMBOL_EXCHANGE
                               concat_ws('T', to_char(exec_time, 'YYYYMMDD'), to_char(exec_time, 'HH24MISSFF3')),
                               null, --DESCRIPTION
                               null, --[10]
                               null, --[11]
                               null, --[12]
                               null, --[13]
                               null --[14]
                               ], ',', '')
    from base
    where tp = 2
--       and case when l_is_multileg then parent_order_id is null else true end

    union all

    select 'T'                                 as record_type,
           coalesce(parent_order_id, order_id) as order_id,
           to_char(exec_time, 'HH24MISSFF3')   as time_id,
           client_order_id                     as record_id,
           2                                   as record_type_id,
           array_to_string(array [
                               'T',
                               order_id::text,
                               order_id::text || '_' || exec_id::text,
                               null,
                               null,
                               instrument_type_id,
                               case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol end,
                               null , --SYMBOL_EXCHANGE
                               concat_ws('T', to_char(exec_time, 'YYYYMMDD'), to_char(exec_time, 'HH24MISSFF3')),--ACTION_DATETIME
                               last_qty::text,
                               to_char(last_px, 'fm99990d0099'),
                               exchange_id,
                               null, --[12]
                               null, --[13]
                               case when multileg_reporting_type = '2' then 'COMPLEX' end, --[14]
                               null , --[15]
                               null , --[16]
                               null , --[17]
                               null , --[18]
                               null , --[19]
                               null , --[20]
                               null , --[21]
                               null , --[22]
                               null --[23]
                               ], ',', '')
    from base
    where tp = 3
    --       and case
--               when l_is_multileg then (multileg_reporting_type = '2' and parent_order_id is null)
--               else multileg_reporting_type = '1' end
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, l_msg || ' Cancels added', l_row_cnt, 'O')
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

end;
$function$
;

select distinct cl.account_id
from dwh.client_order cl
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             inner join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join lateral (select po.sub_strategy_desc
                                from dwh.client_order po
                                where po.order_id = cl.parent_order_id
                                  and po.create_date_id <= cl.create_date_id
                                limit 1) po on true
             left join dwh.d_option_contract oc on oc.instrument_id = di.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
             left join lateral (select fmj.fix_message ->> '109'  as tag_109,
                                       fmj.fix_message ->> '9000' as tag_9000,
                                       fmj.fix_message ->> '9003' as tag_9003,
                                       fmj.fix_message ->> '9004' as tag_9004
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.fix_message_id
                                  and fmj.date_id between :in_start_date_id and :in_end_date_id
                                limit 1) fmj on true
             left join dwh.d_strategy_decision_reason_code sdr
                       on sdr.strategy_decision_reason_code = cl.strtg_decision_reason_code
    where true
--       and case when l_account_ids = '{}'::int8[] then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id between :in_start_date_id and :in_end_date_id
      and cl.trans_type <> 'F'
limit 10;