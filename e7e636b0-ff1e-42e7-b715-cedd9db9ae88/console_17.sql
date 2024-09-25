-- DROP FUNCTION dash360.report_606_s3(int4, int4, varchar, _varchar, varchar, _varchar, varchar, _varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.report_606_s3(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer, p_606s3_file_type character varying DEFAULT 'S3_Standard'::character varying, p_billing_entities character varying[] DEFAULT '{}'::character varying[], p_client_mpid character varying DEFAULT NULL::character varying, p_companies character varying[] DEFAULT '{}'::character varying[], p_report_legs character varying DEFAULT 'N'::character varying, p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], p_billing_entity_tf character varying DEFAULT NULL::character varying)
 RETURNS TABLE(export_row text)
 LANGUAGE plpgsql
AS $function$
declare
  l_sql           text;
  select_stmt     text;
  sql_params      text;
  l_row_cnt       integer;

  l_start_date_id  integer;
  l_end_date_id    integer;
  l_gtc_start_date_id integer;
  l_min_date_id integer;

   l_load_id        integer;
   l_step_id        integer;

  l_billing_entities character varying[];
  l_companies        character varying[];
  l_fix_comp_ids     character varying[];
  l_account_ids      integer[];
  l_tmp_accout_ids int4[];


begin

  /* https://dashfinancial.atlassian.net/browse/DEVREQ-1447 */
  /*
   * 20240802 DS: DEVREQ-4626 -- allow modifications(35=G) for all customers
   * 20240808 DS: DEVREQ-4615 (Add a logic to handle special billing entities in 606 S3 files)
  */
  /* p_606s3_file_type values
   * 'S3_Standard' - common format. DEVREQ-1447
   * 'S3_Vision' - peculiar format for predefined billin entities. DEVREQ-1450
   * 'S3_TDAIMC' - simplified Totals + extended filtering + Companies filtering. DEVREQ-1461 (Custom S3 606a Report for TD Ameritrade)
   * 'S3_Total' - common totals format. DEVREQ-1448
   * 'S3_T3_cust' - T3 Trading Group - custom S3 format. DEVREQ-2123 (606(a) - T3 Trading Group - custom S3 format). This is 'S3_Standard' format with additional filtering.
   * 'S3_FMR_cust' - T3 Trading Group - custom S3 format. DEVREQ-1449 (Custom 606a Report for FMR).
   * 'S3_Ally_cust' - Custom 606(a) Ally Invest format. DEVREQ-2394 (Monthly Custom 606(a) Ally Invest)
  */

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_606_s3 STARTED===', 0, 'O')
   into l_step_id;




  if p_start_date_id is not null and p_end_date_id is not null
  then
    l_start_date_id := p_start_date_id;
    l_end_date_id := p_end_date_id;
  else
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
  end if;

  l_gtc_start_date_id := to_char((to_date(l_start_date_id::varchar, 'YYYYMMDD')::date - interval '12 month'), 'YYYYMMDD');


   l_billing_entities := case
                           when p_billing_entities = '{}' and p_606s3_file_type = 'S3_Vision'
                             then ARRAY['VFM','VIS','OEVFM','VISNCBOE','VFM2']
                           else p_billing_entities
                         end;

   --l_billing_entity_tf := p_billing_entity_tf; --'{ "billing_entities": [ {"id": "AFC","firms": ["LPTF4"]},{"id": "XFOMA","firms": ["LPTF25", "LPTF26"]} ] }'::JSON;

   l_companies := case
                    when p_companies = '{}'
                      then '{}'::character varying[]
                    else p_companies
                  end;

   if p_billing_entity_tf is not null
   then
     with str_to_parse as
        (
          select p_billing_entity_tf::json as l_billing_entity_tf --'{"billing_entities":[{"id":"BTK","firms":["btick01"]},{"id":"CMG","firms":["LPTF229","LPTF222"]}]}'
        )
      select --l_billing_entity_tf
          s.billing_entities
        , s.companies
      into l_billing_entities, l_companies
      from str_to_parse str
        left join lateral
          (
            select array_agg(distinct v ->>'id') as billing_entities
              , array_agg(distinct f.val) as companies
            from json_array_elements(str.l_billing_entity_tf -> 'billing_entities') v
              left join lateral
                (
                  select trim(f::varchar, '"') as val
                  from json_array_elements(v->'firms') f
                ) f on true
          ) s on true
      ;
   end if;

   -- https://dashfinancial.atlassian.net/browse/DEVREQ-2334 fix_comp_ids by client_mpid
   l_fix_comp_ids := case
                       when p_client_mpid = 'ETRS' then array['ETRADEOFP1']
                       when p_client_mpid = 'DEAN' then array['ETRADEDEANOFP']
                     end;
   -- https://dashfinancial.atlassian.net/browse/DEVREQ-2838 accounts by client_mpid
   l_account_ids  := case
                       when p_client_mpid = 'FUTM'
                         then
                           (select array_agg(ac.account_id)
                            from genesis2.account ac
                            where ac.trading_firm_id in ('EFP0009', 'OFP0042')
                              and ac.broker_dealer_mpid = 'FUTM'
                           )
                     end;

  -- https://dashfinancial.atlassian.net/browse/DEVREQ-4615 (Add a logic to handle special billing entities in 606 S3 files)
   l_billing_entities := case
                           when 'RAJACBOE' = any (l_billing_entities)
                              then array_cat(l_billing_entities, array['RAJACBOE_HT'])
                           when 'ICP' = any (l_billing_entities)
                              then array_cat(l_billing_entities, array['ICP_QCC', 'ICP_EMF'])
                           else l_billing_entities
                         end;

    select public.load_log(l_load_id, l_step_id, left(' p_606s3_file_type = '||p_606s3_file_type::varchar||' , p_report_legs = '||p_report_legs::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' p_billing_entities = '||p_billing_entities::varchar||' , p_companies = '||p_companies::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' p_billing_entity_tf = '||coalesce(p_billing_entity_tf::varchar,'{}'), 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' l_billing_entities = '||l_billing_entities::varchar||' , l_companies = '||l_companies::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' p_client_mpid = '||coalesce(p_client_mpid::varchar,'NULL')||' , l_fix_comp_ids = '||coalesce(l_fix_comp_ids::varchar,'NULL'), 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' l_account_ids = '||coalesce(l_account_ids::varchar,'NULL'), 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, ' Period: l_start_date_id = '||l_start_date_id::varchar||' , l_end_date_id = '||l_end_date_id::varchar, 0, 'O')
   into l_step_id;
   -- select public.load_log(l_load_id, l_step_id, ' Period: p_start_date_id = '||p_start_date_id::varchar||' , p_end_date_id = '||p_end_date_id::varchar, 0, 'O')
   --into l_step_id;

--return;


  --> Initial load from dash_trade_record + matching to orders_parent
  execute 'DROP TABLE IF EXISTS tmp_606_s3_order_fyc;';

  if p_606s3_file_type in ('S3_Total')
   then

     -- create a list/array of accounts
     execute 'DROP TABLE IF EXISTS tmp_606_s3_accts_src;';
     create temp table tmp_606_s3_accts_src with (parallel_workers = 4) ON COMMIT drop as
     select a.account_id
     from  genesis2.account a
     where a.trading_firm_id = any (l_companies) -- 'OFP0038' --any(l_trading_firm_ids)
     ;
     GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_accts_src - Initial load', l_row_cnt, 'I')
     into l_step_id;

     execute 'analyze tmp_606_s3_accts_src';

--     execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_accts_src;';
--     create table trash.sdn_tmp_606_s3_accts_src as
--     select * from tmp_606_s3_accts_src;

     -- fast approach
      -- check if number of accounts is less than 1000
     if (select count(1) from tmp_606_s3_accts_src) < 32767 --- < 1000 - use dyn sql
     then
     -- in case when accounts number is less than 1000 than USE dynamic SQL
       execute 'DROP TABLE IF EXISTS tmp_606_s3_order_fyc_src;';

       -- exception for RAJA -> allow modifications
--        if 1=1 -- p_client_mpid ilike 'RAJA%' -- https://dashfinancial.atlassian.net/browse/DEVREQ-4626 -- allow modifications for all customers
--        then
         select array_agg(account_id) into l_tmp_accout_ids from tmp_606_s3_accts_src;

         create temp table tmp_606_s3_order_fyc_src with (parallel_workers = 4)
--              on commit drop
             as
                          select yc.status_date_id
                                  , yc.routed_time
                                  , yc.exec_time
                                  , yc.order_id
                                  , yc.client_order_id
                                  , yc.multileg_reporting_type
                                  , yc.account_id
                                  , yc.instrument_id
                                  , null as orig_order_id
                          from staging.f_yield_capture yc
                          where true
                            and yc.status_date_id between :l_start_date_id and :l_end_date_id -- 20240401 and 20240430 -- l_start_date_id and l_end_date_id --
                            and yc.parent_order_id is not null
                            and yc.account_id in (72162,71361,34069,52622,68488,49521);--= any(l_tmp_accout_ids);


       update tmp_606_s3_order_fyc_src fyc
           set orig_order_id = co.orig_order_id
       from staging.client_order co
       where co.orig_order_id is not null
       and co.order_id = fyc.order_id;
--        raise notice '%', l_sql;

--        execute l_sql; -->>>> DYN SQL
       GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc_src - Initial load', l_row_cnt, 'I')
       into l_step_id;

       execute 'analyze tmp_606_s3_order_fyc_src';

--       execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_order_fyc_src;';
--       create table trash.sdn_tmp_606_s3_order_fyc_src as
--       select * from tmp_606_s3_order_fyc_src;

       execute 'DROP TABLE IF EXISTS tmp_606_s3_order_fyc;';
       create temp table tmp_606_s3_order_fyc with (parallel_workers = 4) ON COMMIT drop as
        select
            yc.status_date_id as date_id
          , to_char(yc.routed_time, 'YYYYMMDD')::integer as order_create_date_id
          , to_char(yc.exec_time, 'YYYYMMDD')::integer as exec_date_id
          , null::bigint as report_id
          , yc.orig_order_id
          , yc.order_id
          , yc.client_order_id
          , yc.multileg_reporting_type
          , hsd.instrument_type_id
          --, null::varchar as order_status --???
          , hsd.display_instrument_id
          --, null::bigint as exec_qty -- exec_qty and net_fee_rebate to take from EDW
          , null::varchar as is_held
          , null::bool as is_sp500
          , null::varchar as is_directed
          , null::varchar as order_type
          , null::bool as notional_under_50k
          , null::int as matching_logic
          , yc.order_id as co_order_id
        from tmp_606_s3_order_fyc_src yc --data_marts.f_yield_capture yc
          join genesis2.instrument hsd on (hsd.instrument_id = yc.instrument_id) -- dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
        where 1=1
        ;
        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc - Initial load', l_row_cnt, 'I')
       into l_step_id;

       execute 'analyze tmp_606_s3_order_fyc';



     else
     -- otherwise use the original approach.
       execute 'DROP TABLE IF EXISTS tmp_606_s3_order_fyc;';
       create temp table tmp_606_s3_order_fyc with (parallel_workers = 4) ON COMMIT drop as
        select
            yc.status_date_id as date_id
          , to_char(yc.routed_time, 'YYYYMMDD')::integer as order_create_date_id
          , to_char(yc.exec_time, 'YYYYMMDD')::integer as exec_date_id
          , null::bigint as report_id
          , co.orig_order_id
          , yc.order_id
          , yc.client_order_id
          , yc.multileg_reporting_type
          , hsd.instrument_type_id
          --, null::varchar as order_status --???
          , hsd.display_instrument_id
          --, null::bigint as exec_qty -- exec_qty and net_fee_rebate to take from EDW
          , null::varchar as is_held
          , null::bool as is_sp500
          , null::varchar as is_directed
          , null::varchar as order_type
          , null::bool as notional_under_50k
          , null::int as matching_logic
          , co.order_id as co_order_id
        from staging.f_yield_capture yc --data_marts.f_yield_capture yc
          join genesis2.account a on (a.account_id = yc.account_id) --dwh.d_account a on (a.account_id = yc.account_id)
          join genesis2.instrument hsd on (hsd.instrument_id = yc.instrument_id) -- dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
          left join lateral
            (
              select co.order_id,  co.orig_order_id
              from staging.client_order_big_data co
              where co.order_id = yc.order_id
                and co.create_date_id >= l_gtc_start_date_id -- 20210401
                --and co.parent_order_id is null
                --and co.multileg_reporting_type in ('1','2')
                --and co.trans_type <> 'F'
              limit 1
            ) co on true
        where yc.status_date_id between l_start_date_id and l_end_date_id -- 20220401 and 20220430 --
          and a.trading_firm_id = any (l_companies) -- 'OFP0038' --any(l_trading_firm_ids)
          --and a.account_name = 'C01'
          and yc.parent_order_id is null
        ;
        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc - Initial load', l_row_cnt, 'I')
       into l_step_id;

       execute 'analyze tmp_606_s3_order_fyc';

   end if;

   -- need to look up orders_parent
   l_min_date_id := coalesce((select min(order_create_date_id) from tmp_606_s3_order_fyc limit 1)::integer, l_start_date_id);
    select public.load_log(l_load_id, l_step_id, ' orders fyc: l_min_date_id = '||l_min_date_id::varchar, 0, 'O')
   into l_step_id;

    --> Matching 1: Match using order_id
      update tmp_606_s3_order_fyc trg
        set
            is_held            = po.is_held
          , is_sp500           = po.is_sp500
          , is_directed        = po.is_directed
          , order_type         = po.order_type
          , notional_under_50k = po.notional_under_50k
          , matching_logic     = 1
      from dash_reporting.zreporting_606_orders_parent po
      where 1=1
        --and trg.trade_date_id = po.date_id -- can be a mismatch order's date and trade date
        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
        and trg.order_id::bigint = po.order_id
        and trg.matching_logic is null
        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
      ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc - Matching 1: Match using order_id', l_row_cnt, 'U')
     into l_step_id;

    --> Matching 2: Match using client_order_id for complex option-leg orders
      update tmp_606_s3_order_fyc trg
        set
            is_held            = po.is_held
          , is_sp500           = po.is_sp500
          , is_directed        = po.is_directed
          , order_type         = po.order_type
          , notional_under_50k = po.notional_under_50k
          , matching_logic     = 2
      from dash_reporting.zreporting_606_orders_parent po
      where 1=1
        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
        and trg.client_order_id = po.client_order_id
        and po.instrument_type_id = 'M'
        and trg.multileg_reporting_type = '2'
        and trg.instrument_type_id = 'O'
        and trg.matching_logic is null
        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
      ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc - Matching 2: Match using client_order_id for complex option-leg orders', l_row_cnt, 'U')
     into l_step_id;

    --> Matching 3: Match using client_order_id
      update tmp_606_s3_order_fyc trg
        set
            is_held            = po.is_held
          , is_sp500           = po.is_sp500
          , is_directed        = po.is_directed
          , order_type         = po.order_type
          , notional_under_50k = po.notional_under_50k
          , matching_logic     = 3
      from dash_reporting.zreporting_606_orders_parent po
      where 1=1
        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
        and trg.client_order_id = po.client_order_id
        and trg.matching_logic is null
        and trg.instrument_type_id = po.instrument_type_id
        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
      ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_fyc - Matching 3: Match using client_order_id', l_row_cnt, 'U')
     into l_step_id;

--     execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_order_fyc;';
--     create table trash.sdn_tmp_606_s3_order_fyc as
--     select * from tmp_606_s3_order_fyc;

  end if; -- 'S3_Total'



  if p_606s3_file_type in ('S3_Standard', 'S3_TDAIMC', 'S3_Total', 'S3_T3_cust', 'S3_Ally_cust') -- exclude 'S3_Vision', 'S3_FMR_cust'
   then

     execute 'DROP TABLE IF EXISTS tmp_606_s3_companycodes;';
       create temp table tmp_606_s3_companycodes with (parallel_workers = 4) ON COMMIT drop as
            select c.companycode
            from goat.billing_customers bc
              left join billing.tbillingcustomersuserentityassgn cue
                on cue.customerid = bc.customer_id and cue.systemid = 7
              left join billing.tcompany c
                on cue.companyid = c.id
            where bc.customer_code = ANY (l_billing_entities) -- in ('TDAIMC') --billing_entity in ('TDAIMC') -- in ('ETIMC') --
      ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, left('tmp_606_s3_companycodes via b_e:'||coalesce(l_billing_entities::varchar,'NULL')||' - identified',200), l_row_cnt, 'I')
       into l_step_id;

     execute 'analyze tmp_606_s3_companycodes';

     execute 'DROP TABLE IF EXISTS tmp_606_s3_order_parent_src;';
       create temp table tmp_606_s3_order_parent_src with (parallel_workers = 4) ON COMMIT drop as
  --    with tf_cte as materialized
  --      (
  --        select c.companycode
  --        from goat.billing_customers bc
  --          left join billing.tbillingcustomersuserentityassgn cue
  --            on cue.customerid = bc.customer_id and cue.systemid = 7
  --          left join billing.tcompany c
  --            on cue.companyid = c.id
  --        where bc.customer_code = ANY (l_billing_entities) -- in ('TDAIMC') --billing_entity in ('TDAIMC') -- in ('ETIMC') --
  --      )
        select
            tr.date_id
          , to_char(tr.order_process_time, 'YYYYMMDD')::integer as order_create_date_id
          , to_char(tr.trade_record_time, 'YYYYMMDD')::integer as exec_date_id
          , case when tr.trade_record_id <> tr.edw_report_id then tr.edw_report_id else tr.trade_record_id end as report_id
          , tr.edw_report_id --, tr.exec_id
          , tr.order_id
          , tr.client_order_id
          , tr.multileg_reporting_type
          , tr.instrument_type_id
          , null::varchar(100) as is_held
          , null::boolean as is_sp500
          , null::varchar(100) as is_directed
          , null::varchar(100) as order_type
          , null::boolean as notional_under_50k
          , null::int as matching_logic
          , tr.fix_comp_id
          --
          --, c.companycode, cue.companyid, bc.*, cue.*, c.*
        from billing.dash_trade_record tr
            --on tr.trading_firm_id = c.companycode
        where 1=1
          and tr.trading_firm_id in (select companycode from tmp_606_s3_companycodes) --(select companycode from tf_cte) --('OFP0016', 'etrade') -- = 'OFP0016' --
          and tr.date_id between l_start_date_id and l_end_date_id -- 20220201 and 20220228
          and case
                when l_fix_comp_ids is null
                  then true
                else tr.fix_comp_id = any (l_fix_comp_ids)
              end
          and case
                when l_account_ids is null
                  then true
                else tr.account_id = any (l_account_ids)
              end
        group by
            tr.date_id
          , to_char(tr.order_process_time, 'YYYYMMDD')::integer
          , to_char(tr.trade_record_time, 'YYYYMMDD')::integer
          , case when tr.trade_record_id <> tr.edw_report_id then tr.edw_report_id else tr.trade_record_id end
          , tr.edw_report_id
          , tr.order_id
          , tr.client_order_id
          , tr.multileg_reporting_type
          , tr.instrument_type_id
          , tr.fix_comp_id
        ;
        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
        select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_parent - Initial load', l_row_cnt, 'I')
       into l_step_id;

     execute 'analyze tmp_606_s3_order_parent_src';

