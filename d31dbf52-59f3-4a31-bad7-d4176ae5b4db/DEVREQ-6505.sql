--https://dashfinancial.atlassian.net/browse/DEVREQ-6505
-- DROP FUNCTION dash360.report_obo_compliance_xls_2(int4, int4, bpchar, _int4, _int8, _varchar);

CREATE or replace FUNCTION dash360.report_obo_compliance_xls_2(in_date_begin_id integer, in_date_end_id integer,
                                                               in_instrument_type character DEFAULT NULL::bpchar,
                                                               in_account_ids integer[] DEFAULT '{}'::integer[],
                                                               in_parent_order_ids bigint[] DEFAULT '{}'::bigint[],
                                                               in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                "OrderID"                   bigint,
                "Trading Firm Name"         character varying,
                "Trading Firm IMID"         character varying,
                "Trading Firm CRD"          character varying,
                "Event Type"                character varying,
                "Event Date"                text,
                "Event Time"                text,
                "Client clOrderID"          character varying,
                "Street clOrderID"          text,
                "Event Qty"                 integer,
                "Event Price"               numeric,
                "Net Price"                 numeric,
                "Multi Leg Indicator"       text,
                "Number of legs"            integer,
                "Leg Order ID"              character varying,
                "Manual Flag"               text,
                "Free Text"                 character varying,
                "Order Status"              character varying,
                "Original Client clOrderID" character varying,
                "Original Street clOrderID" character varying,
                "OSI Symbol"                character varying,
                "Base symbol"               character varying,
                "Symbol"                    character varying,
                "Security Type"             character,
                "Underlying Symbol"         character varying,
                "P/C/S"                     text,
                "Expiration Date"           text,
                "Expiration Time"           text,
                "Side"                      text,
                "TIF"                       character varying,
                "Good Till Date"            text,
                "Good Till Time"            text,
                "Order Qty"                 integer,
                "Filled Qty"                bigint,
                "Order Type Code"           character varying,
                "Order Price"               numeric,
                "Order Creation Date"       text,
                "Order Creation Time"       text,
                "Open/Close"                character,
                "Trading Session"           character varying,
                "Is Held"                   text,
                "Is Cross"                  text,
                "Fee Sensitivity"           smallint,
                "Stop Price"                numeric,
                "Max Floor"                 bigint,
                "Capacity"                  character varying,
                "ExDestination"             character varying,
                "Leg ratio"                 bigint,
                "User"                      text,
                "Account Name"              character varying,
                "Account ID"                integer,
                "Account Holder Type"       character varying,
                "Account FDID"              character varying,
                "Account IMID"              text,
                "Account CRD"               character varying,
                "Sender type"               character varying,
                "Last Mkt"                  character varying,
                "MIC Code"                  character varying,
                "Liquidity Indicator"       character varying,
                "ExecutionID"               text,
                "CAT Reporting Firm IMID"   character varying,
                "Request Date"              text,
                "Request Time"              text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2025-07-04
-- SY: 20250820 https://dashfinancial.atlassian.net/browse/DS-10355 l_retention_date_id field calculation moved from client_order table to gtc_order_status.
declare
    l_load_id           int;
    l_row_cnt           int;
    l_step_id           int;
    l_date_begin_id     int4;
    l_date_end_id       int4;
    l_account_ids       int4[];
    l_retention_date_id int4;
    l_row_count         int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    l_date_begin_id := coalesce(in_date_begin_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_date_end_id := coalesce(in_date_end_id, to_char(current_date, 'YYYYMMDD')::int4);

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;

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

    select public.load_log(l_load_id, l_step_id, 'l_account_id size is ', cardinality(l_account_ids), 'O')
    into l_step_id;

    --    select min(cl.create_date_id)
--    into l_retention_date_id
--    from dwh.client_order cl
--             join dwh.gtc_order_status gtc on gtc.order_id = cl.order_id and gtc.create_date_id = cl.create_date_id
--    where true
--      and (gtc.close_date_id is null
--        or gtc.close_date_id >= l_date_end_id)
--      and case
--              when coalesce(l_account_ids, '{}') = '{}' then true
--              else cl.account_id = any (l_account_ids) end;


    select coalesce(min(gtc.create_date_id), l_date_begin_id)
    into l_retention_date_id
    from dwh.gtc_order_status gtc
    where true
      and (gtc.close_date_id is null
        or gtc.close_date_id >= l_date_end_id)
      and case
              when coalesce(l_account_ids, '{}') = '{}' then true
              else gtc.account_id = any (l_account_ids) end;


--    l_retention_date_id := 20230101;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' retention_date - ' || l_retention_date_id::text, 0, 'O')
    into l_step_id;
    drop table if exists t_base;
    create temp table t_base as
    select coalesce(staging.last_orig_order(cl.order_id), cl.order_id)                          as first_order_id,
           orig.client_order_id                                                                 as orig_client_order_id,
           cl.client_order_id,
           cl.co_client_leg_ref_id                                                              as leg_cl_ord_id,
           cl.trans_type,
           cl.order_id,
           cl.fix_message_id,
           cl.create_date_id,
           cl.order_qty,
           cl.price,
           orig.price                                                                           as net_price,
           cl.multileg_reporting_type,
           cl.instrument_id,
           cl.time_in_force_id,
           cl.expire_time,
           cl.create_time,
           case
               when cl.multileg_reporting_type = '3' then (select count(*)
                                                           from dwh.client_order cli
                                                           where cli.multileg_order_id = cl.order_id)
               else mleg.no_legs end                                                            as no_legs,
           cl.multileg_order_id,
           cl.side,
           cl.order_type_id,
           cl.open_close,
           cl.exec_instruction,
           cl.cross_order_id,
           cl.fee_sensitivity,
           cl.stop_price,
           cl.max_floor,
           cl.ex_destination,
           cl.ratio_qty,
           cl.customer_or_firm_id,
           oc.opra_symbol,
           di.symbol,
           case
               when di.instrument_type_id = 'E' then 'Stock'
               when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
               when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
               else ''
               end                                                                              as pcv,
           di.instrument_type_id,
           coalesce(di.last_trade_date, cl.expire_time)                                         as last_trade_date,
           tf.trading_firm_name,
           tf.cat_imid                                                                          as tf_cat_imid,
           tf.cat_crd                                                                           as tf_cat_crd,
           dos.root_symbol,
           ui.symbol                                                                            as underlying_symbol,
           dtif.tif_short_name                                                                  as tif,
           dot.order_type_name,
           cof.customer_or_firm_name,
           fmj.tag_9000                                                                         as par_tag_9000,
           fmj.tag_50                                                                           as par_tag_50,
           fmj.tag_109                                                                          as par_tag_109,
           to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                as par_tag_5050,
           staging.last_orig_order_process_time(in_order_id := cl.order_id)::timestamp
               at time zone 'UTC'                                                               as par_tag_10061,
           cl.process_time,
           ac.account_name,
           ac.account_id,
           ac.account_holder_type,
           ac.cat_fdid                                                                          as ac_fdid,
           case
               when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                   then tf.cat_imid end                                                         as ac_imid,
           case
               when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                   then ac.crd_number end                                                       as ac_number,
--         ac.broker_dealer_mpid,
           fc.sender_sub_id,
           fmj.tag_58                                                                           as exec_text,
           fmj.tag_17                                                                           as exec_id,
           fmj.tag_52                                                                           as par_tag_52,
           case
               when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                   then tf.cat_imid end                                                         as cat_imid,
           case
               when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                   then ac.crd_number end                                                       as crd_number,
           tf.trading_firm_unq_id,
           case
               when (cl.exec_instruction like '1%' or tag_9291 = 'N') then 'NH'
               when (cl.exec_instruction like '5%' or tag_9291 = 'Y') then 'H'
               end                                                                              as is_held,
           fmj.tag_9281,
           fmj.tag_22017,
           to_timestamp(fmj.tag_60, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'     as order_request_time,
           to_timestamp(nxt.nxt_tag_60, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC' as cancel_request_time

    from dwh.client_order cl
             left join lateral (select *
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                  and orig.create_date_id >= l_retention_date_id
                                limit 1) orig on true
             left join dwh.client_order mleg
                       on (mleg.order_id = cl.multileg_order_id
--                         and mleg.create_date_id >= cl.create_date_id
                           and mleg.create_date_id >= l_retention_date_id)
             join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id

             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
             left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
             left join dwh.d_time_in_force dtif on dtif.tif_id = cl.time_in_force_id
             left join dwh.d_order_type dot on dot.order_type_id = cl.order_type_id
             left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
             left join dwh.d_fix_connection fc
                       on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
             left join lateral (select --coalesce(fmj.fix_message ->> '10061',
                                       --       fmj.fix_message ->> '60') as tag_10061,
                                       fmj.fix_message ->> '5050'  as tag_5050,
                                       fmj.fix_message ->> '50'    as tag_50,
                                       fmj.fix_message ->> '109'   as tag_109,
                                       fmj.fix_message ->> '9000'  as tag_9000,
                                       fmj.fix_message ->> '58'    as tag_58,
                                       fmj.fix_message ->> '17'    as tag_17,
                                       fmj.fix_message ->> '52'    as tag_52,
                                       fmj.fix_message ->> '9291'  as tag_9291,
                                       fmj.fix_message ->> '9281'  as tag_9281,
                                       fmj.fix_message ->> '22017' as tag_22017,
                                       fmj.fix_message ->> '60'    as tag_60
                                from fix_capture.fix_message_json fmj
                                where cl.fix_message_id = fmj.fix_message_id
                                  and fmj.date_id >= cl.create_date_id
                                limit 1) fmj on true
             left join lateral (select fmj.fix_message ->> '60' as nxt_tag_60
                                from dwh.client_order nxt
                                         join fix_capture.fix_message_json fmj
                                              on fmj.fix_message_id = nxt.fix_message_id and
                                                 fmj.date_id = nxt.create_date_id
                                where nxt.create_date_id >= cl.create_date_id
                                  and nxt.orig_order_id = cl.order_id
                                limit 1) nxt on true
    where cl.parent_order_id is null
      and cl.create_date_id between l_date_begin_id and l_date_end_id
      and case
              when coalesce(l_account_ids, '{}') = '{}' then true
              else cl.account_id = any (l_account_ids) end
      and case
              when coalesce(in_parent_order_ids, '{}') = '{}' then true
              else cl.order_id = any (in_parent_order_ids) end
      and case when in_instrument_type is null then true else di.instrument_type_id = in_instrument_type end
      and cl.trans_type <> 'F';
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' base calculated', l_row_count, 'O')
    into l_step_id;

    drop table if exists t_exs;
    create temp table t_exs as
    select b.first_order_id,
           b.order_id                                                                              as parent_order_id,
           -----
           b.orig_client_order_id,
           3                                                                                       as rn,
--                             b.leg_cl_ord_id, b.client_order_id,
           b.client_order_id                                                                       as client_order_id,
--                     ex.secondary_exch_exec_id                                      as exec_id,
           tag_17                                                                                  as exec_id,
           b.trading_firm_name                                                                     as trading_firm_name,
--                     b.cat_imid,
           b.tf_cat_imid                                                                           as tf_cat_imid,
--                     b.cat_crd,
           b.tf_cat_crd                                                                            as tf_cat_crd,
           case
               when ex.exec_type in ('A', '0', '5') then 'Order Ack'
               when ex.exec_type = '4' then 'Cancelled'
               else et.exec_type_description end                                                   as event_type,
           case
               when ex.exec_type in ('A', '0', '5', 's') then
                   b.par_tag_5050
               when ex.exec_type = '4' then
                   ex.exec_time::timestamp
               else
                   to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'
               end                                                                                 as event_ts,
           b.client_order_id::text                                                                 as street_client_order_id,
           b.order_qty                                                                             as event_qty,
           b.price                                                                                 as event_price,
--        null::numeric                                                                           as net_price,
           b.net_price                                                                             as net_price,
           b.multileg_reporting_type                                                               as multileg_indicator,
           b.no_legs::int4,
           b.leg_cl_ord_id                                                                         as multileg_order_id,
           case
               when ex.exec_type in ('A', 'F', '5', 'W', '4') then 'false'
               else '' end                                                                         as manual_flag,
           case when ex.exec_type not in ('A', '0', '5') then ex.exec_text end                     as exec_text,
           os.order_status_description,
           b.opra_symbol,
           b.root_symbol,
           b.symbol,
           b.instrument_type_id,
           case
               when b.instrument_type_id = 'M' then (select underlying_symbol
                                                     from t_base
                                                     where t_base.multileg_order_id = b.order_id
                                                     limit 1)
               else b.underlying_symbol end                                                        as underlying_symbol,
           b.pcv,
           coalesce(b.last_trade_date, ex.exec_time)                                               as expiration_ts,
           b.side,
           b.tif,
           b.expire_time                                                                           as good_till_ts,
           ex.cum_qty                                                                              as cum_qty,
--        fmj.tag_14                                                                              as cum_qty,
           b.order_type_name,
           ex.exec_time                                                                            as order_creation_ts,
--        to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'      as order_creation_ts,
           b.open_close,
--           compliance.get_sor_trading_session(b.order_id, b.instrument_type_id, b.create_date_id)    as trading_session,
           case
               when fmj.tag_9281 in ('A', 'D', 'G') or fmj.tag_22017 = 'A' then 'ALL'
               when fmj.tag_9281 in ('F', 'C') or fmj.tag_22017 = 'B' then 'REGPOST'
               else 'REG' end                                                                      as trading_session,
           b.is_held                                                                               as is_held,
           case
               when b.cross_order_id is not null then 'Y'
               else 'N' end                                                                        as is_cross,
           b.fee_sensitivity,
           b.stop_price,
           b.max_floor,
           b.customer_or_firm_name,
--        b.par_tag_9000                                                                          as ex_destination,
           b.ex_destination                                                                        as ex_destination,
           b.ratio_qty,
           coalesce(fmj.tag_50, tag_109, b.account_name)                                           as user_,
           b.account_name                                                                          as account_name,
--        null                                                                                    as account_name,
           b.account_id                                                                            as account_id,
--        null::int                                                                               as account_id,
           b.account_holder_type,
           b.ac_fdid,
           b.ac_imid,
           b.ac_number,
--         ac.broker_dealer_mpid,
           b.sender_sub_id,

           -- Execution Details
           ex.last_mkt,
           exc.mic_code,
           ex.trade_liquidity_indicator,
           case when ex.exec_type = 'F' then ex.exec_time end                                      as trade_exec_time,
           ex.exec_type,
           case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then tf.cat_imid end   as cat_imid,
           case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then ac.crd_number end as crd_number,
           order_request_time,
           cancel_request_time
    from t_base b
             left join dwh.d_account ac on b.account_id = ac.account_id and ac.is_active
             left join dwh.d_trading_firm tf on b.trading_firm_unq_id = tf.trading_firm_unq_id
             left join dwh.execution ex
                       on ex.order_id = b.order_id and ex.exec_date_id >= b.create_date_id
                           and ex.exec_type not in ('a', 'A', 'S', '0')
             left join lateral (select fmj.fix_message ->> '10061'          as tag_10061,
                                       coalesce(fmj.fix_message ->> '5050',
                                                fmj.fix_message ->> '5051') as tag_5050,

                                       fmj.fix_message ->> '50'             as tag_50,
                                       fmj.fix_message ->> '109'            as tag_109,
                                       fmj.fix_message ->> '17'             as tag_17,

                                       fmj.fix_message ->> '9281'           as tag_9281,
                                       fmj.fix_message ->> '22017'          as tag_22017
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = ex.fix_message_id
                                  and fmj.date_id >= ex.exec_date_id
                                limit 1) fmj on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             join dwh.d_exec_type et on et.exec_type = ex.exec_type
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' executions calculated', l_row_count, 'O')
    into l_step_id;
--par level
    insert into t_exs
    with ord_type as (select *
                      from (values ('D', 'New Order', 1),
                                   ('D', 'Order Route', 2),
                                   ('G', 'Order Modify', 1),
                                   ('G', 'Order Modify Route', 2))
                               as t(trans_type, order_type_value, rn))
    select b.first_order_id                                       as first_order_id,
           b.order_id                                             as parent_order_id,
           b.orig_client_order_id,
           ot.rn,
           b.client_order_id                                      as client_order_id,
           b.exec_id                                              as exec_id,
--        case
--            when ot.order_type_value = 'New Order'
--                then b.trading_firm_name end                                as trading_firm_name,
           b.trading_firm_name                                    as trading_firm_name,
--        case
--            when ot.order_type_value = 'New Order'
--                then b.tf_cat_imid end                                      as tf_cat_imid,
           b.tf_cat_imid                                          as tf_cat_imid,
--        case
--            when ot.order_type_value = 'New Order'
--                then b.tf_cat_crd end                                       as tf_cat_crd,
           b.tf_cat_crd                                           as tf_cat_crd,
           ot.order_type_value                                    as event_type,
           case
               when ot.order_type_value = 'Cancelled' then b.create_time
               else coalesce(b.par_tag_5050, b.par_tag_10061) end as event_ts,
           case
               when ot.trans_type = 'G' and rn = 1 then null
               else b.client_order_id end                         as street_client_order_id,
--            b.street_clorderid::text                                            as street_client_order_id,
           b.order_qty                                            as event_qty,
           b.price                                                as event_price,
           b.net_price                                            as net_price,
           b.multileg_reporting_type                              as multileg_indicator,
           b.no_legs::int4,
--                            b.multileg_order_id,
           b.leg_cl_ord_id                                        as multileg_order_id,
           case
               when ot.rn = 1 then 'true'
               else 'false' end                                   as manual_flag,
--        case
--            when ot.order_type_value != 'New Order'
--                then b.exec_text end                                        as exec_text,
           b.exec_text                                            as exec_text,
           os.order_status_description,-- et.exec_type_description, ex.order_status,
           b.opra_symbol,
           b.root_symbol,
           b.symbol,
           b.instrument_type_id,
           case
               when b.instrument_type_id = 'M' then (select underlying_symbol
                                                     from t_base
                                                     where t_base.multileg_order_id = b.order_id
                                                     limit 1)
               else b.underlying_symbol end                       as underlying_symbol,
           b.pcv,
--                             case
--                                 when ot.order_type_value != 'New Order'
--                                     then b.last_trade_date end                                  as expiration_ts,
           b.last_trade_date                                      as expiration_ts,
           b.side,
           b.tif,
           b.expire_time                                          as good_till_ts,
--        case
--            when ot.order_type_value != 'New Order'
--                then ex.cum_qty::text end                                   as cum_qty,
           ex.cum_qty                                             as cum_qty,
           b.order_type_name,
           b.process_time                                         as order_creation_ts,
--        coalesce(b.par_tag_5050, b.par_tag_10061)                           as order_creation_ts,
           b.open_close,
--           compliance.get_sor_trading_session(b.order_id, b.instrument_type_id, b.create_date_id)    as trading_session,
           case
               when b.tag_9281 in ('A', 'D', 'G') or b.tag_22017 = 'A' then 'ALL'
               when b.tag_9281 in ('F', 'C') or b.tag_22017 = 'B' then 'REGPOST'
               else 'REG' end                                     as trading_session,

           b.is_held                                              as is_held,
           case
               when b.cross_order_id is not null then 'Y'
               else 'N' end                                       as is_cross,
           b.fee_sensitivity,
           b.stop_price,
           b.max_floor,
           b.customer_or_firm_name,

           b.ex_destination                                       as ex_destination,
           b.ratio_qty,
           coalesce(b.par_tag_50, b.par_tag_109, b.account_name)  as user_,
           b.account_name                                         as account_name,
           b.account_id                                           as account_id,
           b.account_holder_type,
           b.ac_fdid,
           b.ac_imid,
           b.ac_number,
           b.sender_sub_id,

           -- Execution Details

           ex.last_mkt                                            as last_mkt,

           exc.mic_code                                           as mic_code,

           ex.trade_liquidity_indicator                           as trade_liquidity_indicator,
           null::timestamp                                        as trade_exec_time,
           et.exec_type,
           case
               when ot.order_type_value = 'New Order'
                   then b.cat_imid end                            as cat_imid,
           case
               when ot.order_type_value = 'New Order'
                   then b.crd_number end                          as cat_crd,
           b.order_request_time,
           b.cancel_request_time
    from t_base b
             join ord_type ot using (trans_type)
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.exec_text,
                 ex.exchange_id,
                 ex.secondary_exch_exec_id
          from dwh.execution ex
          where ex.order_id = b.order_id
            and ex.exec_date_id >= b.create_date_id
          order by exec_id desc
          limit 1
        ) ex on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             left join dwh.d_exec_type et on et.exec_type = ex.exec_type
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' parents calculated', l_row_count, 'O')
    into l_step_id;

    -- return query
