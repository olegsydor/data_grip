DROP FUNCTION trash.report_gtc_fidelity_retail(character varying,
                                                 character varying[],
                                                 character varying,
                                                 integer[],
                                                 int4,
                                                 int4);
select *
from dash360.report_gtc_fidelity_retail(in_start_date_id := 20240108, in_end_date_id := 20240108,
                                        p_is_multileg_report := 'Y', p_trading_firm_ids := '{"OFP0022"}',
                                        p_account_ids := '{29609}');

insert into trash.fidelity
select *, 'o'
from dash360.report_gtc_fidelity_retail(p_report_date_id := 20240108, p_is_multileg_report := 'Y', p_trading_firm_ids := '{"OFP0022"}', p_account_ids := '{29609}')


select export_row from trash.fidelity
where src = 'n'
except
select export_row from trash.fidelity
where src = 'o'


CREATE or replace FUNCTION dash360.report_gtc_fidelity_retail(p_is_multileg_report character varying DEFAULT 'N'::character varying,
                                                 p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                 p_instrument_type_id character varying DEFAULT NULL::character varying,
                                                 p_account_ids integer[] DEFAULT '{}'::integer[],
                                                 in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                 in_end_date_id int4 default to_char(current_date, 'yyyymmdd')::int4)
    returns table
            (
                export_row text
            )
    language plpgsql
as
$function$
declare
    l_row_cnt                 integer;
    l_instrument_type         varchar;
    l_multileg_reporting_type bpchar(1);
    l_account_ids             int4[];
    l_gtc_date_id             integer;
    l_load_id                 integer;
    l_step_id                 integer;
    l_is_current_date         bool := false;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_fidelity_retail for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;
    l_gtc_date_id :=
            to_char((to_date(in_start_date_id::varchar, 'YYYYMMDD') - interval '24 months'), 'YYYYMMDD')::integer;

  select array_agg(account_id)
  into l_account_ids
  from dwh.d_account
  where true
    and case when coalesce(p_account_ids, '{}') = '{}' then true else account_id = any (p_account_ids) end
    and case
            when p_trading_firm_ids = '{}' then trading_firm_id = 'OFP0022'
            else trading_firm_id = any (p_trading_firm_ids) end;

   l_multileg_reporting_type := case when p_is_multileg_report = 'Y' then '2' else '1' end;

   l_instrument_type := p_instrument_type_id;

    select public.load_log(l_load_id, l_step_id, left(' account_ids = '||l_account_ids::varchar, 200), 0, 'O')
   into l_step_id;

  create temp table if not exists tmp_gtc_fidelity_retail_roe
    (
      roe  text
    )
  on commit DROP;
  truncate table tmp_gtc_fidelity_retail_roe;

  DROP TABLE IF EXISTS tmp_gtc_fidelity_retail_ord_open;
  create temp table tmp_gtc_fidelity_retail_ord_open with (parallel_workers = 4)
                                                     ON COMMIT drop as
  select gtc.account_id,
         gtc.order_id,
         cl.client_order_id,
         gtc.create_date_id,
         cl.instrument_id,
         cl.order_type_id,
         cl.time_in_force_id,
         cl.stop_price,
         cl.price,
         cl.order_qty,
         cl.create_time,
         cl.side,
         cl.open_close,
         gtc.close_date_id
  from dwh.gtc_order_status gtc
           join dwh.client_order cl using (order_id, create_date_id)
  join dwh.d_instrument di on di.instrument_id = cl.instrument_id
  where true
  and cl.account_id = any(l_account_ids)
    and cl.parent_order_id is null
    and case when l_instrument_type is null then true else instrument_type_id = l_instrument_type end
    and gtc.time_in_force_id = '1'
