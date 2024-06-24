-- DROP PROCEDURE trash.get_consolidator_eod_pg_9(int4);

CREATE OR REPLACE PROCEDURE trash.get_consolidator_eod_pg_10(IN in_date_id integer)
 LANGUAGE plpgsql
AS $procedure$
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg MAIN table for  ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;




    drop table if exists t_clearing_account;
    create temp table t_clearing_account as
    select *
    from dwh.d_clearing_account ca
    where ca.is_default = 'Y'
      and ca.is_active
      and ca.market_type = 'O'
      and ca.clearing_account_type = '1';
    create index on t_clearing_account (account_id);
    analyze t_clearing_account;

    drop table if exists t_opt_exec_broker;
    create temp table t_opt_exec_broker as
    select * from dwh.d_opt_exec_broker opx where opx.is_default = 'Y' and opx.is_active;
    create index on t_opt_exec_broker (account_id);
    analyze t_opt_exec_broker;

    drop table if exists t_wht;
    create temp table t_wht as (select ss.symbol, clp.instrument_type_id
                                from staging.symbol2lp_symbol_list ss
                                         inner join staging.cons_lp_symbol_list clp
                                                    on clp.lp_symbol_list_id = ss.lp_symbol_list_id
                                where clp.liquidity_provider_id = 'IMC');

    drop table if exists t_blk;
    create temp table t_blk as
        (select ss.symbol, clp.instrument_type_id
         from staging.symbol2lp_symbol_list ss
                  inner join staging.cons_lp_symbol_black_list clp
                             on clp.lp_symbol_list_id = ss.lp_symbol_list_id
         where clp.liquidity_provider_id = 'IMC');
    analyze t_wht;
    analyze t_blk;

    drop table if exists t_providers;
    create temp table t_providers as
    select al.liquidity_provider_id, atp.lp_symbol_list_id, al.account_id, sl.symbol
    from dwh.d_acc_allowed_liquidity_provider al
             inner join dwh.d_ats_liquidity_provider atp
                        on atp.liquidity_provider_id = al.liquidity_provider_id
             join lateral (select sl.symbol
                           from staging.symbol2lp_symbol_list sl
                           where sl.lp_symbol_list_id = atp.lp_symbol_list_id
                           limit 1) sl on true
