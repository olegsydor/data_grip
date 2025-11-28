-- DROP FUNCTION dash360.report_isi_bill_changes_monthly(int4, int4, _varchar);

CREATE OR REPLACE FUNCTION trash.report_isi_bill_changes_monthly(p_start_date_id integer DEFAULT NULL::integer,
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
  l_row_cnt       integer;

  l_start_date_id  integer;
  l_end_date_id    integer;
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

   drop table if exists t_execution;
    create temp table t_execution as
    select exchange_transaction_id,
           treports_id,
           order_id,
           report_id,
           client_order_id,
           torders_id,
           secondary_exch_exec_id,
           date_id,
           venue_exec_id
    from compliance.blaze_execution cbe
    where true
      and cbe.date_id between l_start_date_id and l_end_date_id
      and (exchange_transaction_id is not null
        or treports_id is not null);

       select public.load_log(l_load_id, l_step_id, 'Temp table created', 0, 'O')
   into l_step_id;

       create index on t_execution (date_id);
    create index on t_execution (client_order_id, secondary_exch_exec_id);
    create index on t_execution (client_order_id, exchange_transaction_id);
       select public.load_log(l_load_id, l_step_id, 'Temp table indexed', 0, 'O')
   into l_step_id;

   l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY['isigroup'] else p_trading_firm_ids end;

   select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and trading_firm_id = ANY (p_trading_firm_ids);

    select public.load_log(l_load_id, l_step_id, left(' trading_firm_ids = '||l_trading_firm_ids::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, ' Period: l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar, 0, 'O')
   into l_step_id;

     DROP TABLE IF EXISTS tmp_606_isi_bill_changes;

       create temp table tmp_606_isi_bill_changes with (parallel_workers = 4) ON COMMIT drop as
        select to_char(tr.trade_record_time, 'YYYY-MM-DD') as date_
          , tr.order_id
          , tr.trade_record_id as report_id
--          , tr.exch_exec_id as tag_17
          , coalesce(par.venue_exec_id, tr.exch_exec_id, par.exchange_transaction_id)     as tag_17_remove,
            coalesce(tr.exch_exec_id, par.exchange_transaction_id) as tag_17
--          , tr.secondary_exch_exec_id as street_tag_17
          --
          , to_char(tr.order_process_time, 'YYYYMMDD')::integer as order_date_id
--          , jo.fix_message ->> '143' as t_143
          , tr.ex_destination,
          par.treports_id as par_report_id
        from dwh.flat_trade_record tr
         left join lateral (select venue_exec_id, exchange_transaction_id, treports_id, report_id
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
          and cbe.report_id = par.report_id
          and cbe.date_id = tr.date_id
          and cbe.date_id between l_start_date_id and l_end_date_id
        ) str on true
          left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
        where tr.date_id between l_start_date_id and p_end_date_id
          and tr.account_id = any(l_account_ids)
          and tr.is_busted = 'N'
          and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') <> 'DASH-CBOE') -- DEVREQ-4314 Exclude any execution on orders routed to non-DASH DASHOMS orders.
        ;
        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_isi_bill_changes - Initial load', l_row_cnt, 'I')
       into l_step_id;


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
      coalesce(s.par_report_id::text, s.report_id::text, '')    ||','||  --
--      coalesce(s.report_id::varchar, '')                    ||','||  --
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
