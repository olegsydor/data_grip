create or replace function trash.report_gtc_gtd_schwab_blue_open_order(p_date_id integer default null::integer,
                                                                       p_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                       p_account_ids integer[] default '{}'::integer[],
                                                                       p_sub_system_id character varying[] default null::character varying[],
                                                                       p_fix_comp_id character varying[] default '{}'::character varying[])
    returns table
            (
                export_row text
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-3456 SO 20230831 added input parameter: p_account_name
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-3456 SO 20230919 replaced p_account_name with p_account_ids
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-3706 SO 20231106 added new input parameter p_session
declare
    l_row_cnt           integer;
    l_current_date_id   integer;
    l_gtc_date_id       integer;
    l_trading_firm_ids  character varying[];
    l_account_ids       int4[];
    l_sub_system_unq_id int2[];
    l_load_id           integer;
    l_step_id           integer;
    l_fix_connection_id int4[];
    l_dash_ht_opt_f2_j2 bool;

begin
  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_gtd_schwab_blue_open_order STARTED===', 0, 'O')
   into l_step_id;

   l_current_date_id := coalesce(p_date_id, (to_char(NOW(), 'YYYYMMDD'))::integer);

--    l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY['OFP0028'] else p_trading_firm_ids end;
   l_trading_firm_ids := p_trading_firm_ids;


  select array_agg(account_id)
  into l_account_ids
  from dwh.d_account
  where case
            when coalesce(p_account_ids, '{}') <>  '{}' then account_id = any(p_account_ids)
            when coalesce(l_trading_firm_ids, '{}') <> '{}' then trading_firm_id = any (l_trading_firm_ids)
            else trading_firm_id = 'nothing' end;


  select array_agg(distinct sub_system_unq_id)
  into l_sub_system_unq_id
  from dwh.d_sub_system
  where case
            when p_sub_system_id is not null then sub_system_id = any (p_sub_system_id)
            else sub_system_id = 'nothing' end;

  select array_agg(fix_connection_id)
  into l_fix_connection_id
  from dwh.d_fix_connection
  where case
            when coalesce(p_fix_comp_id, '{}') <> '{}' then fix_comp_id = any (p_fix_comp_id)
            else fix_comp_id = 'nothing end' end;

  l_dash_ht_opt_f2_j2 := case
                             when 'SCHWABTDOE' = any (p_fix_comp_id) or exists (select null
                                                                                from dwh.d_account
                                                                                where account_id = any (p_account_ids)
                                                                                  and account_name = 'CHAS') then true
                             else false end;

    select public.load_log(l_load_id, l_step_id, left(' trading_firm_ids = '||l_trading_firm_ids::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, ' Period: l_current_date_id = '||l_current_date_id::varchar||', l_gtc_date_id = '||l_gtc_date_id::varchar, 0, 'O')
   into l_step_id;


  execute 'DROP TABLE IF EXISTS tmp_gtc_schwab_roe;';
  create temp table tmp_gtc_schwab_roe with (parallel_workers = 4) ON COMMIT drop as
  --insert into tmp_gtc_recon_schwab_roe (roe)
  select
    coalesce(s.order_number::varchar, '')                   ||'|'|| --
    coalesce(s.order_leg_id::varchar, '')                   ||'|'|| --
    coalesce(s.order_entity_date::varchar, '')              ||'|'|| --
    coalesce(s.action_::varchar, '')                        ||'|'|| --
    coalesce(s.type_::varchar, '')                          ||'|'|| --
    coalesce(s.order_quantity::varchar, '')                 ||'|'|| --
    coalesce(s.order_remaining_quantity::varchar, '')       ||'|'|| --
    coalesce(s.equity_option::varchar, '')                  ||'|'|| --
    coalesce(s.symbol_equity::varchar, '')                  ||'|'|| --
    coalesce(s.option_root::varchar, '')                    ||'|'|| --
    coalesce(s.call_puts::varchar, '')                      ||'|'|| --
    coalesce(s.close_open::varchar, '')                     ||'|'|| --
    coalesce(s.option_expiration_date::varchar, '')         ||'|'|| --
    coalesce(s.strike_price::varchar, '')                   ||'|'|| --
    coalesce(s.limit_price::varchar, '')                    ||'|'|| --
    coalesce(s.stop_price::varchar, '')                     ||'|'|| --
    coalesce(s.time_in_force::varchar, '')                  ||'|'|| --
    coalesce(s.order_expiration_date::varchar, '')          ||'|'|| --
    coalesce(s.aon_nh::varchar, '')                                 --
    as roe
  from
    (
      select co.client_order_id as order_number
        , case
            when co.multileg_reporting_type = '1'
              then '0'
            when co.multileg_reporting_type = '2'
              then dense_rank() over (partition by co.multileg_order_id order by gtc.order_id) -- leg_number
          end as order_leg_id
        , to_char(co.create_time , 'MMDDYYYY') as order_entity_date
        , case co.side
            when '1' then 'B'
            when '2' then 'S'
            when '5' then 'SS'
            when '6' then 'SS'
          end as action_
        , case co.order_type_id
            when '1' then 'M'
            when '2' then 'L'
            when '3' then 'S'
            when '4' then 'SL'
            else 'L'
          end as type_
        , co.order_qty as order_quantity
        , ex.leaves_qty as order_remaining_quantity -- ???
          --, ex.cum_qty
        , di.instrument_type_id as equity_option
        , case
            when di.instrument_type_id = 'E'
              then di.symbol
          end as symbol_equity
        , os.root_symbol as option_root
        , case oc.put_call
            when '0' then 'P'
            when '1' then 'C'
          end as call_puts
        , co.open_close as close_open
        , case
            when di.instrument_type_id = 'O'
              then to_char(di.last_trade_date, 'MMDDYY')
          end as option_expiration_date
        , oc.strike_price::numeric(12,4) as strike_price
        , co.price::numeric(12,4) as limit_price
        , co.stop_price::numeric(12,4) as stop_price
        , case co.time_in_force_id
            when '1' then 'GTC'
            when '6' then 'GTD'
            else co.time_in_force_id
          end as time_in_force
        , to_char(co.expire_time, 'MMDDYYYY') as order_expiration_date
        , case
            when co.exec_instruction like '%G%' then 'AON'
            when co.exec_instruction like '%l%' then 'NH'
          end as aon_nh
         from (
         select * from dwh.gtc_order_status gtc
          where close_date_id is null
        and gtc.create_date_id <= l_current_date_id -- created today or earlier -- 20221005 --
        and gtc.time_in_force_id in ('1', '6')
        and case when l_account_ids is not null then gtc.account_id = any(l_account_ids) else true end
          union all
          select * from dwh.gtc_order_status gtc
          where close_date_id is not null
          and close_date_id > l_current_date_id
        and gtc.create_date_id <= l_current_date_id -- created today or earlier -- 20221005 --
        and gtc.time_in_force_id in ('1', '6')
        and case when l_account_ids is not null then gtc.account_id = any(l_account_ids) else true end
        ) gtc
        inner join lateral
          (
            select co.client_order_id
              , co.time_in_force_id
              , co.multileg_reporting_type
              , co.multileg_order_id
              , co.create_time, co.side , co.order_type_id , co.order_qty
              , co.instrument_id , co.open_close, co.price, co.stop_price
              , co.expire_time, co.exec_instruction
              , co.sub_system_unq_id
            from dwh.client_order co
            where co.create_date_id = gtc.create_date_id
              and co.order_id = gtc.order_id
              and co.multileg_reporting_type <> '3'
            and co.parent_order_id is null
            and case when l_sub_system_unq_id is not null then co.sub_system_unq_id = any(l_sub_system_unq_id) else true end
            and case when l_fix_connection_id is not null then co.fix_connection_id = any(l_fix_connection_id) else true end
          ) co on true
        left join dwh.d_account ac
          on gtc.account_id = ac.account_id
        left join dwh.d_instrument di
          on co.instrument_id = di.instrument_id
        left join dwh.d_option_contract oc
          on di.instrument_id = oc.instrument_id
        left join dwh.d_option_series os
          on oc.option_series_id = os.option_series_id
        left join lateral
          (
            select ex.order_id
              , ex.leaves_qty, ex.cum_qty
            from dwh.execution ex
            where ex.order_id = gtc.order_id
              and ex.order_status <> '3' -- not done for day
              and ex.exec_date_id <= l_current_date_id -- open for today -- 20221005 --
            and ex.exec_date_id >= gtc.create_date_id
            order by ex.exec_id desc
            limit 1
          ) ex on true
      where 1=1
--      and case when l_account_ids is not null then gtc.account_id = any(l_account_ids) else true end
    ) s
  ;
   GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Found: % rows', l_row_cnt;
   select public.load_log(l_load_id, l_step_id, 'insert into tmp_gtc_schwab_roe ', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

--   l_row_cnt := coalesce((select count(1) from tmp_gtc_schwab_roe), 0);

   return query
       select case
                  when l_dash_ht_opt_f2_j2 then 'DASH_HT_OPT_F2_J2'
                  else 'DASH_OPT_F1_J1'::varchar end || '|' || -- Destination  <Market Maker Line Name>
              to_char(to_date(l_current_date_id::varchar, 'YYYYMMDD'), 'MMDDYYYY'); -- File Creation Date

     return query
     select roe from tmp_gtc_schwab_roe;

     return query
     select
       'Total Number of Records'     ||'|'|| --
       coalesce(l_row_cnt, 0)::varchar;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_gtd_schwab_blue_open_order COMPLETED===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

END;
$function$
;


select fix_message->>'1' from fix_capture.fix_message_json
where date_id = 20231103
and fix_message->>'1' = 'CHAS2';


select * from dwh.d_account
where account_name ilike 'CHAS%'


select * from dwh.d_fix_connection
where fix_comp_id ilike 'SCHWAB%';

select distinct account_id, fix_comp_id from dwh.client_order
                                        join dwh.d_fix_connection using(fix_connection_id)
where create_date_id = 20231103
and fix_connection_id in (3467,3468,3469,3466,3470,9446)



select * from dash360.report_gtc_gtd_schwab_blue_open_order(p_account_ids := '{34069, 68488}');
select * from trash.report_gtc_gtd_schwab_blue_open_order(p_account_ids := '{34069, 68488}', p_fix_comp_id := '{"SCHWABOFP", "SCHWABTDAMOFP1"}');
select * from trash.report_gtc_gtd_schwab_blue_open_order(p_account_ids := '{34069, 68488}', p_fix_comp_id := '{"SCHWABOFP"}');
select * from trash.report_gtc_gtd_schwab_blue_open_order(p_account_ids := '{34069, 68488}', p_fix_comp_id := '{"SCHWABTDOE"}');
select * from trash.report_gtc_gtd_schwab_blue_open_order(p_fix_comp_id := '{"SCHWABTDOE"}');

select * from trash.report_gtc_gtd_schwab_blue_open_order(p_fix_comp_id := '{"SCHWABOFP"}');
select * from trash.report_gtc_gtd_schwab_blue_open_order(p_account_ids := '{XXXXXX}'