--                              and sl.symbol = :in_symbol
    where atp.lp_symbol_list_id is not null
      and atp.is_active
      and al.is_active
    union
    select al.liquidity_provider_id, atp.lp_symbol_list_id, al.account_id, null
    from dwh.d_acc_allowed_liquidity_provider al
             inner join dwh.d_ats_liquidity_provider atp
                        on atp.liquidity_provider_id = al.liquidity_provider_id
    where atp.lp_symbol_list_id is null
      and atp.is_active
      and al.is_active;
    create index on t_providers(account_id);

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: temp tables have been created',
                           0, 'O')
    into l_step_id;

    drop table if exists trash.so_imc_base;
    create table trash.so_imc_base as
    select order_id,
           transaction_id,
           create_time,
           order_qty,
           price,
           parent_order_id,
           exch_order_id,
           cross_order_id,
           is_originator,
           orig_order_id,
           client_order_id,
           cl_exchange_id,
           sub_strategy_id,
           sub_strategy_desc,
           sub_system_unq_id,
           opt_exec_broker_id,
           clearing_firm_id,
           clearing_account,
           sub_account,
           open_close,
           customer_or_firm_id,
           opt_customer_firm_street,
           eq_order_capacity,
           exec_instruction,
           strtg_decision_reason_code,
           request_number,
           order_type_id,
           time_in_force_id,
           multileg_reporting_type,
           cons_payment_per_contract,
           instrument_id,
           create_date_id,
           fix_connection_id,
           no_legs,
           leg_number,
           side,
           exec_id,
           exec_time,
           exec_type,
           cum_qty,
           order_status,
           last_px,
           last_qty,
           contra_account_capacity,
           trade_liquidity_indicator,
           exch_exec_id,
           ex_exchange_id,
           contra_broker,
           contra_trader,
           secondary_order_id,
           secondary_exch_exec_id,
           trading_firm_id,
           opt_is_fix_clfirm_processed,
           opt_customer_or_firm,
           account_id,
           opt_exec_broker,
           exec_date_id,
           fix_message_id,
           pro_sub_strategy_desc,
           pro_client_order_id,
           pro_order_type_id,
           pro_time_in_force_id,
           str_cons_payment_per_contract,
           str_order_id,
           str_cross_order_id,
           str_strtg_decision_reason_code,
           str_request_number,
           str_create_date_id,
           rfr_id,
           orig_rfr_id,
           replaced_order_id,
           cancel_order_id,
           contra_cross_exec_qty,
           contra_cross_lp_id,
           es_fix_message_id,
           es_exec_id,
           billing_code,
           es_contra_broker,
           es_contra_account_capacity,
           es_contra_trader,
           es_exchange_id,
           account_demo_mnemonic,
           acceptor_id,
           str_t9730,
           par_t9730,
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.t_base_gtc;

    insert into trash.so_imc_base
    select order_id,
           transaction_id,
           create_time,
           order_qty,
           price,
           parent_order_id,
           exch_order_id,
           cross_order_id,
           is_originator,
           orig_order_id,
           client_order_id,
           cl_exchange_id,
           sub_strategy_id,
           sub_strategy_desc,
           sub_system_unq_id,
           opt_exec_broker_id,
           clearing_firm_id,
           clearing_account,
           sub_account,
           open_close,
           customer_or_firm_id,
           opt_customer_firm_street,
           eq_order_capacity,
           exec_instruction,
           strtg_decision_reason_code,
           request_number,
           order_type_id,
           time_in_force_id,
           multileg_reporting_type,
           cons_payment_per_contract,
           instrument_id,
           create_date_id,
           fix_connection_id,
           no_legs,
           leg_number,
           side,
           exec_id,
           exec_time,
           exec_type,
           cum_qty,
           order_status,
           last_px,
           last_qty,
           contra_account_capacity,
           trade_liquidity_indicator,
           exch_exec_id,
           ex_exchange_id,
           contra_broker,
           contra_trader,
           secondary_order_id,
           secondary_exch_exec_id,
           trading_firm_id,
           opt_is_fix_clfirm_processed,
           opt_customer_or_firm,
           account_id,
           opt_exec_broker,
           exec_date_id,
           fix_message_id,
           pro_sub_strategy_desc,
           pro_client_order_id,
           pro_order_type_id,
           pro_time_in_force_id,
           str_cons_payment_per_contract,
           str_order_id,
           str_cross_order_id,
           str_strtg_decision_reason_code,
           str_request_number,
           str_create_date_id,
           rfr_id,
           orig_rfr_id,
           replaced_order_id,
           cancel_order_id,
           contra_cross_exec_qty,
           contra_cross_lp_id,
           es_fix_message_id,
           es_exec_id,
           billing_code,
           es_contra_broker,
           es_contra_account_capacity,
           es_contra_trader,
           es_exchange_id,
           account_demo_mnemonic,
           acceptor_id,
           str_t9730,
           par_t9730,           
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.t_base;
    analyze trash.so_imc_base;

    select count(*) into l_row_cnt from trash.so_imc_base;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: imc_base is ready',
                           l_row_cnt, 'O')
    into l_step_id;

    -- MAIN PART
    drop table if exists trash.so_imc_main;
    create table trash.so_imc_main as
    with white as (select symbol, instrument_type_id from t_wht)
       , black as (select symbol, instrument_type_id from t_blk)
    select tbs.transaction_id,
           tbs.exec_id,
           tbs.trading_firm_id,                                                                                                  --entitycode
           tbs.create_time,
           tbs.exec_time,
           oc.opra_symbol,                                                                                                       --osi
           case i.instrument_type_id
               when 'E' then i.symbol
               when 'O'
                   then ui.symbol end                                                                  as base_code,
           case i.instrument_type_id
               when 'E' then i.symbol
               when 'O'
                   then os.root_symbol end                                                             as root_symbol,
           case ui.instrument_type_id when 'E' then 'EQUITY' when 'I' then 'INDEX' end                 as base_asset_type,
           --
           to_char(oc.maturity_year, 'FM0000') || to_char(oc.maturity_month, 'FM00') ||
           to_char(oc.maturity_day, 'FM00')                                                            as expiration_date,
           oc.strike_price,
           case oc.put_call when '0' then 'P' when '1' then 'C' else 'S' end                           as type_code,
           case tbs.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end as SIDE,
