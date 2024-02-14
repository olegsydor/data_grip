-- DROP FUNCTION trash.obo_sor2(int4, int4, _int4, _int8);
select * from t_sor
select * from dash360.report_obo_compliance_xls(in_date_begin_id := 20240208, in_date_end_id := 20240208, in_account_ids := '{63614,68077,54131}')
select * from trash.report_lpeod_aos_compliance(p_start_date_id => 20240207, p_end_date_id => 20240208, p_account_ids => '{68415}');
drop function if exists trash.obo_sor22;

create or replace function dash360.report_obo_compliance_xls(in_date_begin_id integer, in_date_end_id integer,
                                                             in_account_ids integer[] default '{}'::integer[],
                                                             in_parent_order_ids bigint[] default '{}'::bigint[])
    returns table
            (
                parent_order_id             int8,
                "Trading Firm Name"         varchar(60),
                "Trading Firm IMID"         varchar(13),
                "Trading Firm CRD"          varchar(15),
                "Event Type"                varchar,
                "Event Date"                text,
                "Event Time"                text,
                "Client clOrderID"          varchar(256),
                "Street clOrderID"          text,
                "Event Qty"                 int4,
                "Event Price"               numeric(12, 4),
                "Net Price"                 numeric(12, 4),
                "Multi Leg Indicator"       text,
                "Number of legs"            int4,
                "Leg Order ID"              int8,
                "Manual Flag"               text,
                "Free Text"                 varchar(512),
                "Order Status"              varchar,
                "Original Client clOrderID" varchar,
                "Original Street clOrderID" varchar,
                "OSI Symbol"                varchar(30),
                "Base symbol"               varchar(10),
                "Symbol"                    varchar(10),
                "Security Type"             bpchar,
                "Underlying Symbol"         varchar(10),
                "P/C/S"                     text,
                "Expiration Date"           text,
                "Expiration Time"           text,
                "Side"                      text,
                "TIF"                       varchar(3),
                "Good Till Date"            text,
                "Good Till Time"            text,
                "Order Qty"                 int4,
                "Filled Qty"                int8,
                "Order Type Code"           varchar(255),
                "Order Price"               numeric(12, 4),
                "Order Creation Date"       text,
                "Order Creation Time"       text,
                "Open/Close"                bpchar(1),
                "Trading Session"           varchar,
                "Is Held"                   text,
                "Is Cross"                  text,
                "Fee Sensitivity"           int2,
                "Stop Price"                numeric(12, 4),
                "Max Floor"                 int8,
                "Capacity"                  varchar(255),
                "ExDestination"             varchar(5),
                "Leg ratio"                 int8,
                "User"                      text,
                "Account Name"              varchar(30),
                "Account ID"                int4,
                "Account Holder Type"       varchar(1),
                "Account FDID"              varchar(40),
                "Account IMID"              text,
                "Account CRD"               varchar,
                "Sender type"               varchar(20),
                "Last Mkt"                  varchar(5),
                "MIC Code"                  varchar(4),
                "Liquidity Indicator"       varchar(256),
                "ExecutionID"               text,
                "CAT Reporting Firm IMID"   varchar
            )
    language plpgsql
