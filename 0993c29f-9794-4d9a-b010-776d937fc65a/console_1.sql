-- DROP FUNCTION dash360.report_obo_compliance_xls(int4, int4, bpchar, _int4, _int8, _varchar, bpchar, bpchar, bpchar, _varchar);

CREATE or replace FUNCTION trash.report_obo_compliance_xls2(in_date_begin_id integer, in_date_end_id integer,
                                                            in_instrument_type character DEFAULT NULL::bpchar,
                                                            in_account_ids integer[] DEFAULT '{}'::integer[],
                                                            in_parent_order_ids bigint[] DEFAULT '{}'::bigint[],
                                                            in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                            in_exclude_eos character DEFAULT 'Y'::bpchar,
                                                            in_include_routes character DEFAULT 'Y'::bpchar,
                                                            in_include_acks character DEFAULT 'Y'::bpchar,
                                                            in_fix_comp_ids character varying[] DEFAULT '{}'::character varying(30)[])
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
                "Event Price"               text,
                "Net Price"                 text,
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
                "Order Price"               text,
                "Order Creation Date"       text,
                "Order Creation Time"       text,
                "Open/Close"                character,
                "Trading Session"           character varying,
                "Is Held"                   text,
                "Is Cross"                  text,
                "Fee Sensitivity"           smallint,
                "Stop Price"                text,
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
                "Request Time"              text,
                "Strike Price"              text,
                "Remaining Qty"             bigint,
                "Affiliated Flag"           character,
                "Solicitation Flag"         text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2025-07-04
-- SY: 20250820 https://dashfinancial.atlassian.net/browse/DS-10355 l_retention_date_id field calculation moved from client_order table to gtc_order_status.
-- SY: 20251013 left has been added to avoid ERROR SqlState: 22008 MessageText: date/time field value out of range: "20251013-19:25:16.657925405"
-- SO: 20251111 https://dashfinancial.atlassian.net/browse/DEVREQ-6896 add the in_fix_comp_ids parameter to the existing dash360.report_obo_compliance_xls function
-- MB: 20260914 https://dashfinancial.atlassian.net/browse/DS-11931 Expanded with exec_type = 'G'
-- DS: 20261119 added l_trading_firm_ids to handle inputs like in_trading_firm_ids => '{"\"socgenpsc\""}'
-- OS: 20261120 https://dashfinancial.atlassian.net/browse/DS-12368 performance impr
declare
    l_load_id           int;
    l_step_id           int;
    l_date_begin_id     int4;
    l_date_end_id       int4;
    l_account_ids       int4[];
    l_trading_firm_ids  varchar[];
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

    l_trading_firm_ids :=
            (SELECT ARRAY(SELECT translate(item, '"' || chr(92), '') FROM unnest(in_trading_firm_ids) AS t(item)));

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and is_active
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (l_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    drop table if exists t_accounts;
    create temp table t_accounts as
    SELECT *
    FROM dwh.d_account
    where true
      and is_active
      and case when l_account_ids = '{}' then true else account_id = any (l_account_ids) end;
    get diagnostics l_row_count = row_count;

    create index on t_accounts (account_id);

    select public.load_log(l_load_id, l_step_id, 'Accounts table filled', l_row_count, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, 'l_account_id size is ' || left(l_account_ids::varchar, 180),
                           cardinality(l_account_ids), 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, 'in_trading_firm_ids: ' || left(in_trading_firm_ids::varchar, 180),
                           cardinality(in_trading_firm_ids), 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, 'l_trading_firm_ids: ' || left(l_trading_firm_ids::varchar, 180),
                           cardinality(l_trading_firm_ids), 'O')
    into l_step_id;

    select coalesce(min(gtc.create_date_id), l_date_begin_id)
    into l_retention_date_id
    from dwh.gtc_order_status gtc
             join t_accounts using (account_id)
    where true
      and (gtc.close_date_id is null
        or gtc.close_date_id >= l_date_end_id);


--    l_retention_date_id := 20230101;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' retention_date - ' || l_retention_date_id::text, 0, 'O')
    into l_step_id;

    drop table if exists t_client_order;
    create temp table if not exists t_client_order
    as
    select cl.*,
           ac.account_name,
           ac.account_holder_type,
           ac.cat_fdid,
           ac.crd_number,
           ac.is_affiliate,
           ac.trading_firm_id as ac_trading_firm_id
    from dwh.client_order cl
             join t_accounts ac on ac.account_id = cl.account_id
    where cl.create_date_id between l_date_begin_id and l_date_end_id
      and cl.trans_type <> 'F'
      and coalesce(cl.parent_order_id, -123) = -123 --cl.parent_order_id is null (to avoid the parent_order_id index usage)
      and case
              when coalesce(l_account_ids, '{}') = '{}' then true
              else cl.account_id = any (l_account_ids) end
      and case
              when coalesce(in_parent_order_ids, '{}') = '{}' then true
              else cl.order_id = any (in_parent_order_ids) end;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' t_client_order created', l_row_count, 'O')
    into l_step_id;

    analyze t_client_order;

    drop table if exists t_first;
    create temp table t_first as
    select cl.order_id, root_order.*
    from t_client_order cl
             LEFT JOIN LATERAL (
        WITH RECURSIVE total AS (SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time,
                                        0 as lvl

                                 FROM dwh.client_order co
                                 WHERE co.orig_order_id IS NOT NULL
                                   AND co.order_id = cl.order_id

                                 UNION ALL

                                 SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time,
                                        lvl + 1
                                 FROM dwh.client_order co
                                          JOIN total t
                                               ON co.order_id = t.orig_order_id)
        SELECT t.order_id     AS first_order_id,
               t.process_time AS first_process_time,
               t.lvl
        FROM total t
        WHERE t.orig_order_id IS NULL
        LIMIT 1
        ) root_order ON true
    where cl.orig_order_id is not null;
    analyze t_first;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' t_first calculated', l_row_count, 'O')
    into l_step_id;
    drop table if exists t_base;
    create temp table t_base as
    select --coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order_id,
