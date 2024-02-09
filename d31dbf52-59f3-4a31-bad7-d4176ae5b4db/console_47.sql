-- DROP PROCEDURE dash_reporting.get_consolidator_eod_cutler_copy_sep_1(date);

CREATE OR REPLACE PROCEDURE dash_reporting.get_consolidator_eod_cutler_copy_sep_1(IN in_date date DEFAULT CURRENT_DATE)
 LANGUAGE plpgsql
AS $procedure$
declare
  -- 20231002 OS https://dashfinancial.atlassian.net/browse/DEVREQ-3584 removed date_id from where condition ~ 444 row

    l_load_id int;
    l_step_id int;
    row_cnt   int;
    l_date_id int4;
    l_acc_ids int4[];
    f_day_1 timestamp := in_date::date::timestamp;
    f_day_2 timestamp := in_date::date::timestamp + interval '1 day';
    counter int4 := 1;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    l_date_id = to_char(in_date, 'YYYYMMDD')::int4;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 STARTED ====', l_date_id, 'O')
    into l_step_id;

/*
    -- Checking if all expected rows in cons_lite_parent_to_rfr were loaded
    -- or pause for 30 * pg_sleep(x) seconds
    while counter < 3 and (select count(*)
                            from (select rfr_id--, message
                                  from consolidator.consolidator_message
                                  where message_type in (6, 7)
                                    and date_id = l_date_id
                                    and request_number in (0)
                                    and message ilike '%cutler%'
                                  except
                                  select rfr_id
                                  from consolidator.cons_lite_parent_to_rfr
                                  where date_id = l_date_id) x) > 0
        loop
            perform pg_sleep(30);
            counter := counter + 1;
        end loop;
     if counter = 3 then
       perform public.send(
           in_to := 'oleh.sydor@iongroup.com,katherine.erhardt@iongroup.com,savyona.abel@iongroup.com,oleksandr.semenchenko@iongroup.com',
           in_subject := 'WARNING: Daily report for Cutler has been sent with missing rfr_ids: ' || l_date_id::text,
           in_body := 'Daily report for Cutler has been sent with missing rfr_ids.');
     end if;
  */
     select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 cons_lite_parent_to_rfr passed ====', counter, 'O')
     into l_step_id;

    -- preparing data
    -- temp table for all gtc orders active within the timeslot NOT INCLUDING REPORTING DATE
create temp table t_accounts as
    select account_id from dwh.d_account ac
             join lateral (select
                           from dwh.d_trading_firm tf
                           where tf.trading_firm_id = ac.trading_firm_id
                             and tf.is_eligible4consolidator = 'Y'
                           limit 1) tf on true
    where true
      and (ac.date_start, coalesce(ac.date_end, '2399-01-01'::date)) overlaps
          (f_day_1, f_day_2)
    into l_acc_ids;

    drop table if exists t_gos;

    create temp table t_gos as
    select gtc.create_date_id, gtc.order_id, gtc.close_date_id
    from dwh.gtc_order_status gtc
             join lateral (select 1
                           from dwh.client_order co
                           where co.create_date_id = gtc.create_date_id
                             and co.order_id = gtc.order_id
                             and co.multileg_reporting_type = '1'
                           limit 1) co on true
    where (create_date_id::text::date, coalesce(close_date_id::text::date, '2399-12-31')) overlaps
          (:in_date - interval '1 day', :in_date - interval '1 day');

    get diagnostics row_cnt = row_count;

    create index on t_gos (create_date_id, order_id);

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 gtc orders counted ====', row_cnt, 'O')
    into l_step_id;


-- foreign tables as a temp ones

    drop table if exists t_cons_lp_allowed_tf;
    create temp table t_cons_lp_allowed_tf
    as
    select * from staging.cons_lp_allowed_tf;


    drop table if exists t_cons_lp_symbol_list;
    create temp table t_cons_lp_symbol_list
    as
    select * from staging.cons_lp_symbol_list;

    drop table if exists t_lp_symbol_registration;
    create temp table t_lp_symbol_registration
    as
    select * from staging.lp_symbol_registration;
    create index on t_lp_symbol_registration (create_time);
    create index on t_lp_symbol_registration (liquidity_provider_id);

    drop table if exists t_symbol2lp_symbol_list;
    create temp table t_symbol2lp_symbol_list
    as
    select * from staging.symbol2lp_symbol_list;
    create index on t_symbol2lp_symbol_list (lp_symbol_list_id, symbol);


    -- performing the table for base data
    -- NON GTC orders


    drop table if exists trash.cutler_base;

