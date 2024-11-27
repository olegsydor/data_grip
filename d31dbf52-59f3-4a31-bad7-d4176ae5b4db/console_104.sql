select cl_exchange_id,
       ex_exchange_id,
       transaction_id,
       str_t9730,
--        substr(str_t9730, 2, 1) as counterparty_range_for_saphire,
       par_t9730,
       counterparty_range,
           case
               when tbs.ex_exec_type = 'F' then
                   case
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
from dash_reporting.imc_final x
where true
  and ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%'])
  and cl_exchange_id is null


select
    tbs.cl_exchange_id,
    tbs.ex_exchange_id,
    tbs.transaction_id,
    tbs.ex_exch_exec_id,
               case
               when tbs.ex_exec_type = 'F' then
                   case
--                        when tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%']) then substr(coalesce(str_t9730, par_t9730), 2, 1)
                       when tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%']) then substr(str_t9730, 2, 1)
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
*
from dash_reporting.imc_base_ext_md tbs
where true
and tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%'])
and tbs.ex_exch_exec_id = '7200749401763';


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
    analyze dash_reporting.imc_base_ext_md;


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


    drop table if exists dash_reporting.imc_final;
    create table dash_reporting.imc_final as
    with white as (select symbol, instrument_type_id from t_wht)
       , black as (select symbol, instrument_type_id from t_blk)
    select tbs.transaction_id,
           tbs.ex_exec_id,
           tbs.ac_trading_firm_id,                                                                                               --entitycode
           tbs.create_time,
           tbs.ex_exec_time,
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
               when tbs.ex_exec_type = '4' then 'Canceled'
               when tbs.ex_exec_type = '5' then 'Replaced'
               when tbs.ex_exec_type = 'F' and tbs.ex_order_status = '6' then
                   case
                       when tbs.ex_cum_qty = tbs.order_qty then 'Filled'
                       else 'Partial Fill'
                       end
               when tbs.ex_order_status = 'A' then 'Pending New'
               when tbs.ex_order_status = '0' then 'New'
               when tbs.ex_order_status = '8' then 'Rejected'
               when tbs.ex_order_status = 'a' then 'Pending Replace'
               when tbs.ex_order_status = 'b' then 'Pending Cancel'
               when tbs.ex_order_status = '1' then 'Partial Fill'
               when tbs.ex_order_status = '2' then 'Filled'
               when tbs.ex_order_status = '3' then 'Done For Day'
               else tbs.ex_order_status end                                                            as ORD_STATUS,
           tbs.price,
           tbs.ex_last_px,
           tbs.order_qty,                                                                                                        --entered qty
           -- ask++
           tbs.ex_last_qty,                                                                                                      --statusqty


           tbs.RFR_ID,--rfr_id
           tbs.ORIG_RFR_ID,--orig_rfr_id
           tbs.client_order_id,

           tbs.REPLACED_ORDER_ID,
           tbs.cancel_order_id,

           tbs.par_client_order_id                                                                     as parent_client_order_id,
           tbs.order_id,                                                                                                         --systemorderid
           case
               when tbs.cl_exchange_id = 'ALGOWX' then 'WEX_SWEEP'
               else coalesce(tbs.sub_strategy_desc, exc.mic_code)
               end                                                                                     as exchange_code,

           case
               when tbs.par_order_id is null then tbs.fc_acceptor_id
               when dss.sub_system_id like '%CONS%' then 'CONS'
               when dss.sub_system_id like '%OSR%' then 'SOR'
               when dss.sub_system_id like '%ATLAS%' or dss.sub_system_id like '%ATS%' then 'ATS'
               else dss.sub_system_id
               end                                                                                     as EX_CONNECTION,


           lpad(coalesce(tbs.opx_opt_exec_broker, opx.opt_exec_broker), 3, '0')                        as give_up_firm,
           case
               when tbs.ac_opt_is_fix_clfirm_processed = 'Y' then tbs.clearing_firm_id
               else coalesce(lpad(ca.cmta, 3, '0'), tbs.clearing_firm_id)
               end                                                                                     as cmta_firm,
           tbs.clearing_account,
           tbs.sub_account,
           tbs.open_close,
           case
               when (tbs.par_order_id is null or tbs.customer_or_firm_id is not null)
                   then case coalesce(tbs.customer_or_firm_id, tbs.ac_opt_customer_or_firm)
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
               when tbs.ex_exec_type = 'F' then
                   case
                       when tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%']) then substr(str_t9730, 2, 1)
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
           ot.order_type_short_name,
           tif.tif_short_name,                                                                                                   -- TIME_IN_FORCE
           tbs.exec_instruction,                                                                                                 -- EXEC_INST
           tbs.ex_trade_liquidity_indicator,

           tbs.ex_exch_exec_id,
           tbs.exch_order_id,
           tbs.cross_order_id,
           case
               when tbs.REQUEST_NUMBER >= 99 then ''
               else tbs.REQUEST_NUMBER::text
               end                                                                                     as REQUEST_COUNT,