--               cl.order_id as first_order_id,
           coalesce(root_order.first_order_id, cl.order_id)           AS first_order_id,
           orig.client_order_id                                       as orig_client_order_id,
           cl.client_order_id,
           cl.co_client_leg_ref_id                                    as leg_cl_ord_id,
           cl.trans_type,
           cl.order_id,
           cl.fix_message_id,
           cl.create_date_id,
           cl.order_qty,
           cl.price,
           orig.price                                                 as net_price,
           cl.multileg_reporting_type,
           cl.instrument_id,
           cl.time_in_force_id,
           cl.expire_time,
           cl.create_time,
           case
               when cl.multileg_reporting_type = '3' then lnb.no_legs
               else 1 end                                             as no_legs,
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
               end                                                    as pcv,
           di.instrument_type_id,
           coalesce(di.last_trade_date, cl.expire_time)               as last_trade_date,
           tf.trading_firm_name,
           tf.cat_imid                                                as tf_cat_imid,
           tf.cat_crd                                                 as tf_cat_crd,
           dos.root_symbol,
           ui.symbol                                                  as underlying_symbol,
           dtif.tif_short_name                                        as tif,
           dot.order_type_name,
           cof.customer_or_firm_name,
           fmj.tag_9000                                               as par_tag_9000,
           fmj.tag_50                                                 as par_tag_50,
           fmj.tag_109                                                as par_tag_109,
           to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as par_tag_5050,
--            staging.last_orig_order_process_time(in_order_id := cl.order_id)::timestamp
--                at time zone 'UTC'                                      as par_tag_10061,
           root_order.first_process_time AT TIME ZONE 'UTC'           AS par_tag_10061,
           cl.process_time,
           cl.account_name,
           cl.account_id,
           cl.account_holder_type,
           cl.cat_fdid                                                as ac_fdid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then tf.cat_imid end                               as ac_imid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then cl.crd_number end                             as ac_number,