--    begin
    create table trash.cutler_base with (parallel_workers = 4) as
    with imc_black as (select ss.symbol, clp.instrument_type_id, clp.start_date, clp.end_date
                       from staging.symbol2lp_symbol_list_audit ss
                                inner join staging.cons_lp_symbol_list_audit clp
                                           on clp.lp_symbol_list_audit_id = ss.lp_symbol_list_audit_id
                       where clp.liquidity_provider_id = 'IMC'
                         and clp.lp_symbol_list_type = 'B'
                         and (clp.start_date, coalesce(clp.end_date, '2399-01-01'::date)) overlaps
                             (:f_day_1, :f_day_2))
    select cl.transaction_id,
           cl.instrument_id,
           cl.order_id,
           cl.create_date_id,
           str.create_date_id as str_create_date_id,
           cl.fix_message_id,
           ex.exec_id,
           ac.trading_firm_id,
           cl.create_time,
           ex.exec_time,
           cl.side,
           ex.exec_type,
           ex.order_status,
           ex.cum_qty,
           cl.order_qty,
           cl.price,
           ex.last_px,
           ex.last_qty,
           cl.parent_order_id             as parent_order_id,
           cl.exch_order_id,
           cl.cross_order_id,
           str.order_id                   as str_order_id,
           str.cross_order_id             as str_cross_order_id,
           cl.is_originator,
           cl.orig_order_id,
           cl.client_order_id,
           pro.client_order_id            as parent_client_order_id,
           cl.exchange_id,
           es.exchange_id                 as es_exchange_id,
           cl.sub_strategy_desc,
           fc.acceptor_id,
           ac.opt_is_fix_clfirm_processed,
           cl.clearing_firm_id,
           cl.account_id,
           cl.sub_account,
           cl.open_close,
           cl.customer_or_firm_id,
           ac.opt_customer_or_firm,
           cl.order_capacity_id,
           ex.contra_account_capacity,
           ex.contra_broker               as ex_contra_broker,
           es.contra_broker               as es_contra_broker,
           es.contra_account_capacity     as es_contra_account_capacity,
           cl.exec_instruction,
           ex.trade_liquidity_indicator,
           ex.exch_exec_id,
           cl.strtg_decision_reason_code  as cl_strtg_decision_reason_code,
           str.strtg_decision_reason_code as str_strtg_decision_reason_code,
           cl.request_number,
           pro.sub_strategy_id            as pro_sub_strategy_id,
           pro.sub_strategy_desc          as pro_sub_strategy_desc,
           cl.sub_strategy_id,
           cl.request_number              as cl_request_number,
           str.request_number             as str_request_number,
           pro.order_type_id              as pro_order_type_id,
           cl.order_type_id,
           pro.time_in_force_id           as pro_time_in_force_id,
           cl.time_in_force_id,
           ex.contra_trader               as ex_contra_trader,
           es.contra_trader               as es_contra_trader,
           i.instrument_type_id,
           i.symbol,
           str.transaction_id             as str_transaction_id,
           str.create_time                as str_create_time,
           es.exec_id                     as es_exec_id,
           os.underlying_instrument_id    as underlying_instrument_id,
           os.root_symbol                 as root_symbol,
           oc.opra_symbol                 as opra_symbol,
           oc.maturity_year               as maturity_year,
           oc.maturity_month              as maturity_month,
           oc.maturity_day                as maturity_day,
           oc.strike_price                as strike_price,
           oc.put_call                    as put_call,
           cl.multileg_order_id,
           cl.sub_system_unq_id           as sub_system_id,
           cl.opt_exec_broker_id,
           dss.sub_system_name,
           cl.cons_payment_per_contract   as cons_payment_per_contract,
           str.cons_payment_per_contract  as str_cons_payment_per_contract,
           cl.multileg_reporting_type,
           cl.eq_order_capacity,
           case
               when (case
                         when i.instrument_type_id = 'E' then i.symbol
                         when i.instrument_type_id = 'O' then os.root_symbol end) in (select symbol from imc_black)
                   then 'Y'
               else 'N' end               as imc_black_list,
           cl.opt_customer_firm_street
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.account_id in (select account_id from t_accounts)
             join dwh.d_instrument i on i.instrument_id = cl.instrument_id
             join dwh.d_account ac on (ac.account_id = cl.account_id)
             join lateral (select
                           from dwh.d_trading_firm tf
                           where tf.trading_firm_id = ac.trading_firm_id
                             and tf.is_eligible4consolidator = 'Y'
                           limit 1) tf on true
             join lateral (select fc.acceptor_id
                           from dwh.d_fix_connection fc
                           where fc.fix_connection_id = cl.fix_connection_id
                             and fc.fix_comp_id <> 'IMCCONS'
                           limit 1) fc on true
             left join lateral (select pro.order_type_id,
                                       pro.sub_strategy_id,
                                       pro.time_in_force_id,
                                       pro.client_order_id,
                                       pro.sub_strategy_desc
                                from dwh.client_order pro
                                where pro.order_id = cl.parent_order_id
                                  and pro.create_date_id = to_char(cl.parent_order_process_time, 'YYYYMMDD')::int4
                                limit 1) pro on true
             left join dwh.client_order str
                       on (str.parent_order_id = cl.order_id and str.client_order_id = ex.secondary_order_id
                           and ex.exec_type = 'F'
                           and str.create_date_id = to_char(:in_date::date, 'YYYYMMDD')::int
                           ) -- str.create_date_id = cl.create_date_id
             left join dwh.execution es on (es.order_id = str.order_id and es.exec_date_id = ex.exec_date_id and
                                            es.exch_exec_id = ex.secondary_exch_exec_id)
             left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
             left join dwh.d_option_series os on (os.option_series_id = oc.option_series_id)
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = cl.sub_system_unq_id
    where true
      and ex.exec_time::date = :in_date::date
      and ex.exec_date_id = to_char(:in_date::date, 'YYYYMMDD')::int
      and cl.create_date_id = to_char(:in_date::date, 'YYYYMMDD')::int
      and cl.multileg_reporting_type in ('1','2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
      and cl.client_order_id = '9Z1196685267828'
      ;

    get diagnostics row_cnt = row_count;
--    commit;
--    end;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 cutler_base non gtc data inserted ====', row_cnt,
                           'O')
    into l_step_id;

    -- GTC orders

    analyze t_gos;

