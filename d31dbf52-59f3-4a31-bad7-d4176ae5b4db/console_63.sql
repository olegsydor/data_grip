-- DROP FUNCTION dash_reporting.get_consolidator_eod(date);
select * from dash_reporting.get_consolidator_eod(in_date := '2024-04-23')
CREATE OR REPLACE FUNCTION dash_reporting.get_consolidator_eod_(in_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(rec text)
 LANGUAGE plpgsql
AS $function$
-- SY: 20220102 https://dashfinancial.atlassian.net/browse/DS-4536 Ask price field has been fixed. Mistype was there bid_quantity  was used for some reason
-- SO: 20230823 https://dashfinancial.atlassian.net/browse/DEVREQ-3214 added 2 sets for MIAX and MEMX
-- SO: 20240201 https://dashfinancial.atlassian.net/browse/DEVREQ-3983 added the column demo_account_mnemonic
--              the simple join was used to avoid modifying the oracle part of this flow
declare
    ref       refcursor;
    l_load_id int;
    l_step_id int;
    row_cnt   int;
    l_date_id int4;



begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod STARTED ====', 0, 'O')
    into l_step_id;
    l_date_id = to_char(in_date, 'YYYYMMDD')::int4;
--   l_date_id = 20220527;
   create temp table rec_tmp on commit drop as
select 1 as rec_type, 0 as order_status,
		 'EntityCode,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,'||
		 'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,RFRID,OrigRFRID,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,ExchangeCode,ExConnection,GiveUpFirm,CMTAFirm,Account,SubAccount,'||
		 'OpenClose,Range,CounterpartyRange,PriceQualifier,TimeQualifier,ExecInst,LiquidityIndicator,ExchangeTransactionID,ExchangeOrderID,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,'||
		 'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,'||
		 'BidSzR,BidR,AskR,AskSzR,BidSzD,BidD,AskD,AskSzD,BidSzS,BidS,AskS,AskSzS,BidSzU,BidU,AskU,AskSzU,CrossOrderID,AuctionType,RequestCount,BillingType,ContraBroker,ContraTrader,WhiteList,PaymentPerContract,ContraCrossExecutedQty,CrossLPID,demo_account_mnemonic'
		as rec

	  union all
	  select

-- 	    cl.transaction_id,
        cl.rec_type, cl.order_status,
		cl.trading_firm_id||','|| --EntityCode
		to_char(cl.create_time,'YYYYMMDD')||','|| --CreateDate
		to_char(cl.create_time,'HH24MISSFF3')||','|| --CreateTime
		to_char(cl.exec_time,'YYYYMMDD')||','|| --StatusDate
		to_char(cl.exec_time,'HH24MISSFF3')||','|| --StatusTime
		coalesce(cl.opra_symbol, '')||','|| --OSI
		coalesce(cl.base_code, '')||','||--BaseCode
        coalesce(cl.root_symbol, '')||','|| --Root
		coalesce(cl.base_asset_type, '')||','||
		--
		coalesce(cl.expiration_date, '')||','||
		coalesce(staging.trailing_dot(cl.strike_price), '')||','||
		coalesce(cl.type_code, '')||','|| -- (S - stock)
		coalesce(cl.side, '')||','||
		coalesce(cl.leg_count::text, '')||','||  --LegCount
		coalesce(cl.leg_number::text, '')||','||  --LegNumber
		''||','||  --OrderType
		coalesce(cl.ord_status, '')||','||
		coalesce(to_char(cl.price, 'FM999990D0099'), '')||','||
		coalesce(to_char(cl.last_px, 'FM999990D0099'), '')||','||  --StatusPrice
		coalesce(cl.order_qty::text, '')||','|| --EnteredQty
		-- ask++
		coalesce(cl.last_qty::text, '')||','|| --StatusQty
		coalesce(cl.rfr_id, '')||','||--RFRID
		coalesce(cl.orig_rfr_id, '')||','||--OrigRFRID
		coalesce(cl.client_order_id, '')||','||
		coalesce(cl.replaced_order_id, '') ||','|| --Replaced Order
		coalesce(cl.cancel_order_id, '')||','|| --CancelOrderID
		coalesce(cl.parent_order_id, '')||','||
		coalesce(cl.order_id::text, '')||','|| --SystemOrderID
		coalesce(cl.exchange_code, '')||','|| --ExchangeCode
		coalesce(cl.ex_connection, '')||','|| --ExConnection
		coalesce(cl.give_up_firm, '')||','||--GiveUpFirm
		coalesce(cl.cmta_firm, '')||','|| --CMTAFirm
		coalesce(cl.clearing_account, '')||','||  --Account
		coalesce(cl.sub_account, '')||','||  --SubAccount
		coalesce(cl.open_close, '')||','||
		coalesce(cl.range, '')||','||  --Range
		--EX.CONTRA_ACCOUNT_CAPACITY
--		coalesce(cl.counterparty_range, '')||','||
		coalesce(case ascii(cl.counterparty_range) when 0 then repeat(' ', 1) else cl.counterparty_range end, '')||','||
		coalesce(cl.order_type, '')||','|| --PriceQualifier
		coalesce(cl.time_in_force, '')||','|| --TimeQualifier
		coalesce(cl.exec_inst, '')||','|| --ExecInst
        -- The next row was changed within https://dashfinancial.atlassian.net/browse/DEVREQ-3278
        coalesce(staging.get_trade_liquidity_indicator(cl.trade_liquidity_indicator), '') || ',' || --Maker/Take
		coalesce(cl.exch_exec_id, '')||','|| --ExchangeTransactionID
		coalesce(cl.exch_order_id, '')||','|| --ExchangeOrderID

     	coalesce(amex.bid_quantity::text,'')||','|| --BidSzA
		coalesce(to_char(amex.bid_price,'FM999999.0099'),'')||','|| --BidA
		coalesce(to_char(amex.ask_price,'FM999999.0099'),'')||','||  --AskA
		coalesce(amex.ask_quantity::text,'')||','||  --AskSzA

		coalesce(bato.bid_quantity::text,'')||','|| --BidSzZ
		coalesce(to_char(bato.bid_price,'FM999999.0099'),'')||','|| --BidZ
		coalesce(to_char(bato.ask_price,'FM999999.0099'),'')||','||  --AskZ
		coalesce(bato.ask_quantity::text,'')||','||  --AskSzZ

		coalesce(box.bid_quantity::text,'')||','|| --BidSzB
		coalesce(to_char(box.bid_price,'FM999999.0099'),'')||','|| --BidB
		coalesce(to_char(box.ask_price,'FM999999.0099'),'')||','||  --AskB
		coalesce(box.ask_quantity::text,'')||','||  --AskSzB
		--
		coalesce(cboe.bid_quantity::text,'')||','|| --BidSzC
		coalesce(to_char(cboe.bid_price,'FM999999.0099'),'')||','|| --BidC
		coalesce(to_char(cboe.ask_price,'FM999999.0099'),'')||','||  --AskC
		coalesce(cboe.ask_quantity::text,'')||','||  --AskSzC

		coalesce(c2ox.bid_quantity::text,'')||','|| --BidSzW
		coalesce(to_char(c2ox.bid_price,'FM999999.0099'),'')||','|| --BidW
		coalesce(to_char(c2ox.ask_price,'FM999999.0099'),'')||','||  --AskW
		coalesce(c2ox.ask_quantity::text,'')||','||  --AskSzW

		coalesce(nqbxo.bid_quantity::text,'')||','|| --BidSzT
		coalesce(to_char(nqbxo.bid_price,'FM999999.0099'),'')||','|| --BidT
		coalesce(to_char(nqbxo.ask_price,'FM999999.0099'),'')||','||  --AskT
		coalesce(nqbxo.ask_quantity::text,'')||','||  --AskSzT

		coalesce(ise.bid_quantity::text,'')||','|| --BidSzI
		coalesce(to_char(ise.bid_price,'FM999999.0099'),'')||','|| --BidI
		coalesce(to_char(ise.ask_price,'FM999999.0099'),'')||','||  --AskI
		coalesce(ise.ask_quantity::text,'')||','||  --AskSzI

		coalesce(arca.bid_quantity::text,'')||','|| --BidSzP
		coalesce(to_char(arca.bid_price,'FM999999.0099'),'')||','|| --BidP
		coalesce(to_char(arca.ask_price,'FM999999.0099'),'')||','||  --AskP
		coalesce(arca.ask_quantity::text,'')||','||  --AskSzP

        coalesce(miax.bid_quantity::text,'')||','|| --BidSzM
		coalesce(to_char(miax.bid_price,'FM999999.0099'),'')||','|| --BidM
		coalesce(to_char(miax.ask_price,'FM999999.0099'),'')||','||  --AskM
		coalesce(miax.ask_quantity::text,'')||','||  --AskSzM

        coalesce(gemini.bid_quantity::text,'')||','|| --BidSzH
		coalesce(to_char(gemini.bid_price,'FM999999.0099'),'')||','|| --BidH
		coalesce(to_char(gemini.ask_price,'FM999999.0099'),'')||','||  --AskH
		coalesce(gemini.ask_quantity::text,'')||','||  --AskSzH

        coalesce(nsdqo.bid_quantity::text,'')||','|| --BidSzQ
		coalesce(to_char(nsdqo.bid_price,'FM999999.0099'),'')||','|| --BidQ
		coalesce(to_char(nsdqo.ask_price,'FM999999.0099'),'')||','||  --AskQ
		coalesce(nsdqo.ask_quantity::text,'')||','||  --AskSzQ

        coalesce(phlx.bid_quantity::text,'')||','|| --BidSzX
		coalesce(to_char(phlx.bid_price,'FM999999.0099'),'')||','|| --BidX
		coalesce(to_char(phlx.ask_price,'FM999999.0099'),'')||','||  --AskX
		coalesce(phlx.ask_quantity::text,'')||','||  --AskSzX

        coalesce(edgo.bid_quantity::text,'')||','|| --BidSzE
		coalesce(to_char(edgo.bid_price,'FM999999.0099'),'')||','|| --BidE
		coalesce(to_char(edgo.ask_price,'FM999999.0099'),'')||','||  --AskE
		coalesce(edgo.ask_quantity::text,'')||','||  --AskSzE

        coalesce(mcry.bid_quantity::text,'')||','|| --BidSzJ
		coalesce(to_char(mcry.bid_price,'FM999999.0099'),'')||','|| --BidJ
		coalesce(to_char(mcry.ask_price,'FM999999.0099'),'')||','||  --AskJ
		coalesce(mcry.ask_quantity::text,'')||','||  --AskSzJ

        coalesce(mprl.bid_quantity::text,'')||','|| --BidSzR
		coalesce(to_char(mprl.bid_price,'FM999999.0099'),'')||','|| --BidR
		coalesce(to_char(mprl.ask_price,'FM999999.0099'),'')||','||  --AskR
		coalesce(mprl.ask_quantity::text,'')||','||  --AskSzR

        coalesce(emld.bid_quantity::text,'')||','|| --BidSzD
		coalesce(to_char(emld.bid_price,'FM999999.0099'),'')||','|| --BidD
		coalesce(to_char(emld.ask_price,'FM999999.0099'),'')||','||  --AskD
		coalesce(emld.ask_quantity::text,'')||','||  --AskSzD
-----
       coalesce(sphr.bid_qty::text, '') || ',' || --BidSzS
       coalesce(to_char(sphr.bid_price, 'FM999999.0099'), '') || ',' || --BidS
       coalesce(to_char(sphr.ask_price, 'FM999999.0099'), '') || ',' || --AskS
       coalesce(sphr.ask_qty::text, '') || ',' || --AskSzS

       coalesce(mxop.bid_qty::text, '') || ',' || --BidSzU
       coalesce(to_char(mxop.bid_price, 'FM999999.0099'), '') || ',' || --BidU
       coalesce(to_char(mxop.ask_price, 'FM999999.0099'), '') || ',' || --AskU
       coalesce(mxop.ask_qty::text, '') || ',' || --AskSzU
-----
		--CrossOrderID,AuctionType,RequestCount,BillingType,ContraBroker,ContraTrader,WhiteList,PaymentPerContract,ContraCrossExecutedQty
		coalesce(cl.cross_order_id::text, '')||','|| --CrossOrderID
-- 		coalesce(cl.auction_type, '')||','|| --Auc.type
		case
		    when CL.STRATEGY_DECISION_REASON_CODE in ('74') and substring(fmj.t9730, 2, 1) in ('B','b','s') then 'FLASH'
			when CL.STRATEGY_DECISION_REASON_CODE in ('32', '62', '96', '99') then 'FLASH'
			when Cl.CROSS_TYPE = 'P' then 'PIM' when Cl.CROSS_TYPE = 'Q' then 'QCC'
		    when Cl.CROSS_TYPE = 'F' then 'Facilitation'
		    when Cl.CROSS_TYPE = 'S' then 'Solicitation'
       else coalesce(CL.CROSS_TYPE, '') end||','|| --Auc.type


		coalesce(cl.request_count, '')||','|| --Req.count
		coalesce(cl.billing_code, '')||','||--Billing Code
        coalesce(cl.contra_broker, '')||','|| --ContraBroker
		coalesce(cl.contra_trader, '')||','|| --ContraTrader
		coalesce(cl.white_list, '')||','||  --WhiteList
		coalesce(staging.trailing_dot(cl.cons_payment_per_contract), '')||','||
		coalesce(cl.contra_cross_exec_qty::text, '')||','||
		coalesce(cl.contra_cross_lp_id, '')||','||
		coalesce(dc.account_demo_mnemonic, '')
    as rec
from staging.cons_eod_permanent cl
         left join lateral (select account_demo_mnemonic
                            from dwh.client_order co
                                     join dwh.d_account da using (account_id)
                            where cl.order_id = co.order_id
                              and co.create_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                            limit 1) dc on true
         left join lateral (select fix_message ->> '9730' as t9730
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = cl.fix_message_id
                              and fmj.date_id = public.get_dateid(cl.exec_time::date)
                            limit 1) fmj on true
      -- amex
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'AMEX'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) amex on true
-- bato
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'BATO'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) bato on true
-- box
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'BOX'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) box on true
-- cboe
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'CBOE'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) cboe on true
-- c2ox
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'C2OX'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) c2ox on true
-- nqbxo
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'NQBXO'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) nqbxo on true
-- ise
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'ISE'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) ise on true
-- arca
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'ARCA'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) arca on true
-- miax
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'MIAX'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) miax on true
-- gemini
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'GEMINI'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) gemini on true
-- nsdqo
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'NSDQO'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) nsdqo on true
-- phlx
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'PHLX'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) phlx on true
-- edgo
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'EDGO'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) edgo on true
-- mcry
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'MCRY'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) mcry on true
-- mprl
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'MPRL'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) mprl on true
-- emld
               left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                  from dwh.l1_snapshot ls
                                  where ls.transaction_id = cl.transaction_id
                                    and ls.exchange_id = 'EMLD'
                                    and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                  limit 1
          ) emld on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity as ask_qty, ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'SPHR'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) sphr on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity as ask_qty, ls.bid_quantity as bid_qty
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = cl.transaction_id
                                  and ls.exchange_id = 'MXOP'
                                  and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                limit 1
        ) mxop on true
--         where 1=2
--        limit 1000
       ;

		get diagnostics row_cnt = row_count;
		select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod temp table was created', row_cnt, 'I')
		into l_step_id;

		create index on rec_tmp (rec_type, order_status);
		select public.load_log(l_load_id, l_step_id, 'get_consolidator_eod temp table was indexed', row_cnt, 'I')
		into l_step_id;


		return query
		select x.rec from rec_tmp x
		order by rec_type, order_status;

end;
$function$
;