--         ac.broker_dealer_mpid,
           fc.sender_sub_id,
           fmj.tag_58                                                 as exec_text,
           fmj.tag_17                                                 as exec_id,
           fmj.tag_52                                                 as par_tag_52,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then tf.cat_imid end                               as cat_imid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then cl.crd_number end                             as crd_number,
           tf.trading_firm_unq_id,
           case
               when (cl.exec_instruction like '1%' or tag_9291 = 'N') then 'NH'
               when (cl.exec_instruction like '5%' or tag_9291 = 'Y') then 'H'
               end                                                    as is_held,
           fmj.tag_9281,
           fmj.tag_22017,
           to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as order_request_time,
           to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as cancel_request_time,
           oc.strike_price,
           cl.is_affiliate,
           case when cl.ex_destination = 'DASH' then 'Y' else 'N' end as solicitation-- if 'Y' - Y otherwise N
    from t_client_order cl
             left join lateral (select orig.client_order_id, orig.price
                                from dwh.client_order orig
                                where true
                                  and cl.orig_order_id is not null
                                  and orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                  and orig.create_date_id >= l_retention_date_id
                                limit 1) orig on true
--              join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = cl.ac_trading_firm_id

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
                                  and nxt.create_date_id >= l_date_begin_id
                                  and nxt.create_date_id <= l_date_end_id
                                limit 1) nxt on true
             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
--                                   and cnl.create_date_id = in_date_id --??
                                  and cnl.create_date_id >= l_retention_date_id
                                  and cl.multileg_order_id is not null
                                limit 1) lnb on true
             LEFT JOIN LATERAL (select * from t_first fst where fst.order_id = cl.order_id limit 1) root_order on true
    where true
      and case when in_instrument_type is null then true else di.instrument_type_id = in_instrument_type end
      and case when in_exclude_eos = 'N' then true else fc.is_high_frequency_trader = 'N' end
      and case when in_fix_comp_ids = '{}' then true else coalesce(fc.fix_comp_id, '') = any (in_fix_comp_ids) end;
    get diagnostics l_row_count = row_count;

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
                   to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'
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
               when ex.exec_type in ('A', 'F', 'G', '5', 'W', '4') then 'false'
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
           case when ex.exec_type in ('F', 'G') then ex.exec_time end                              as trade_exec_time,
           ex.exec_type,
           case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then tf.cat_imid end   as cat_imid,
           case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then ac.crd_number end as crd_number,
           order_request_time,
           cancel_request_time,
           strike_price,
           b.order_qty - coalesce(ex.cum_qty, 0)                                                   as remaining_qty,
           b.is_affiliate,
           null                                                                                    as solicitation
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
    get diagnostics l_row_count = row_count;
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
           b.cancel_request_time,
           b.strike_price,
           b.order_qty - coalesce(ex.cum_qty, 0)                  as remaining_qty,
           b.is_affiliate,
           case
               when ot.order_type_value = 'New Order'
                   then b.solicitation end                        as solicitation
    from t_base b
             join ord_type ot
                  on ot.trans_type = b.trans_type and case when in_include_routes = 'Y' then true else ot.rn = 1 end
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
    get diagnostics l_row_count = row_count;
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
               to_char(event_price, 'FM99999990D0099')                       as "Event Price",
               to_char(net_price, 'FM99999990D0099')                         as "Net Price",
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
               to_char(event_price, 'FM99999990D0099')                       as "Order Price",
               to_char(order_creation_ts, 'DD.MM.YYYY')                      as "Order Creation Date",
               to_char(order_creation_ts, 'HH24:MI:SS.US')                   as "Order Creation Time",
               open_close                                                    as "Open/Close",
               trading_session::varchar                                      as "Trading Session",
               is_held                                                       as "Is Held",
               is_cross                                                      as "Is Cross",
               fee_sensitivity                                               as "Fee Sensitivity",
               to_char(stop_price, 'FM99999990D0099')                        as "Stop Price",
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
                           end, 'HH24:MI:SS.US')                             as "Request Time",
               to_char(strike_price, 'FM99999990D0099')                      as "Strike Price",
               case
                   when event_type = 'New Order' then event_qty
                   when event_type = 'Trade' then remaining_qty end
                                                                             as "Remaining Qty",
               is_affiliate                                                  as "Affiliated Flag",
               solicitation                                                  as "Solicitation Flag"
        from (select *
-- into trash.so_obo
              from t_exs
              where case when exec_type in ('A', '0', '5', 'b') and event_ts is null then false else true end
                and case when in_include_acks = 'Y' then true else exec_type not in ('A', '0', '5') end
              order by 1, 2 nulls first, 3, rn, event_ts) x;
    get diagnostics l_row_count = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls_new for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' COMPLETED', l_row_count, 'O')
    into l_step_id;