--           tbs.BILLING_CODE,


           case
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.PAR_ORDER_ID is not null and tbs.ex_exchange_id = 'CBOE'
                           then ltrim(tbs.ex_contra_broker, 'CBOE:')
                       when tbs.PAR_ORDER_ID is not null then tbs.ex_contra_broker
                       when tbs.PAR_ORDER_ID is null and tbs.es_exchange_id = 'CBOE'
                           then ltrim(tbs.ES_CONTRA_BROKER, 'CBOE:')
                       when tbs.PAR_ORDER_ID is null then tbs.ES_CONTRA_BROKER end
               end                                                                                     as CONTRA_BROKER,

           case
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.PAR_ORDER_ID is not null then tbs.ex_CONTRA_TRADER
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
               when tbs.ex_EXEC_TYPE = 'F' then
                   case
                       when tbs.par_order_id is not null then tbs.cons_payment_per_contract
                       else tbs.STR_cons_payment_per_contract
                       end
               end                                                                                     as cons_payment_per_contract,
           tbs.CONTRA_CROSS_EXEC_QTY,

           --getContraCrossLPID(NVL(tbs.STR_ORDER_ID,CL.ORDER_ID))-- ALP.LP_DEMO_MNEMONIC

           CONTRA_CROSS_LP_ID,

           coalesce(tbs.strtg_decision_reason_code,
                    tbs.STR_strtg_decision_reason_code)                                                as STRATEGY_DECISION_REASON_CODE,
           cro.CROSS_TYPE,
           tbs.ex_fix_message_id                                                                       as parent_fix_message_id, -- ex.fix_message_id parent order
           tbs.es_FIX_MESSAGE_ID,
           tbs.ex_exchange_id,
           tbs.cl_exchange_id,
           tbs.es_exec_id,

           tbs.ac_account_id,
           I.SYMBOL,
           OS.ROOT_SYMBOL                                                                              as os_ROOT_SYMBOL,
           case tbs.MULTILEG_REPORTING_TYPE
               when '1' then 'O'
               when '2'
                   then 'M' end                                                                        as instrument_type,
           case
               when tbs.billing_code is not null then tbs.billing_code
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and dash_reporting.get_lp_list(tbs.ac_account_id, i.symbol, tbs.create_time::date) -- equal staging.get_lp_list_tmp(ac.ACCOUNT_ID, I.SYMBOL, in_date_id::text::date) is NOT null
                   then 'Exhaust'
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   and staging.get_lp_list_lite(tbs.ac_ACCOUNT_ID, OS.ROOT_SYMBOL,
                                                    case tbs.MULTILEG_REPORTING_TYPE
                                                        when '1' then 'O'
                                                        when '2' then 'M' end) is not null
                   then 'Exhaust'
               when tbs.ex_EXEC_TYPE = 'F' and
                    (coalesce(tbs.par_SUB_STRATEGY_desc, tbs.SUB_STRATEGY_desc) not in ('DMA', 'CSLDTR', 'RETAIL') or
                     coalesce(tbs.request_number, tbs.str_request_number, -1) = -1)
                   then 'Exhaust_IMC'
               end as BILLING_CODE,
           tbs.ac_account_demo_mnemonic,

           tbs.str_t9730,
           tbs.par_t9730,

           tbs.amex_bid_quantity                                                                       as BidSzA,
           tbs.amex_bid_price                                                                          as BidA,
           tbs.amex_ask_price                                                                          as AskA,
           tbs.amex_ask_quantity                                                                       as AskSzA,

           tbs.bato_bid_quantity                                                                       as BidSzZ,
           tbs.bato_bid_price                                                                          as BidZ,
           tbs.bato_ask_price                                                                          as AskZ,
           tbs.bato_ask_quantity                                                                       as AskSzZ,

           tbs.box_bid_quantity                                                                        as BidSzB,
           tbs.box_bid_price                                                                           as BidB,
           tbs.box_ask_price                                                                           as AskB,
           tbs.box_ask_quantity                                                                        as AskSzB,
