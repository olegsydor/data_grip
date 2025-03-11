create temp table tmp_606_isi_bill_changes_ with (parallel_workers = 4)
--                                            ON COMMIT drop
as
--     EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select to_char(tr.trade_record_time, 'YYYY-MM-DD') as report_date,
       tr.client_order_id                          as "OrderID",
       tr.secondary_order_id                       as "ExchOrderID",
       tr.secondary_exch_exec_id                   as "ReportID",
       tr.exch_exec_id                             as "Tag17"

from dwh.flat_trade_record tr
         left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and
                                                      jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
where true
 and tr.date_id between :l_start_date_id and :p_end_date_id
  and tr.account_id = any('{51464,14759,14760,14761,14762,14763,14764,14766,14767,14769,14771,14772,14773,14774,14775,14776,14777,14778,14779,14780,14781,14782,14803,14804,14805,14806,14807,14808,15971,15972,15973,15974,15975,15976,19619,19626,19629,19633,19676,19677,19678,19679,19680,19681,23810,24009,24010,24549,24550,24551,24552,24553,24554,24555,24556,24557,24558,24559,24560,24992,24993,24994,24995,24996,35590,35591,36673,36674,36675,36676,36677,36682,36683,36685,52061,52062,52063,52064,52065,52066,52067,52101,63695,70279,70341,70342,70343,70344,14768,73616,36679,51465,14765,14770,19634,36680,36681,58770}')
  and tr.is_busted = 'N'
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
and case when tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE' then false else true end
;

select * from tmp_606_isi_bill_changes_
except
select * from tmp_606_isi_bill_changes
;

------------


-- DROP FUNCTION dash360.report_isi_bill_changes_monthly(int4, int4, _varchar);

create or replace function dash360.report_isi_bill_changes_monthly(p_start_date_id integer default null::integer,
                                                                   p_end_date_id integer default null::integer,
                                                                   p_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                   p_add_exchange_order_id char default 'N')
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
                                               ON COMMIT drop as
    select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           coalesce(tr.client_order_id, '')            as "OrderID",
           coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
           coalesce(tr.secondary_exch_exec_id, '')     as "ReportID",
           coalesce(tr.exch_exec_id, '')               as "Tag17"
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


    if p_add_exchange_order_id = 'Y' then
        RETURN QUERY
            select 'Date,OrderID,ReportID,Tag17,ExchOrderID';
        return query
            select s."Date" || ',' ||
                   s."OrderID" || ',' ||
                   s."ReportID" || ',' ||
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
                   s."ReportID" || ',' ||
                   s."Tag17"
            from tmp_606_isi_bill_changes s
            order by s."Date", s."ReportID";
    end if;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_isi_bill_changes_monthly (modified) COMPLETE===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

end;
$function$
;
create temp table t02 as
select *
from dash360.report_isi_bill_changes_monthly(20241201, 20241231, '{socgen01,LPTF286,socbridge}', p_add_exchange_order_id := 'N');

create temp table t01 as
select *
from dash360.report_isi_bill_changes_monthly(20241201, 20241231, '{socgen01,LPTF286,socbridge}', p_add_exchange_order_id := 'Y');


alter function dash360.report_isi_bill_changes_monthly set schema trash;
alter function dash360.report_isi_bill_changes_monthly_mod rename to report_isi_bill_changes_monthly;


create temp table t02 as
select *
from dash360.report_isi_bill_changes_monthly(20241201, 20241231, '{socgen01,LPTF286,socbridge}',
                                             p_add_exchange_order_id := 'N');

create temp table t01 as
select *
from dash360.report_isi_bill_changes_monthly(20241201, 20241231, '{socgen01,LPTF286,socbridge}',
                                             p_add_exchange_order_id := 'Y');



select * from t01


 select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           coalesce(tr.client_order_id, '')            as "OrderID",
           coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
           coalesce(tr.secondary_exch_exec_id, '')     as "ReportID",
           coalesce(tr.exch_exec_id, '')               as "Tag17",

           instrument_type_id,
           exchange_id,
           jo.fix_message ->> '9483',
           jo.fix_message ->> '1003',
           jo.fix_message ->> '880'
 ,tr.*
,
    from dwh.flat_trade_record tr
             left join fix_capture.fix_message_json jo on tr.order_fix_message_id = jo.fix_message_id and
                                                          jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
    left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id
    where true
      and tr.date_id between :l_start_date_id and :p_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end
 and tr.exchange_id in ('NYSE', 'XPSX');