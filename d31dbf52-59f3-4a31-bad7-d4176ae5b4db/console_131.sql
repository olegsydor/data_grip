	select
		o."StatusDate"::date as "Period",
		tf.trading_firm_name::varchar as "Trading Firm",
		a.account_name::varchar as "Account",
		cf.customer_or_firm_name::varchar as "Capacity",
		sum(coalesce(o."CumQty", 0))::int8 as "Qty",
		count(distinct o."ClOrdID") as "Parent Order Count"
	from dwh.historic_order_details_storage o
	join dwh.d_account a on (a.account_id = o."AccountID")
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
	where "Status_Date_id" >= :l_start_quarter_date_id and "Status_Date_id" < :l_date_id
		and o."InstrumentType" = 'O'
		and o."CustomerOrderID" is null
	group by "Period", "Account", "Capacity", "Trading Firm";



	select
		o."StatusDate"::date as "Period",
		tf.trading_firm_name::varchar as "Trading Firm",
		a.account_name::varchar as "Account",
		cf.customer_or_firm_name::varchar as "Capacity",
		sum(o."CumQty") as "Qty",
		count(distinct o."ClOrdID") as "Parent Order Count"
	from dwh.historic_order_details_storage o
	join dwh.d_account a on (a.account_id = o."AccountID")
	join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
	where "Status_Date_id" >= :l_start_quarter_date_id and "Status_Date_id" < :l_date_id
		and o."InstrumentType" = 'O'
		and o."CustomerOrderID" is null
	group by "Period", "Account", "Capacity", "Trading Firm";



-- 	union all

    select cl.create_date_id::text::date      as "Period",
           tf.trading_firm_name::varchar      as "Trading Firm",
           a.account_name::varchar            as "Account",
           cf.customer_or_firm_name::varchar  as "Capacity",
           sum(ex.cum_qty)                    as "Qty",
           count(distinct cl.client_order_id) as "Parent Order Count"
    from dwh.client_order cl
             join dwh.d_account a on (a.account_id = cl.account_id and a.is_active)
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id and tf.is_active)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = cl.customer_or_firm_id)
             left join lateral (select sum(ex.last_qty) as cum_qty
                                from dwh.execution ex
                                where ex.order_id = cl.order_id
                                  and ex.exec_date_id >= cl.create_date_id
                                  and ex.exec_type in ('F', 'G')
                                  and ex.is_busted = 'N'
                                limit 1) ex on true
    where true
      and cl.create_date_id >= :l_start_quarter_date_id
      and cl.create_date_id < :l_date_id
      and di.instrument_type_id = 'O'
      and cl.parent_order_id is null
    group by "Period", "Account", "Capacity", "Trading Firm";



