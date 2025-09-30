-- dash360.report_surveillance_socgen_acct_mgr_capacity_change(in_start_date_id, in_end_date_id, in_trading_firm_ids, in_account_ids)


create or replace function dash360.report_surveillance_socgen_acct_mgr_capacity_change(in_start_date_id int4,
                                                                            in_end_date_id int4,
                                                                            in_trading_firm_ids character varying(9)[] default '{"socgenpsc","socgeneqd"}',
                                                                            in_account_ids int4[] default '{}'::int4[])
    returns table
            (
                "Trading Firm"              character varying(60),
                "Account"                   character varying(30),
                "Sub Account"               character varying(10),
                "Original Account Capacity" character varying(255),
                "Modified Account Capacity" character varying(255),
                "Modification Date"         text
            )
    language plpgsql
AS
$function$
-- 20250929 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6730
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
    l_start_date date := in_start_date_id::text::date;
    l_end_date date := in_end_date_id::text::date;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_acct_mgr_capacity_change for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    return query
        with cte_sa1 as (select sa.account_id, sa.opt_customer_or_firm, cf.customer_or_firm_name
                         from dwh.d_sg_account sa
                                  join dwh.d_account a on (a.account_id = sa.account_id)
                             --join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                                  left join dwh.d_customer_or_firm cf
                                            on (cf.customer_or_firm_id = sa.opt_customer_or_firm)
                         where sa.date_start::date between l_start_date and l_end_date
                           and case
                                   when coalesce(in_trading_firm_ids, '{}'::character varying(9)[]) =
                                        '{}'::character varying(9)[] then true
                                   else a.trading_firm_id = any (in_trading_firm_ids) end
                           and case
                                   when coalesce(in_account_ids, '{}'::int4[]) = '{}'::int4[] then true
                                   else sa.account_id = any (in_account_ids) end
                           and not sa.is_active),
             cte_sa2 as (select sa.account_id,
                                a.trading_firm_id,
                                tf.trading_firm_name,
                                a.account_name,
                                sa.sg_sub_account,
                                sa.opt_customer_or_firm,
                                cf.customer_or_firm_name,
                                sa.date_start
                         from dwh.d_sg_account sa
                                  join dwh.d_account a on (a.account_id = sa.account_id)
                                  join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                                  left join dwh.d_customer_or_firm cf
                                            on (cf.customer_or_firm_id = sa.opt_customer_or_firm)
                         where sa.date_start::date between l_start_date and l_end_date
                           and case
                                   when coalesce(in_trading_firm_ids, '{}'::character varying(9)[]) =
                                        '{}'::character varying(9)[] then true
                                   else a.trading_firm_id = any (in_trading_firm_ids) end
                           and case
                                   when coalesce(in_account_ids, '{}'::int4[]) = '{}'::int4[] then true
                                   else sa.account_id = any (in_account_ids) end
                           and sa.is_active)
        select sa2.trading_firm_name                 as "Trading Firm",
               sa2.account_name                      as "Account",
               sa2.sg_sub_account                    as "Sub Account",
               sa1.customer_or_firm_name             as "Original Account Capacity",
               sa2.customer_or_firm_name             as "Modified Account Capacity",
               to_char(sa2.date_start, 'MM/DD/YYYY') as "Modification Date"
        from cte_sa1 sa1
                 join cte_sa2 sa2 on (sa2.account_id = sa1.account_id)
        where sa1.opt_customer_or_firm is distinct from sa2.opt_customer_or_firm
        order by sa2.trading_firm_id, sa2.account_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_acct_mgr_capacity_change for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ===',
                           l_row_cnt, 'C')
    into l_step_id;

end ;
$function$;

select * from dash360.report_surveillance_socgen_acct_mgr_capacity_change(20250901, 20250930);



create or replace function dash360.report_surveillance_socgen_ord_capacity_conflict(in_start_date_id int4,
                                                                                    in_end_date_id int4,
                                                                                    in_trading_firm_ids character varying(9)[] default '{"socgenpsc","socgeneqd"}',
                                                                                    in_account_ids int4[] default '{}'::int4[])
    returns table
            (
                "Trading Firm"                 varchar(60),
                "Account"                      varchar(30),
                "Sub Account"                  text,
                "Cl Ord ID"                    varchar(256),
                "Create Date"                  text,
                "Create Time"                  text,
                "FIX Comp ID"                  varchar(30),
                "Acceptor ID"                  varchar(30),
                "Sec Type"                     text,
                "Symbol"                       varchar(100),
                "Side"                         text,
                "O/C"                          text,
                "Order Qty"                    int4,
                "Price"                        numeric(12, 4),
                "Exchange Name"                varchar,
                "Acct Mgr Configured Capacity" varchar(255),
                "Order Routed Capacity"        varchar(255)
            )
    language plpgsql
