-- DROP FUNCTION trash.report_isi_bill_changes_monthly(int4, int4, _varchar);

CREATE or replace FUNCTION trash.report_isi_bill_changes_monthly(p_start_date_id integer DEFAULT NULL::integer,
                                                                 p_end_date_id integer DEFAULT NULL::integer,
                                                                 p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
  select_stmt     text;
  sql_params      text;
  l_row_cnt       integer;

  l_start_date_id  integer;
  l_end_date_id    integer;
  l_trading_firm_ids character varying[];

   l_load_id        integer;
   l_step_id        integer;
l_account_ids int4[];

begin
  /*https://dashfinancial.atlassian.net/browse/DEVREQ-2469
   *
   * 2024-05-21 DS DEVREQ-4314 Exclude BLAZE/DASH OMS routes on "Billing ExecutionID to Tag17 cross reference"
   *
   *
   * */
  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly STARTED===', 0, 'O')
   into l_step_id;

   if p_start_date_id is not null and p_end_date_id is not null
    then
      l_start_date_id := p_start_date_id;
      l_end_date_id := p_end_date_id;
    else
      l_start_date_id := (to_char(date_trunc(NOW() - interval '1 month'), 'YYYYMMDD'))::integer;
      l_end_date_id := (to_char(date_trunc(NOW()) - interval '1 day' , 'YYYYMMDD'))::integer;

   end if;

   l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY['isigroup'] else p_trading_firm_ids end;

        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and trading_firm_id = ANY (l_trading_firm_ids);

    select public.load_log(l_load_id, l_step_id, left('trading_firm_ids = '||l_trading_firm_ids::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, 'Period: l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar, 0, 'O')
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
  GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  create index on t_execution (date_id);
  create index on t_execution (client_order_id, secondary_exch_exec_id);
  create index on t_execution (client_order_id, exchange_transaction_id);

  select public.load_log(l_load_id, l_step_id, 'temp table t_execution was created', l_row_cnt, 'I')
  into l_step_id;

     execute 'DROP TABLE IF EXISTS tmp_606_isi_bill_changes;';
       create temp table tmp_606_isi_bill_changes with (parallel_workers = 4) ON COMMIT drop as
        select to_char(tr.trade_record_time, 'YYYY-MM-DD') as date_
          , tr.order_id
--           , tr.trade_record_id as report_id
--           , coalesce(str.treports_id::text, tr.secondary_exch_exec_id) as report_id -- changed
            , coalesce(str.treports_id, tr.trade_record_id) as report_id -- changed
--           , tr.exch_exec_id as tag_17
          , coalesce(par.exchange_transaction_id, tr.exch_exec_id)     as tag_17
--           , tr.secondary_exch_exec_id as street_tag_17
          --
--           , to_char(tr.order_process_time, 'YYYYMMDD')::integer as order_date_id
          , jo.fix_message ->> '143' as t_143
          , tr.ex_destination
        from dwh.flat_trade_record tr
          left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer

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


        where tr.date_id between l_start_date_id and l_end_date_id
          and tr.account_id = any(l_account_ids)
          and tr.is_busted = 'N'
          and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') <> 'DASH-CBOE') -- DEVREQ-4314 Exclude any execution on orders routed to non-DASH DASHOMS orders.
        ;

        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_isi_bill_changes - Initial load', l_row_cnt, 'I')
       into l_step_id;


     execute 'analyze tmp_606_isi_bill_changes';
   -- execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_isi_bill_changes;';
   -- create table trash.sdn_tmp_606_isi_bill_changes as
   -- select * from tmp_606_isi_bill_changes;

   RETURN QUERY
    select 'DATE,ORDERID,REPORTID,TAG17' as roe --,SECONDARY TAG17
    union all
    select
      coalesce(s.date_::varchar, '')                        ||','||  --
      coalesce(s.order_id::varchar, '')                     ||','||  --
      coalesce(s.report_id::varchar, '')                    ||','||  --
      coalesce(s.tag_17::varchar, '')                                --
      --coalesce(s.street_tag_17::varchar, '')                         --

      as roe
    from
      (
        select date_, order_id, report_id, tag_17 --, street_tag_17
        from tmp_606_isi_bill_changes
        order by 1,2,3
      ) s
    ;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly COMPLETE===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

end;
$function$
;



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
    and cbe.date_id between :l_start_date_id and :l_end_date_id
    and (exchange_transaction_id is not null
      or treports_id is not null);


  create index on t_execution (date_id);
  create index on t_execution (client_order_id, secondary_exch_exec_id);
  create index on t_execution (client_order_id, exchange_transaction_id);

with alll as (
/*select to_char(tr.trade_record_time, 'YYYY-MM-DD')            as date_
                   , tr.order_id
--           , tr.trade_record_id as report_id
--           , coalesce(str.treports_id::text, tr.secondary_exch_exec_id) as report_id -- changed
                   , coalesce(str.treports_id, tr.trade_record_id)          as report_id -- changed
--           , tr.exch_exec_id as tag_17
                   , coalesce(par.exchange_transaction_id, tr.exch_exec_id) as tag_17
--           , tr.secondary_exch_exec_id as street_tag_17
                   --
--           , to_char(tr.order_process_time, 'YYYYMMDD')::integer as order_date_id
                   , jo.fix_message ->> '143'                               as t_143
                   , tr.ex_destination
 */
  select *

              from dwh.flat_trade_record tr
                  left join fix_capture.fix_message_json jo
              on tr.order_fix_message_id = jo.fix_message_id and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                  left join lateral (select exchange_transaction_id, order_id, report_id, client_order_id, torders_id
                  from t_execution cbe -- compliance.blaze_execution cbe
                  where cbe.client_order_id = tr.client_order_id
                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                  and cbe.date_id = tr.date_id
                  and cbe.date_id between :l_start_date_id and :l_end_date_id
                  limit 1) par on true
                  left join lateral (
                  select treports_id, order_id, report_id, client_order_id, torders_id, exchange_transaction_id
                  from t_execution cbe --compliance.blaze_execution cbe
                  where cbe.client_order_id = tr.client_order_id
                  and cbe.exchange_transaction_id = par.exchange_transaction_id
                  and cbe.date_id = tr.date_id
                  and cbe.date_id between :l_start_date_id and :l_end_date_id
                  ) str on true
              where tr.date_id between :l_start_date_id            and :l_end_date_id
--                 and tr.account_id = any (:l_account_ids)
--                 and tr.is_busted = 'N'
--                 and not (tr.ex_destination = 'BRKPT'
--                 and coalesce (jo.fix_message ->> '143'
--                   , '-1') <> 'DASH-CBOE') -- DEVREQ-4314 Exclude any execution on orders routed to non-DASH DASHOMS orders.
--                 and tr.order_id = 100000019696533916
    and trade_record_id = 4081308813
              )
select * from alll
where row_to_json(alll.*)::text ilike '%4080716370%'

select * from dwh.d_account
    where d_account.trading_firm_id in('vision01', 'OFP0050'
;


    if coalesce(p_account_ids, '{}') = '{}' and coalesce(p_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select string_agg(account_id::text,',')
--         into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(:p_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (:p_trading_firm_ids)
                  else true end
          and case
                  when coalesce(p_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (p_account_ids)
                  else true end;
    end if;
--'{70524,70525,70029,71611,68234,70526,70527,70528,70529,70530,70531,70532,70600,70601,70602,73627,68232,68233,68235,68236,69981,70094,70095,70096,70097,70098,70099,70100,70101,70102,70103,70104,70105,70106,70107,70108,70109,70110,70111,70112,70113,73537,73658,73659,73681,74532,68212,68405,68406,73660}'


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
      and cbe.date_id between :l_start_date_id and :l_end_date_id
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
           coalesce(tr.exch_exec_id, par.exchange_transaction_id)     as "Tag17",
           jo.t_17,
           jos.t_17,
           par.exchange_transaction_id, tr.exch_exec_id,
           str.treports_id::text, tr.secondary_exch_exec_id
    from dwh.flat_trade_record tr
             left join lateral (select exchange_transaction_id --order_id, report_id, client_order_id, torders_id
                                from t_execution cbe -- compliance.blaze_execution cbe
                                where cbe.client_order_id = tr.client_order_id
                                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                                  and cbe.date_id = tr.date_id
                                  and cbe.date_id between :l_start_date_id and :l_end_date_id
                                limit 1) par on true
             left join lateral (
        select treports_id --order_id, report_id, client_order_id, torders_id, exchange_transaction_id
        from t_execution cbe --compliance.blaze_execution cbe
        where cbe.client_order_id = tr.client_order_id
          and cbe.exchange_transaction_id = par.exchange_transaction_id
          and cbe.date_id = tr.date_id
          and cbe.date_id between :l_start_date_id and :l_end_date_id
        ) str on true
             left join lateral (select jo.fix_message ->> '143' as t_143,
                                       jo.fix_message ->> '17' as t_17
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true
             left join lateral (select jo.fix_message ->> '143'  as t_143,
                                       jo.fix_message ->> '9483' as t_9483,
                                       jo.fix_message ->> '1003' as t_1003,
                                       jo.fix_message ->> '880'  as t_880,
                                       jo.fix_message ->> '17'  as t_17
                                from fix_capture.fix_message_json jo
                                where tr.street_trade_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jos on true
             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
      and tr.date_id between :l_start_date_id and :l_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end
    and tr.order_id = '100000020803992963'
and coalesce(str.treports_id::text, tr.secondary_exch_exec_id) = '1410797555';
1410797555



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

 select fmj.fix_message ->> '17', * from dwh.client_order cl
           join fix_capture.fix_message_json fmj on fmj.fix_message_id = cl.fix_message_id
 where true
--      and cl.order_id = 100000020803992963
--  and cl.client_order_id = '20250529VSIND27914'
 and cl.client_order_id = '1_32250529'