--     execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_order_parent_src;';
--     create table trash.sdn_tmp_606_s3_order_parent_src as
--     select * from tmp_606_s3_order_parent_src;
-- return;

     -- need to look up orders_parent
     l_min_date_id := coalesce((select min(order_create_date_id) from tmp_606_s3_order_parent_src limit 1)::integer, l_start_date_id);
      select public.load_log(l_load_id, l_step_id, ' orders parent: l_min_date_id = '||l_min_date_id::varchar, 0, 'O')
     into l_step_id;

    --> Matching 1: Match using order_id
--      update tmp_606_s3_order_parent trg
--        set
--            is_held            = po.is_held
--          , is_sp500           = po.is_sp500
--          , is_directed        = po.is_directed
--          , order_type         = po.order_type
--          , notional_under_50k = po.notional_under_50k
--          , matching_logic     = 1
--      from dash_reporting.zreporting_606_orders_parent po
--      where 1=1
--        --and trg.trade_date_id = po.date_id -- can be a mismatch order's date and trade date
--        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
--        and trg.order_id::bigint = po.order_id
--        and trg.matching_logic is null
--        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
--      ;
--      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
--      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_parent - Matching 1: Match using order_id', l_row_cnt, 'U')
--     into l_step_id;
--
--    --> Matching 2: Match using client_order_id for complex option-leg orders
--      update tmp_606_s3_order_parent trg
--        set
--            is_held            = po.is_held
--          , is_sp500           = po.is_sp500
--          , is_directed        = po.is_directed
--          , order_type         = po.order_type
--          , notional_under_50k = po.notional_under_50k
--          , matching_logic     = 2
--      from dash_reporting.zreporting_606_orders_parent po
--      where 1=1
--        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
--        and trg.client_order_id = po.client_order_id
--        and po.instrument_type_id = 'M'
--        and trg.multileg_reporting_type = '2'
--        and trg.instrument_type_id = 'O'
--        and trg.matching_logic is null
--        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
--      ;
--      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
--      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_parent - Matching 2: Match using client_order_id for complex option-leg orders', l_row_cnt, 'U')
--     into l_step_id;
--
--    --> Matching 3: Match using client_order_id
--      update tmp_606_s3_order_parent trg
--        set
--            is_held            = po.is_held
--          , is_sp500           = po.is_sp500
--          , is_directed        = po.is_directed
--          , order_type         = po.order_type
--          , notional_under_50k = po.notional_under_50k
--          , matching_logic     = 3
--      from dash_reporting.zreporting_606_orders_parent po
--      where 1=1
--        and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
--        and trg.client_order_id = po.client_order_id
--        and trg.matching_logic is null
--        and trg.instrument_type_id = po.instrument_type_id
--        and po.date_id between l_min_date_id and l_end_date_id -- 20220201 and 20220228
--      ;
--      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
--      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_parent - Matching 3: Match using client_order_id', l_row_cnt, 'U')
--     into l_step_id;

     execute 'DROP TABLE IF EXISTS tmp_606_s3_order_parent;';
       create temp table tmp_606_s3_order_parent with (parallel_workers = 4) ON COMMIT drop as
      with match_logic_1_cte as materialized
        (
          select trg.date_id, trg.order_create_date_id, trg.exec_date_id, trg.report_id, trg.edw_report_id, trg.order_id, trg.client_order_id, trg.multileg_reporting_type, trg.instrument_type_id, trg.fix_comp_id
            , po.is_held as is_held
            , po.is_sp500 as is_sp500
            , po.is_directed as is_directed
            , po.order_type as order_type
            , po.notional_under_50k as notional_under_50k
            , po.matching_logic as matching_logic
          from --trash.sdn_tmp_606_s3_order_parent_src trg
               tmp_606_s3_order_parent_src trg
            left join lateral
              (
                select po.*
                  , 1 as matching_logic
                from dash_reporting.zreporting_606_orders_parent po
                where 1=1
                  --and trg.trade_date_id = po.date_id -- can be a mismatch order's date and trade date
                  and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
                  and trg.order_id::bigint = po.order_id
                  and trg.matching_logic is null
                  and po.date_id between l_min_date_id and l_end_date_id -- 20220901 and 20220931 --
                limit 1
              ) po on true
          where 1=1
            and trg.matching_logic is null
        )
        , match_logic_2_cte as materialized
        (
          select trg.date_id, trg.order_create_date_id, trg.exec_date_id, trg.report_id, trg.edw_report_id, trg.order_id, trg.client_order_id, trg.multileg_reporting_type, trg.instrument_type_id, trg.fix_comp_id
            , po.is_held as is_held
            , po.is_sp500 as is_sp500
            , po.is_directed as is_directed
            , po.order_type as order_type
            , po.notional_under_50k as notional_under_50k
            , po.matching_logic as matching_logic
          from match_logic_1_cte as trg
            left join lateral
              (
                select po.*
                  , 2 as matching_logic
                from dash_reporting.zreporting_606_orders_parent po
                where 1=1
                  and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
                  and trg.client_order_id = po.client_order_id
                  and po.instrument_type_id = 'M'
                  and trg.multileg_reporting_type = '2'
                  and trg.instrument_type_id = 'O'
                  and trg.matching_logic is null
                  and po.date_id between l_min_date_id and l_end_date_id -- 20220901 and 20220931 --
                limit 1
              ) po on true
          where 1=1
            and trg.matching_logic is null
        )
        , match_logic_3_cte as materialized
        (
          select trg.date_id, trg.order_create_date_id, trg.exec_date_id, trg.report_id, trg.edw_report_id, trg.order_id, trg.client_order_id, trg.multileg_reporting_type, trg.instrument_type_id, trg.fix_comp_id
            , po.is_held as is_held
            , po.is_sp500 as is_sp500
            , po.is_directed as is_directed
            , po.order_type as order_type
            , po.notional_under_50k as notional_under_50k
            , po.matching_logic as matching_logic
          from match_logic_2_cte as trg
            left join lateral
              (
                select po.*
                  , 3 as matching_logic
                from dash_reporting.zreporting_606_orders_parent po
                where 1=1
                  and trg.order_create_date_id = po.date_id -- should be correct (except GTH)
                  and trg.client_order_id = po.client_order_id
                  and trg.matching_logic is null
                  and trg.instrument_type_id = po.instrument_type_id
                  and po.date_id between l_min_date_id and l_end_date_id -- 20220901 and 20220931 --
                limit 1
              ) po on true
          where 1=1
            and trg.matching_logic is null
        )
          select *
          from match_logic_1_cte as trg
          where matching_logic = 1
          union all
          select *
          from match_logic_2_cte as trg
          where matching_logic = 2
          union all
          select *
          from match_logic_3_cte as trg
          where coalesce(matching_logic, 3) = 3
      ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      select public.load_log(l_load_id, l_step_id, 'tmp_606_s3_order_parent - Matching all 3 logics', l_row_cnt, 'U')
     into l_step_id;

     execute 'analyze tmp_606_s3_order_parent';