-- select 'OrderID|exec_id|Trading Firm Name|Event Type|Event Date|Event Time|Orig clOrderID|Street clOrderID|Event Qty|Event Price|Executed Timestamp|Multi Leg Indicator|Number of legs|Leg Order ID|Free Text|Order Status|OSI Symbol|Base symbol|Symbol|Security Type|Underlying Symbol|P/C/V|Expiration Date|Side|TIF|Good Till Date|Good Till Time|Order Qty|Filled Qty|Order Type Code|Order Price|Order Creation Date|Order Creation Time|Open/Close|Trading Session|Is Held|Is Cross|Stop Price|Max Floor|Capacity|ExDestination|Leg ratio|User|Account Name|Account ID|Last Mkt|MIC Code|Liquidity Indicator';

    return query
        select parent_order_id                                               as "OrderID",
               trading_firm_name                                             as "Trading Firm Name",
               tf_cat_imid                                                   as "Trading Firm IMID",
               tf_cat_crd                                                    as "Trading Firm CRD",
               event_type                                                    as "Event Type",
               to_char(event_ts, 'MM/DD/YYYY')                               as "Event Date",
               case
                   when event_type = 'Cancelled' then coalesce(to_char(event_ts, 'HH24:MI:SS:MS'), '')
                   else coalesce(to_char(event_ts, 'HH24:MI:SS:US'), '') end as "Event Time",
               client_order_id                                               as "Client clOrderID",
               street_client_order_id                                        as "Street clOrderID",
               event_qty                                                     as "Event Qty",
               event_price                                                   as "Event Price",
               net_price                                                     as "Net Price",
               case
                   when multileg_indicator <> '1' then 'Y'
                   else 'N'
                   end, -- as "Multi Leg Indicator",
               no_legs                                                       as "Number of legs",
               multileg_order_id                                             as "Leg Order ID",
               manual_flag                                                   as "Manual Flag",
               exec_text                                                     as "Free Text",
               -- Order Detail
               order_status_description                                      as "Order Status",
               case
                   when event_type = 'New Order' then ''
                   else orig_client_order_id end                             as "Original Client clOrderID",
               case
                   when event_type = 'Order Route'
                       then orig_client_order_id end                         as "Original Street clOrderID",
               opra_symbol                                                   as "OSI Symbol",
               root_symbol                                                   as "Base symbol",
               symbol                                                        as "Symbol",
               case instrument_type_id
                   when 'O' then 'Option'
                   when 'E' then 'Equity'
                   else coalesce(instrument_type_id, '') end                 as "Security Type",

               underlying_symbol                                             as "Underlying Symbol",
               pcv                                                           as "P/C/S",
               to_char(expiration_ts, 'MM/DD/YYYY')                          as "Expiration Date",
               to_char(expiration_ts, 'HH24:MI:SS.MS')                       as "Expiration Time",
               case
                   when side = '1' then 'Buy'
                   when side = '2' then 'Sell'
                   when side in ('5', '6') then 'Sell Short'
                   end                                                       as "Side",
               tif                                                           as "TIF",
               to_char(good_till_ts, 'MM/DD/YYYY')                           as "Good Till Date",
               to_char(good_till_ts, 'HH24:MI:SS.MS')                        as "Good Till Time",
               event_qty                                                     as "Order Qty",
               cum_qty                                                       as "Filled Qty",
               order_type_name                                               as "Order Type Code",
               event_price                                                   as "Order Price",
               to_char(order_creation_ts, 'DD.MM.YYYY')                      as "Order Creation Date",
               to_char(order_creation_ts, 'HH24:MI:SS.US')                   as "Order Creation Time",
               open_close                                                    as "Open/Close",
               trading_session::varchar                                      as "Trading Session",
               is_held                                                       as "Is Held",
               is_cross                                                      as "Is Cross",
               fee_sensitivity                                               as "Fee Sensitivity",
               stop_price                                                    as "Stop Price",
               max_floor                                                     as "Max Floor",
               customer_or_firm_name                                         as "Capacity",
               ex_destination                                                as "ExDestination",
               ratio_qty                                                     as "Leg ratio",
               user_                                                         as "User",