--       and gtc.create_date_id >= :l_gtc_date_id
    and gtc.create_date_id <= in_start_date_id
    and cl.sub_strategy_id in (select dts.target_strategy_id
                               from dwh.d_target_strategy dts
                               where dts.target_strategy_name = 'RETAIL')       -- only 9000 tag = RETAIL
      and (gtc.close_date_id is null
           or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
    and cl.multileg_reporting_type = l_multileg_reporting_type
--   and cl.client_order_id in ('JZ/6232/X42/799840/24005HAEZH ')
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Found: % rows', l_row_cnt;
   select public.load_log(l_load_id, l_step_id, 'insert into tmp_gtc_fidelity_retail_ord_open ', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

  --return;

  if p_is_multileg_report = 'N'
  then
     -- Report Name: Fidelity Single-leg Open Order Report
    insert into tmp_gtc_fidelity_retail_roe (roe)
    select s.daso_mm_firm
        || s.daso_ord_date
        || s.daso_mkt_seq
        || s.daso_action
        || s.daso_put_call_ind
        || s.daso_open_close_ind
        || s.daso_quantity
        || s.daso_opra_code
        || s.daso_udly_symbol
        || s.daso_optn_symbol
        || s.daso_exp_year
        || s.daso_month_name
        || s.daso_month_num
        || s.daso_exp_day
        || s.daso_strike_price
        || s.daso_mkt_lmt
        || s.daso_lmt_price
        || s.daso_stp_price
        || s.daso_tif
        || s.daso_listed_otc_ind
        || s.daso_order_num
        || s.filler
        || s.daso_d_rec_id

        as roe
    -- select s.* --s.trading_firm_id, s.gts_is_closed, count(1) as cnt
    from
      (
        select 'DASO' as daso_mm_firm
          , to_char(co.create_time, 'YYMMDD') as daso_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as daso_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as daso_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as daso_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as daso_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as daso_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0))::varchar,8,'0') as daso_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as daso_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as daso_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as daso_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as daso_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as daso_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as daso_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as daso_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as daso_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as daso_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_lmt_price
          , lpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as daso_tif
          , 'LST' as daso_listed_otc_ind
          --, lpad(' ',19,' ')
          --|| lpad(co.client_order_id,10,' ') as daso_order_num
          , lpad(co.client_order_id,29,' ') as daso_order_num
          , lpad(' ',28,' ') as filler
          , '2' as daso_d_rec_id
          , case
              --when coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0) >= co.order_qty then 1 -- order is filled -- too long
              when ex.max_exec_type = '4' then 1 -- order is cancelled
              when ex.max_exec_type = '8' then 1 -- order was rejected
              when ex.max_order_status in ('2', '4', '5', '8') then 1 -- order status: filled, canceled, replaced, rejected
              --when coalesce(di.last_trade_date, current_timestamp) <= current_timestamp  then 1 -- Expiration date of instrument is exceeded
              when to_char(coalesce(di.last_trade_date, current_timestamp), 'YYYYMMDD')::integer < in_start_date_id  then 1 -- Expiration date of instrument is exceeded
              else 0
            end as gts_is_closed
          --, ac.trading_firm_id
          --, co.*
        from --tmp_gtc_fidelity_retail_ord fyc
             tmp_gtc_fidelity_retail_ord_open fyc
          inner join lateral
            (
              select cl.client_order_id
                , cl.create_time
                , cl.side, cl.open_close
                , cl.order_qty, cl.price, cl.stop_price
                , cl.parent_order_id
                , cl.instrument_id, cl.order_type_id, cl.time_in_force_id
                , cl.order_id, cl.create_date_id
              from dwh.client_order cl
              where cl.order_id = fyc.order_id
                and cl.sub_strategy_id in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                and cl.multileg_reporting_type = l_multileg_reporting_type
                and cl.trans_type <> 'F'
                and cl.create_date_id >= l_gtc_date_id
                and cl.create_date_id <= in_start_date_id
                and cl.parent_order_id is null
            ) co on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc
            on oc.instrument_id = co.instrument_id
          left join dwh.d_instrument di
            on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot
            on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif
            on co.time_in_force_id = tif.tif_id
          left join lateral
            (
              select ex.order_id
                , max(ex.exec_type) as max_exec_type
                , max(ex.order_status) as max_order_status
                --, sum(case when ex.exec_type in ('F','1','2') then ex.last_qty else 0 end) as cum_qty
                , max(ex.exec_time) as max_exec_time
              from dwh.execution ex
              where ex.exec_date_id >= l_gtc_date_id
                and ex.exec_date_id <= in_start_date_id
                and ex.order_id = co.order_id
                --and ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej
                and
                  (
                    --ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej, replaced
                    ex.exec_type in ('4','8') -- fill, canc, rej, replaced
                    or
                    ex.order_status in ('2', '4', '5', '8') -- fill, canc, rej, replaced
                  )
                and is_busted = 'N'
              group by ex.order_id
              limit 1
            ) ex on true
        where true
      ) s
    where true
      and s.gts_is_closed = 0
    ;

  else
     -- Report Name: Fidelity Multi-leg Open Order Report
    insert into tmp_gtc_fidelity_retail_roe (roe)
    select s.dasm_mm_firm
        || s.dasm_ord_date
        || s.dasm_mkt_seq
        || s.dasm_action
        || s.dasm_put_call_ind
        || s.dasm_open_close_ind
        || s.dasm_quantity
        || s.dasm_opra_code
        || s.dasm_udly_symbol
        || s.dasm_optn_symbol
        || s.dasm_exp_year
        || s.dasm_month_name
        || s.dasm_month_num
        || s.dasm_exp_day
        || s.dasm_strike_price
        || s.dasm_mkt_lmt
        || s.dasm_lmt_price
        || s.dasm_stp_price
        || s.dasm_tif
        || s.dasm_listed_otc_ind
        || s.dasm_order_id
        || s.filler
        || s.dasm_d_rec_id

        as roe
    -- select s.* --s.trading_firm_id, s.gts_is_closed, count(1) as cnt
    from
      (

        select 'DASM' as dasm_mm_firm
          , to_char(co.create_time, 'YYMMDD') as dasm_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as dasm_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as dasm_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as dasm_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as dasm_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as dasm_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders_interval(in_order_id => co.order_id, in_date_id => co.create_date_id, in_max_date_id => in_start_date_id), 0))::varchar, 8, '0') as dasm_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as dasm_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as dasm_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as dasm_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as dasm_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as dasm_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as dasm_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as dasm_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as dasm_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as dasm_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_lmt_price
          , lpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as dasm_tif
          , 'LST' as dasm_listed_otc_ind
          , lpad(co.client_order_id,29,' ') as dasm_order_id -- filler(19) + order_id(10)
          , lpad(' ',2,' ') as filler
          , '2' as dasm_d_rec_id
            , case when close_date_id is null then 0
            when close_date_id <= in_start_date_id then 1
            else 0
            end as gts_is_closed
        from tmp_gtc_fidelity_retail_ord_open co
            inner join lateral
              (
                select 1
                from dwh.client_order cl
                where cl.order_id = co.order_id
                  and cl.sub_strategy_id = 78 --in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                  and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                  and cl.multileg_reporting_type = '2' --l_multileg_reporting_type
                  and cl.trans_type <> 'F'
                  and cl.create_date_id >= l_gtc_date_id
                  and cl.create_date_id <= in_start_date_id
                  and cl.parent_order_id is null
                  limit 1
              ) co_in on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc on oc.instrument_id = co.instrument_id
          left join dwh.d_option_series dos on dos.option_series_id = oc.option_series_id
          left join dwh.d_instrument di    on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot      on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif  on co.time_in_force_id = tif.tif_id

        where true
        and coalesce (close_date_id, 30011231) > in_end_date_id  -- as a max date to comare
        and case when (di.symbol in ('VIX', 'SPX') and di.last_trade_date = in_start_date_id::text::date + interval '1 day') then false else true end
      ) s
    where true
