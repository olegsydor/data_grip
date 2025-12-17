-- DROP FUNCTION trash.report_isi_bill_changes_monthly_2(int4, int4, _varchar);

-- DROP FUNCTION trash.report_isi_bill_changes_monthly_2(int4, int4, _varchar);

CREATE OR REPLACE FUNCTION trash.report_isi_bill_changes_monthly_2(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer, p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
 RETURNS TABLE(export_row text)
 LANGUAGE plpgsql
AS $function$
DECLARE
  select_stmt     text;
  sql_params      text;
  l_row_cnt       integer;

  l_start_date_id  integer;
  l_end_date_id    integer;
  l_gtc_date_id    integer;
  l_trading_firm_ids character varying[];

   l_load_id        integer;
   l_step_id        integer;
   l_account_ids    integer[];


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

--   l_gtc_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD') - interval '6 months'), 'YYYYMMDD')::integer;


       select public.load_log(l_load_id, l_step_id, 'Temp table t_blaze_client_order created', l_row_cnt, 'O')
   into l_step_id;

   drop table if exists t_execution;
    create temp table t_execution as
select cbe.exchange_transaction_id,
           cbe.treports_id,
           cbe.order_id,
           cbe.report_id,
           cbe.client_order_id,
           cbe.torders_id,
           cbe.secondary_exch_exec_id,
           cbe.date_id,
           cbe.venue_exec_id
           from compliance.blaze_execution cbe
    where true
      and cbe.date_id = 20251010
      and (exchange_transaction_id is not null
        or treports_id is not null);



       create index on t_execution (date_id);
    create index on t_execution (client_order_id, secondary_exch_exec_id);
    create index on t_execution (client_order_id, exchange_transaction_id);

   l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY['isigroup'] else p_trading_firm_ids end;


       create temp table tmp_606_isi_bill_changes with (parallel_workers = 4)
--ON COMMIT drop
as
        select par.*, str.*
        from dwh.flat_trade_record tr
         left join lateral (select *
                                from t_execution cbe -- compliance.blaze_execution cbe
                                where cbe.client_order_id = tr.client_order_id
                                  and cbe.secondary_exch_exec_id = tr.secondary_exch_exec_id
                                  and cbe.date_id = tr.date_id
                                  and cbe.date_id = 20251010
                                limit 1) par on true
                          left  join  lateral  (
                select  *
                from  t_execution  cbe  --compliance.blaze_execution  cbe
                where  cbe.client_order_id  =  tr.client_order_id
                    and  cbe.exchange_transaction_id  =  par.exchange_transaction_id
                    and  cbe.date_id  =  tr.date_id
                    and  cbe.date_id = 20251010
                )  str  on  true
          left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
        where tr.date_id = 20251010
          and tr.account_id = any('{70108,68232,68233,68234,68235,68236,69981,70029,70094,70095,70096,70097,70098,70099,70100,70101,70102,70103,70104,70105,70106,70107,70109,70110,70111,70112,70113,70524,70525,70526,70527,70528,70529,70530,70531,70532,70600,70601,70602,71611,73537,73627,73658,73659,73681,74532,75566,75605,68405,68406,74964,68212,73660}')
          and tr.is_busted = 'N'
          and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') <> 'DASH-CBOE') -- DEVREQ-4314 Exclude any execution on orders routed to non-DASH DASHOMS orders.
and tr.order_id = 100000023187974943

analyze tmp_606_isi_bill_changes;
   -- execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_isi_bill_changes;';
   -- create table trash.sdn_tmp_606_isi_bill_changes as
   -- select * from tmp_606_isi_bill_changes;

   RETURN QUERY
    select 'DATE,ORDERID,REPORTID,TAG17' as roe --,SECONDARY TAG17
    union all
    select
      coalesce(s.date_::varchar, '')                        ||','||  --
      coalesce(s.order_id::varchar, '')                     ||','||  --
--      coalesce(s.par_report_id::text, s.report_id::text, '')    ||','||  --
      coalesce(s.report_id::varchar, '')                    ||','||  --
      coalesce(s.tag_17::varchar, '')                                --
      --coalesce(s.street_tag_17::varchar, '')                         --

      as roe
    from
      (
        select date_, order_id, report_id, tag_17, par_report_id --, street_tag_17
        from tmp_606_isi_bill_changes
        order by 1,2,3
      ) s
    ;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly COMPLETE===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

end;
$function$
;
;