end;
$function$
;



-- DROP FUNCTION trash.report_obo_compliance_xls_dev_261120(int4, int4, bpchar, _int4, _int8, _varchar, bpchar, bpchar, bpchar, _varchar);
select *
from trash.report_obo_compliance_xls2(in_date_begin_id => 20261118, in_date_end_id => 20261118, in_account_ids => null,
                                     in_trading_firm_ids => '{\"socgenpsc\"}', in_instrument_type => case
                                                                                                         when 'Both' = 'Equity'
                                                                                                             then 'E'
                                                                                                         when 'Both' = 'Option'
                                                                                                             then 'O'
                                                                                                         else null end,
                                     in_include_routes := 'Y', in_include_acks := 'Y', in_exclude_eos := 'N',
                                     in_fix_comp_ids := COALESCE(null, ARRAY []::varchar(30)[]));
SELECT pg_get_functiondef(
    'staging.last_orig_order(bigint)'::regprocedure
);

SELECT pg_get_functiondef(
    'staging.last_orig_order_process_time(bigint)'::regprocedure
);
---------------------------------------
-- {80359,78226,79824,79826,79827,79828,79830,79831,79832,79833,79836,80330,80380,80381,79934,79851,79852,79854,79937,79855,79938,79857,79939,79940,79859,79941,79868,79878,79959,75867,79887,79892,79896,79898,79973,77134,77812,77813,77814,77815,77816,77004,77132,77142,77216,79965,77805,77808,77809,77810,77879,78203,81106,81115,78228,78229,78230,78231,79486,79462,80957,78234,78235,78236,78237,77801,78238,78239,78342,78995,79309,79315,79316,79329,78206,79335,79407,79408,79421,79422,79537,79297,79298,79835,79837,79299,79838,79839,79301,79302,78993,79303,79305,79306,79858,79861,79866,79310,79871,79311,78998,79449,78999,79313,79877,79314,79881,79317,79882,79410,79885,79319,79891,79320,79411,79351,79412,79481,79540,79413,79894,79415,79324,79325,79416,79543,79326,79417,79544,79897,78347,79328,79899,79909,79331,79332,79913,79334,79338,79339,79340,79920,79921,79341,79923,78349,79929,78350,78351,79343,79424,79930,79344,79345,79932,79933,79347,79936,78352,79348,79427,79943,79946,79947,79951,79957,79963,79966,79523,79971,79974,79975,79978,79988,79991,80218,79994,79999,80003,80004,77767,79430,80012,80014,80017,81114,80018,80019,80020,80023,80024,80025,80026,80047,79365,79355,80027,80028,80031,80032,80033,80035,80037,80038,80042,80043,80044,80045,80048,80049,80053,80054,80056,80059,80058,80063,80064,80065,80068,80069,80067,80073,80075,80076,80077,80078,80101,80110,80966,80080,80081,80111,80082,80133,80156,79431,80084,80161,80163,80086,80087,80088,80089,80092,79363,80181,80102,80103,80191,80192,80104,80105,80224,80992,80108,80197,80200,80109,80201,80118,80119,80120,80122,80209,79368,80125,80210,80126,80127,80215,80128,80219,80222,80223,80129,80130,80231,80131,80235,80132,80237,79890,80135,80241,80220,80242,80137,80246,80247,80260,80139,80248,79371,80121,80266,80141,80269,80142,80285,80143,79323,79333,80144,80409,80442,80478,80544,80443,80464,80444,80553,80445,79352,80446,80251,80447,80150,80151,80152,80256,80153,80154,80258,79372,80155,80157,80261,80158,80160,80262,80162,77878,77880,80166,80264,80167,79366,79358,79849,80171,80172,80173,80174,79889,79961,79452,79508,79875,80238,80140,80557,80288,80289,79387,79389,80113,81000,81005,81001,80360,79390,79393,79395,79396,79397,79400,79402,79404,80395,80483,80489,80270,79503,79950,79432,79433,79434,79435,79436,79437,81142,81159,79438,79439,79440,79441,79442,79443,79444,79445,80100,79447,79450,79453,80595,79454,79455,79357,79457,80039,80455,79124,80499,79125,79461,79126,79127,79128,79464,80116,79465,79466,79129,79130,79467,79131,79468,79637,79132,79469,79133,79134,79471,79135,79472,79136,79474,80074,80482,79476,79554,79555,79556,79479,79482,79559,79746,79483,79560,79484,79562,79563,77861,79564,79488,79993,79489,79356,79485,80621,79492,79493,77802,79494,80134,79312,79147,79496,79149,79497,79148,80524,80525,79146,80282,79500,78994,79502,80016,80057,79876,79505,79470,80630,79549,80631,79565,79566,80634,79510,80635,79511,80636,80637,79513,80638,80639,79515,80640,79446,79516,80641,79491,79649,80642,79518,80643,79519,79766,80644,78211,79520,80645,79521,80646,79768,79522,80647,81022,79478,81023,81024,79834,79529,79530,77144,77379,78215,77806,77811,77817,78204,78208,78210,78212,78205,78213,80085,79531,80454,79499,78216,78217,79490,78218,79369,78219,78220,78221,78222,78224,78225,78227,78240,79578,78241,78242,78243,78244,78245,79394,78246,78320,78343,78344,78345,78346,78348,79277,79294,79295,79296,79579,79399,79300,79580,79304,81178,79307,79308,79330,79336,79337,79581,79342,79350,79353,79359,79364,79388,79391,79392,81179,79582,79405,79398,79401,79403,79409,79414,79418,79423,81180,79650,79425,79745,79825,79426,79848,79428,79850,79429,79853,79856,79862,79507,79541,79542,79558,79863,79864,79865,79867,79869,79870,79872,79873,79879,79874,79880,79884,79886,79888,79893,79895,79900,79901,79902,79903,79904,79906,79907,79908,79910,79911,79912,79914,79915,79916,79917,79918,79919,79922,79924,79925,79926,79927,79928,79931,79935,76160,79942,79944,79945,75866,75868,79952,75886,79953,77401,77403,77404,77799,77800,79954,79955,79512,77854,77857,77858,77859,77860,77876,79956,79958,79960,79962,79964,79967,79969,79970,79972,79976,79977,79979,79980,79984,79986,79987,79989,79990,79992,79995,79996,79997,79998,80000,80001,80005,80006,80007,80008,80010,80011,80013,80015,80022,78247,78248,78249,78304,78313,78314,78315,78316,78317,78311,80029,80030,79504,79495,80034,80061,80040,80062,80071,80072,80079,80036,80041,80090,80091,80093,80050,80051,80052,80094,80096,80097,80098,80099,80107,80112,80114,80115,80117,80123,80124,80159,80164,80165,80168,80169,80170,80178,80180,80185,80186,80187,80188,80189,80190,80193,80194,80195,80198,78209,80199,80202,80203,80204,80205,80206,80207,80208,80211,80214,80216,80217,80221,80225,80226,80227,80228,80229,80070,80232,80236,80233,80234,80239,80240,80243,79019,80244,80263,80283,80286,80327,80267,80396,80411,80413,80414,80416,79021,80427,80429,80434,80437,80438,80439,80440,80441,80632,80633,80436,79022,79023,79024,79025,79420,79026,79487,80046,79027,79028,80339,79029,81038,81053,79030,79031,81040,79367,79463,79517,79527,79557,79451,79460,79032,81041,79033,81042,81043,79034,79242,77807,77208,81044,79035,81195,79036,79598,81045,79037,81046,79038,81047,79361,81048,79039,79293,79040,79587,81049,79604,79041,79588,79605,79042,79589,79043,79590,79606,79607,79044,79591,79045,79592,79608,79046,79593,79609,79047,79594,79610,79611,78223,80095,79048,79595,79049,79596,79597,79613,79506,79619,79362,80332,80268,80668,80670,81057,81058,81060,81059,80671,80673,81064,79624,81065,79370,79456,80674,80675,81066,79625,79680,79406,79682,79683,79684,78201,79685,79686,79318,79448,79687,79458,79501,79514,79477,80331,79679,80287,80338,80341,79688,79689,81067,79690,81201,79691,80691,80692,79692,80693,79693,80694,79694,80695,79695,79696,80696,80697,79697,78305,78321,80698,80699,79699,79700,80700,80701,80702,79701,79634,80703,80335,79702,80704,80731,79635,79703,81102,81070,81093,79704,80705,81072,79705,81094,81103,80706,81071,79706,81104,80707,79707,80708,81105,80709,79020,80710,80711,77143,80712,80713,79767,80714,80060,80715,80138,80716,80717,80230,80212,80718,80719,80720,80721,79321,80722,77380,77853,79141,79473,79615,79626,79847,80213,80259,77005,79246,79354,79459,79349,79586,78996,79539,80083,80257,80179,80672,80669,81107,77769,79480,79528,79583,79612,79623,79883,79905,79948,79949,80009,80055,80196,80329,75887,75888,77803,79322,79123,79538,79360,79419,79698,80021,79860,80333,80340,80500,80782,80783,80106,80265,77877,79090,79245,79498,79509,79475,79576,79829,80562,80785,78309,79621,77406,79525,79524,79796,79797,79798,77804,77405,78207,79327,79681,78214,80342,77851,79810,80781,79526,79603,79584,79585,79811,80892,77768,78318,80894,80066,80002,80428,80136,80931,80933,78319,78202,78997,80245,79985,77798}
-- DROP FUNCTION trash.report_obo_compliance_xls(int4, int4, bpchar, _int4, _int8, _varchar, bpchar, bpchar, bpchar, _varchar);

 if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and is_active
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (l_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    drop table if exists t_accounts;
    create temp table t_accounts as
    SELECT *
    FROM dwh.d_account
    where true
      and is_active
      and trading_firm_id = ANY (:l_trading_firm_ids) case when :l_account_ids = '{}' then true else account_id = any (:l_account_ids) end;


    create index on t_accounts (account_id);


    select coalesce(min(gtc.create_date_id), :l_date_begin_id)
--     into l_retention_date_id
    from dwh.gtc_order_status gtc
    join t_accounts using (account_id)
    where true
      and (gtc.close_date_id is null
        or gtc.close_date_id >= :l_date_end_id)
      and case
              when coalesce(:l_account_ids, '{}') = '{}' then true
              else gtc.account_id = any (:l_account_ids) end; -- 20260804




select string_agg(account_id::text, ',') from t_accounts

    drop table if exists t_client_order;
    drop table if exists t_client_order;
    create temp table if not exists t_client_order
    as
    select cl.*,
           ac.account_name,
           ac.account_holder_type,
           ac.cat_fdid,
           ac.crd_number,
           ac.is_affiliate,
           ac.trading_firm_id as ac_trading_firm_id
    from dwh.client_order cl
             join t_accounts ac on ac.account_id = cl.account_id
    where cl.create_date_id between :l_date_begin_id and :l_date_end_id
      and cl.trans_type <> 'F'
      and coalesce(cl.parent_order_id, -123) = -123 --cl.parent_order_id is null (to avoid the parent_order_id index usage)
      and case
              when coalesce(:l_account_ids, '{}') = '{}' then true
              else cl.account_id = any (:l_account_ids) end
      and case
              when coalesce(:in_parent_order_ids, '{}') = '{}' then true
              else cl.order_id = any (:in_parent_order_ids) end;


    analyze t_client_order;

    drop table if exists t_base;
    create temp table t_base as
    select --coalesce(staging.last_orig_order(cl.order_id), cl.order_id) as first_order_id,
--               cl.order_id as first_order_id,
           coalesce(root_order.first_order_id, cl.order_id)           AS first_order_id,
           orig.client_order_id                                       as orig_client_order_id,
           cl.client_order_id,
           cl.co_client_leg_ref_id                                    as leg_cl_ord_id,
           cl.trans_type,
           cl.order_id,
           cl.fix_message_id,
           cl.create_date_id,
           cl.order_qty,
           cl.price,
           orig.price                                                 as net_price,
           cl.multileg_reporting_type,
           cl.instrument_id,
           cl.time_in_force_id,
           cl.expire_time,
           cl.create_time,
           case
               when cl.multileg_reporting_type = '3' then lnb.no_legs
               else 1 end                                             as no_legs,
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
               end                                                    as pcv,
           di.instrument_type_id,
           coalesce(di.last_trade_date, cl.expire_time)               as last_trade_date,
           tf.trading_firm_name,
           tf.cat_imid                                                as tf_cat_imid,
           tf.cat_crd                                                 as tf_cat_crd,
           dos.root_symbol,
           ui.symbol                                                  as underlying_symbol,
           dtif.tif_short_name                                        as tif,
           dot.order_type_name,
           cof.customer_or_firm_name,
           fmj.tag_9000                                               as par_tag_9000,
           fmj.tag_50                                                 as par_tag_50,
           fmj.tag_109                                                as par_tag_109,
           to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as par_tag_5050,
--            staging.last_orig_order_process_time(in_order_id := cl.order_id)::timestamp
--                at time zone 'UTC'                                      as par_tag_10061,
           root_order.first_process_time AT TIME ZONE 'UTC'           AS par_tag_10061,
           cl.process_time,
           cl.account_name,
           cl.account_id,
           cl.account_holder_type,
           cl.cat_fdid                                                as ac_fdid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then tf.cat_imid end                               as ac_imid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then cl.crd_number end                             as ac_number,
--         ac.broker_dealer_mpid,
           fc.sender_sub_id,
           fmj.tag_58                                                 as exec_text,
           fmj.tag_17                                                 as exec_id,
           fmj.tag_52                                                 as par_tag_52,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then tf.cat_imid end                               as cat_imid,
           case
               when cl.cat_fdid like cl.crd_number || ':' || tf.cat_imid
                   then cl.crd_number end                             as crd_number,
           tf.trading_firm_unq_id,
           case
               when (cl.exec_instruction like '1%' or tag_9291 = 'N') then 'NH'
               when (cl.exec_instruction like '5%' or tag_9291 = 'Y') then 'H'
               end                                                    as is_held,
           fmj.tag_9281,
           fmj.tag_22017,
           to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as order_request_time,
           to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                      as cancel_request_time,
           oc.strike_price,
           cl.is_affiliate,
           case when cl.ex_destination = 'DASH' then 'Y' else 'N' end as solicitation-- if 'Y' - Y otherwise N
    from t_client_order cl
             left join lateral (select orig.client_order_id, orig.price
                                from dwh.client_order orig
                                where true
                                  and cl.orig_order_id is not null
                                  and orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                  and orig.create_date_id >= :l_retention_date_id
                                limit 1) orig on true
--              join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = cl.ac_trading_firm_id

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
                                  and nxt.create_date_id >= :l_date_begin_id
                                  and nxt.create_date_id <= :l_date_end_id
                                limit 1) nxt on true
             left join lateral (select cnl.no_legs
                                from dwh.client_order cnl
                                where cnl.order_id = cl.multileg_order_id
--                                   and cnl.create_date_id = in_date_id --??
                                  and cnl.create_date_id >= :l_retention_date_id
                                  and cl.multileg_order_id is not null
                                limit 1) lnb on true
             LEFT JOIN LATERAL (
        WITH RECURSIVE total AS (SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time
                                 FROM dwh.client_order co
                                 WHERE co.orig_order_id IS NOT NULL
                                   AND co.order_id = cl.order_id

                                 UNION ALL

                                 SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time
                                 FROM dwh.client_order co
                                          JOIN total t
                                               ON co.order_id = t.orig_order_id)
        SELECT t.order_id     AS first_order_id,
               t.process_time AS first_process_time
        FROM total t
        WHERE t.orig_order_id IS NULL
        LIMIT 1
        ) root_order ON true
    where true

      and case when :in_instrument_type is null then true else di.instrument_type_id = :in_instrument_type end
      --and case when in_exclude_eos = 'Y' then true else fc.is_high_frequency_trader = 'N' end
      and case when :in_exclude_eos = 'N' then true else fc.is_high_frequency_trader = 'N' end
      and case when :in_fix_comp_ids = '{}' then true else coalesce(fc.fix_comp_id, '') = any (:in_fix_comp_ids) end