-- 		NVL((select CO_NO_LEGS from CLIENT_ORDER where ORDER_ID = tbs.CO_MULTILEG_ORDER_ID),1), --LEG_COUNT
           tbs.no_legs,                                                                                                          --LEG_COUNT ???
           tbs.leg_number,
           case
               when tbs.exec_type = '4' then 'Canceled'
               when tbs.exec_type = '5' then 'Replaced'
               when tbs.exec_type = 'F' and tbs.order_status = '6' then
                   case
                       when tbs.cum_qty = tbs.order_qty then 'Filled'
                       else 'Partial Fill'
                       end
               when tbs.order_status = 'A' then 'Pending New'
               when tbs.order_status = '0' then 'New'
               when tbs.order_status = '8' then 'Rejected'
               when tbs.order_status = 'a' then 'Pending Replace'
               when tbs.order_status = 'b' then 'Pending Cancel'
               when tbs.order_status = '1' then 'Partial Fill'
               when tbs.order_status = '2' then 'Filled'
               when tbs.order_status = '3' then 'Done For Day'
               else tbs.order_status end                                                               as ORD_STATUS,
           tbs.price,
           tbs.last_px,
           tbs.order_qty,                                                                                                        --entered qty
           -- ask++
           tbs.last_qty,                                                                                                         --statusqty


           tbs.RFR_ID,--rfr_id
           tbs.ORIG_RFR_ID,--orig_rfr_id
           tbs.client_order_id,

           tbs.REPLACED_ORDER_ID,
           tbs.cancel_order_id,

           tbs.pro_client_order_id                                                                     as parent_client_order_id,
           tbs.order_id,                                                                                                         --systemorderid
           case
               when tbs.cl_exchange_id = 'ALGOWX' then 'WEX_SWEEP'
               else coalesce(tbs.sub_strategy_desc, exc.mic_code)
               end                                                                                     as exchange_code,

           case
               when tbs.parent_order_id is null then tbs.acceptor_id
               when dss.sub_system_id like '%CONS%' then 'CONS'
               when dss.sub_system_id like '%OSR%' then 'SOR'
               when dss.sub_system_id like '%ATLAS%' or dss.sub_system_id like '%ATS%' then 'ATS'
               else dss.sub_system_id
               end                                                                                     as EX_CONNECTION,


           coalesce(tbs.opt_exec_broker, opx.opt_exec_broker)                                          as give_up_firm,
           case
               when tbs.opt_is_fix_clfirm_processed = 'Y' then tbs.clearing_firm_id
               else coalesce(lpad(ca.cmta, 3, '0'), tbs.clearing_firm_id)
               end                                                                                     as cmta_firm,
           tbs.clearing_account,
           tbs.sub_account,
           tbs.open_close,
           case
               when (tbs.parent_order_id is null or tbs.customer_or_firm_id is not null)
                   then case coalesce(tbs.customer_or_firm_id, tbs.opt_customer_or_firm)
                            when '0' then 'CUST'
                            when '1' then 'FIRM'
                            when '2' then 'BD'
                            when '3' then 'BD-CUST'
                            when '4' then 'MM'
                            when '5' then 'AMM'
                            when '7' then 'BD-FIRM'
                            when '8' then 'CUST-PRO'
                            when 'J' then 'JBO' end
               else coalesce(tbs.customer_or_firm_id, tbs.eq_order_capacity, tbs.opt_customer_firm_street)
               end                                                                                     as RANGE,
           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.parent_order_id is not null then tbs.contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
           ot.order_type_short_name,
           tif.tif_short_name,                                                                                                   -- TIME_IN_FORCE
           tbs.exec_instruction,                                                                                                 -- EXEC_INST
           tbs.trade_liquidity_indicator,

           tbs.exch_exec_id,
           tbs.exch_order_id,
           tbs.cross_order_id,
           case
               when tbs.REQUEST_NUMBER >= 99 then ''
               else tbs.REQUEST_NUMBER::text
               end                                                                                     as REQUEST_COUNT,