--     execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_order_parent;';
--     create table trash.sdn_tmp_606_s3_order_parent as
--     select * from tmp_606_s3_order_parent;


     execute 'DROP TABLE IF EXISTS tmp_606_s3_billing_entity_to_client_mpid;';
     create temp table tmp_606_s3_billing_entity_to_client_mpid
       (billing_entity varchar(50), client_mpid varchar(50)) with (parallel_workers = 4) ON COMMIT drop;
     insert into tmp_606_s3_billing_entity_to_client_mpid (billing_entity, client_mpid)
       VALUES ('SCHWABOFP', 'CHAS')
         , ('INA', 'APCC')
         , ('INA_E', 'APCC')
         , ('ebsrbc', 'DAIN')
         , ('WEDBULLOFP', 'WBUL')
         , ('TASTY', 'TWTT')
         , ('dough', 'DOPE')
         , ('DOUGHOFP', 'DOPE')
         , ('raymjay01', 'RAJA')
         , ('RAJACBOE', 'RAJA')
         , ('RAJACBOE_HT', 'RAJA')
         , ('wallstacc','WABR')
         , ('cfglobal','CFGT')
         , ('CFGCBOE','CFGT')
         --, ('ETIMC', 'ETRS') -- !!! ETRS vs DEAN for ETIMC. Will use p_client_mpid only.
         , ('VTW', 'VTDT')
         , ('viewtrade', 'VTDT')
         , ('INS', 'INGS')
         , ('olive01', 'OTUS')
         , ('GARW', 'GWDS')
         , ('garwood01', 'GWDS')
         , ('ICP', 'ICAP')
         , ('ICS', 'ICAP')
         , ('ICAPLP', 'ICAP')
         , ('ICAP_DASH', 'ICAP')
         , ('icap', 'ICAP')
         , ('ICP_QCC', 'ICAP')
         , ('ICP_EMF', 'ICAP')
         , ('Chapd', 'ICAP')
         , ('CHAPCBOE', 'ICAP')
         , ('PFP', 'PBON')
         , ('PRE', 'PBON')
         , ('PRR', 'PBON')
         , ('prebon01', 'PBON')
         , ('Prebon Financial Products', 'PBON')
         , ('FIDOFP', 'NFSC')
         , ('WELLSOFP', 'WCHV')
         , ('isigroup', 'ISIG')
         , ('Guggen', 'GUGG')
         , ('GFI', 'GFIS');

     --raise notice 'cnt: %', (select count(1) from tmp_606_s3_billing_entity_to_client_mpid);

     -- make parallel insert-select into temp table
     -- source report data parallel temp table
     execute 'DROP TABLE IF EXISTS tmp_606_s3_report_data;';
     create temp table tmp_606_s3_report_data with (parallel_workers = 4) ON COMMIT drop as
      with tbcuea_cte as materialized
        (
          select customerid, userid, companyid, systemid, status
          from billing.tbillingcustomersuserentityassgn --billing_foreign.edw_tbillingcustomersuserentityassgn
        )
      select
          case
            when cbd.c_p in ('C', 'P') then ''
            when bc.customer_code <> dbc.customer_code and bc.customer_code = replace(cbd.billing_entity, '_HT', '')
                then (case when coalesce(o.isnotheld, case when cbd.ord_is_not_held=1 then 1::bit end) = 1::bit then 'NH' else 'H' end)
            else s3op.is_held
          end as held_type
        , case
               when cbd.billing_entity = 'ETIMC' and cbd.fix_comp_id = 'ETRADEOFP1' then 'ETRS' -- s3op.fix_comp_id ???
               when cbd.billing_entity = 'ETIMC' and cbd.fix_comp_id = 'ETRADEDEANOFP' then 'DEAN'
               else coalesce(clmp.client_mpid, p_client_mpid)
          end as entry_firm
        , cbd.date_id
        --, to_char(to_date(cbd.date_id::varchar, 'YYYYMMDD'), 'MON-yy') as date_v
        --, 'DFIN' as route_firm
        --, null as entry_firm
        , case
            when cbd.c_p = 'S' then cbd.exchange
            when cbd.c_p  in ('C','P') then 'DASH'
          end as venue
        , case
            when cbd.c_p = 'S' and s3op.is_sp500 = true then 'NMS S&P 500'
            when cbd.c_p = 'S' then 'NMS Non S&P 500'
            when cbd.c_p in ('C','P') then 'NMS Options'
            else 'ER'
          end as stock_group
        , case
            when cbd.c_p = 'S' and s3op.is_sp500 = true then 'NMS S&P 500'
            when cbd.c_p = 'S' then 'NMS Non S&P 500'
            when cbd.c_p in ('C','P') then 'NMS Options'
            else 'ER'
          end as stock_group_total
        , case
            when cbd.c_p in ('C','P') and coalesce(bod.legcount, cbd.bod_leg_count, o.legcount) > 1 then 'OTH' --Each option leg of a complex order will always OTH
            when s3op.order_type is not null and s3op.order_type <> 'Directed' --For ELECTRONIC
              then
                case s3op.order_type
                  when 'Market' then 'MKT'
                  when 'Marketable Limit' then 'MKL'
                  when 'Non Marketable Limit' then 'LMT'
                  when 'Other' then 'OTH'
                  else 'ER'
                end
            else case when pq.shortdesc in ('MKT', 'MKL', 'LMT', 'OTH') then pq.shortdesc else 'OTH' end --For MANUAL
          end as order_type
        , case
            when cbd.c_p in ('C','P') and coalesce(bod.legcount, cbd.bod_leg_count, o.legcount) > 1 then 'OTH' --Each option leg of a complex order will always OTH
            when s3op.order_type is not null and s3op.order_type <> 'Directed' --For ELECTRONIC
              then
                case s3op.order_type
                  when 'Market' then 'MKT'
                  when 'Marketable Limit' then 'MKL'
                  when 'Non Marketable Limit' then 'LMT'
                  when 'Other' then 'OTH'
                  else 'ER'
                end
            else case when pq.shortdesc in ('MKT', 'MKL', 'LMT', 'OTH') then pq.shortdesc else 'OTH' end --For MANUAL
          end as order_type_total
        , cbd.filled_qty as executed_volume
        --, coalesce(cbd.net_rebate_fee, 0.0) as fee_rebate
        , case
            when cbd.billing_entity in ('ETIMC') -- https://dashfinancial.atlassian.net/browse/DEVREQ-3377. ProductID = 12, 53 (PFOFTF, PFOFRB) to include only PFOF fees for ETIMC
              then coalesce(cbd.pfof, 0.0) * -1 -- net_rebate_fee has reverted sign of all products summarizing
            else coalesce(cbd.net_rebate_fee, 0.0)
          end as fee_rebate
        , cbd.account
        , cbd.billing_entity
        , cbd.c_p
        , cbd.electronic
        , coalesce(s3op.notional_under_50k, (case when abs(coalesce(o.filled::numeric, cbd.ord_filled::numeric) * coalesce(o.avgprice::numeric, cbd.ord_avg_price::numeric) * (case when cbd.security_type = 'Option' then 100.0 else 1.0 end)::numeric) <= 50000.0 then true else false end)) as notional_under_50k
        , case
            when bc.customer_code <> dbc.customer_code and bc.customer_code = replace(cbd.billing_entity, '_HT', '') then 'ND'
            else s3op.is_directed
          end as is_directed
        , cbd.cmta_firm
        , cbd.company
        , cbd.cl_ord_id
        , concat(cbd.cl_ord_id,cbd.osi_series) as cl_ord_id_osi_series
        , cbd.exchange
        , bod.order_id as bod_order_id
        , cbd.bod_order_id as cbd_bod_order_id
        --, cbd.order_id as cbd_order_id >>> to add  cbd.order_id to dash_reporting.s3_customer_billing_detail_for_606_report table
        , o.ForWhom
        , o.Capacity
        , cbd.cbd_range
        --
        , s3op.notional_under_50k as s3op_notional_under_50k
        , o.filled
        , o.avgprice
        , cbd.security_type
        , cbd.report_id as cbd_report_id
        , bod.legcount as bod_legcount
        , cbd.bod_leg_count as cbd_bod_leg_count
        , s3op.order_type as s3op_order_type
        , s3op.is_sp500 as s3op_is_sp500
        , s3op.fix_comp_id
        , pq.shortdesc as pq_shortdesc
        , cbd.ord_id
        , cbd.ord_price_qualifier
        , cbd.ord_filled
        , cbd.ord_avg_price
        , cbd.ord_is_not_held
        , cbd.fix_comp_id as cbd_fix_comp_id
        , coalesce(cbd.pfof, 0.0) * -1 as cbd_pfof_commission
      from dash_reporting.s3_customer_billing_detail_for_606_report cbd
         -- [EDW_Billing].[dbo].[TBillingOrderDefinition] bod with(nolock) on (bod.ReportID = cbd.REPORTID)
        left join billing.tbillingorderdefinition bod
          on cbd.report_id = bod.report_id
          and cbd.ptm_id = bod.ptm_id
          and 1<>1 -- temporarily exclude this table as we have this data imported from EDW with commissions
        --> [TOrder_EDW], [Dash_Trade_Record], [zreporting_606_orders_parent], [Dash_Trade_Record], [zreporting_606_orders_parent]
         -- [EDW_Billing].[dbo].[TOrder_EDW] o with(nolock) on (o.ID = bod.OrderID)
        left join billing.torder_edw o
          --on coalesce(bod.order_id, cbd.bod_order_id) = o.id -- old condition
          on coalesce(bod.order_id, cbd.bod_order_id) = o.id -- new condition (should allow to not use billing.torder_edw on PG billing side) >>> to add  cbd.order_id to dash_reporting.s3_customer_billing_detail_for_606_report table
         -- [EDW_Billing].[dbo].[Dash_Trade_Record] tr1 with(nolock) on (tr1.trade_record_id = cbd.REPORTID and convert(date, tr1.trade_record_time) = cbd.[DATE] and tr1.is_busted = 'N')
        --left join billing.dash_trade_record tr1
        --  on cbd.report_id = tr1.trade_record_id and cbd.date_id = tr1.date_id and tr1.is_busted = 'N'
        --left join lateral
        --  (
        --    select tr1.client_order_id, tr1.order_process_time, tr1.multileg_reporting_type, tr1.instrument_type_id
        --    from billing.dash_trade_record tr1
        --    where cbd.report_id = tr1.trade_record_id
        --      and cbd.date_id = tr1.date_id
        --      and tr1.is_busted = 'N'
        --      and tr1.date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 --
        --    limit 1
        --  ) tr1 on true
        --left join dash_reporting.zreporting_606_orders_parent po1
        --  on tr1.client_order_id  = po1.client_order_id and to_char(tr1.order_process_time, 'YYYYMMDD')::integer = po1.date_id and (case when tr1.multileg_reporting_type <> '1' then 'M' else tr1.instrument_type_id end) = po1.instrument_type_id
        --left join billing.dash_trade_record tr2
        --  on cbd.report_id = tr2.edw_report_id and cbd.date_id = tr2.date_id and tr2.is_busted = 'N'
        --left join lateral
        --  (
        --    select tr2.client_order_id, tr2.order_process_time, tr2.multileg_reporting_type, tr2.instrument_type_id
        --     , tr2.edw_report_id
        --     , tr2.date_id
        --    from billing.dash_trade_record tr2
        --    where tr2.edw_report_id = cbd.report_id
        --      and tr2.date_id = cbd.date_id
        --      and tr2.is_busted = 'N'
        --      and tr2.date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 --
        --    limit 1
        --  ) tr2 on true
        --left join dash_reporting.zreporting_606_orders_parent po2
        --  on tr2.client_order_id  = po2.client_order_id and to_char(tr2.order_process_time, 'YYYYMMDD')::integer = po2.date_id and (case when tr2.multileg_reporting_type <> '1' then 'M' else tr2.instrument_type_id end) = po2.instrument_type_id
        -- s3op
        left join tmp_606_s3_order_parent s3op on s3op.exec_date_id = cbd.date_id and s3op.report_id = cbd.report_id
        --left join tmp_606_s3_order_parent s3op on s3op.exec_date_id = cbd.date_id
        --  and case when s3op.edw_report_id is not null
        --           then s3op.report_id = cbd.report_id
        --           else s3op.client_order_id = cbd.cl_ord_id --
        --      end
         -- [LiquidPoint_EDW].[dbo].[TCompany] c with(nolock) on (c.ID = bod.CompanyID and c.EDWActive = 1)
        left join billing.tcompany c
          on coalesce(bod.company_id, cbd.bod_company_id, o.companyid) = c.id and c.edwactive = 1::bit
         -- [EDW_Billing].[dbo].[TBillingCustomersUserEntityAssgn] cuea with(nolock) on (cuea.CompanyID = c.EDWCompanyID and cuea.SystemID = c.SystemID and cuea.UserID = 0 and cuea.Status = 1)
        left join tbcuea_cte cuea
          on c.edwcompanyid = cuea.companyid and c.systemid = cuea.systemid and cuea.userid = 0 and cuea.status = 1
         -- [EDW_Billing].[dbo].[TBillingCustomers] bc with(nolock) on (bc.CustomerID = cuea.CustomerID)
        left join goat.billing_customers bc
          on cuea.customerid = bc.customer_id
        left join billing.tcompany dc
          on coalesce(bod.destinationcompany_id, cbd.bod_destination_company_id, o.destinationcompanyid) = dc.id and dc.edwactive = 1::bit
        left join tbcuea_cte dcuea
          on dc.edwcompanyid = dcuea.companyid and dc.systemid = dcuea.systemid and dcuea.userid = 0 and dcuea.status = 1
        left join goat.billing_customers dbc
          on dcuea.customerid = dbc.customer_id
        left join
          (
            select id, shortdesc
            from billing.lpricequalifier -- billing_foreign.edw_lpricequalifier
          ) pq
          on coalesce(o.pricequalifier, cbd.ord_price_qualifier) = pq.id
        left join tmp_606_s3_billing_entity_to_client_mpid clmp on cbd.billing_entity = clmp.billing_entity
      where cbd.date_id between l_start_date_id and l_end_date_id --20210601 and 20210630
        and cbd.billing_entity = ANY (l_billing_entities) --'FIDOFP' -- client_mpid = 'NFSC'
     ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      raise NOTICE 'l_row_cnt = % ', l_row_cnt;

      execute 'analyze tmp_606_s3_report_data';