-- Account Details
               account_name                                                  as "Account Name",
               account_id                                                    as "Account ID",
               account_holder_type                                           as "Account Holder Type",
               ac_fdid                                                       as "Account FDID",
               ac_imid::text                                                 as "Account IMID",
               ac_number                                                     as "Account CRD",
               sender_sub_id                                                 as "Sender Type",

               -- Execution Details
               last_mkt                                                      as "Last Mkt",
               mic_code                                                      as "MIC Code",
               trade_liquidity_indicator                                     as "Liquidity Indicator",
               exec_id                                                       as "ExecutionID",
               ac_imid                                                       as "CAT Reporting Firm IMID",
               to_char(case
                           when event_type = 'Cancelled' then cancel_request_time
                           when event_type ilike '%modify%' then order_request_time
                           end, 'DD.MM.YYYY')                                as "Request Date",
               to_char(case
                           when event_type = 'Cancelled' then cancel_request_time
                           when event_type ilike '%modify%' then order_request_time
                           end, 'HH24:MI:SS.US')                             as "Request Time"
        from (select *
-- into trash.so_obo
              from t_exs
              where case when exec_type in ('A', '0', '5', 'b') and event_ts is null then false else true end
              order by 1, 2 nulls first, 3, rn, event_ts) x;
end;
$function$
;



---
select cl.account_id
from dwh.client_order cl
             join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id

    where cl.parent_order_id is null
      and cl.create_date_id between :l_date_begin_id and :l_date_end_id
      and di.instrument_type_id = 'O'
      and cl.trans_type <> 'F'
and not exists (select null from dwh.gtc_order_status gos where gos.account_id = cl.account_id and gos.close_date_id is null);


select *
from dash360.report_obo_compliance_xls_2(20250218, 20250221, null,
                                         '{58549,64894,68334,71776,71797,71827,71852,71871,72082,72991,73089}',
                                         '{19158555678,19159621489,19158555679,19159621495,19158555680,19159621501,19161719278,19161719279,19161719282,19163253234,19163264539,19168490738,19176656452,19176967344,19176978122,19176979238,19179142317,19179142678,19179143605,19179143648,19179143792,19191747171,19197256857,19191747172,19197256860,19191747174,19197256862,19197561973,19218836009,19218836011,19218836014,19222801424,19238029924,19245808594}');



-- drop function if exists dash360.report_obo_compliance_xls;
-- alter function dash360.report_obo_compliance_xls_2 rename to report_obo_compliance_xls;