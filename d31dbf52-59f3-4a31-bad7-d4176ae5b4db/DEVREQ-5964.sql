select to_char(tr.trade_record_time, 'YYYY-MM-DD')              as "Date",
       coalesce(cbe.order_id, tr.client_order_id, '')           as "OrderID",
       coalesce(tr.secondary_order_id, '')                      as "ExchOrderID",
       case
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP') then jos.t_880
           end                                                  as aux_tag_street,
       coalesce(cbe.report_id, tr.secondary_exch_exec_id)       as "ReportID", -- Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange
       coalesce(cbe.ExchangeTransactionID, tr.exch_exec_id) as "Tag17"
from dwh.flat_trade_record tr
         LEFT JOIN (select order_id, report_id, client_order_id,
                    from compliance.blaze_execution cbe
                    where cbe.fff = tr.fff) cbe on true
         left join lateral (select jo.fix_message ->> '143' as t_143
                            from fix_capture.fix_message_json jo
                            where tr.order_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jo on true
         left join lateral (select jo.fix_message ->> '143'  as t_143,
                                   jo.fix_message ->> '9483' as t_9483,
                                   jo.fix_message ->> '1003' as t_1003,
                                   jo.fix_message ->> '880'  as t_880
                            from fix_capture.fix_message_json jo
                            where tr.street_trade_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jos on true
         left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
where true
--   and tr.secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')
  and tr.client_order_id = '20250325VSIND28939'
  and tr.date_id between :l_start_date_id and :p_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'
  and case
          when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
              then false
          else true end

;
report_id in ('00000000-3230-3030-7374-726b6135326c', '00000000-3030-3030-7374-726b6135326c') and

select * from dwh.execution
where exec_date_id = 20250325
and order_id in (100000019696533965, 100000019696533916)
and secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')

select * from dwh.d_account
where 	true
  and trading_firm_id in ('xfa', 'xfachi')
		and account_name <> 'XFADESKTCM'


select * from client_order
where parent_order_id = 100000019696533916;
---
with base as (
select to_char(ex.exec_time, 'YYYY-MM-DD') as "Date",
                     cl.client_order_id                  as "OrderID",
                     str.client_order_id                 as "ExchOrderID",
                     case
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP')
                             then jos.t_9483
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL')
                             then jos.t_1003
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX')
                             then jos.t_880
                         when (di.instrument_type_id, cl.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP')
                             then jos.t_880
                         end                             as aux_tag_street,
                     ex.secondary_exch_exec_id           as "ReportID",
                     ex.exch_exec_id                     as "Tag17"
                      ,
                     cl.trading_firm_id,
                     ac.account_name,
                     fxm.*,
                     ex.*,
                     cl.* --ex.*, order_qty
              from client_order cl
                       inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
                       join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                       left join dwh.d_exchange dex on dex.exchange_id = cl.exchange_id and dex.is_active
                  -- 		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
--
-- 		inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
-- 		inner join d_option_contract oc on oc.instrument_id = cl.instrument_id
-- 		inner join d_option_series os on os.option_series_id  = oc.option_series_id
-- 		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
                       left join lateral
                  (select j.fix_message,
                          j.fix_message ->> '143'   as tag_143,
                          j.fix_message ->> '423'   as tag_423,
                          j.fix_message ->> '9281'  as tag_9281,
                          j.fix_message ->> '22017' as tag_22017,
                          j.fix_message ->> '115'   as tag_115,
                          j.fix_message ->> '109'   as tag_109--, j.fix_message->>'5059' as tag_5059, j.fix_message->>'134' as tag_134, j.fix_message->>'135' as tag_135
                   from fix_capture.fix_message_json j
                   where j.fix_message_id = cl.fix_message_id
                     and j.date_id = :in_date_id
                   limit 1
                  ) fxm on true
                       left join lateral (select client_order_id
                                          from dwh.client_order str
                                          where str.parent_order_id = cl.order_id
                                          limit 1) str on true
                       left join lateral (select exch_exec_id, exec_time, ex.fix_message_id, ex.secondary_exch_exec_id
                                          from dwh.execution ex
                                          where ex.order_id = cl.order_id
                                            and ex.exec_type = 'F'
                  ) ex on true
                       left join lateral (select jo.fix_message ->> '143'  as t_143,
                                                 jo.fix_message ->> '9483' as t_9483,
                                                 jo.fix_message ->> '1003' as t_1003,
                                                 jo.fix_message ->> '880'  as t_880
                                          from fix_capture.fix_message_json jo
                                          where ex.fix_message_id = jo.fix_message_id
                                            and jo.date_id = cl.create_date_id
                                          limit 1) jos on true
              where cl.create_date_id = :in_date_id
                and case
                        when cl.parent_order_id is null then true
                        when cl.parent_order_id is not null and cl.trading_firm_id in ('xfa', 'xfachi') and
                             ac.account_name <> 'XFADESKTCM' then true -- XFA
                        when cl.parent_order_id is not null and fxm.tag_143 in ('RFAC', 'DASH')
                            then true -- routed to DASH Desk (143=DASH), Casey Securities (Tag 143 = RFAC)
--           when cl.parent_order_id is not null and ac.account_name in ('TASTYSPX', 'TDSPX_BP')
--               then true -- for SPX
                        else false end
                and ac.account_id = 73660)
select row_to_json(base.*), * from base
where true
    and row_to_json(base.*)::text ilike '%759044098874146816%'

; -- e.g. Vision March 2025 example--BEAA0023-20250325

select row_to_json(ftr.*), * from dwh.flat_trade_record ftr
where date_id = 20250325
-- and account_id = 73660
--   and alternative_compliance_id = '370416750445'
and row_to_json(ftr.*)::text ilike '%370416750445%'
;



select * from staging.dash_trade_record
where date_id = 20250325
and account_id = 73660


'20250325VSIND28939'

select * from dwh.execution ex
    where true
      and ex.exec_date_id = 20250325
and row_to_json(ex.*)::text ilike any(array['%l25akrts0002%', '%l25akrts0000%'])
--~~* ANY(ARRAY['MARKET_DATA', '%list%']);


select exch_exec_id, secondary_exch_exec_id, * from dwh.execution ex
    where true
      and ex.exec_date_id = 20250325
      and (exch_exec_id = any('{l25aks000000,l25akrvo0000,l25aks040002,l25akruc0002,l25akruo0002,l25akrvc0002,l25akrv00002,l25akru40002,l25akrvs0000,l25akrts0002,l25akruk0000,l25aks0c0002,l25akrv80000,l25aks0g0002,l25aks000004,l25aks080002,l25akrvg0002,l25akrv00000,l25akrvo0002,l25aks0g0000,l25aks080000,l25akrvc0000,l25akrvk0002,l25akruo0000,l25aks040000,l25akrvs0002,l25akrug0000,l25akrvk0000,l25akruc0000,l25akrv40000,l25akrvk0004,l25aks000002,l25akru40000,l25aks0c0000,l25akrvg0000,l25akrts0000}')
        or secondary_exch_exec_id = any('{l25aks000000,l25akrvo0000,l25aks040002,l25akruc0002,l25akruo0002,l25akrvc0002,l25akrv00002,l25akru40002,l25akrvs0000,l25akrts0002,l25akruk0000,l25aks0c0002,l25akrv80000,l25aks0g0002,l25aks000004,l25aks080002,l25akrvg0002,l25akrv00000,l25akrvo0002,l25aks0g0000,l25aks080000,l25akrvc0000,l25akrvk0002,l25akruo0000,l25aks040000,l25akrvs0002,l25akrug0000,l25akrvk0000,l25akruc0000,l25akrv40000,l25akrvk0004,l25aks000002,l25akru40000,l25aks0c0000,l25akrvg0000,l25akrts0000}'))



    'l25aks0c0000','l25aks080000','l25akrv00000','l25aks0g0000','l25akrvc0000','l25akrvo0002','l25aks040000','l25akrug0000','l25akruc0000','l25akrvs0002','l25akrvk0000','l25akrts0000','l25akrv40000','l25akruo0000','l25akrvk0004','l25aks000002','l25akru40000','l25akrvg0000'

select alternative_compliance_id, client_order_id, *  from dwh.client_order
where account_id = 73660
and create_date_id between 20250325 and 20250326
and client_order_id = 'BEAA0023-20250325'

select * from dwh.flat_trade_record
    where true
and client_order_id = '20250325VSIND28939'
and date_id between 20250325 and 20250326



select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
       str.torders_id                              as "OrderID",
       coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
       case
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP') then jos.t_880
           end                                     as aux_tag_street,
       str.treports_id                             as "ReportID", -- Based on execution.secondary_exch_exec_id of the parent order trade. Means exec_id of the street order that arrives form the exchange
       par.exchange_transaction_id                 as "Tag17"
from dwh.flat_trade_record tr
         left join lateral (select order_id, report_id, client_order_id, torders_id, exchange_transaction_id
                            from compliance.blaze_execution cbe
                            where cbe.client_order_id = tr.client_order_id
                              and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                              and cbe.date_id = tr.date_id
                            limit 1) par on true
         left join lateral (
    select order_id, report_id, client_order_id, torders_id, exchange_transaction_id, treports_id
    from compliance.blaze_execution cbe
    where cbe.client_order_id = tr.client_order_id
      and cbe.exchange_transaction_id = par.exchange_transaction_id
      and cbe.date_id = tr.date_id
    ) str on true
         left join lateral (select jo.fix_message ->> '143' as t_143
                            from fix_capture.fix_message_json jo
                            where tr.order_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jo on true
         left join lateral (select jo.fix_message ->> '143'  as t_143,
                                   jo.fix_message ->> '9483' as t_9483,
                                   jo.fix_message ->> '1003' as t_1003,
                                   jo.fix_message ->> '880'  as t_880
                            from fix_capture.fix_message_json jo
                            where tr.street_trade_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jos on true
         left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
where true
  and tr.client_order_id = '20250325VSIND28939'
  and tr.date_id between :l_start_date_id and :p_end_date_id
  and tr.account_id = any (:l_account_ids)
  and tr.is_busted = 'N'
  and case
          when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
              then false
          else true end;

select order_id, report_id, client_order_id, torders_id, exchange_transaction_id, *
from compliance.blaze_execution cbe
where cbe.client_order_id = '20250325VSIND28939'
  and secondary_exch_exec_id = 'l25akrts0000';


select order_id, report_id, client_order_id, torders_id, exchange_transaction_id, *
from compliance.blaze_execution cbe
where cbe.client_order_id = '20250325VSIND28939'
and exchange_transaction_id = '360007058544';

select * from dwh.d_account
where true
--     and account_id = 73660
and trading_firm_id = 'OFP0050';


select bar.*
from dash_reporting.bofa_allocation_report as bar
where to_report = 'R';

select btr.*
from dash_reporting.bofa_trade_record as btr
where to_report = 'R';

select *
from trash.exchanges_execid_to_tag17_cross_reference(p_start_date_id := 20250325, p_end_date_id := 20250325,
                                                     p_trading_firm_ids := '{"OFP0050"}',
                                                     p_add_exchange_order_id := 'Y', p_account_ids := '{73660}');

drop function dash360.exchanges_execid_to_tag17_cross_reference;
create function dash360.exchanges_execid_to_tag17_cross_reference(p_start_date_id integer default null::integer,
                                                                  p_end_date_id integer default null::integer,
                                                                  p_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                  p_add_exchange_order_id character default 'N'::bpchar,
                                                                  p_account_ids int4[] default '{}'::int4[]
)
    returns table
            (
                export_row text
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-2469
    -- 2024-05-21 DS DEVREQ-4314 Exclude BLAZE/DASH OMS routes on "Billing ExecutionID to Tag17 cross reference"
    -- 2025-03-06 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5704
    -- 2025-05-19 OS https://dashfinancial.atlassian.net/browse/DS-9961
    -- 2025-05-29 OS performance tuning and changed logging messages
declare
    l_row_cnt          integer;
    l_start_date_id    integer;
    l_end_date_id      integer;
    l_trading_firm_ids character varying[];
    l_account_ids      int4[];
    l_load_id          integer;
    l_step_id          integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.exchanges_execid_to_tag17_cross_reference STARTED===', 0,
                           'O')
    into l_step_id;

    if p_start_date_id is not null and p_end_date_id is not null
    then
        l_start_date_id := p_start_date_id;
        l_end_date_id := p_end_date_id;
    else
        l_start_date_id := (to_char(date_trunc(NOW() - interval '1 month'), 'YYYYMMDD'))::integer;
        l_end_date_id := (to_char(date_trunc(NOW()) - interval '1 day', 'YYYYMMDD'))::integer;

    end if;

    if coalesce(p_account_ids, '{}') = '{}' and coalesce(p_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(p_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (p_trading_firm_ids)
                  else true end
          and case
                  when coalesce(p_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (p_account_ids)
                  else true end;
    end if;

    select public.load_log(l_load_id, l_step_id, left('trading_firm_ids = ' || l_trading_firm_ids::varchar, 200), 0,
                           'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id,
                           'Period: l_start_date_id = ' || l_start_date_id::varchar || ', l_end_date_id = ' ||
                           l_end_date_id::varchar, 0, 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, 'Account_ids: ' || left(l_account_ids::text, 50), 0, 'O')
    into l_step_id;


    drop table if exists t_execution;
    create temp table t_execution as
    select exchange_transaction_id,
           treports_id,
           order_id,
           report_id,
           client_order_id,
           torders_id,
           secondary_exch_exec_id,
           date_id
    from compliance.blaze_execution cbe
    where true
      and cbe.date_id between l_start_date_id and l_end_date_id
      and (exchange_transaction_id is not null
        or treports_id is not null);

    create index on t_execution (date_id);
    create index on t_execution (client_order_id, secondary_exch_exec_id);
    create index on t_execution (client_order_id, exchange_transaction_id);

    select public.load_log(l_load_id, l_step_id, 'temp table for billing executions was created', 0,
                           'O')
    into l_step_id;

    drop table if exists tmp_report;
    create temp table tmp_report with (parallel_workers = 4)
--                                                ON COMMIT drop
    as
    select to_char(tr.trade_record_time, 'YYYY-MM-DD')                as "Date",
           tr.client_order_id                                         as "OrderID",
--            coalesce(str.torders_id::text, tr.client_order_id)         as "OrderID",
           tr.secondary_order_id                                      as "ExchOrderID",
           case
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP')
                   then jos.t_880
               end                                                    as aux_tag_street,
           coalesce(str.treports_id::text, tr.secondary_exch_exec_id) as "ReportID",
           coalesce(par.exchange_transaction_id, tr.exch_exec_id)     as "Tag17"
    from dwh.flat_trade_record tr
             left join lateral (select exchange_transaction_id --order_id, report_id, client_order_id, torders_id
                                from t_execution cbe -- compliance.blaze_execution cbe
                                where cbe.client_order_id = tr.client_order_id
                                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                                  and cbe.date_id = tr.date_id
                                  and cbe.date_id between l_start_date_id and l_end_date_id
                                limit 1) par on true
             left join lateral (
        select treports_id --order_id, report_id, client_order_id, torders_id, exchange_transaction_id
        from t_execution cbe --compliance.blaze_execution cbe
        where cbe.client_order_id = tr.client_order_id
          and cbe.exchange_transaction_id = par.exchange_transaction_id
          and cbe.date_id = tr.date_id
          and cbe.date_id between l_start_date_id and l_end_date_id
        ) str on true
             left join lateral (select jo.fix_message ->> '143' as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true
             left join lateral (select jo.fix_message ->> '143'  as t_143,
                                       jo.fix_message ->> '9483' as t_9483,
                                       jo.fix_message ->> '1003' as t_1003,
                                       jo.fix_message ->> '880'  as t_880
                                from fix_capture.fix_message_json jo
                                where tr.street_trade_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jos on true
             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.date_id between l_start_date_id and l_end_date_id
      and tr.account_id = any (l_account_ids)
      and tr.is_busted = 'N'
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'tmp_report - Initial load', l_row_cnt, 'I')
    into l_step_id;


    analyze tmp_report;

    if p_add_exchange_order_id = 'Y' then
        return query
            select 'Date,OrderID,ReportID,Tag17,ExchOrderID';
        return query
            select array_to_string(ARRAY [
                                       s."Date",
                                       s."OrderID"::text,
                                       coalesce(aux_tag_street, s."ReportID"::text),
                                       s."Tag17",
                                       s."ExchOrderID"
                                       ], ',', '')
            from tmp_report s
            order by s."Date", s."ExchOrderID", s."ReportID";
    else
        return query
            select 'Date,OrderID,ReportID,Tag17';
        return query
            select array_to_string(ARRAY [
                                       s."Date",
                                       s."OrderID"::text,
                                       coalesce(aux_tag_street, s."ReportID"::text) ,
                                       s."Tag17"
                                       ], ',', '')
            from tmp_report s
            order by s."Date", s."ReportID";
    end if;

    select public.load_log(l_load_id, l_step_id, 'dash360.exchanges_execid_to_tag17_cross_reference COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

end;
$function$
;

select * from tmp_606_isi_bill_changes
;
alter function dash360.exchanges_execid_to_tag17_cross_reference rename to exchanges_execid_to_tag17_cross_reference_old;
alter function dash360.exchanges_execid_to_tag17_cross_reference_old set schema trash;
alter function trash.exchanges_execid_to_tag17_cross_reference(int4, int4, _varchar, bpchar, _int4) set schema dash360;


select *
from dash360.exchanges_execid_to_tag17_cross_reference(p_start_date_id := 20250303, p_end_date_id := 20250331,
                                                       p_trading_firm_ids := '{"OFP0050"}',
                                                       p_add_exchange_order_id := 'Y')--, p_account_ids := '{73660}');

gs

-- p_start_date_id := 20250303, p_end_date_id := 20250331,
--                                                        p_trading_firm_ids := '{"OFP0050"}',
--                                                        p_add_exchange_order_id := 'Y' (I didn't see this selection in DASH360 APP), p_account_ids := I select all accounts under OFP0050)

;

select *
from tmp_606_isi_bill_changes s




 select
     tr.client_order_id,
     tr.secondary_exch_exec_id,

     to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           tr.client_order_id/*str.torders_id*/        as "OrderID",
           tr.secondary_order_id                       as "ExchOrderID",
           case
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP')
                   then jos.t_880
               end                                     as aux_tag_street,
           str.treports_id                             as "ReportID",
           par.exchange_transaction_id                 as "Tag17"
    from dwh.flat_trade_record tr
             left join lateral (select order_id, report_id, client_order_id, torders_id, exchange_transaction_id
                                from compliance.blaze_execution cbe
                                where cbe.client_order_id = tr.client_order_id
                                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                                  and cbe.date_id = tr.date_id
                                  and cbe.date_id between :l_start_date_id and :p_end_date_id
                                limit 1) par on true
             left join lateral (
        select order_id, report_id, client_order_id, torders_id, exchange_transaction_id, treports_id
        from compliance.blaze_execution cbe
        where cbe.client_order_id = tr.client_order_id
          and cbe.exchange_transaction_id = par.exchange_transaction_id
          and cbe.date_id = tr.date_id
          and cbe.date_id between :l_start_date_id and :p_end_date_id
        ) str on true
             left join lateral (select jo.fix_message ->> '143' as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true
             left join lateral (select jo.fix_message ->> '143'  as t_143,
                                       jo.fix_message ->> '9483' as t_9483,
                                       jo.fix_message ->> '1003' as t_1003,
                                       jo.fix_message ->> '880'  as t_880
                                from fix_capture.fix_message_json jo
                                where tr.street_trade_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jos on true
             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.date_id between :l_start_date_id and :p_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;


select order_id, report_id, client_order_id, torders_id, exchange_transaction_id
                                from compliance.blaze_execution cbe
                                where cbe.client_order_id = '20250317VSIND61743'
                                  and cbe.secondary_exch_exec_id = '1Y000OI46'
                                  and cbe.date_id = 20250317
                                  and cbe.date_id between :l_start_date_id and :p_end_date_id










-- VERY OLD VERSION
CREATE OR REPLACE FUNCTION trash.report_isi_bill_changes_monthly_prev_version(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer, p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], p_add_exchange_order_id character DEFAULT 'N'::bpchar)
 RETURNS TABLE(export_row text)
 LANGUAGE plpgsql
AS $function$
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-2469
    -- 2024-05-21 DS DEVREQ-4314 Exclude BLAZE/DASH OMS routes on "Billing ExecutionID to Tag17 cross reference"
    -- 2025-03-06 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5704
DECLARE

    l_row_cnt          integer;
    l_start_date_id    integer;
    l_end_date_id      integer;
    l_gtc_date_id      integer;
    l_trading_firm_ids character varying[];
    l_account_ids      int4[];
    l_load_id          integer;
    l_step_id          integer;

begin


    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly STARTED===', 0,
                           'O')
    into l_step_id;

    if p_start_date_id is not null and p_end_date_id is not null
    then
        l_start_date_id := p_start_date_id;
        l_end_date_id := p_end_date_id;
    else
        l_start_date_id := (to_char(date_trunc(NOW() - interval '1 month'), 'YYYYMMDD'))::integer;
        l_end_date_id := (to_char(date_trunc(NOW()) - interval '1 day', 'YYYYMMDD'))::integer;

    end if;

    l_gtc_date_id :=
            to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD') - interval '6 months'), 'YYYYMMDD')::integer;

    l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY ['isigroup'] else p_trading_firm_ids end;


    select array_agg(ac.account_id)
    into l_account_ids
    from dwh.d_account ac
    where ac.trading_firm_id = any (l_trading_firm_ids);


    select public.load_log(l_load_id, l_step_id, left(' trading_firm_ids = ' || l_trading_firm_ids::varchar, 200), 0,
                           'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id,
                           ' Period: l_start_date_id = ' || l_start_date_id::varchar || ', l_end_date_id = ' ||
                           l_end_date_id::varchar, 0, 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, ' Account_ids: ' || left(l_account_ids::text, 50), 0, 'O')
    into l_step_id;

    DROP TABLE IF EXISTS tmp_606_isi_bill_changes;
    create temp table tmp_606_isi_bill_changes with (parallel_workers = 4)
--                                                ON COMMIT drop
    as
    select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           coalesce(tr.client_order_id, '')            as "OrderID",
           coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
  case
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP') then jos.t_9483
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL') then jos.t_1003
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
           when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP') then jos.t_880
           end as aux_tag_street,
           coalesce(tr.secondary_exch_exec_id, '')     as "ReportID",
           coalesce(tr.exch_exec_id, '')               as "Tag17"
    from dwh.flat_trade_record tr
             left join lateral (select jo.fix_message ->> '143'  as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true
     left join lateral (select jo.fix_message ->> '143'  as t_143,
                                   jo.fix_message ->> '9483' as t_9483,
                                   jo.fix_message ->> '1003' as t_1003,
                                   jo.fix_message ->> '880'  as t_880
                            from fix_capture.fix_message_json jo
                            where tr.street_trade_fix_message_id = jo.fix_message_id
                              and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                            limit 1) jos on true
             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.date_id between l_start_date_id and p_end_date_id
      and tr.account_id = any (l_account_ids)
      and tr.account_id = 73660
      and tr.is_busted = 'N'
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'tmp_606_isi_bill_changes - Initial load', l_row_cnt, 'I')
    into l_step_id;


    analyze tmp_606_isi_bill_changes;

    if p_add_exchange_order_id = 'Y' then
        RETURN QUERY
            select 'Date,OrderID,ReportID,Tag17,ExchOrderID';
        return query
            select s."Date" || ',' ||
                   s."OrderID" || ',' ||
                   coalesce(aux_tag_street, s."ReportID") || ',' ||
                   s."Tag17" || ',' ||
                   s."ExchOrderID"
            from tmp_606_isi_bill_changes s
            order by s."Date", s."ExchOrderID", s."ReportID";
    else
        RETURN QUERY
            select 'Date,OrderID,ReportID,Tag17';
        return query
            select s."Date" || ',' ||
                   s."OrderID" || ',' ||
                   coalesce(aux_tag_street, s."ReportID") || ',' ||
                   s."Tag17"
            from tmp_606_isi_bill_changes s
            order by s."Date", s."ReportID";
    end if;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly (modified) COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

end;
$function$

--------- TEST EXCEUTION PLAN
drop table t_execution;
create temp table t_execution as
select exchange_transaction_id, treports_id, order_id, report_id, client_order_id, torders_id, secondary_exch_exec_id, date_id
from compliance.blaze_execution cbe
where true
  and cbe.date_id between :l_start_date_id and :p_end_date_id
  and (exchange_transaction_id is not null
    or treports_id is not null);

create index on t_execution (date_id);
create index on t_execution (client_order_id, secondary_exch_exec_id);
create index on t_execution (client_order_id, exchange_transaction_id);


EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select to_char(tr.trade_record_time, 'YYYY-MM-DD')                as "Date",
           tr.client_order_id                                         as "OrderID",
--            coalesce(str.torders_id::text, tr.client_order_id)         as "OrderID",
           tr.secondary_order_id                                      as "ExchOrderID",
           case
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XASE', 'AMER') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'ARCAE', 'ARCA')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XCHI', 'CHX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NSX', 'NSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'NYSE', 'NYSE') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'XPSX', 'PSX') then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'AMEXP', 'AMEROP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'ARCAP', 'ARCAOP')
                   then jos.t_9483
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'EPRL', 'PEARLEQ')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'EMLD', 'EMLD') then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MIAX', 'MIAMI')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MPRL', 'PEARL')
                   then jos.t_1003
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('E', 'MEMX', 'MEMX') then jos.t_880
               when (tr.instrument_type_id, tr.exchange_id, dex.cat_exchange_id) = ('O', 'MXOP', 'MEMXOP')
                   then jos.t_880
               end                                                    as aux_tag_street,
           coalesce(str.treports_id::text, tr.secondary_exch_exec_id) as "ReportID",
           coalesce(par.exchange_transaction_id, tr.exch_exec_id)     as "Tag17"
    from dwh.flat_trade_record tr
             left join lateral (select exchange_transaction_id -- order_id, report_id, client_order_id, torders_id
                                from t_execution cbe--compliance.blaze_execution cbe
                                where cbe.client_order_id = tr.client_order_id
                                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                                  and cbe.date_id = tr.date_id
                                  and cbe.date_id between :l_start_date_id and :p_end_date_id
                                limit 1) par on true
             left join lateral (
        select treports_id -- order_id, report_id, client_order_id, torders_id, exchange_transaction_id
        from t_execution cbe--compliance.blaze_execution cbe
        where cbe.client_order_id = tr.client_order_id
          and cbe.exchange_transaction_id = par.exchange_transaction_id
          and cbe.date_id = tr.date_id
          and cbe.date_id between :l_start_date_id and :p_end_date_id
        ) str on true
             left join lateral (select jo.fix_message ->> '143' as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true
             left join lateral (select jo.fix_message ->> '143'  as t_143,
                                       jo.fix_message ->> '9483' as t_9483,
                                       jo.fix_message ->> '1003' as t_1003,
                                       jo.fix_message ->> '880'  as t_880
                                from fix_capture.fix_message_json jo
                                where tr.street_trade_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jos on true
             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.date_id between :l_start_date_id and :p_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;