--    begin
    insert into trash.cutler_base
    with imc_black as (select ss.symbol, clp.instrument_type_id, clp.start_date, clp.end_date
                       from staging.symbol2lp_symbol_list_audit ss
                                inner join staging.cons_lp_symbol_list_audit clp
                                           on clp.lp_symbol_list_audit_id = ss.lp_symbol_list_audit_id
                       where clp.liquidity_provider_id = 'IMC'
                         and clp.lp_symbol_list_type = 'B'
                         and (clp.start_date, coalesce(clp.end_date, '2399-01-01'::date)) overlaps (:f_day_1, :f_day_1))
    select cl.transaction_id,
           cl.instrument_id,
           cl.order_id,
           cl.create_date_id,
           str.create_date_id as str_create_date_id,
           cl.fix_message_id,
           ex.exec_id,
           ac.trading_firm_id,
           cl.create_time,
           ex.exec_time,
           cl.side,
           ex.exec_type,
           ex.order_status,
           ex.cum_qty,
           cl.order_qty,
           cl.price,
           ex.last_px,
           ex.last_qty,
           cl.parent_order_id             as parent_order_id,
           cl.exch_order_id,
           cl.cross_order_id,
           str.order_id                   as str_order_id,
           str.cross_order_id             as str_cross_order_id,
           cl.is_originator,
           cl.orig_order_id,
           cl.client_order_id,
           pro.client_order_id            as parent_client_order_id,
           cl.exchange_id,
           es.exchange_id                 as es_exchange_id,
           cl.sub_strategy_desc,
           fc.acceptor_id,
           ac.opt_is_fix_clfirm_processed,
           cl.clearing_firm_id,
           cl.account_id,
           cl.sub_account,
           cl.open_close,
           cl.customer_or_firm_id,
           ac.opt_customer_or_firm,
           cl.order_capacity_id,
           ex.contra_account_capacity,
           ex.contra_broker               as ex_contra_broker,
           es.contra_broker               as es_contra_broker,
           es.contra_account_capacity     as es_contra_account_capacity,
           cl.exec_instruction,
           ex.trade_liquidity_indicator,
           ex.exch_exec_id,
           cl.strtg_decision_reason_code  as cl_strtg_decision_reason_code,
           str.strtg_decision_reason_code as str_strtg_decision_reason_code,
           cl.request_number,
           pro.sub_strategy_id            as pro_sub_strategy_id,
           pro.sub_strategy_desc          as pro_sub_strategy_desc,
           cl.sub_strategy_id,
           cl.request_number              as cl_request_number,
           str.request_number             as str_request_number,
           pro.order_type_id              as pro_order_type_id,
           cl.order_type_id,
           pro.time_in_force_id           as pro_time_in_force_id,
           cl.time_in_force_id,
           ex.contra_trader               as ex_contra_trader,
           es.contra_trader               as es_contra_trader,
           i.instrument_type_id,
           i.symbol,
           str.transaction_id             as str_transaction_id,
           str.create_time                as str_create_time,
           es.exec_id                     as es_exec_id,
           os.underlying_instrument_id    as underlying_instrument_id,
           os.root_symbol                 as root_symbol,
           oc.opra_symbol                 as opra_symbol,
           oc.maturity_year               as maturity_year,
           oc.maturity_month              as maturity_month,
           oc.maturity_day                as maturity_day,
           oc.strike_price                as strike_price,
           oc.put_call                    as put_call,
           cl.multileg_order_id,
           cl.sub_system_unq_id           as sub_system_id,
           cl.opt_exec_broker_id,
           dss.sub_system_name,
           cl.cons_payment_per_contract   as cons_payment_per_contract,
           str.cons_payment_per_contract  as str_cons_payment_per_contract,
           cl.multileg_reporting_type,
           cl.eq_order_capacity,
           case
               when (case
                         when i.instrument_type_id = 'E' then i.symbol
                         when i.instrument_type_id = 'O' then os.root_symbol end) in (select symbol from imc_black)
                   then 'Y'
               else 'N' end               as imc_black_list,
           cl.opt_customer_firm_street
    from t_gos gos
             join dwh.client_order cl
                  on gos.order_id = cl.order_id and gos.create_date_id = cl.create_date_id --and gos.close_date_id is null
             join dwh.execution ex on cl.order_id = ex.order_id
             join dwh.d_instrument i on i.instrument_id = cl.instrument_id
             join dwh.d_account ac on ac.account_id = cl.account_id
             join lateral (select
                           from dwh.d_trading_firm tf
                           where tf.trading_firm_id = ac.trading_firm_id
                             and tf.is_eligible4consolidator = 'Y'
                           limit 1) tf on true
             join lateral (select fc.acceptor_id
                           from dwh.d_fix_connection fc
                           where fc.fix_connection_id = cl.fix_connection_id
                             and fc.fix_comp_id <> 'IMCCONS'
                           limit 1) fc on true
             left join lateral (select pro.order_type_id,
                                       pro.sub_strategy_id,
                                       pro.time_in_force_id,
                                       pro.client_order_id,
                                       pro.sub_strategy_desc
                                from dwh.client_order pro
                                where pro.order_id = cl.parent_order_id
                                  and pro.create_date_id = to_char(cl.parent_order_process_time, 'YYYYMMDD')::int4
                                limit 1) pro on true
             left join dwh.client_order str
                       on (str.parent_order_id = cl.order_id and str.client_order_id = ex.secondary_order_id
                           and ex.exec_type = 'F'
--                           and str.create_date_id = gos.create_date_id
                           )
             left join dwh.execution es on (es.order_id = str.order_id and es.exec_date_id = ex.exec_date_id and
                                            es.exch_exec_id = ex.secondary_exch_exec_id)
             left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
             left join dwh.d_option_series os on (os.option_series_id = oc.option_series_id)
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = cl.sub_system_unq_id
    where true
      and ex.exec_time::date = :in_date::date
      and ex.exec_date_id = to_char(:in_date::date, 'YYYYMMDD')::int --??
      and gos.create_date_id < to_char(:in_date::date, 'YYYYMMDD')::int
      and cl.create_date_id < to_char(:in_date::date, 'YYYYMMDD')::int
      and cl.multileg_reporting_type in ('1','2')
      and ex.is_busted = 'N'
      and ex.exec_type not in ('E', 'S', 'D', 'y')
      and cl.trans_type <> 'F'
    and cl.client_order_id = '9Z1196685267828';

    get diagnostics row_cnt = row_count;
