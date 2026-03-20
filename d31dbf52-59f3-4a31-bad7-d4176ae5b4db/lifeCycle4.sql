select *
from trash.so_dash_finra_inquiry(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                 in_include_routes := 'Y', in_include_acks := 'N',
                                 in_client_order_ids := '{"STS58450000425", "aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN", "20260106WEBUL473748", "20260106WEBUL467862", "10Z2612950942332", "10105039617582D1","STS58450000430"}');

select *
from trash.so_dash_finra_inquiry(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                 in_include_routes := 'Y', in_include_acks := 'Y',
                                 in_client_order_ids := '{"aV0jpDKHR5a6/KsCIlRQnA==_0a15hvN"}');

select *
from trash.so_dash_finra_inquiry(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                 in_include_routes := 'Y', in_include_acks := 'Y',
                                 in_client_order_ids := '{"DFIN:5KP600000G0006"}');

select *
from trash.so_dash_finra_inquiry(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                 in_include_routes := 'Y', in_include_acks := 'Y',
                                 in_client_order_ids := '{"DFIN:5KP600000G0006", "DFTD:20260106-00196-00009"}');

select *
from trash.so_dash_finra_inquiry(in_date_begin_id := 20260106, in_date_end_id := 20260106,
                                 in_include_routes := 'Y', in_include_acks := 'Y',
                                 in_client_order_ids := '{"EGAK9104-20260106"}');



drop function if exists trash.so_dash_finra_inquiry;
create or replace function trash.so_dash_finra_inquiry(in_date_begin_id integer, in_date_end_id integer,
                                                       in_instrument_type character DEFAULT NULL::bpchar,
                                                       in_account_ids integer[] DEFAULT '{}'::integer[],
                                                       in_parent_order_ids bigint[] DEFAULT '{}'::bigint[],
                                                       in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                       in_exclude_eos character DEFAULT 'Y'::bpchar,
                                                       in_include_routes character DEFAULT 'Y'::bpchar,
                                                       in_include_acks character DEFAULT 'Y'::bpchar,
                                                       in_fix_comp_ids character varying[] DEFAULT '{}'::character varying(30)[],
                                                       in_client_order_ids character varying[] DEFAULT '{}'::character varying(256)[])
    returns table
            (
                "OrderID"                   bigint,            -- 1
                "Trading Firm Name"         character varying,
                "Trading Firm IMID"         character varying,
                "Trading Firm CRD"          character varying,
                "Event Type"                text,              -- 5
                "Event Date"                text,
                "Event Time"                text,
                "Client clOrderID"          character varying,
                "Street clOrderID"          character varying,
                "Event Qty"                 integer,           -- 10
                "Event Price"               text,
                "Net Price"                 text,
                "Multi Leg Indicator"       text,
                "Number of legs"            integer,
                "Leg Order ID"              character varying, -- 15
                "Manual Flag"               text,
--                 "Free Text"                 text,
                "Order Status"              character varying,
                "Original Client clOrderID" character varying,
                "Original Street clOrderID" character varying, -- 20
                "OSI Symbol"                character varying,
                "Base symbol"               character varying,
                "Symbol"                    character varying,
                "Security Type"             character,
                "Underlying Symbol"         character varying, -- 25
                "P/C/S"                     text,
                "Expiration Date"           text,
                "Expiration Time"           text,
                "Side"                      text,
                "TIF"                       character varying, -- 30
                "Good Till Date"            text,
                "Good Till Time"            text,
                "Order Qty"                 integer,
                "Filled Qty"                bigint,
                "Order Type Code"           character varying, -- 35
                "Order Price"               text,
                "Order Creation Date"       text,
                "Order Creation Time"       text,
                "Open/Close"                character,
                "Trading Session"           character varying, --40
                "Is Held"                   character(1),
                "Is Cross"                  text,
                "Fee Sensitivity"           smallint,
                "Stop Price"                text,
                "Max Floor"                 bigint,            --45
                "Capacity"                  character varying,
                "ExDestination"             character varying,
                "Leg ratio"                 bigint,
                "User"                      text,
                "Account Name"              character varying, -- 50
                "Account ID"                integer,
                "Account Holder Type"       character varying,
                "Account FDID"              character varying,
                "Account IMID"              character varying,
                "Account CRD"               character varying, -- 55
                "Sender type"               text,
                "Last Mkt"                  character varying,
                "MIC Code"                  character varying,
                "Liquidity Indicator"       character varying,
                "ExecutionID"               text,              -- 60
                "CAT Reporting Firm IMID"   text,
                "Request Date"              text,
                "Request Time"              text,
                "Strike Price"              text,
                "Remaining Qty"             integer,           -- 65
                "Affiliated Flag"           character,
                "Solicitation Flag"         text
            )
    LANGUAGE plpgsql