as
$function$
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_date_begin_id int4;
    l_date_end_id   int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    l_date_begin_id := coalesce(in_date_begin_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_date_end_id := coalesce(in_date_end_id, to_char(current_date, 'YYYYMMDD')::int4);

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text ||
                           ' STARTED===', 0, 'O')
    into l_step_id;

    drop table if exists t_sor;

    -- parent level
    create temp table t_sor as
    select
        -- head
        staging.last_orig_order(in_order_id := cl.order_id) as first_order_id,
        cl.order_id                                         as parent_order_id,
        cl.order_id                                         as street_order_id,
        ''                                                  as exec_id,
        cl.create_date_id,

        -- Firm Details
        tf.trading_firm_name,
        tf.cat_imid                                         as firm_cat_imid,
        tf.cat_crd                                          as firm_cat_crd,

        -- Event Details
        'New Order'                                         as event_type,
        to_timestamp(fmj.tag_10061, 'YYYYMMDD-HH24:MI:SS')  as event_ts,
        cl.client_order_id                                  as parent_clorderid,
        null::text                                          as street_clorderid,
        cl.order_qty                                        as event_order_qty,
        cl.price                                            as event_price,
        mleg.price                                          as net_price,
        cl.multileg_reporting_type,
        mleg.no_legs,
        cl.multileg_order_id,
        '??'                                                as manual_flag,
        ex.text_,

        -- Order Detail
        os.order_status_description,
        orig.client_order_id                                as orig_client_order_id,
        cl.order_id,
        oc.opra_symbol,
        dos.root_symbol,
        di.symbol,
        di.instrument_type_id,
        ui.symbol                                           as underlying_symbol,
        case
            when di.instrument_type_id = 'E' then 'Stock'
            when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
            when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
            end                                             as pcv,
        di.last_trade_date                                  as expiration_ts,
        cl.side,
        dtif.tif_short_name                                 as tif,
        cl.expire_time                                      as good_till_ts,
        cl.order_qty,
        ex.cum_qty,
        ot.order_type_name,
        cl.price,
        cl.create_time                                      as order_creation_ts,
        cl.open_close,
        cl.exec_instruction,
        cl.cross_order_id,
        cl.fee_sensitivity,
        cl.stop_price,
        cl.max_floor,
        cof.customer_or_firm_name,
        cl.ex_destination,
        cl.ratio_qty,
        coalesce(fmj.tag_50, tag_109)                       as user_,

        -- Account Details
        ac.account_name,
        ac.account_id,
        ac.account_holder_type,
        ac.cat_fdid,
        case
            when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                then tf.cat_imid end                        as cat_imid,
        case
            when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid
                then ac.crd_number end                      as crd_number,
-- ac.broker_dealer_mpid,
        fc.sender_sub_id,

        -- Execution Details
        ex.last_mkt,
        exc.mic_code,
        ex.trade_liquidity_indicator
    -- CAT Details

    from dwh.client_order as cl
             left join dwh.client_order mleg
                       on (mleg.order_id = cl.orig_order_id and mleg.create_date_id >= cl.create_date_id)
             join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.text_,
                 ex.exchange_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id
            and ex.exec_date_id >= l_date_begin_id
          order by exec_id desc
          limit 1
        ) ex on true
             left join lateral (select orig.client_order_id
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                limit 1) orig on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             left join dwh.d_option_series dos
                       on oc.option_series_id = dos.option_series_id
             left join dwh.d_instrument ui
                       on ui.instrument_id = dos.underlying_instrument_id
             left join dwh.d_time_in_force dtif
                       on dtif.tif_id = cl.time_in_force_id
             left join lateral (select fix_message ->> '40'    as tag_40,
                                       fix_message ->> '50'    as tag_50,
                                       fix_message ->> '109'   as tag_109,
                                       fix_message ->> '58'    as tag_58,
                                       fix_message ->> '10061' as tag_10061
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = cl.fix_message_id
                                limit 1) fmj on true
             left join dwh.d_customer_or_firm cof
                       on cof.customer_or_firm_id = cl.customer_or_firm_id
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
             left join dwh.d_fix_connection fc
                       on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
    where cl.parent_order_id is null
      and case
              when coalesce(in_parent_order_ids, '{}') = '{}' then true
              else cl.order_id = any (in_parent_order_ids) end
      and cl.create_date_id between l_date_begin_id and l_date_end_id
      and case when coalesce(in_account_ids, '{}') = '{}' then true else ac.account_id = any (in_account_ids) end;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' counted ', l_row_cnt, 'O')
    into l_step_id;

    -- exec level
    insert into t_sor
    (first_order_id, parent_order_id, street_order_id, exec_id, create_date_id, trading_firm_name, firm_cat_imid,
     firm_cat_crd,
     event_type, event_ts, parent_clorderid, street_clorderid, event_order_qty, event_price, net_price,
     multileg_reporting_type, no_legs, multileg_order_id, manual_flag, text_, order_status_description,
     orig_client_order_id, order_id, opra_symbol, root_symbol, symbol, instrument_type_id, underlying_symbol, pcv,
     expiration_ts, side, tif, good_till_ts, order_qty, cum_qty, order_type_name, price, order_creation_ts, open_close,
     exec_instruction, cross_order_id, fee_sensitivity, stop_price, max_floor, customer_or_firm_name, ex_destination,
     ratio_qty, user_, account_name, account_id, account_holder_type, cat_fdid, cat_imid, crd_number,
     sender_sub_id, last_mkt, mic_code, trade_liquidity_indicator)

    select
        -- head
        cl.first_order_id,
        cl.parent_order_id                                                                      as parent_order_id,
        cl.order_id                                                                             as street_order_id,
        fmj.tag_17                                                                              as exec_id,
        cl.create_date_id                                                                       as create_date_id,
        -- Firm Details
        tf.trading_firm_name,
        tf.cat_imid                                                                             as firm_cat_imid,
        tf.cat_crd                                                                              as firm_cat_crd,

        -- Event Details
        'Execution'                                                                             as event_type,
        to_timestamp(fmj.tag_5050, 'YYYYMMDD-HH24:MI:SS')                                       as event_ts,
        cl.parent_clorderid                                                                     as parent_clorderid,
        cl.street_clorderid                                                                     as street_clorderid,
        ex.last_qty                                                                             as event_qty,
        ex.last_px                                                                              as event_price,
        null                                                                                    as net_price,
        cl.multileg_reporting_type,
        null,
        cl.multileg_order_id,
        '??'                                                                                    as manual_flag,
        ex.text_,

        -- Order Detail
        et.exec_type_description,
        cl.orig_client_order_id                                                                 as orig_client_order_id,
        cl.order_id,
        cl.opra_symbol,
        cl.root_symbol,
        cl.symbol,
        cl.instrument_type_id,
        cl.underlying_symbol,
        cl.pcv,
        cl.expiration_ts,
        cl.side,
        cl.tif,
        cl.good_till_ts,
        cl.order_qty,
        ex.cum_qty,
        cl.order_type_name,
        cl.price,
        cl.order_creation_ts,
        cl.open_close,
        cl.exec_instruction,
        cl.cross_order_id,
        cl.fee_sensitivity,
        cl.stop_price,
        cl.max_floor,
        cl.customer_or_firm_name,
        cl.ex_destination,
        cl.ratio_qty,
        cl.user_,

        -- Account Details
        ac.account_name,
        ac.account_id,
        ac.account_holder_type,
        ac.cat_fdid,
        case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then tf.cat_imid end   as cat_imid,
        case when ac.cat_fdid like ac.crd_number || '%:%' || tf.cat_imid then ac.crd_number end as crd,