--           tbs.BILLING_CODE,


           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.PARENT_ORDER_ID is not null and tbs.ex_exchange_id = 'CBOE'
                           then ltrim(tbs.CONTRA_BROKER, 'CBOE:')
                       when tbs.PARENT_ORDER_ID is not null then tbs.CONTRA_BROKER
                       when tbs.PARENT_ORDER_ID is null and tbs.es_exchange_id = 'CBOE'
                           then ltrim(tbs.ES_CONTRA_BROKER, 'CBOE:')
                       when tbs.PARENT_ORDER_ID is null then tbs.ES_CONTRA_BROKER end
               end                                                                                     as CONTRA_BROKER,

           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.PARENT_ORDER_ID is not null then tbs.CONTRA_TRADER
                       else tbs.ES_CONTRA_TRADER
                       end
               end                                                                                     as CONTRA_TRADER,

           case
               when case I.INSTRUMENT_TYPE_ID when 'E' then I.SYMBOL when 'O' then OS.ROOT_SYMBOL end in
                    (select SYMBOL
                     from black
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end)
                   then 'N'
               when case I.INSTRUMENT_TYPE_ID when 'E' then I.SYMBOL when 'O' then OS.ROOT_SYMBOL end in
                    (select SYMBOL
                     from white
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end)
                   then 'Y'
               when (select count(*)
                     from white
                     where INSTRUMENT_TYPE_ID = case when tbs.multileg_reporting_type = '1' then 'O' else 'M' end) = 0
                   then 'Y'
               else 'N'
               end                                                                                     as white_list,            --WHITE_LIST
           case
               when tbs.EXEC_TYPE = 'F' then
                   case
                       when tbs.parent_order_id is not null then tbs.cons_payment_per_contract
                       else tbs.STR_cons_payment_per_contract
                       end
               end                                                                                     as cons_payment_per_contract,
           tbs.CONTRA_CROSS_EXEC_QTY,

           --getContraCrossLPID(NVL(tbs.STR_ORDER_ID,CL.ORDER_ID))-- ALP.LP_DEMO_MNEMONIC

           CONTRA_CROSS_LP_ID,

           coalesce(tbs.strtg_decision_reason_code,
                    tbs.STR_strtg_decision_reason_code)                                                as STRATEGY_DECISION_REASON_CODE,
           cro.CROSS_TYPE,
           tbs.fix_message_id                                                                          as parent_fix_message_id, -- ex.fix_message_id parent order
           tbs.es_FIX_MESSAGE_ID,
           tbs.ex_exchange_id,
           tbs.cl_exchange_id,
           tbs.es_exec_id,

           tbs.ACCOUNT_ID,
           I.SYMBOL,
           OS.ROOT_SYMBOL                                                                              as os_ROOT_SYMBOL,
           case tbs.MULTILEG_REPORTING_TYPE
               when '1' then 'O'
               when '2'
                   then 'M' end                                                                        as instrument_type,
           case
               when tbs.BILLING_CODE is not null then tbs.BILLING_CODE
               when tbs.EXEC_TYPE = 'F' and
                    (coalesce(tbs.pro_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and trash.get_lp_list_tmp(tbs.account_id, symbol, create_time::date) -- equal staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is NOT null
                   then 'Exhaust'
               when tbs.EXEC_TYPE = 'F' and
                    (coalesce(tbs.pro_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and staging.get_lp_list_lite_tmp(tbs.ACCOUNT_ID, OS.ROOT_SYMBOL,
                                                    case tbs.MULTILEG_REPORTING_TYPE
                                                        when '1' then 'O'
                                                        when '2' then 'M' end) is not null
                   then 'Exhaust'
               when tbs.EXEC_TYPE = 'F' and
                    (coalesce(tbs.pro_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   then 'Exhaust_IMC'
               end as BILLING_CODE,
           tbs.account_demo_mnemonic,
           
           tbs.str_t9730,
           tbs.par_t9730,
           
           bidsza,
           bida,
           aska,
           asksza,
           bidszz,
           bidz,
           askz,
           askszz,
           bidszb,
           bidb,
           askb,
           askszb,
           bidszc,
           bidc,
           askc,
           askszc,
           bidszw,
           bidw,
           askw,
           askszw,
           bidszt,
           bidt,
           askt,
           askszt,
           bidszi,
           bidi,
           aski,
           askszi,
           bidszp,
           bidp,
           askp,
           askszp,
           bidszm,
           bidm,
           askm,
           askszm,
           bidszh,
           bidh,
           askh,
           askszh,
           bidszq,
           bidq,
           askq,
           askszq,
           bidszx,
           bidx,
           askx,
           askszx,
           bidsze,
           bide,
           aske,
           asksze,
           bidszj,
           bidj,
           askj,
           askszj,
           bidszr,
           bidr,
           askr,
           askszr,
           bidszd,
           bidd,
           askd,
           askszd,
           bidszs,
           bids,
           asks,
           askszs,
           bidszu,
           bidu,
           asku,
           askszu
    from trash.so_imc_base tbs
             inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
--              inner join dwh.d_fix_connection fc on (fc.fix_connection_id = tbs.fix_connection_id)
             left join dwh.cross_order cro on cro.cross_order_id = tbs.cross_order_id
             left join dwh.d_exchange exc on exc.exchange_id = tbs.cl_exchange_id and exc.is_active
             left join dwh.d_option_contract oc on (oc.instrument_id = tbs.instrument_id)
             left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
             left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id


             left join t_clearing_account ca
                       on tbs.account_id = ca.account_id-- and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1')
             left join t_opt_exec_broker opx on opx.account_id = tbs.account_id-- and opx.is_default = 'Y' and opx.is_active)
             left join dwh.d_order_type ot on ot.order_type_id = tbs.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = tbs.time_in_force_id
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = tbs.sub_system_unq_id
    where true;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: main db is ready',
                           l_row_cnt, 'O')
    into l_step_id;

--    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg: COMPLETED===',
--                           l_row_cnt, 'O')
--    into l_step_id;
--     return l_row_cnt;
end;
$procedure$
;