AS
$fn$
declare
    l_load_id           int;
    l_step_id           int;
    l_date_begin_id     int4;
    l_date_end_id       int4;
    l_account_ids       int4[];
    l_retention_date_id int4;
    l_row_count         int4;
    l_script_name       text := 'finra inquiry report ';
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    l_date_begin_id := coalesce(in_date_begin_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_date_end_id := coalesce(in_date_end_id, to_char(current_date, 'YYYYMMDD')::int4);

    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text || ' STARTED===', 0,
                           'O')
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

    -- GTC date_id
    select coalesce(min(gtc.create_date_id), l_date_begin_id)
    into l_retention_date_id
    from dwh.gtc_order_status gtc
    where true
      and (gtc.close_date_id is null
        or gtc.close_date_id >= l_date_end_id)
      and case
              when coalesce(l_account_ids, '{}') = '{}' then true
              else gtc.account_id = any (l_account_ids) end
      and case
              when coalesce(in_client_order_ids, '{}') = '{}' then true
              else gtc.client_order_id = any (in_client_order_ids) end;

    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' min gtc date_id calculated', l_retention_date_id,
                           'C')
    into l_step_id;

-- parent orders
    drop table if exists t_order;
    create temp table t_order as
    select order_id                                                                              as first_order_id,
           cl.*,
           di.symbol,
           di.symbol_suffix,
           di.instrument_type_id,
           di.last_trade_date,
           ac.cat_report_on_behalf_of,
           tf.trading_firm_name,
           tf.cat_imid                                                                           as tf_cat_imid,
           tf.cat_crd                                                                            as tf_cat_crd,
           orig.client_order_id                                                                  as orig_client_order_id,
           orig.price                                                                            as orig_price,
           oc.opra_symbol,
           oc.strike_price,
           os.root_symbol,
           ui.symbol                                                                             as underlying_symbol,
           fmj.tag_58,
           fmj.tag_50,
           fmj.tag_109,
           case
               when di.instrument_type_id = 'E' then 'Stock'
               when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
               when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
               end                                                                               as pcv,
           dtif.tif_short_name                                                                   as tif,
           dot.order_type_name,
           case
               when tag_9281 in ('A', 'D', 'G') then 'ALL'
               when tag_22017 = 'A' then 'ALL'
               when tag_9281 in ('F', 'C') then 'REGPOST'
               when tag_22017 = 'B' then 'REGPOST'
               else 'REG' end                                                                    as trading_session,
           cof.customer_or_firm_name,
           ac.account_name,
           case when ac.is_broker_dealer is distinct from 'Y' then ac.account_holder_type end    as account_holder_type,
           case when ac.is_broker_dealer is distinct from 'Y' then ac.cat_fdid end               as ac_fdid,
           ac.crd_number,
           tf.cat_imid,
           ac.is_affiliate,
           case when ac.is_broker_dealer is not distinct from 'Y' then ac.broker_dealer_mpid end as ac_imid,
           ac.crd_number                                                                         as ac_number,
           case when ac.is_broker_dealer is not distinct from 'Y' then 'F' end                   as sender_type,
           fc.sender_sub_id,
           to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as order_request_time,
           to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as cancel_request_time,
           case when cl.ex_destination = 'DASH' then 'Y' else 'N' end                            as is_solicitation,
           to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as tag_5050,
           tag_17,
           ex.*,
           cl.client_order_id                                                                    as parent_client_order_id,
           dex.ex_destination_desc,
           fmj.tag_60 as tag60
    from dwh.client_order cl
             join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.exec_text,
                 ex.exchange_id as ex_exchange_id,
                 ex.secondary_exch_exec_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id
          order by exec_id desc
          limit 1
        ) ex on true
             left join lateral (select client_order_id, price
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                  and orig.create_date_id >= l_retention_date_id
                                limit 1) orig on cl.orig_order_id is not null
             left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
             left join d_option_series os on os.option_series_id = oc.option_series_id
             left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
             left join dwh.d_fix_connection fc
                       on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
             left join dwh.d_time_in_force dtif on dtif.tif_id = cl.time_in_force_id
             left join lateral (select fmj.fix_message ->> '5050'  as tag_5050,
                                       fmj.fix_message ->> '50'    as tag_50,
                                       fmj.fix_message ->> '109'   as tag_109,
                                       -- fmj.fix_message ->> '9000'  as tag_9000,
                                       fmj.fix_message ->> '58'    as tag_58,
                                       fmj.fix_message ->> '17'    as tag_17,
                                       -- fmj.fix_message ->> '52'    as tag_52,
                                       -- fmj.fix_message ->> '9291'  as tag_9291,
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
             left join dwh.d_order_type dot on dot.order_type_id = cl.order_type_id
             left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
--              left join dwh.d_ex_destination dex on dex.ex_destination_code = cl.ex_destination and dex.exchange_id = cl.exchange_id and dex.is_active
             left join dwh.d_ex_destination dex on (dex.ex_destination_code = cl.ex_destination and coalesce(dex.exchange_id, '') = coalesce(cl.exchange_id, '') and dex.instrument_type_id = di.instrument_type_id and dex.is_active)
    where cl.parent_order_id is null
      and cl.create_date_id between l_date_begin_id and l_date_end_id
      and case
              when coalesce(l_account_ids, '{}') = '{}' then true
              else cl.account_id = any (l_account_ids) end
      and case
              when coalesce(in_client_order_ids, '{}') = '{}' then true
              else cl.client_order_id = any (in_client_order_ids) end
      and case when in_instrument_type is null then true else di.instrument_type_id = in_instrument_type end
      and case when in_exclude_eos = 'N' then true else fc.is_high_frequency_trader = 'N' end
      and case when in_fix_comp_ids = '{}' then true else coalesce(fc.fix_comp_id, '') = any (in_fix_comp_ids) end
      and cl.trans_type <> 'F'
      and cl.trans_type in ('D', 'G')
      and cl.multileg_reporting_type in ('1', '2');
    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' parent orders added', l_row_count,
                           'I')
    into l_step_id;

    analyze t_order;

