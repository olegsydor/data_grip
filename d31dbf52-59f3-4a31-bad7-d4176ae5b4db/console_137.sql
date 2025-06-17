select order_id
   from data_marts.f_yield_capture fyc
    inner join dwh.d_target_strategy dts on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
    join dwh.d_account a on fyc.account_id = a.account_id
   where  fyc.status_date_id between  :in_start_date_id and :in_end_date_id
      and parent_order_id is not null
      and dts.target_strategy_name in ('SENSOR')
and fyc.account_id in (select account_id
                        from dwh.d_trading_firm tf
                                 join dwh.d_account ac using (trading_firm_id)
                        where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                          and ac.is_active
                          and tf.is_active);



select tr.date_id::text,                        -- as trade_dt,
       oc.opra_symbol,                          -- as symbol,
       sum(tr.last_qty)::text,                  -- as qty,
       round(sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0),
             6)::text,                          -- as price,
       round(sum(tr.last_qty * 0.075), 6)::text -- as comm

from dwh.flat_trade_record tr
         inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
         inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
         inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
         left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
         left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
where true
  and tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.instrument_type_id = 'E'
  and tr.is_busted = 'N'
  and acc.account_id in (select account_id
                         from dwh.d_trading_firm tf
                                  join dwh.d_account ac using (trading_firm_id)
                         where
                             trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus', 'Cowen Prime Services')
                           and ac.is_active
                           and tf.is_active)
  and tr.order_id in (select order_id
                      from data_marts.f_yield_capture fyc
                               inner join dwh.d_target_strategy dts
                                          on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
                               join dwh.d_account a on fyc.account_id = a.account_id
                      where fyc.status_date_id between :in_start_date_id and :in_end_date_id
                        and parent_order_id is not null
                        and dts.target_strategy_name in ('SENSOR')
                        and fyc.account_id in (select account_id
                                               from dwh.d_trading_firm tf
                                                        join dwh.d_account ac using (trading_firm_id)
                                               where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus',
                                                                           'Cowen Prime Services')
                                                 and ac.is_active
                                                 and tf.is_active))
group by tr.open_close, tr.side, tr.date_id, tr.order_id, oc.opra_symbol, tr.order_id



select order_id, order_qty, order_price
                      from data_marts.f_yield_capture fyc
                               inner join dwh.d_target_strategy dts
                                          on (dts.target_strategy_id = fyc.parent_sub_strategy_id)
                               join dwh.d_account a on fyc.account_id = a.account_id
                      where fyc.status_date_id between :in_start_date_id and :in_end_date_id
                        and parent_order_id is not null
                        and dts.target_strategy_name in ('SENSOR')
                        and fyc.account_id in (select account_id
                                               from dwh.d_trading_firm tf
                                                        join dwh.d_account ac using (trading_firm_id)
                                               where trading_firm_name in ('Pleasant Lake Partners', 'Stifel Nicolaus',
                                                                           'Cowen Prime Services')
                                                 and ac.is_active
                                                 and tf.is_active);


select * from dwh.client_order
where order_id = 100000019928855616;


CREATE OR REPLACE FUNCTION dash360.report_isi_bill_changes_monthly_mod(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer, p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
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

    select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly (modified) STARTED===', 0,
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
                                               ON COMMIT drop as
    select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           tr.client_order_id                          as "OrderID",
           tr.secondary_order_id                       as "ExchOrderID",
           tr.secondary_exch_exec_id                   as "ReportID",
           tr.exch_exec_id                             as "Tag17"
    from dwh.flat_trade_record tr
             left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and
                                                          jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
    where true
      and tr.date_id between l_start_date_id and p_end_date_id
      and tr.account_id = any (l_account_ids)
      and tr.is_busted = 'N'
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'tmp_606_isi_bill_changes - Initial load', l_row_cnt, 'I')
    into l_step_id;


    analyze tmp_606_isi_bill_changes;

    RETURN QUERY
        select 'Date,OrderID,ExchOrderID,ReportID,Tag17 ';

    return query
        select array_to_string(ARRAY [
                                   s."Date",
                                   s."OrderID",
                                   s."ExchOrderID",
                                   s."ReportID",
                                   s."Tag17"
                                   ], ',', '')
        from (select *
              from tmp_606_isi_bill_changes
              order by 1, 3, 4) s;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly (modified) COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

end;
$function$