AS
$function$
-- 20250929 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6730
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_ord_capacity_conflict for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where true
      and case
              when coalesce(in_trading_firm_ids, '{}'::varchar[]) <> '{}'::varchar[]
                  then trading_firm_id = ANY (in_trading_firm_ids)
              else true end
      and case
              when coalesce(in_account_ids, '{}'::integer[]) <> '{}'::integer[] then account_id = ANY (in_account_ids)
              else true end;

    return query
        select tf.trading_firm_name                       as "Trading Firm",
               a.account_name                             as "Account",
               --case when fmpo.fix_message->>'10701' is not null then concat(a.account_name, '_', fmpo.fix_message->>'10701') end as "Sub Account",
               fmpo.fix_message ->> '10701'               as "Sub Account",
               co.client_order_id                         as "Cl Ord ID",
               to_char(co.create_time, 'MM/DD/YYYY')      as "Create Date",
               to_char(co.create_time, 'HH24:MI:SS.US')   as "Create Time",
               fc.fix_comp_id                             as "FIX Comp ID",
               fc.acceptor_id                             as "Acceptor ID",
               case
                   when hsd.instrument_type_id = 'E' then 'Equity'
                   when hsd.instrument_type_id = 'O' then 'Option'
                   end                                    as "Sec Type",
               hsd.display_instrument_id                  as "Symbol",
               --to_char(hsd.maturity_date, 'MM/DD/YYYY') as "Expiration",
               case
                   when co.side = '1' then 'Buy'
                   when co.side = '2' then 'Sell'
                   when co.side in ('5', '6') then 'Sell Short'
                   end                                    as "Side",
               case
                   when co.open_close = 'O' then 'Open'
                   when co.open_close = 'C' then 'Close'
                   end                                    as "O/C",
               co.order_qty                               as "Order Qty",
               co.price                                   as "Price",
               coalesce(ex.exchange_name, co.exchange_id) as "Exchange Name",
               --co.clearing_account as "Clearing Account",
               --co.sub_account as "Sub Account",
               cfa.customer_or_firm_name                  as "Acct Mgr Configured Capacity",
               cfo.customer_or_firm_name                  as "Order Routed Capacity"
        from dwh.client_order co
                 join dwh.d_account a on (a.account_id = co.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = co.instrument_id)
                 left join dwh.d_customer_or_firm cfo on (cfo.customer_or_firm_id = co.customer_or_firm_id)
                 left join dwh.d_customer_or_firm cfa on (cfa.customer_or_firm_id = a.opt_customer_or_firm)
                 left join dwh.d_fix_connection fc on (fc.fix_connection_id = co.fix_connection_id)
                 left join dwh.d_exchange ex on (ex.exchange_id = co.exchange_id and ex.is_active)
                 left join dwh.client_order po on (po.create_date_id between in_start_date_id and in_end_date_id
            and po.create_date_id = co.create_date_id
            and po.order_id = co.parent_order_id)
--left join fix_capture.fix_message_json fmo on (fmo.date_id = co.create_date_id and fmo.fix_message_id = co.fix_message_id)
                 left join fix_capture.fix_message_json fmpo
                           on (fmpo.date_id between in_start_date_id and in_end_date_id
                               and fmpo.date_id = co.create_date_id
                               and fmpo.fix_message_id = po.fix_message_id)
        where co.create_date_id between in_start_date_id and in_end_date_id
          and a.account_id = any (in_account_ids)
          and co.parent_order_id is not null
          and co.multileg_reporting_type in ('1', '2')
          and co.customer_or_firm_id != a.opt_customer_or_firm
          and a.opt_customer_or_firm is not null
          and co.customer_or_firm_id is not null
        --and fc.acceptor_id ilike 'fastlb%'
        order by co.create_date_id, co.client_order_id, co.order_id;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_ord_capacity_conflict for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ===',
                           l_row_cnt, 'C')
    into l_step_id;

end ;
$function$;

select * from dash360.report_surveillance_socgen_ord_capacity_conflict(20250925, 20250926);



create or replace function dash360.report_surveillance_socgen_pta_capacity_mismatch(in_start_date_id int4,
                                                                                    in_end_date_id int4,
                                                                                    in_trading_firm_ids character varying(9)[] default '{"socgenpsc","socgeneqd"}',
                                                                                    in_account_ids int4[] default '{}'::int4[])
    returns table
            (
                "Trading Firm"            varchar(60),
                "Account"                 varchar(30),
                "Sub Account"             text,
                "Cl Ord ID"               varchar(256),
                "Date"                    text,
                "Time"                    text,
                "Symbol"                  varchar(100),
                "Side"                    text,
                "O/C"                     text,
                "Last Qty"                int4,
                "Last Px"                 numeric(16, 8),
                "Exchange Name"           varchar,
                "Exec Broker"             varchar(32),
                "CMTA"                    varchar(3),
                "Client ID"               varchar(255),
                "Remarks"                 varchar(100),
                "Trade Record Reason"     bpchar(1),
                "Original Order Capacity" varchar(255),
                "Modified Order Capacity" varchar(255)
            )
    language plpgsql