--    commit;
--    end;

    select * from trash.cutler_base

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 cutler_base gtc data inserted ====', row_cnt, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 cutler_base indexed ====', 0, 'O')
    into l_step_id;

    analyze trash.cutler_base;

    -- "short" table with minimum attributes
    drop table if exists trash.cutler_extended;

    create table trash.cutler_extended with (parallel_workers = 4) as
    select
         cl.imc_black_list,
cl.trading_firm_id,
rfr.rfr_id,
cl.parent_order_id,
rfr.rfr_id,
t10162,
cl.parent_order_id,
        cl.*, rfr.rfr_id as rfr_rfr_id,
    cro.cross_type as cro_cross_type,
    exc.mic_code as exc_mic_code,
    ui.symbol as ui_symbol,
    ui.instrument_type_id as ui_instrument_type_id,
    ca.cmta as ca_cmta,
    opx.opt_exec_broker_id as opx_opt_exec_broker_id,
    ot.order_type_short_name as ot_order_type_short_name,
    tif.tif_short_name as tif_tif_short_name,
    resp.route_type as resp_route_type
    from trash.cutler_base cl
             join lateral (
        select rfr_id as rfr_id
        from consolidator.cons_lite_parent_to_rfr rfr
        where rfr.parent_client_order_id = coalesce(cl.parent_client_order_id, cl.client_order_id)
--          and rfr.date_id = cl.create_date_id
          order by 1
         limit 1
        ) rfr on true
             join lateral (
        select fmj.fix_message ->> '10162' as t10162
        from fix_capture.fix_message_json fmj
        where fmj.date_id = cl.create_date_id
          and fmj.fix_message_id = cl.fix_message_id
        limit 1
        ) fm on true

            left join dwh.cross_order cro on cro.cross_order_id = cl.cross_order_id
             left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and
                                             (exc.date_start, coalesce(exc.date_end, '2399-01-01'::date)) overlaps
                                             (:f_day_1, :f_day_2)
             left join dwh.d_instrument ui on ui.instrument_id = cl.underlying_instrument_id
             left join lateral (
        select cmta
        from dwh.d_clearing_account ca
        where (cl.account_id = ca.account_id and ca.is_default = 'Y' and
               ca.market_type = 'O' and
               ca.clearing_account_type = '1'
            and (ca.date_start, coalesce(ca.date_end, '2399-01-01'::date)) overlaps
                (:f_day_1, :f_day_2))
        order by ca.date_start desc
        limit 1
        ) ca on true
             left join lateral (select *
                                from dwh.d_opt_exec_broker opx
                                where opx.account_id = cl.account_id
                                  and opx.is_default = 'Y'
                                  and (opx.start_date, coalesce(opx.end_date, '2399-01-01'::date)) overlaps
                                      (:f_day_1, :f_day_2)
                                limit 1) opx on true
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join lateral (
        select request_number, co.side
        from dwh.client_order co
        where co.order_id = cl.order_id
          and co.create_date_id = cl.create_date_id
        limit 1) req on true
             left join lateral (
        select route_type::text
        from consolidator.consolidator_message cm
                 join consolidator.routing_instruction_message im using (cons_message_id)
        where cm.date_id = cl.create_date_id
          and cm.rfr_id = rfr.rfr_id
          and im.side = req.side
          and message_type = 8
        limit 1) resp on true

    where true
      and ((cl.imc_black_list = 'Y')
        or (
                       cl.imc_black_list = 'N'
                   and cl.trading_firm_id ilike 'OFP%'
                   and rfr.rfr_id is not null
                   and ((cl.parent_order_id is not null and rfr.rfr_id = t10162)
                   or
                        (cl.parent_order_id is null)
                           )
               ));

    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 cutler_extended table created ====', row_cnt, 'O')
    into l_step_id;


    analyze trash.cutler_extended;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 FINISHED ====', 0, 'O')
    into l_step_id;
*/

   -- the all script was suppressed
   -- the rows below should be deleted if the report will be active again
   truncate table trash.cutler_extended;

  select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_Cutler 1 FINISHED EMPTY (it is expected as the report was stopped!!!) ====', 0, 'O')
    into l_step_id;

end;
$procedure$
;

COMMENT ON PROCEDURE dash_reporting.get_consolidator_eod_cutler_copy_sep_1(date) IS 'The first part of the Cutler report: preparing main table for the report';