-- Street orders
    insert into t_order
    select cl.parent_order_id                                                                    as first_order_id,
           cl.*,
           di.symbol,
           di.symbol_suffix,
           di.instrument_type_id,
           di.last_trade_date,
           ac.cat_report_on_behalf_of,
           tf.trading_firm_name,
           tf.cat_imid                                                                           as tf_cat_imid,
           tf.cat_crd                                                                            as tf_cat_crd,
           orig.client_order_id                                                                  as orig_client_order_id,
           orig.price                                                                            as orig_price,
           oc.opra_symbol,
           oc.strike_price,
           os.root_symbol,
           ui.symbol                                                                             as underlying_symbol,
           fmj.tag_58,
           fmj.tag_50,
           fmj.tag_109,
           case
               when di.instrument_type_id = 'E' then 'Stock'
               when di.instrument_type_id = 'O' and oc.put_call = '1' then 'Call'
               when di.instrument_type_id = 'O' and oc.put_call = '0' then 'Put'
               end                                                                               as pcv,
           dtif.tif_short_name                                                                   as tif,
           dot.order_type_name,
           case
               when tag_9281 in ('A', 'D', 'G') then 'ALL'
               when tag_22017 = 'A' then 'ALL'
               when tag_9281 in ('F', 'C') then 'REGPOST'
               when tag_22017 = 'B' then 'REGPOST'
               else 'REG' end                                                                    as trading_session,
           cof.customer_or_firm_name,
           ac.account_name,
           case when ac.is_broker_dealer is distinct from 'Y' then ac.account_holder_type end    as account_holder_type,
           case when ac.is_broker_dealer is distinct from 'Y' then ac.cat_fdid end               as ac_fdid,
           ac.crd_number,
           tf.cat_imid,
           ac.is_affiliate,
           case when ac.is_broker_dealer is not distinct from 'Y' then ac.broker_dealer_mpid end as ac_imid,
           ac.crd_number                                                                         as ac_number,
           case when ac.is_broker_dealer is not distinct from 'Y' then 'F' end                   as sender_type,
           fc.sender_sub_id,
           to_timestamp(left(fmj.tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as order_request_time,
           to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as cancel_request_time,
           case when cl.ex_destination = 'DASH' then 'Y' else 'N' end                            as is_solicitation,
           to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                 as tag_5050,
           fmj.tag_17,
           ex.*,
           par.parent_client_order_id                                                            as parent_client_order_id,
           dex.ex_destination_desc,
           fmj.tag_60 as tag60
    from t_order par
             join dwh.client_order cl on cl.parent_order_id = par.order_id
             join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
             join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             left join lateral
        ( select ex.exec_id,
                 ex.order_status,
                 ex.exec_type,
                 ex.cum_qty,
                 ex.exec_time,
                 ex.last_mkt,
                 ex.trade_liquidity_indicator,
                 ex.exec_text,
                 ex.exchange_id as ex_exchange_id,
                 ex.secondary_exch_exec_id
          from dwh.execution ex
          where ex.order_id = cl.order_id
            and ex.exec_date_id >= cl.create_date_id
          order by exec_id desc
          limit 1
        ) ex on true
             left join lateral (select client_order_id, price
                                from dwh.client_order orig
                                where orig.order_id = cl.orig_order_id
                                  and orig.create_date_id <= cl.create_date_id
                                  and orig.create_date_id >= l_retention_date_id
                                limit 1) orig on cl.orig_order_id is not null
             left join dwh.d_option_contract oc on di.instrument_id = oc.instrument_id
             left join d_option_series os on os.option_series_id = oc.option_series_id
             left join dwh.d_instrument ui on os.underlying_instrument_id = ui.instrument_id
             left join dwh.d_fix_connection fc
                       on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
             left join dwh.d_time_in_force dtif on dtif.tif_id = cl.time_in_force_id
             left join lateral (select fmj.fix_message ->> '5050'  as tag_5050,
                                       fmj.fix_message ->> '50'    as tag_50,
                                       fmj.fix_message ->> '109'   as tag_109,
                                       -- fmj.fix_message ->> '9000'  as tag_9000,
                                       fmj.fix_message ->> '58'    as tag_58,
                                       fmj.fix_message ->> '17'    as tag_17,
                                       -- fmj.fix_message ->> '52'    as tag_52,
                                       -- fmj.fix_message ->> '9291'  as tag_9291,
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
             left join dwh.d_order_type dot on dot.order_type_id = cl.order_type_id
             left join dwh.d_customer_or_firm cof on cof.customer_or_firm_id = cl.customer_or_firm_id
             left join dwh.d_ex_destination dex on (dex.ex_destination_code = cl.ex_destination and coalesce(dex.exchange_id, '') = coalesce(cl.exchange_id, '') and dex.instrument_type_id = di.instrument_type_id and dex.is_active)
    where cl.parent_order_id is not null
      and cl.create_date_id between l_date_begin_id and l_date_end_id;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' street orders added', l_row_count,
                           'I')
    into l_step_id;

    analyze t_order;

    drop table if exists t_event;
    create temp table t_event as
    select b.first_order_id,
           b.order_id,
           -----
           b.orig_client_order_id,
           4 + row_number() over (partition by b.order_id order by ex.exec_id)                     as rn,
           b.co_client_leg_ref_id,
           b.parent_client_order_id                                                                as parent_client_order_id,
           fmj.tag_17                                                                              as exec_id,
           b.trading_firm_name                                                                     as trading_firm_name,
           b.tf_cat_imid                                                                           as tf_cat_imid,
           b.tf_cat_crd                                                                            as tf_cat_crd,
--        ex.exec_type,
--        et.exec_type_description,
           case
               when ex.exec_type in ('A', '0', '5') then 'Order Ack'
               when ex.exec_type = '4' then 'Cancelled'
               else et.exec_type_description end                                                   as event_type,
           case
               when ex.exec_type in ('A', '0', '5', 's') then
                   b.tag_5050
               when ex.exec_type = '4' then
                   ex.exec_time::timestamp
               else
                   to_timestamp(left(fmj.tag_5050, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone 'UTC'
               end                                                                                 as event_ts,
           b.client_order_id                                                                       as street_client_order_id,
           b.order_qty                                                                             as event_qty,
           b.price                                                                                 as event_price,
           b.orig_price                                                                            as net_price,
           b.multileg_reporting_type                                                               as multileg_indicator,
           b.no_legs,
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
                                                     from t_order
                                                     where t_order.multileg_order_id = b.order_id
                                                     limit 1)
               else b.underlying_symbol end                                                        as underlying_symbol,
           b.pcv,
           coalesce(b.last_trade_date, ex.exec_time)                                               as expiration_ts,
           b.side,
           b.tif,
           case when b.time_in_force_id = '6' then b.expire_time end                               as good_till_ts, -- Good Till Date: Should only be set when the Order Type is GTD
           ex.cum_qty                                                                              as cum_qty,

           b.order_type_name,
           ex.exec_time                                                                            as order_creation_ts,
           b.open_close,
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
           b.ex_destination_desc                                                                   as ex_destination_desc,
           b.ratio_qty,
           coalesce(fmj.tag_50, fmj.tag_109, b.account_name)                                       as user_,
           b.account_name                                                                          as account_name,
           b.account_id                                                                            as account_id,
           b.account_holder_type,
           b.ac_fdid,
           b.ac_imid,
           b.ac_number,
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
           to_timestamp(left(nxt.nxt_tag_60, 24), 'YYYYMMDD-HH24:MI:SS:US')::timestamp at time zone
           'UTC'                                                                                   as cancel_request_time,
           strike_price,
           b.order_qty - coalesce(ex.cum_qty, 0)                                                   as remaining_qty,
           b.is_affiliate,
           null                                                                                    as solicitation
    from t_order b
             join dwh.execution ex
                  on ex.order_id = b.order_id and ex.exec_date_id >= b.create_date_id
--                   and ex.exec_type not in ('a', 'A', 'S', '0')
             left join dwh.d_account ac on b.account_id = ac.account_id and ac.is_active
             left join dwh.d_trading_firm tf on b.trading_firm_unq_id = tf.trading_firm_unq_id

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
             left join lateral (select fmj.fix_message ->> '60' as nxt_tag_60
                                from dwh.client_order nxt
                                         join fix_capture.fix_message_json fmj
                                              on fmj.fix_message_id = nxt.fix_message_id and
                                                 fmj.date_id = nxt.create_date_id
                                where nxt.create_date_id >= b.create_date_id
                                  and nxt.orig_order_id = b.order_id
                                  and nxt.create_date_id >= l_date_begin_id
                                  and nxt.create_date_id <= l_date_end_id
                                limit 1) nxt on (ex.exec_type = '4' or ex.order_status = '4')
             left join dwh.d_order_status os on ex.order_status = os.order_status
             join dwh.d_exec_type et on et.exec_type = ex.exec_type
             left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
    where b.parent_order_id is not null
      and ex.exec_type = 'F';

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' route events added', l_row_count,
                           'I')
    into l_step_id;

    analyze t_event;

    -- Result
    drop table if exists t_result;
    create temp table if not exists t_result as
        -- Orders
    select x.first_order_id,
           x.order_id                                                                                                 as "OrderID",
           x.orig_client_order_id,
           x.rn,
           trading_firm_name                                                                                          as "Trading Firm Name",
           tf_cat_imid                                                                                                as "Trading Firm IMID",
           tf_cat_crd                                                                                                 as "Trading Firm CRD",
           case
               when rn in (0, 1) then order_type_value
               when x.exec_type = 'X' then 'Order Cancel'
               else 'Order Route' end                                                                                 as "Event Type",
           to_char(x.process_time, 'MM/DD/YYYY')                                                                      as "Event Date",
           to_char(x.process_time, 'HH24:MI:SS:US')                                                                   as "Event Time",
           x.parent_client_order_id                                                                                   as "Client clOrderID",
           case
               when rn in (0, 1) then null
               else x.client_order_id end                                                                             as "Street clOrderID",
           x.order_qty                                                                                                as "Event Qty",
           to_char(x.price, 'FM99999990D0099')                                                                        as "Event Price",
           case
               when x.exec_type != 'X'
                   then to_char(x.orig_price, 'FM99999990D0099') end                                                  as "Net Price",
           case
               when x.multileg_reporting_type <> '1' then 'Y'
               else 'N'
               end                                                                                                    as "Multi Leg Indicator",
           no_legs                                                                                                    as "Number of legs",
           co_client_leg_ref_id                                                                                       as "Leg Order ID",
           'false'                                                                                                    as "Manual Flag",
           x.tag_58                                                                                                   as "Free Text",
           -- Order Detail

           case when rn != 1 then order_status_description end                                                        as "Order Status",
           case
               when rn = 0
                   then orig_client_order_id end                                                                      as "Original Client clOrderID",
           case
               when rn > 1
                   then orig_client_order_id end                                                                      as "Original Street clOrderID",
           opra_symbol                                                                                                as "OSI Symbol",
           root_symbol                                                                                                as "Base symbol",
           symbol                                                                                                     as "Symbol",
           case x.instrument_type_id
               when 'O' then 'Option'
               when 'E' then 'Equity'
               else x.instrument_type_id end                                                                          as "Security Type",

           underlying_symbol                                                                                          as "Underlying Symbol",
           pcv                                                                                                        as "P/C/S",
           to_char(last_trade_date, 'MM/DD/YYYY')                                                                     as "Expiration Date",
           to_char(last_trade_date, 'HH24:MI:SS.MS')                                                                  as "Expiration Time",
           case
               when side = '1' then 'Buy'
               when side = '2' then 'Sell'
               when side in ('5', '6') then 'Sell Short'
               end                                                                                                    as "Side",
           tif                                                                                                        as "TIF",
           case
               when time_in_force_id = '6'
                   then to_char(coalesce(x.last_trade_date, x.expire_time), 'MM/DD/YYYY') end                         as "Good Till Date",
           case
               when time_in_force_id = '6' then to_char(coalesce(x.last_trade_date, x.expire_time),
                                                        'HH24:MI:SS.MS') end                                          as "Good Till Time",
           order_qty                                                                                                  as "Order Qty",
           case when rn != 1 then x.cum_qty end                                                                       as "Filled Qty",
           order_type_name                                                                                            as "Order Type Code",
           to_char(price, 'FM99999990D0099')                                                                          as "Order Price",
           to_char(process_time, 'MM/DD/YYYY')                                                                        as "Order Creation Date",
           to_char(process_time, 'HH24:MI:SS.US')                                                                     as "Order Creation Time",
           open_close                                                                                                 as "Open/Close",
           trading_session::varchar                                                                                   as "Trading Session",
           is_held                                                                                                    as "Is Held",
           case
               when x.cross_order_id is not null then 'Y'
               else 'N' end                                                                                           as "Is Cross",
           fee_sensitivity                                                                                            as "Fee Sensitivity",
           to_char(stop_price, 'FM99999990D0099')                                                                     as "Stop Price",
           max_floor                                                                                                  as "Max Floor",
           case when rn = 0 then customer_or_firm_name end                                                            as "Capacity",                -- Capacity: Only on New Orders as it does not change
           ex_destination_desc                                                                                        as "ExDestination",
           ratio_qty                                                                                                  as "Leg ratio",
           coalesce(x.tag_50, x.tag_109, x.account_name)                                                              as "User",

-- Account Details
           account_name                                                                                               as "Account Name",
           account_id                                                                                                 as "Account ID",
           account_holder_type                                                                                        as "Account Holder Type",
           ac_fdid                                                                                                    as "Account FDID",
           ac_imid                                                                                                    as "Account IMID",
           ac_number                                                                                                  as "Account CRD",
           sender_type                                                                                                as "Sender Type",

           -- Execution Details
           case
               when rn < 0
                   then x.last_mkt end                                                                                as "Last Mkt",                -- Last Market: Should be set only on Trades (remove from ACK)
           case
               when rn > 0
                   then mic_code end                                                                                  as "MIC Code",
           case
               when rn < 0
                   then trade_liquidity_indicator end                                                                 as "Liquidity Indicator",     -- Should be set only on Trades (remove from Order Route)
           tag_17                                                                                                     as "ExecutionID",
           'DFIN'                                                                                                     as "CAT Reporting Firm IMID", -- CAT Reporting Firm IMID: Should be DFIN or empty on Trades
           to_char(case
                       when rn in (0, 1) and trans_type = 'D' then null
                       when x.exec_type = 'X' then cancel_request_time
--                        when event_type ilike '%modify%' then order_request_time
                       else order_request_time
                       end,
                   'MM/DD/YYYY')                                                                                      as "Request Date",
           to_char(case
                       when rn in (0, 1) and trans_type = 'D'  then null
                       when x.exec_type = 'X' then cancel_request_time
--                        when event_type ilike '%modify%' then order_request_time
                       else order_request_time
                       end,
                   'HH24:MI:SS.US')                                                                                   as "Request Time",

           to_char(strike_price, 'FM99999990D0099')                                                                   as "Strike Price",
           case
               when rn != 1 then order_qty
               end                                                                                                    as "Remaining Qty",
           is_affiliate                                                                                               as "Affiliated Flag",
           case
               when rn not in (1, 3)
                   then is_solicitation end                                                                           as "Solicitation Flag"        -- Ack and Routes empty
    from (
-- Real order
             select case when trans_type = 'D' then 'New' when trans_type = 'G' then 'Modify' end as order_type_value, tb.*, 0 as rn
             from t_order tb
             where tb.parent_order_id is null
-- Syntetic row
             union all
             select case when trans_type = 'D' then 'Ack' when trans_type = 'G' then 'Modify Ack' end as order_type_value,
                    tb.*,
                    1
             from t_order tb
             where tb.parent_order_id is null
               and in_include_acks = 'Y'

             union all
-- Street orders
             select 'Street', tb.*, 3
             from t_order tb
             where tb.parent_order_id is not null) x
             left join dwh.d_order_status os on x.order_status = os.order_status
             left join dwh.d_exec_type et on et.exec_type = x.exec_type
             left join dwh.d_exchange exc on exc.exchange_id = x.ex_exchange_id and exc.is_active;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' orders added into result table', l_row_count,
                           'I')
    into l_step_id;


    insert into t_result
-- executions
    select first_order_id,
           order_id                                                               as "OrderID",
           orig_client_order_id,
           rn,
           trading_firm_name                                                      as "Trading Firm Name",
           tf_cat_imid                                                            as "Trading Firm IMID",
           tf_cat_crd                                                             as "Trading Firm CRD",
           event_type                                                             as "Event Type",
           to_char(event_ts, 'MM/DD/YYYY')                                        as "Event Date",
           case
               when event_type = 'Cancelled' then coalesce(to_char(event_ts, 'HH24:MI:SS:MS'), '')
               else coalesce(to_char(event_ts, 'HH24:MI:SS:US'), '') end          as "Event Time",
           parent_client_order_id                                                 as "Client clOrderID",
           street_client_order_id                                                 as "Street clOrderID",
           event_qty                                                              as "Event Qty",
           to_char(event_price, 'FM99999990D0099')                                as "Event Price",
           to_char(net_price, 'FM99999990D0099')                                  as "Net Price",
           case
               when multileg_indicator <> '1' then 'Y'
               else 'N'
               end                                                                as "Multi Leg Indicator",
           no_legs                                                                as "Number of legs",
           co_client_leg_ref_id                                                   as "Leg Order ID",
           manual_flag                                                            as "Manual Flag",
           exec_text                                                              as "Free Text",
           -- Order Detail
           order_status_description                                               as "Order Status",
           case
               when event_type = 'New Order' then null
               else orig_client_order_id end                                      as "Original Client clOrderID",
           case
               when event_type = 'Order Route'
                   then orig_client_order_id end                                  as "Original Street clOrderID",
           opra_symbol                                                            as "OSI Symbol",
           root_symbol                                                            as "Base symbol",
           symbol                                                                 as "Symbol",
           case instrument_type_id
               when 'O' then 'Option'
               when 'E' then 'Equity'
               else instrument_type_id               end                          as "Security Type",

           underlying_symbol                                                      as "Underlying Symbol",
           pcv                                                                    as "P/C/S",
           to_char(expiration_ts, 'MM/DD/YYYY')                                   as "Expiration Date",
           to_char(expiration_ts, 'HH24:MI:SS.MS')                                as "Expiration Time",
           case
               when side = '1' then 'Buy'
               when side = '2' then 'Sell'
               when side in ('5', '6') then 'Sell Short'
               end                                                                as "Side",
           tif                                                                    as "TIF",
           to_char(good_till_ts, 'MM/DD/YYYY')                                    as "Good Till Date",
           to_char(good_till_ts, 'HH24:MI:SS.MS')                                 as "Good Till Time",
           event_qty                                                              as "Order Qty",
           cum_qty                                                                as "Filled Qty",
           order_type_name                                                        as "Order Type Code",
           to_char(event_price, 'FM99999990D0099')                                as "Order Price",
           to_char(order_creation_ts, 'MM/DD/YYYY')                               as "Order Creation Date",
--            to_char(order_creation_ts, 'HH24:MI:SS.US')                   as "Order Creation Time",
           to_char(order_creation_ts, 'HH24:MI:SS:US')                            as "Order Creation Time", -- Creation time: Please set to the same format as event Time
           open_close                                                             as "Open/Close",
           trading_session::varchar                                               as "Trading Session",
           is_held                                                                as "Is Held",
           is_cross                                                               as "Is Cross",
           fee_sensitivity                                                        as "Fee Sensitivity",
           to_char(stop_price, 'FM99999990D0099')                                 as "Stop Price",
           max_floor                                                              as "Max Floor",
           null                                                                   as "Capacity",
           ex_destination_desc                                                    as "ExDestination",
           ratio_qty                                                              as "Leg ratio",
           user_                                                                  as "User",

-- Account Details
           account_name                                                           as "Account Name",
           account_id                                                             as "Account ID",
           account_holder_type                                                    as "Account Holder Type",
           ac_fdid                                                                as "Account FDID",
           ac_imid::text                                                          as "Account IMID",
           ac_number                                                              as "Account CRD",
           sender_sub_id                                                          as "Sender Type",

           -- Execution Details
           last_mkt                                                               as "Last Mkt",
           mic_code                                                               as "MIC Code",
           trade_liquidity_indicator                                              as "Liquidity Indicator",
           exec_id                                                                as "ExecutionID",
           null                                                                   as "CAT Reporting Firm IMID",
           to_char(case
                       when event_type = 'Cancelled' then cancel_request_time
                       when event_type ilike '%modify%' then order_request_time
                       end, 'MM/DD/YYYY')                                         as "Request Date",
           to_char(case
                       when event_type = 'Cancelled' then cancel_request_time
                       when event_type ilike '%modify%' then order_request_time
                       end, 'HH24:MI:SS.US')                                      as "Request Time",
           to_char(strike_price, 'FM99999990D0099')                               as "Strike Price",
           case
               when event_type = 'New Order' then event_qty
               when event_type = 'Trade' then remaining_qty end                   as "Remaining Qty",
           is_affiliate                                                           as "Affiliated Flag",
           solicitation                                                           as "Solicitation Flag"
    from t_event x
    where case when exec_type in ('A', '0', '5', 'b') and event_ts is null then false else true end;

    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' events added into result table', l_row_count,
                           'I')
    into l_step_id;

    create index on t_result (first_order_id, rn, "OrderID");
    get diagnostics l_row_count = row_count;
    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text ||
                           ' result table indexed', l_row_count,
                           'I')
    into l_step_id;

    return query
        select tr."OrderID",
               tr."Trading Firm Name",
               tr."Trading Firm IMID",
               tr."Trading Firm CRD",
               tr."Event Type",
               tr."Event Date",
               tr."Event Time",
               tr."Client clOrderID",
               tr."Street clOrderID",
               tr."Event Qty",
               tr."Event Price",
               tr."Net Price",
               tr."Multi Leg Indicator",
               tr."Number of legs",
               tr."Leg Order ID",
               tr."Manual Flag",