-- DROP FUNCTION dash_reporting.imc_report(int4);

    CREATE OR REPLACE FUNCTION dash_reporting.imc_report(in_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
        RETURNS TABLE
                (
                    ret_row text
                )
        LANGUAGE plpgsql
    AS
    $function$
        -- 20240821 SO https://dashfinancial.atlassian.net/browse/DS-8299
-- permanent tables instead of temp ones are used to review potential incidents after finishing the report
    declare
        l_load_id           int;
        l_row_cnt           int;
        l_step_id           int;
        l_retention_date_id int4 := 20230901;

    begin
        select nextval('public.load_timing_seq') into l_load_id;
        l_step_id := 1;
        select public.load_log(l_load_id, l_step_id,
                               'get_consolidator_eod_pg printing for ' || in_date_id::text || ' STARTED ===',
                               0, 'O')
        into l_step_id;

        drop table if exists t_cust_or_firm;
        create temp table t_cust_or_firm as
        select distinct customer_or_firm_id, cof.exchange_id, cof.exch_customer_or_firm_id
        from dwh.d_exchange2customer_or_firm cof
        where true
          and cof.is_active;
        get diagnostics l_row_cnt = row_count;
        create index on t_cust_or_firm (exchange_id, exch_customer_or_firm_id);
        select public.load_log(l_load_id, l_step_id,
                               'get_consolidator_eod_pg temp table customer_or_firm created ' || in_date_id::text ||
                               ' STARTED ===',
                               l_row_cnt, 'O')
        into l_step_id;

        drop table if exists dash_reporting.imc_pg_report;
        create table dash_reporting.imc_pg_report as
        select cl.transaction_id,
               cl.order_id,
               cl.ex_exec_id as exec_id,
               cl.ac_trading_firm_id || ',' || --EntityCode
               to_char(cl.create_time, 'YYYYMMDD') || ',' || --CreateDate
               to_char(cl.create_time, 'HH24MISSFF3') || ',' || --CreateTime
               to_char(cl.ex_exec_time, 'YYYYMMDD') || ',' || --StatusDate
               to_char(cl.ex_exec_time, 'HH24MISSFF3') || ',' || --StatusTime
               coalesce(cl.opra_symbol, '') || ',' || --OSI
               coalesce(cl.base_code, '') || ',' ||--BaseCode
               coalesce(cl.root_symbol, '') || ',' || --Root
               coalesce(cl.base_asset_type, '') || ',' ||
                   --
               coalesce(cl.expiration_date, '') || ',' ||
               coalesce(staging.trailing_dot(cl.strike_price), '') || ',' ||
               coalesce(cl.type_code, '') || ',' || -- (S - stock)
               coalesce(cl.side, '') || ',' ||
               coalesce(cl.no_legs::text, '') || ',' || --LegCount
               coalesce(cl.leg_number::text, '') || ',' || --LegNumber
               '' || ',' || --OrderType
               coalesce(cl.ord_status, '') || ',' ||
               coalesce(to_char(cl.price, 'FM999990D0099'), '') || ',' ||
               coalesce(to_char(cl.ex_last_px, 'FM999990D0099'), '') || ',' || --StatusPrice
               coalesce(cl.order_qty::text, '') || ',' || --EnteredQty
-- ask++
               coalesce(cl.ex_last_qty::text, '') || ',' || --StatusQty
               coalesce(cl.rfr_id, '') || ',' ||--RFRID
               coalesce(cl.orig_rfr_id, '') || ',' ||--OrigRFRID
               coalesce(cl.client_order_id, '') || ',' ||
               coalesce(cl.replaced_order_id, '') || ',' || --Replaced Order
               coalesce(cl.cancel_order_id, '') || ',' || --CancelOrderID
               coalesce(cl.parent_client_order_id, '') || ',' ||
               coalesce(cl.order_id::text, '') || ',' || --SystemOrderID
               coalesce(cl.exchange_code, '') || ',' || --ExchangeCode
               coalesce(cl.ex_connection, '') || ',' || --ExConnection
               coalesce(cl.give_up_firm, '') || ',' ||--GiveUpFirm
               coalesce(cl.cmta_firm, '') || ',' || --CMTAFirm
               coalesce(cl.clearing_account, '') || ',' || --Account
               coalesce(cl.sub_account, '') || ',' || --SubAccount
               coalesce(cl.open_close, '') || ',' ||
               coalesce(cl.range, '') || ',' || --Range
--EX.CONTRA_ACCOUNT_CAPACITY
--		coalesce(cl.counterparty_range, '')||','||
               coalesce(case ascii(cl.counterparty_range) when 0 then repeat(' ', 1) else cof.customer_or_firm_id end,
                        '') || ',' ||
               coalesce(cl.order_type_short_name, '') || ',' || --PriceQualifier
               coalesce(cl.tif_short_name, '') || ',' || --TimeQualifier
               coalesce(cl.exec_instruction, '') || ',' || --ExecInst
-- The next row was changed within https://dashfinancial.atlassian.net/browse/DEVREQ-3278
               coalesce(staging.get_trade_liquidity_indicator(cl.ex_trade_liquidity_indicator), '') ||
               ',' || --Maker/Take
               coalesce(cl.ex_exch_exec_id, '') || ',' || --ExchangeTransactionID
               coalesce(cl.exch_order_id, '') || ',' || --ExchangeOrderID

               coalesce(BidSzA::text, '') || ',' || --BidSzA
               coalesce(to_char(BidA, 'FM999999.0099'), '') || ',' || --BidA
               coalesce(to_char(AskA, 'FM999999.0099'), '') || ',' || --AskA
               coalesce(AskSzA::text, '') || ',' || --AskSzA

               coalesce(BidSzZ::text, '') || ',' || --BidSzZ
               coalesce(to_char(BidZ, 'FM999999.0099'), '') || ',' || --BidZ
               coalesce(to_char(AskZ, 'FM999999.0099'), '') || ',' || --AskZ
               coalesce(AskSzZ::text, '') || ',' || --AskSzZ

               coalesce(BidSzB::text, '') || ',' || --BidSzB
               coalesce(to_char(BidB, 'FM999999.0099'), '') || ',' || --BidB
               coalesce(to_char(AskB, 'FM999999.0099'), '') || ',' || --AskB
               coalesce(AskSzB::text, '') || ',' || --AskSzB
--
               coalesce(BidSzC::text, '') || ',' || --BidSzC
               coalesce(to_char(BidC, 'FM999999.0099'), '') || ',' || --BidC
               coalesce(to_char(AskC, 'FM999999.0099'), '') || ',' || --AskC
               coalesce(AskSzC::text, '') || ',' || --AskSzC

               coalesce(BidSzW::text, '') || ',' || --BidSzW
               coalesce(to_char(BidW, 'FM999999.0099'), '') || ',' || --BidW
               coalesce(to_char(AskW, 'FM999999.0099'), '') || ',' || --AskW
               coalesce(AskSzW::text, '') || ',' || --AskSzW

               coalesce(BidSzT::text, '') || ',' || --BidSzT
               coalesce(to_char(BidT, 'FM999999.0099'), '') || ',' || --BidT
               coalesce(to_char(AskT, 'FM999999.0099'), '') || ',' || --AskT
               coalesce(AskSzT::text, '') || ',' || --AskSzT

               coalesce(BidSzI::text, '') || ',' || --BidSzI
               coalesce(to_char(BidI, 'FM999999.0099'), '') || ',' || --BidI
               coalesce(to_char(AskI, 'FM999999.0099'), '') || ',' || --AskI
               coalesce(AskSzI::text, '') || ',' || --AskSzI

               coalesce(BidSzP::text, '') || ',' || --BidSzP
               coalesce(to_char(BidP, 'FM999999.0099'), '') || ',' || --BidP
               coalesce(to_char(AskP, 'FM999999.0099'), '') || ',' || --AskP
               coalesce(AskSzP::text, '') || ',' || --AskSzP

               coalesce(BidSzM::text, '') || ',' || --BidSzM
               coalesce(to_char(BidM, 'FM999999.0099'), '') || ',' || --BidM
               coalesce(to_char(AskM, 'FM999999.0099'), '') || ',' || --AskM
               coalesce(AskSzM::text, '') || ',' || --AskSzM

               coalesce(BidSzH::text, '') || ',' || --BidSzH
               coalesce(to_char(BidH, 'FM999999.0099'), '') || ',' || --BidH
               coalesce(to_char(AskH, 'FM999999.0099'), '') || ',' || --AskH
               coalesce(AskSzH::text, '') || ',' || --AskSzH

               coalesce(BidSzQ::text, '') || ',' || --BidSzQ
               coalesce(to_char(BidQ, 'FM999999.0099'), '') || ',' || --BidQ
               coalesce(to_char(AskQ, 'FM999999.0099'), '') || ',' || --AskQ
               coalesce(AskSzQ::text, '') || ',' || --AskSzQ

               coalesce(BidSzX::text, '') || ',' || --BidSzX
               coalesce(to_char(BidX, 'FM999999.0099'), '') || ',' || --BidX
               coalesce(to_char(AskX, 'FM999999.0099'), '') || ',' || --AskX
               coalesce(AskSzX::text, '') || ',' || --AskSzX

               coalesce(BidSzE::text, '') || ',' || --BidSzE
               coalesce(to_char(BidE, 'FM999999.0099'), '') || ',' || --BidE
               coalesce(to_char(AskE, 'FM999999.0099'), '') || ',' || --AskE
               coalesce(AskSzE::text, '') || ',' || --AskSzE

               coalesce(BidSzJ::text, '') || ',' || --BidSzJ
               coalesce(to_char(BidJ, 'FM999999.0099'), '') || ',' || --BidJ
               coalesce(to_char(AskJ, 'FM999999.0099'), '') || ',' || --AskJ
               coalesce(AskSzJ::text, '') || ',' || --AskSzJ

               coalesce(BidSzR::text, '') || ',' || --BidSzR
               coalesce(to_char(BidR, 'FM999999.0099'), '') || ',' || --BidR
               coalesce(to_char(AskR, 'FM999999.0099'), '') || ',' || --AskR
               coalesce(AskSzR::text, '') || ',' || --AskSzR

               coalesce(BidSzD::text, '') || ',' || --BidSzD
               coalesce(to_char(BidD, 'FM999999.0099'), '') || ',' || --BidD
               coalesce(to_char(AskD, 'FM999999.0099'), '') || ',' || --AskD
               coalesce(AskSzD::text, '') || ',' || --AskSzD
-----
               coalesce(BidSzS::text, '') || ',' || --BidSzS
               coalesce(to_char(BidS, 'FM999999.0099'), '') || ',' || --BidS
               coalesce(to_char(AskS, 'FM999999.0099'), '') || ',' || --AskS
               coalesce(AskSzS::text, '') || ',' || --AskSzS

               coalesce(BidSzU::text, '') || ',' || --BidSzU
               coalesce(to_char(BidU, 'FM999999.0099'), '') || ',' || --BidU
               coalesce(to_char(AskU, 'FM999999.0099'), '') || ',' || --AskU
               coalesce(AskSzU::text, '') || ',' || --AskSzU
-----
--CrossOrderID,AuctionType,RequestCount,BillingType,ContraBroker,ContraTrader,WhiteList,PaymentPerContract,ContraCrossExecutedQty
               coalesce(cl.cross_order_id::text, '') || ',' || --CrossOrderID
-- 		coalesce(cl.auction_type, '')||','|| --Auc.type
               case
                   when --cl.STRATEGY_DECISION_REASON_CODE in ('74') and
                       cl.ex_exchange_id in
                       ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
                           and exists (select upper(description)
                                       from dwh.d_liquidity_indicator li
                                       where (upper(description) like '%FLASH%'
                                           or upper(description) like '%EXPOSURE%')
                                         and li.trade_liquidity_indicator = cl.ex_trade_liquidity_indicator)
                       then 'FLASH'
                   when cl.ex_exchange_id in ('AMEXP')
                       and exists (select upper(description)
                                   from dwh.d_liquidity_indicator li
                                   where (upper(description) like '%BOLD REMOVE%'
                                       )
                                     and li.trade_liquidity_indicator = cl.ex_trade_liquidity_indicator)
                       then 'FLASH'
                   when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(cl.par_t9730, 2, 1) in ('B', 'b', 's')
                       then 'FLASH'
                   when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(cl.str_t9730, 2, 1) in ('B', 'b', 's')
                       then 'FLASH'
--                   when CL.STRATEGY_DECISION_REASON_CODE in ('32', '62', '96', '99') then 'FLASH'
                   when Cl.CROSS_TYPE = 'P' then 'PIM'
                   when Cl.CROSS_TYPE = 'Q' then 'QCC'
                   when Cl.CROSS_TYPE = 'F' then 'Facilitation'
                   when Cl.CROSS_TYPE = 'S' then 'Solicitation'
                   else coalesce(CL.CROSS_TYPE, '') end || ',' || --Auc.type


               coalesce(cl.request_count, '') || ',' || --Req.count
               coalesce(cl.billing_code, '') || ',' ||--Billing Code
               coalesce(cl.contra_broker, '') || ',' || --ContraBroker
               coalesce(cl.contra_trader, '') || ',' || --ContraTrader
               coalesce(cl.white_list, '') || ',' || --WhiteList
               coalesce(staging.trailing_dot(cl.cons_payment_per_contract), '') || ',' ||
               coalesce(cl.contra_cross_exec_qty::text, '') || ',' ||
               coalesce(cl.contra_cross_lp_id, '') || ',' ||
               coalesce(cl.ac_account_demo_mnemonic, '')
                             as rec
        from dash_reporting.imc_final cl
                 left join lateral (select customer_or_firm_id
                                    from t_cust_or_firm cof
                                    where cof.exchange_id = cl.ex_exchange_id
                                      and cof.exch_customer_or_firm_id = cl.counterparty_range
                                    limit 1) cof on cl.counterparty_range is not null;
        get diagnostics l_row_cnt = row_count;

        select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod_pg printing: data is ready',
                               l_row_cnt, 'O')
        into l_step_id;

        create index on dash_reporting.imc_pg_report (order_id, exec_id);
        return query
            select
                'EntityCode,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,' ||
                'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,RFRID,OrigRFRID,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,ExchangeCode,ExConnection,GiveUpFirm,CMTAFirm,Account,SubAccount,' ||
                'OpenClose,Range,CounterpartyRange,PriceQualifier,TimeQualifier,ExecInst,LiquidityIndicator,ExchangeTransactionID,ExchangeOrderID,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,' ||
                'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,' ||
                'BidSzR,BidR,AskR,AskSzR,BidSzD,BidD,AskD,AskSzD,BidSzS,BidS,AskS,AskSzS,BidSzU,BidU,AskU,AskSzU,CrossOrderID,AuctionType,RequestCount,BillingType,ContraBroker,ContraTrader,WhiteList,PaymentPerContract,ContraCrossExecutedQty,CrossLPID,demo_account_mnemonic';

        return query
            select rec
            from dash_reporting.imc_pg_report
            order by order_id, exec_id
--    limit 0
        ;

        select public.load_log(l_load_id, l_step_id,
                               'get_consolidator_eod_pg printing for  ' || in_date_id::text || ' FINISHED ===',
                               l_row_cnt, 'O')
        into l_step_id;

    end;
    $function$
    ;