AS
$function$
-- 20250929 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6730
declare
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_pta_capacity_mismatch for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where true
      and case
              when coalesce(in_trading_firm_ids, '{}'::varchar[]) <> '{}'::varchar[]
                  then trading_firm_id = ANY (in_trading_firm_ids)
              else true end
      and case
              when coalesce(in_account_ids, '{}'::integer[]) <> '{}'::integer[] then account_id = ANY (in_account_ids)
              else true end;

    return query
        with cte_tr1 as (select tr.date_id,
                                tr.order_id,
                                tr.exec_id,
                                tr.trade_record_id,
                                tr.opt_customer_firm,
                                cf.customer_or_firm_name
                         from dwh.flat_trade_record tr
                                  left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = tr.opt_customer_firm)
                         where tr.date_id between in_start_date_id and in_end_date_id
                           and tr.account_id = any (l_account_ids)
                           and tr.is_busted = 'Y'
                           and tr.opt_customer_firm is not null
                           and tr.orig_trade_record_id is null
                           and tr.is_cross_order = 'N'),
             cte_tr2 as (select tr.date_id,
                                tr.order_id,
                                tr.exec_id,
                                tr.trade_record_id,
                                tr.opt_customer_firm,
                                tf.trading_firm_name,
                                a.account_name,
                                tr.client_order_id,
                                tr.trade_record_time,
                                hsd.display_instrument_id,
                                hsd.maturity_date,
                                tr.side,
                                tr.open_close,
                                tr.last_qty,
                                tr.last_px,
                                tr.exchange_id,
                                ex.exchange_name,
                                cf.customer_or_firm_name,
                                tr.exec_broker,
                                tr.cmta,
                                tr.clearing_account_number,
                                tr.sub_account,
                                tr.client_id,
                                tr.remarks,
                                tr.trade_record_reason,
                                tr.db_create_time,
                                fmj.tag10701
                         from dwh.flat_trade_record tr
                                  join dwh.d_account a on (a.account_id = tr.account_id)
                                  join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = tr.trading_firm_unq_id)
                                  join dwh.historic_security_definition_all hsd
                                       on (hsd.instrument_id = tr.instrument_id)
                                  left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = tr.opt_customer_firm)
                                  left join dwh.d_exchange ex on (ex.exchange_id = tr.exchange_id and ex.is_active)
                                  left join lateral (select fmo.fix_message ->> '10701' as tag10701
                                                     from fix_capture.fix_message_json fmo
                                                     where fmo.date_id = tr.date_id
                                                       and fmo.fix_message_id = tr.order_fix_message_id
                                                     limit 1) fmj on true
                         where tr.date_id between in_start_date_id and in_end_date_id
                           and tr.account_id = any (l_account_ids)
                           --and a.account_id in ()
                           and tr.opt_customer_firm is not null
                           and tr.is_busted = 'N'
                           and tr.is_cross_order = 'N')
        select t2.trading_firm_name                           as "Trading Firm",
               t2.account_name                                as "Account",
               --case when t2.tag10701 is not null then concat(t2.account_name, '_', t2.tag10701) end as "Sub Account",
               t2.tag10701                                    as "Sub Account",
               t2.client_order_id                             as "Cl Ord ID",
               to_char(t2.trade_record_time, 'MM/DD/YYYY')    as "Date",
               to_char(t2.trade_record_time, 'HH24:MI:SS.US') as "Time",
               t2.display_instrument_id                       as "Symbol",
               --to_char(t2.maturity_date, 'MM/DD/YYYY') as "Expiration",
               case
                   when t2.side = '1' then 'Buy'
                   when t2.side = '2' then 'Sell'
                   when t2.side in ('5', '6') then 'Sell Short'
                   end                                        as "Side",
               case
                   when t2.open_close = 'O' then 'Open'
                   when t2.open_close = 'C' then 'Close'
                   end                                        as "O/C",
               t2.last_qty                                    as "Last Qty",
               t2.last_px                                     as "Last Px",
               coalesce(t2.exchange_name, t2.exchange_id)     as "Exchange Name",
               t2.exec_broker                                 as "Exec Broker",
               t2.cmta                                        as "CMTA",
               --t2.clearing_account_number as "Clearing Account Number",
               --t2.sub_account as "Sub Account",
               t2.client_id                                   as "Client ID",
               t2.remarks                                     as "Remarks",
               t2.trade_record_reason                         as "Trade Record Reason",
               t1.customer_or_firm_name                       as "Original Order Capacity",
               t2.customer_or_firm_name                       as "Modified Order Capacity"

        from cte_tr1 as t1
                 join cte_tr2 as t2
                      on (t2.date_id = t1.date_id and t2.order_id = t1.order_id and t2.exec_id = t1.exec_id)
        where t1.opt_customer_firm is distinct from t2.opt_customer_firm
        order by t2.date_id, t2.client_order_id, t2.order_id, t2.trade_record_id;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_pta_capacity_mismatch for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ===',
                           l_row_cnt, 'C')
    into l_step_id;

end ;
$function$;