--    execute 'DROP TABLE IF EXISTS trash.sdn_tmp_606_s3_report_data;';
--    create table trash.sdn_tmp_606_s3_report_data as
--    select * from tmp_606_s3_report_data;

  end if; -- 'S3_Standard', 'S3_TDAIMC', 'S3_Total', 'S3_T3_cust', 'S3_Ally_cust'

  if p_606s3_file_type in ('S3_Standard', 'S3_T3_cust')
  then

   RETURN QUERY
    select
      coalesce(s.held_type::varchar, '')               ||'|'||  -- as [HELD_TYPE]
      coalesce(s.date_v::varchar, '')                  ||'|'||  -- as [DATE]
      coalesce(s.route_firm::varchar, '')              ||'|'||  -- as [ROUTE_FIRM]
      coalesce(s.entry_firm::varchar, '')              ||'|'||  -- as [ENTRY_FIRM]
      coalesce(s.stock_group::varchar, '')             ||'|'||  -- as [STOCK_GROUP]
      coalesce(s.order_type::varchar, '')              ||'|'||  -- as [ORDER_TYPE]
      coalesce(s.executed_volume::varchar, '')         ||'|'||  -- as [EXECUTED_VOLUME]
      coalesce(s.net_fee_rebate::varchar, '')                   -- as [NET_FEE_REBATE]
    from
      (
        select rd.held_type
          , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy') as date_v
          , 'DFIN' as route_firm
          --, coalesce(clmp.client_mpid, p_client_mpid) as entry_firm
          , rd.entry_firm
          , rd.stock_group
          , rd.order_type
          , sum(rd.executed_volume) as executed_volume
          , round(sum(rd.fee_rebate), 4) as net_fee_rebate
        from tmp_606_s3_report_data rd
          --left join tmp_606_s3_billing_entity_to_client_mpid clmp on rd.billing_entity = clmp.billing_entity
        where (rd.c_p = 'S' or rd.notional_under_50k = true )
          and rd.billing_entity not in ('ICP_QCC', 'ICP_EMF')
          and rd.COMPANY not in ('OE-Schwab OFP Staging', 'OE-Schwab OFP Staging Reroute') --Temporarily suppress for DEVREQ-3527
          --and rd.is_directed = 'ND' --Exclude directed orders
          and coalesce(rd.is_directed,'ND') = 'ND' --Exclude directed orders
          and ((rd.c_p = 'S' and rd.held_type = 'H') or (rd.c_p in ('C', 'P') and rd.held_type = ''))
          and case when p_606s3_file_type = 'S3_T3_cust' then rd.cbd_range = 'CUST' else true end
          -- filter limited by s3op trades
          and case
                when coalesce(l_fix_comp_ids::varchar , l_account_ids::varchar ) is null
                  then true
                else rd.s3op_order_type is not null
              end
        group by rd.held_type
          , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy')
          , rd.stock_group
          , rd.order_type
          --, coalesce(clmp.client_mpid, p_client_mpid)
          , rd.entry_firm
      ) s
    ;
   end if;

  if p_606s3_file_type = 'S3_TDAIMC'
  then

   RETURN QUERY
     select
      coalesce(s.held_type::varchar, '')               ||'|'||  -- as [HELD_TYPE]
      coalesce(s.date_v::varchar, '')                  ||'|'||  -- as [DATE]
      coalesce(s.route_firm::varchar, '')              ||'|'||  -- as [ROUTE_FIRM]
      coalesce(s.entry_firm::varchar, '')              ||'|'||  -- as [ENTRY_FIRM]
      coalesce(s.stock_group::varchar, '')             ||'|'||  -- as [STOCK_GROUP]
      coalesce(s.order_type::varchar, '')              ||'|'||  -- as [ORDER_TYPE]
      coalesce(s.executed_volume::varchar, '')         ||'|'||  -- as [EXECUTED_VOLUME]
      coalesce(s.net_fee_rebate::varchar, '')                   -- as [NET_FEE_REBATE]
    from
      (
        select rd.held_type
          , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy') as date_v
          , 'DFIN' as route_firm
          , p_client_mpid as entry_firm
          , rd.stock_group
          , rd.order_type
          , sum(rd.executed_volume) as executed_volume
          , round(sum(rd.fee_rebate), 4) as net_fee_rebate
        from tmp_606_s3_report_data rd
             --trash.sdn_tmp_606_s3_report_data rd
          left join tmp_606_s3_billing_entity_to_client_mpid clmp on rd.billing_entity = clmp.billing_entity
        where (rd.c_p = 'S' or rd.notional_under_50k = true )
          and rd.is_directed = 'ND' --Exclude directed orders
          and ((rd.c_p = 'S' and rd.held_type = 'H') or (rd.c_p in ('C', 'P') and rd.held_type = ''))
          and (rd.cmta_firm <> '615' or rd.cmta_firm is null)
          and case when l_companies <> '{}' then rd.company = any (l_companies) else true end -- 'OFP0011'FOMA
        group by rd.held_type
          , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy')
          , rd.stock_group
          , rd.order_type
          , coalesce(clmp.client_mpid, p_client_mpid)
      ) s
    ;
   end if;

  if p_606s3_file_type = 'S3_Total'
  then

   RETURN QUERY
     select 'HELD_TYPE,DATE,Venue,STOCK_GROUP_TOTAL,ORDER_TYPE_TOTAL,Total Orders,Directed Orders Routed,Non Directed Orders Routed,Executed_Contracts,Net_Execution Fee/Rebate' as roe
     union all
     select
      coalesce(s.held_type::varchar, '')                   ||','||  -- as [HELD_TYPE]
      coalesce(s.date_v::varchar, '')                      ||','||  -- as [DATE]
      coalesce(s.venue::varchar, '')                       ||','||  -- as [Venue]
      coalesce(s.stock_group::varchar, '')                 ||','||  -- as [STOCK_GROUP]
      coalesce(s.order_type::varchar, '')                  ||','||  -- as [ORDER_TYPE]
      coalesce(s.total_orders::varchar, '')                ||','||  -- as [Total Orders]
      coalesce(s.directed_orders_routed::varchar, '')      ||','||  -- as [Directed Orders Routed]
      coalesce(s.non_directed_orders_routed::varchar, '')  ||','||  -- as [Non Directed Orders Routed]
      coalesce(s.executed_contracts::varchar, '')          ||','||  -- as [Executed_Contracts]
      coalesce(s.net_fee_rebate::varchar, '')                       -- as [Net_Execution Fee/Rebate]
    from
      (
        select coalesce(s_yc.held_type, s_cbd.held_type) as held_type
          , coalesce(s_yc.date_v, s_cbd.date_v) as date_v
          , coalesce(s_yc.venue, s_cbd.venue) as venue
          , coalesce(s_yc.stock_group, s_cbd.stock_group) as stock_group
          , coalesce(s_yc.order_type, s_cbd.order_type) as order_type
          , s_yc.total_orders as total_orders
          , s_yc.directed_orders_routed as directed_orders_routed
          , s_yc.non_directed_orders_routed as non_directed_orders_routed
          , s_cbd.executed_contracts as executed_contracts
          , s_cbd.net_fee_rebate as net_fee_rebate
        from
          (
            select
                case
                  when yc.instrument_type_id = 'O' then ''::varchar
                  else yc.is_held
                end as held_type
              , to_char(to_date(yc.exec_date_id::varchar, 'YYYYMMDD'), 'Mon-yy') as date_v
              , p_client_mpid as venue -- null::varchar as venue --
              , case
                  when yc.instrument_type_id = 'E' and yc.is_sp500 then 'NMS S&P 500'
                  when yc.instrument_type_id = 'E' then 'NMS Non S&P 500'
                  when yc.instrument_type_id = 'O' then 'NMS Options'
                  else 'ER'
                end as stock_group
              , case
                  when yc.instrument_type_id = 'O' and yc.multileg_reporting_type <> '1' then 'OTH'
                  when yc.order_type = 'Market' then 'MKT'
                  when yc.order_type = 'Marketable Limit' then 'MKL'
                  when yc.order_type = 'Non Marketable Limit' then 'LMT'
                  when yc.order_type = 'Other' then 'OTH'
                  else 'ER'
                end as order_type
              , count(distinct (case when p_report_legs='N' then yc.client_order_id else yc.client_order_id||yc.display_instrument_id end) ) as total_orders
              , count(distinct case when yc.is_directed = 'D' then (case when p_report_legs='N' then yc.client_order_id else yc.client_order_id||yc.display_instrument_id end) end) as directed_orders_routed
              , count(distinct case when yc.is_directed = 'ND' or yc.is_directed is null then (case when p_report_legs='N' then yc.client_order_id else yc.client_order_id||yc.display_instrument_id end) end) as non_directed_orders_routed
              , 0::bigint /*sum(yc.executed_volume)*/ as executed_contracts
              , 0.0::numeric /*round(sum(case when rd.is_directed = 'ND' then rd.fee_rebate else 0.0 end), 4)*/ as net_fee_rebate
            from tmp_606_s3_order_fyc yc
                 --trash.sdn_tmp_606_s3_order_fyc yc
            where 1=1
              and (yc.instrument_type_id = 'E' or (yc.instrument_type_id = 'O' and yc.notional_under_50k))
              -- need to suppress for RAJA the following exclusion of modifs
              and case when 1=1 -- p_client_mpid ilike 'RAJA%' -- https://dashfinancial.atlassian.net/browse/DEVREQ-4626 - allow modifications for all customers
                       then true
                       else yc.orig_order_id is null
                  end
            group by case
                  when yc.instrument_type_id = 'O' then ''::varchar
                  else yc.is_held
                end
              , to_char(to_date(yc.exec_date_id::varchar, 'YYYYMMDD'), 'Mon-yy')
              --, venue
              , case
                  when yc.instrument_type_id = 'E' and yc.is_sp500 then 'NMS S&P 500'
                  when yc.instrument_type_id = 'E' then 'NMS Non S&P 500'
                  when yc.instrument_type_id = 'O' then 'NMS Options'
                  else 'ER'
                end
              , case
                  when yc.instrument_type_id = 'O' and yc.multileg_reporting_type <> '1' then 'OTH'
                  when yc.order_type = 'Market' then 'MKT'
                  when yc.order_type = 'Marketable Limit' then 'MKL'
                  when yc.order_type = 'Non Marketable Limit' then 'LMT'
                  when yc.order_type = 'Other' then 'OTH'
                  else 'ER'
                end
          ) s_yc
        full outer join
          (
            select rd.held_type
              , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy') as date_v
              , p_client_mpid as venue -- null::varchar as venue --
              , rd.stock_group_total as stock_group
              , rd.order_type_total as order_type
              --, count(distinct (case when p_report_legs='Y' then rd.cl_ord_id_osi_series else rd.cl_ord_id end) ) as total_orders
              --, count(distinct case when rd.is_directed = 'D' then (case when p_report_legs='Y' then rd.cl_ord_id_osi_series else rd.cl_ord_id end) end) as directed_orders_routed
              --, count(distinct case when rd.is_directed = 'ND' then (case when p_report_legs='Y' then rd.cl_ord_id_osi_series else rd.cl_ord_id end) end) as non_directed_orders_routed
              , sum(rd.executed_volume) as executed_contracts
              , round(sum(case when rd.is_directed = 'ND' then rd.fee_rebate else 0.0 end), 4) as net_fee_rebate
            from tmp_606_s3_report_data rd
                 --trash.sdn_tmp_606_s3_report_data rd
              --left join tmp_606_s3_billing_entity_to_client_mpid clmp on rd.billing_entity = clmp.billing_entity
            where (rd.c_p = 'S' or rd.notional_under_50k = true )
            group by rd.held_type
              , to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy')
              , rd.stock_group_total
              , rd.order_type_total
          ) s_cbd
            on s_yc.held_type = s_cbd.held_type
            and s_yc.stock_group = s_cbd.stock_group
            and s_yc.order_type = s_cbd.order_type
      ) s
    ;
   end if;


  if p_606s3_file_type = 'S3_Vision'
  then
  -- added by SO
  select array_agg(distinct account_id) from genesis2.account
  where trading_firm_id in ('LPTF332', 'vision01') into l_account_ids;
   -- end of added by SO
   RETURN QUERY
    select 'Exchange Name,Total,Market,Limit,Other' as roe
    union all
    select
      coalesce(s.exchange_name::varchar, '')                   ||','||  -- as [Exchange Name]
      coalesce(s.total_qty::varchar, '')                       ||','||  -- as [Total]
      coalesce(s.market_qty::varchar, '')                      ||','||  -- as [Market]
      coalesce(s.limit_qty::varchar, '')                       ||','||  -- as [Limit]
      coalesce(s.other_qty::varchar, '')                                -- as [Other]

      as roe
    from
      (
        select s.real_exchange_id as exchange_name
          , sum(s.order_count)::bigint as total_qty
          , sum(case when s.order_type = 'Market' then s.order_count else 0 end)::bigint as market_qty
          , sum(case when s.order_type = 'Limit' then s.order_count else 0 end)::bigint as limit_qty
          , sum(case when s.order_type = 'Other' then s.order_count else 0 end)::bigint as other_qty
        from
          (
            select yc.real_exchange_id
              , case
                  when yc.instrument_type_id = 'O' and yc.multileg_reporting_type = '2' then 'Other'
                  when yc.order_type_id = '1' then 'Limit'
                  when yc.order_type_id = '2' then 'Market'
                  else 'Other'
                end::varchar as order_type
              , count( distinct (case when p_report_legs = 'N' then yc.client_order_id else yc.client_order_id||hsd.display_instrument_id end) ) as order_count
            from staging.f_yield_capture yc
              join genesis2.account a on (a.account_id = yc.account_id) --dwh.d_account a on (a.account_id = yc.account_id)
              join genesis2.instrument hsd on (hsd.instrument_id = yc.instrument_id) -- dwh.historic_security_definition_all hsd on (hsd.instrument_id = yc.instrument_id)
            where yc.status_date_id between l_start_date_id and l_end_date_id -- 20220401 and 20220430 --
              -- added by SO
              and yc.account_id = any(l_account_ids)
              -- end of added by SO
              and a.trading_firm_id in ('LPTF332', 'vision01') -- = 'OFP0038' --any(l_trading_firm_ids) = any (l_companies) --
              and yc.instrument_type_id = 'O'
              and yc.parent_order_id is not null
            group by real_exchange_id, order_type
            order by 1
          ) s
        group by s.real_exchange_id
      ) s
    ;
      GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
      raise NOTICE 'l_row_cnt = % ', l_row_cnt;
   end if;


  if p_606s3_file_type = 'S3_FMR_cust'
  then

   RETURN QUERY
    with cte_cbd as materialized
      (
        select cbd.billing_entity
          , cbd.cl_ord_id
          , cbd.fix_comp_id
          , sum(cbd.pfoftf) as pfoftf
          , sum(coalesce(cbd.net_rebate_fee, 0.0)) as net_fee_rebate
        from dash_reporting.s3_customer_billing_detail_for_606_report cbd
        where cbd.date_id between l_start_date_id and l_end_date_id --20220401 and 20220430
          and cbd.billing_entity in ('FIDOFP', 'NFSCBOE','NFSCBOE_HT')
          and cbd.filled_qty > 0
          --and coalesce(cbd.net_rebate_fee, 0.0) = 0.0
        group by cbd.billing_entity
          , cbd.cl_ord_id
          , cbd.fix_comp_id
      )
    -- Header Record
    select concat(s.hdr_id, '/', s.hdr_date, '/', s.hdr_iorid, '/', s.hdr_prcs_yr, '/', s.hdr_prcs_qtr, '/', s.hdr_prcs_mth, s.filler) as roe
    from
      (
        select
            'H' as hdr_id
          , public.get_dateid(current_date)::text as hdr_date
          , 'DASHECON' as hdr_iorid
          , to_char(to_date(l_start_date_id::varchar,'YYYYMMDD'), 'YYYY') as hdr_prcs_yr
          , lpad(extract(quarter from to_date(l_start_date_id::varchar,'YYYYMMDD'))::text, 2, '0') as hdr_prcs_qtr
          , to_char(to_date(l_start_date_id::varchar,'YYYYMMDD'), 'MM') as hdr_prcs_mth
          , repeat(' ', 170) as filler
      ) s

    union all

    -- Detail Record (RHUB route)
    select concat(s.rec_i, '/', s.market_place, '/', s.market_sequence, '/', s.account_prefix, '/', s.account_number, '/', s.order_id, ',', s.nfr_sign, s.fee_rebate_dollars, '.', s.fee_rebate_decimals, s.filler) as roe
    from
      (
        select
            'D' as rec_i
          , repeat(' ', 2) as market_place
          , repeat(' ', 4) as market_sequence
          , repeat(' ', 3) as account_prefix
          , repeat(' ', 6) as account_number
          , rpad(cbd.cl_ord_id, 21, ' ') as order_id
          , case when cbd.net_fee_rebate >= 0 then ' ' else '-' end as nfr_sign
          --, lpad( (string_to_array(abs(cbd.net_fee_rebate)::text, '.'))[1], 13, '0') as fee_rebate_dollars
          , lpad( trunc(abs(cbd.net_fee_rebate))::text, 13, '0') as fee_rebate_dollars
          --, left((string_to_array(cbd.net_fee_rebate::text, '.'))[2], 5) as fee_rebate_decimals
          , left(rpad(substr(mod(abs(cbd.net_fee_rebate), 1)::text, 3), 5, '0'), 5) as fee_rebate_decimals
          , repeat(' ', 137) as filler
        from cte_cbd cbd
        where cbd.fix_comp_id not like 'NFSC%' or cbd.fix_comp_id is null
        order by 6 -- cl_ord_id
      ) s

    union all

    -- Detail Record (FBSI route)
    select concat(s.rec_i, '/', s.order_id, ',', s.nfr_sign, s.fee_rebate_dollars, '.', s.fee_rebate_decimals, s.filler) as roe
    from
      (
        select
            'D' as rec_i
          , rpad(cbd.cl_ord_id, 40, ' ') as order_id
          , case when cbd.net_fee_rebate >= 0 then ' ' else '-' end as nfr_sign
          --, lpad( (string_to_array(abs(cbd.net_fee_rebate)::text, '.'))[1], 13, '0') as fee_rebate_dollars
          , lpad( trunc(abs(cbd.net_fee_rebate))::text, 13, '0') as fee_rebate_dollars
          --, left((string_to_array(cbd.net_fee_rebate::text, '.'))[2], 5) as fee_rebate_decimals
          , left(rpad(substr(mod(abs(cbd.net_fee_rebate), 1)::text, 3), 5, '0'), 5) as fee_rebate_decimals
          , repeat(' ', 137) as filler
        from cte_cbd cbd
        where cbd.fix_comp_id like 'NFSC%'
        order by 2 -- cl_ord_id
      ) s

    union all

    -- Trailer Record
    select concat(s.tlr_id, '/', s.tlr_count, s.filler) as roe
    from
      (
        select 'T' as tlr_id
          , lpad((count(1))::text, 9, '0') as tlr_count
          , repeat(' ', 189) as filler
        from cte_cbd cbd
      ) s
    ;
   end if;

  if p_606s3_file_type in ('S3_Ally_cust') -- the logic is the same as it is for 'S3_Standard'
  then
   RETURN QUERY
    select 'DATE,CLIENT_ID,Venue,STOCK_GROUP,ORDER_TYPE,EXECUTED_QUANTITY,NET_EXECUTION' as header_row
    ;

   RETURN QUERY
    select
      coalesce(s.date_v::varchar, '')                  ||','||  -- as [DATE]
      coalesce(s.client_id::varchar, '')               ||','||  -- as [CLIENT_ID]
      coalesce(s.venue::varchar, '')                   ||','||  -- as [Venue]
      coalesce(s.stock_group::varchar, '')             ||','||  -- as [STOCK_GROUP]
      coalesce(s.order_type::varchar, '')              ||','||  -- as [ORDER_TYPE]
      coalesce(s.executed_quantity::varchar, '')       ||','||  -- as [EXECUTED_QUANTITY]
      coalesce(s.net_execution::varchar, '')                    -- as [NET_EXECUTION]
    from
      (
        select to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy') as date_v
          --, 'MBTS' as client_id -- ?
          , p_client_mpid as client_id -- null::varchar as venue --
          , 'DASH' as venue
          , rd.stock_group::varchar as stock_group
          , case
              when s3op_notional_under_50k = false and rd.c_p in ('C', 'P') -- Oversize is for Opt only DEVREQ-3769
                then 'Oversize'
              else rd.order_type::varchar
            end as order_type
          , sum(rd.executed_volume) as executed_quantity
          , sum(rd.fee_rebate) as net_execution
        from tmp_606_s3_report_data rd
             -- trash.sdn_tmp_606_s3_report_data rd
        where 1=1
          --and (rd.c_p = 'S' or rd.notional_under_50k = true )
          and rd.billing_entity not in ('ICP_QCC', 'ICP_EMF')
          --and rd.is_directed = 'ND' --Exclude directed orders
          and coalesce(rd.is_directed,'ND') = 'ND' --Exclude directed orders
          and ((rd.c_p = 'S' and rd.held_type = 'H') or (rd.c_p in ('C', 'P') and rd.held_type = ''))
          --and case when p_606s3_file_type = 'S3_T3_cust' then rd.cbd_range = 'CUST' else true end
        group by to_char(to_date(rd.date_id::varchar, 'YYYYMMDD'), 'Mon-yy')
          , rd.stock_group::varchar
          , case
              when s3op_notional_under_50k = false and rd.c_p in ('C', 'P') -- Oversize is for Opt only DEVREQ-3769
                then 'Oversize'
              else rd.order_type::varchar
            end
      ) s
    ;
   end if;


   select public.load_log(l_load_id, l_step_id, 'dash360.report_606_s3 COMPLETE===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

end;
$function$
;