--                tr."Free Text",
               tr."Order Status",
               tr."Original Client clOrderID",
               tr."Original Street clOrderID",
               tr."OSI Symbol",
               tr."Base symbol",
               tr."Symbol",
               tr."Security Type",
               tr."Underlying Symbol",
               tr."P/C/S",
               tr."Expiration Date",
               tr."Expiration Time",
               tr."Side",
               tr."TIF",
               tr."Good Till Date",
               tr."Good Till Time",
               tr."Order Qty",
               tr."Filled Qty",
               tr."Order Type Code",
               tr."Order Price",
               tr."Order Creation Date",
               tr."Order Creation Time",
               tr."Open/Close",
               tr."Trading Session",
               tr."Is Held",
               tr."Is Cross",
               tr."Fee Sensitivity",
               tr."Stop Price",
               tr."Max Floor",
               tr."Capacity",
               tr."ExDestination",
               tr."Leg ratio",
               tr."User",
               tr."Account Name",
               tr."Account ID",
               tr."Account Holder Type",
               tr."Account FDID",
               tr."Account IMID",
               tr."Account CRD",
               tr."Sender Type",
               tr."Last Mkt",
               tr."MIC Code",
               tr."Liquidity Indicator",
               tr."ExecutionID",
               tr."CAT Reporting Firm IMID",
               tr."Request Date",
               tr."Request Time",
               tr."Strike Price",
               tr."Remaining Qty",
               tr."Affiliated Flag",
               tr."Solicitation Flag"
        from t_result as tr
        order by first_order_id, rn, "OrderID";

    select public.load_log(l_load_id, l_step_id,
                           l_script_name || l_date_begin_id::text || '-' || l_date_end_id::text || ' COMPLETED===', 0,
                           'C')
    into l_step_id;