--       and cl.trans_type <> 'F'
    ;
create table trash.t_first_orig as
select cl.order_id, root_order.*
from t_client_order cl
LEFT JOIN LATERAL (
        WITH RECURSIVE total AS (SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time,
                                        0 as lvl

                                 FROM dwh.client_order co
                                 WHERE co.orig_order_id IS NOT NULL
                                   AND co.order_id = cl.order_id

                                 UNION ALL

                                 SELECT co.order_id,
                                        co.orig_order_id,
                                        co.process_time,
                                        lvl + 1
                                 FROM dwh.client_order co
                                          JOIN total t
                                               ON co.order_id = t.orig_order_id)
        SELECT t.order_id     AS first_order_id,
               t.process_time AS first_process_time,
               t.lvl
        FROM total t
        WHERE t.orig_order_id IS NULL
        LIMIT 1
        ) root_order ON true
where cl.orig_order_id is not null;

create temp table t_19 as
select * from t_18
order by 4 desc;

select * from dwh.client_order
where order_id = 526100993766971714
select *
from trash.report_obo_compliance_xls2(in_date_begin_id => 20261119, in_date_end_id => 20261119, in_account_ids => null,
                                     in_trading_firm_ids => '{\"socgenpsc\"}', in_instrument_type => case
                                                                                                         when 'Both' = 'Equity'
                                                                                                             then 'E'
                                                                                                         when 'Both' = 'Option'
                                                                                                             then 'O'
                                                                                                         else null end,
                                     in_include_routes := 'Y', in_include_acks := 'Y', in_exclude_eos := 'N',
                                     in_fix_comp_ids := COALESCE(null, ARRAY []::varchar(30)[]));



select ori.*, cl.client_order_id
from trash.t_first_orig ori
join dwh.client_order cl using (order_id)
where cl.create_date_id = 20261118
order by 4 desc