--
           tbs.cboe_bid_quantity                                                                       as BidSzC,
           tbs.cboe_bid_price                                                                          as BidC,
           tbs.cboe_ask_price                                                                          as AskC,
           tbs.cboe_ask_quantity                                                                       as AskSzC,

           tbs.c2ox_bid_quantity                                                                       as BidSzW,
           tbs.c2ox_bid_price                                                                          as BidW,
           tbs.c2ox_ask_price                                                                          as AskW,
           tbs.c2ox_ask_quantity                                                                       as AskSzW,

           tbs.nqbxo_bid_quantity                                                                      as BidSzT,
           tbs.nqbxo_bid_price                                                                         as BidT,
           tbs.nqbxo_ask_price                                                                         as AskT,
           tbs.nqbxo_ask_quantity                                                                      as AskSzT,

           tbs.ise_bid_quantity                                                                        as BidSzI,
           tbs.ise_bid_price                                                                           as BidI,
           tbs.ise_ask_price                                                                           as AskI,
           tbs.ise_ask_quantity                                                                        as AskSzI,

           tbs.arca_bid_quantity                                                                       as BidSzP,
           tbs.arca_bid_price                                                                          as BidP,
           tbs.arca_ask_price                                                                          as AskP,
           tbs.arca_ask_quantity                                                                       as AskSzP,

           tbs.miax_bid_quantity                                                                       as BidSzM,
           tbs.miax_bid_price                                                                          as BidM,
           tbs.miax_ask_price                                                                          as AskM,
           tbs.miax_ask_quantity                                                                       as AskSzM,

           tbs.gemini_bid_quantity                                                                     as BidSzH,
           tbs.gemini_bid_price                                                                        as BidH,
           tbs.gemini_ask_price                                                                        as AskH,
           tbs.gemini_ask_quantity                                                                     as AskSzH,

           tbs.nsdqo_bid_quantity                                                                      as BidSzQ,
           tbs.nsdqo_bid_price                                                                         as BidQ,
           tbs.nsdqo_ask_price                                                                         as AskQ,
           tbs.nsdqo_ask_quantity                                                                      as AskSzQ,

           tbs.phlx_bid_quantity                                                                       as BidSzX,
           tbs.phlx_bid_price                                                                          as BidX,
           tbs.phlx_ask_price                                                                          as AskX,
           tbs.phlx_ask_quantity                                                                       as AskSzX,

           tbs.edgo_bid_quantity                                                                       as BidSzE,
           tbs.edgo_bid_price                                                                          as BidE,
           tbs.edgo_ask_price                                                                          as AskE,
           tbs.edgo_ask_quantity                                                                       as AskSzE,

           tbs.mcry_bid_quantity                                                                       as BidSzJ,
           tbs.mcry_bid_price                                                                          as BidJ,
           tbs.mcry_ask_price                                                                          as AskJ,
           tbs.mcry_ask_quantity                                                                       as AskSzJ,

           tbs.mprl_bid_quantity                                                                       as BidSzR,
           tbs.mprl_bid_price                                                                          as BidR,
           tbs.mprl_ask_price                                                                          as AskR,
           tbs.mprl_ask_quantity                                                                       as AskSzR,

           tbs.emld_bid_quantity                                                                       as BidSzD,
           tbs.emld_bid_price                                                                          as BidD,
           tbs.emld_ask_price                                                                          as AskD,
           tbs.emld_ask_quantity                                                                       as AskSzD,

           tbs.sphr_bid_quantity                                                                       as BidSzS,
           tbs.sphr_bid_price                                                                          as BidS,
           tbs.sphr_ask_price                                                                          as AskS,
           tbs.sphr_ask_quantity                                                                       as AskSzS,

           tbs.mxop_bid_quantity                                                                       as BidSzU,
           tbs.mxop_bid_price                                                                          as BidU,
           tbs.mxop_ask_price                                                                          as AskU,
           tbs.mxop_ask_quantity                                                                       as AskSzU

    from dash_reporting.imc_base_ext_md tbs
             inner join dwh.d_instrument i on i.instrument_id = tbs.instrument_id
             left join dwh.cross_order cro on cro.cross_order_id = tbs.cross_order_id
             left join dwh.d_exchange exc on exc.exchange_id = tbs.cl_exchange_id and exc.is_active

             left join dwh.d_option_contract oc on (oc.instrument_id = tbs.instrument_id)
             left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
             left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
             left join t_clearing_account ca
                       on tbs.ac_account_id = ca.account_id --and ca.is_default = 'Y' and ca.is_active and ca.market_type = 'O' and ca.clearing_account_type = '1'
             left join t_opt_exec_broker opx
                       on opx.account_id = tbs.ac_account_id --and opx.is_default = 'Y' and opx.is_active
             left join dwh.d_order_type ot on ot.order_type_id = tbs.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = tbs.time_in_force_id
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = tbs.sub_system_unq_id
    where true;