--      and s.gts_is_closed = 0
    ;
  end if;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Found: % rows', l_row_cnt;
   select public.load_log(l_load_id, l_step_id, 'insert into tmp_gtc_fidelity_retail_roe ', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

  l_row_cnt := coalesce((select count(1) from tmp_gtc_fidelity_retail_roe), 0);

  if p_is_multileg_report = 'N'
  then
     -- Report Name: Fidelity Single-leg Open Order Report
   RETURN QUERY
     select
       rpad('DASO'::varchar, 4, ' ') || -- DASO-FILE-ID
       rpad(to_char(to_date(in_start_date_id::varchar,'YYYYMMDD'), 'YYMMDD'), 6, ' ') || -- DASO-FILE-DATE  l_current_date_id - Current business date
       rpad(' '::varchar, 151, ' ') || -- FILLER
       rpad('1'::varchar, 1, ' ') -- DASO-H-REC-ID
     union all
     select t.roe from tmp_gtc_fidelity_retail_roe t
     union all
     select
       lpad(l_row_cnt::varchar, 6, '0') || -- DASO-REC-COUNT
       rpad(' '::varchar, 155, ' ') ||  -- FILLER in spaces
       rpad('9'::varchar, 1, ' ')      -- DASO-T-REC-ID
     ;
  else
     -- Report Name: Fidelity Multi-leg Open Order Report
   RETURN QUERY
     select
       rpad('DASM'::varchar, 4, ' ') || -- DASM-FILE-ID
       rpad(to_char(to_date(in_start_date_id::varchar,'YYYYMMDD'), 'YYMMDD'), 6, ' ') || -- DASM-FILE-DATE  l_current_date_id - Current business date
       rpad(' '::varchar, 125, ' ') || -- FILLER
       rpad('1'::varchar, 1, ' ') -- DASM-H-REC-ID
     union all
     select t.roe from tmp_gtc_fidelity_retail_roe t
     union all
     select
       lpad(l_row_cnt::varchar, 6, '0') || -- DASM-REC-COUNT
       rpad(' '::varchar, 129, ' ') ||  -- FILLER in spaces
       rpad('9'::varchar, 1, ' ')      -- DASO-T-REC-ID
     ;
  end if;

  --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
  --RAISE INFO 'Exported: % rows', l_row_cnt;

  select public.load_log(l_load_id, l_step_id,
                         'dash360.report_gtc_fidelity_retail for ' || in_start_date_id::text || '-' ||
                         in_end_date_id::text || ' STARTED===',
                         coalesce(l_row_cnt, 0), 'E')
  into l_step_id;

END;
$function$
;