-- ac.broker_dealer_mpid,
        cl.sender_sub_id,

        -- Execution Details
        ex.last_mkt,
        exc.mic_code,
        ex.trade_liquidity_indicator
    -- CAT Details
    from t_sor cl
             left join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
             left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.text_,
                 ex.last_qty,
                 ex.last_px,
                 ex.exchange_id,
                 ex.fix_message_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id -- hardcode to fix later
            and ex.exec_date_id >= l_date_begin_id
-- and ex.exec_type not in ('a', '5', 'A', 'S')
        ) ex on true
             left join dwh.d_order_status os on ex.order_status = os.order_status
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
             left join dwh.d_exec_type et on et.exec_type = ex.exec_type
             left join lateral (select fix_message ->> '17'   as tag_17,
                                       fix_message ->> '50'   as tag_50,
                                       fix_message ->> '109'  as tag_109,
                                       fix_message ->> '58'   as tag_58,
                                       fix_message ->> '5050' as tag_5050
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = ex.fix_message_id
                                limit 1) fmj on true
-- where cl.event_type = 'Order Route'
    ;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls exec level for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' counted ', l_row_cnt, 'O')
    into l_step_id;

    return query
        select rep.parent_order_id,                                                     -- as parent_order_id,

               -- Firm Details
               rep.trading_firm_name,                                                   -- as "Trading Firm Name",
               rep.firm_cat_imid,                                                       -- as "Trading Firm IMID",
               rep.firm_cat_crd,                                                        --  as "Trading Firm CRD",
               -- Event Details
               case when rep.exec_id is not null then rep.order_status_description end, -- as "Event Type",
               to_char(rep.event_ts, 'MM/DD/YYYY'),                                     -- as "Event Date",
               to_char(rep.event_ts, 'HH24:MI:SS.MS'),                                  -- as "Event Time",
               rep.parent_clorderid,                                                    -- as "Client clOrderID",
               rep.street_clorderid,                                                    -- as "Street clOrderID",
               rep.event_order_qty,                                                     -- as "Event Qty",
               rep.event_price,                                                         -- as "Event Price",
               rep.net_price,                                                           -- as "Net Price",
               case
                   when rep.multileg_reporting_type <> '1' then 'Y'
                   else 'N'
                   end,                                                                 -- as "Multi Leg Indicator",
               rep.no_legs,                                                             -- as "Number of legs",
               rep.multileg_order_id,                                                   -- as "Leg Order ID",
               rep.manual_flag,                                                         -- as "Manual Flag",
               rep.text_,                                                               -- as "Free Text",

               -- Order Detail
               case
                   when rep.exec_id is null
                       then rep.order_status_description end,                           -- as "Order Status",
               case
                   when rep.event_type = 'New Order'
                       then orig_client_order_id end,                                   -- as "Original Client clOrderID", 
               case
                   when rep.event_type = 'Order Route'
                       then orig_client_order_id end,                                   -- as "Original Street clOrderID", 
               rep.opra_symbol,                                                         -- as "OSI Symbol",
               rep.root_symbol,                                                         -- as "Base symbol",
               rep.symbol,                                                              -- as "Symbol",
               case rep.instrument_type_id
                   when 'O' then 'Option'
                   when 'E' then 'Equity'
                   else rep.instrument_type_id end,                                     -- as "Security Type",
               rep.underlying_symbol,                                                   -- as "Underlying Symbol",
               rep.pcv,                                                                 -- as "P/C/S",
               to_char(rep.expiration_ts, 'MM/DD/YYYY'),                                -- as "Expiration Date",
               to_char(rep.expiration_ts, 'HH24:MI:SS.MS'),                             -- as "Expiration Time",
               case
                   when rep.side = '1' then 'Buy'
                   when rep.side = '2' then 'Sell'
                   when rep.side in ('5', '6') then 'Sell Short'
                   end,                                                                 -- as "Side",
               rep.tif,                                                                 -- as "TIF",
               to_char(rep.good_till_ts, 'MM/DD/YYYY'),                                 -- as "Good Till Date",
               to_char(rep.good_till_ts, 'HH24:MI:SS.MS'),                              -- as "Good Till Time",
               rep.order_qty,                                                           -- as "Order Qty",
               rep.cum_qty,                                                             -- as "Filled Qty",
               rep.order_type_name,                                                     -- as "Order Type Code",
               rep.price,                                                               -- as "Order Price",
               to_char(rep.order_creation_ts, 'DD.MM.YYYY'),                            -- as "Order Creation Date",
               to_char(rep.order_creation_ts, 'HH24:MI:SS.MS'),                         -- as "Order Creation Time",
               rep.open_close,                                                          -- as "Open/Close",
               compliance.get_eq_sor_trading_session(in_order_id := rep.order_id,
                                                     in_date_id := rep.create_date_id), -- as "Trading Session",
               case
                   when rep.exec_instruction like '1%' then 'NH'
                   when rep.exec_instruction like '5%' then 'H'
                   else 'NH'
                   end,                                                                 -- as "Is Held",
               case when rep.cross_order_id is not null then 'Y' else 'N' end,          -- as "Is Cross",
               rep.fee_sensitivity,                                                     -- as "Fee Sensitivity",
               rep.stop_price,                                                          -- as "Stop Price",
               rep.max_floor,                                                           -- as "Max Floor",
               rep.customer_or_firm_name,                                               -- as "Capacity",
               rep.ex_destination,                                                      -- as "ExDestination",
               rep.ratio_qty,                                                           -- as "Leg ratio",
               rep.user_,                                                               -- as "User",

               -- Account Details
               rep.account_name,                                                        -- as "Account Name",
               rep.account_id,                                                          -- as "Account ID",
               rep.account_holder_type,                                                 -- as "Account Holder Type",
               rep.cat_fdid,                                                            -- as "Account FDID",
               null::text,                                                              -- as "Account IMID",
               rep.crd_number,                                                          -- as "Account CRD",
               rep.sender_sub_id,                                                       -- as "Sender type",

               -- Execution Details
               rep.last_mkt,                                                            -- as "Last Mkt",
               rep.mic_code,                                                            -- as "MIC Code",
               rep.trade_liquidity_indicator,                                           -- as "Liquidity Indicator",
               rep.exec_id,                                                             -- as "ExecutionID",

               -- CAT Details
               rep.cat_imid                                                             -- as "CAT Reporting Firm IMID"
--  ], ',', '')
        from t_sor rep
        order by coalesce(rep.first_order_id, rep.parent_order_id), rep.parent_order_id, rep.street_order_id, rep.exec_id nulls first;
    
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_obo_compliance_xls for ' || l_date_begin_id::text || ' - ' ||
                           l_date_end_id::text || ' FINISHED=== ', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;
alter function dash360.report_lpeod_aos_compliance rename to report_lpeod_aos_compliance_old;
alter function trash.report_lpeod_aos_compliance set schema dash360;