end ;
$fn$;

select tif, *
from t_order;

select *
from t_result as tr
order by first_order_id, rn, "OrderID";

select * from t_event

select ex_destination, exchange_id, instrument_type_id, * from t_order
select ex_destination, exchange_id, *
from dwh.client_order
where order_id in (408797182017002287, 408797182017002288)


        select tr."OrderID",
               tr."Trading Firm Name",
               tr."Trading Firm IMID",
               tr."Trading Firm CRD",
               tr."Event Type",
               tr."Event Date",
               tr."Event Time",
               tr."Client clOrderID",
               tr."Street clOrderID",
               tr."Event Qty",
               tr."Event Price",
               tr."Net Price",
               tr."Multi Leg Indicator",
               tr."Number of legs",
               tr."Leg Order ID",
               tr."Manual Flag",
               tr."Free Text",
               tr."Order Status",
               tr."Original Client clOrderID",
               tr."Original Street clOrderID",
               tr."OSI Symbol",
               tr."Base symbol",
               tr."Symbol",
               tr."Security Type",
               tr."Underlying Symbol",
               tr."P/C/S",
               tr."Expiration Date",
               tr."Expiration Time",
               tr."Side",
               tr."TIF",
               tr."Good Till Date",
               tr."Good Till Time",
               tr."Order Qty",
               tr."Filled Qty",
               tr."Order Type Code",
               tr."Order Price",
               tr."Order Creation Date",
               tr."Order Creation Time",
               tr."Open/Close",
               tr."Trading Session",
               tr."Is Held",
               tr."Is Cross",
               tr."Fee Sensitivity",
               tr."Stop Price",
               tr."Max Floor",
               tr."Capacity",
               tr."ExDestination",
               tr."Leg ratio",
               tr."User",
               tr."Account Name",
               tr."Account ID",
               tr."Account Holder Type",
               tr."Account FDID",
               tr."Account IMID",
               tr."Account CRD",
               tr."Sender Type",
               tr."Last Mkt",
               tr."MIC Code",
               tr."Liquidity Indicator",
               tr."ExecutionID",
               tr."CAT Reporting Firm IMID",
               tr."Request Date",
               tr."Request Time",
               tr."Strike Price",
               tr."Remaining Qty",
               tr."Affiliated Flag",
               tr."Solicitation Flag"
        from t_result as tr
        order by first_order_id, rn, "OrderID";


