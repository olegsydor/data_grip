/*select *
from dash360.report_rps_lpeod_compliance(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                         in_account_ids := '{16358,18379,24812,24813,27610,27609,24810,24811,24990,29173,54064,16357,16355,16356}');

select *
from dash360.report_rps_lpeod_compliance(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                         in_account_ids := '{16357}');

create or replace function dash360.report_rps_lpeod_compliance(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[])
 returns table(ret_row text)
 language plpgsql
as
$function$
declare
    l_firm text := '';

begin
    if exists (select null from dwh.d_account where account_id = any (in_account_ids) and trading_firm_id = 'aostb01')
    then
        l_firm = 'aostb01';
    end if;
    return query
        select case
                   when l_firm = 'aostb01'
                       then
                                       'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,' ||
                                       'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,' ||
                                       'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,' ||
                                       'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,' ||
                                       'BidSzNBBO,BidNBBO,AskNBBO,AskSzNBBO,BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz'
                   else
                                       'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,' ||
                                       'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,' ||
                                       'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,' ||
                                       'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,' ||
                                       'BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz'
                   end;
    return query
        select
-- 		      EX.ORDER_ID as rec_type, EX.EXEC_ID as order_status,
AC.ACCOUNT_NAME || ',' || --UserLogin
FC.FIX_COMP_ID || ',' || --SendingUserLogin
AC.TRADING_FIRM_ID || ',' || --EntityCode
TF.TRADING_FIRM_NAME || ',' || --EntityName
'' || ',' || --DestinationEntity
'' || ',' || --Owner
to_char(CL.CREATE_TIME, 'YYYYMMDD') || ',' || --CreateDate
to_char(EX.EXEC_TIME, 'HH24MISSFF3') || ',' || --CreateTime
'' || ',' || --StatusDate
'' || ',' || --StatusTime
OC.OPRA_SYMBOL || ',' || --OSI
UI.SYMBOL || ',' ||--BaseCode
OS.ROOT_SYMBOL || ',' || --Root
UI.INSTRUMENT_TYPE_ID || ',' || --BaseAssetType
to_char(OC.MATURITY_MONTH, 'FM00') || '/' || to_char(OC.MATURITY_DAY, 'FM00') || '/' || OC.MATURITY_YEAR ||
',' || --ExpirationDate
OC.STRIKE_PRICE || ',' ||
case when OC.PUT_CALL = '0' then 'P' else 'C' end || ',' || --TypeCode
case
    when CL.SIDE = '1' and CL.OPEN_CLOSE = 'C' then 'BC'
    else case CL.SIDE when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' end
    end || ',' ||
case
    when cl.multileg_reporting_type = '1' then '1'
    else
        (select NO_LEGS from dwh.CLIENT_ORDER mcl where mcl.ORDER_ID = CL.MULTILEG_ORDER_ID) end || ',' || --LegCount
--  			LN.LEG_NUMBER||','||  --LegNumber
case
    when cl.multileg_reporting_type = '1' then ''
    else
        coalesce(staging.get_multileg_leg_number(cl.order_id)::text, '') end || ',' || --LegNumber
'' || ',' || --OrderType
case
    when CL.PARENT_ORDER_ID is null then
        case EX.ORDER_STATUS
            when 'A' then 'Pnd Open'
            when 'b' then 'Pnd Cxl'
            when 'S' then 'Pnd Rep'
            when '1' then 'Partial'
            when '2' then 'Filled'
            else
                case EX.EXEC_TYPE
                    when '4' then 'Canceled'
                    when 'W' then 'Replaced'
                    else coalesce(EX.EXEC_TYPE, '') end end
    else case EX.ORDER_STATUS
             when 'A' then 'Ex Pnd Open'
             when '0' then 'Ex Open'
             when '8' then 'Ex Rej'
             when 'b' then 'Ex Pnd Cxl'
             when '1' then 'Ex Partial'
             when '2' then 'Ex Rpt Fill'
             when '4' then 'Ex Rpt Out'
             else coalesce(EX.ORDER_STATUS, '') end
    end || ',' || --Status
coalesce(to_char(CL.PRICE, 'FM999990D0099'), '') || ',' ||
to_char(EX.LAST_PX, 'FM999990D0099') || ',' || --StatusPrice
CL.ORDER_QTY || ',' || --Entered Qty
-- ask++
EX.LEAVES_QTY || ',' || --StatusQty
--Order
CL.CLIENT_ORDER_ID || ',' ||
case
    when EX.EXEC_TYPE in ('S', 'W') then orig.client_order_id
    else '' end || ',' || --Replaced Order
case
    when EX.EXEC_TYPE in ('b', '4') then cxl.client_order_id
    else '' end || ',' || --CancelOrderID
coalesce(po.client_order_id, '') || ',' ||
CL.ORDER_ID || ',' || --SystemOrderID
'' || ',' || --Generation
coalesce(CL.sub_strategy_desc, EXC.MIC_CODE, '') || ',' || --ExchangeCode
-- 			coalesce(CL.opt_exec_broker_id,OPX.OPT_EXEC_BROKER)||','|| --GiveUpFirm -- changed
coalesce((select opt_exec_broker
          from dwh.d_opt_exec_broker dbr
          where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
          limit 1), '') || ',' ||--giveupfirm
-- 			case
-- 			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then--CL.OPT_CLEARING_FIRM_ID
-- 			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
-- 			end||','|| --CMTAFirm
case
    when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
    else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '')
    end || ',' || --CMTAFirm
'' || ',' || --AccountAlias
'' || ',' || --Account
'' || ',' || --SubAccount
'' || ',' || --SubAccount2
'' || ',' || --SubAccount3
CL.OPEN_CLOSE || ',' ||
case (case AC.OPT_IS_FIX_CUSTFIRM_PROCESSED
          when 'Y' then coalesce(CL.customer_or_firm_id, AC.OPT_CUSTOMER_OR_FIRM)
          else AC.OPT_CUSTOMER_OR_FIRM
    end)
    when '0' then 'CUST'
    when '1' then 'FIRM'
    when '2' then 'BD'
    when '3' then 'BD-CUST'
    when '4' then 'MM'
    when '5' then 'AMM'
    when '7' then 'BD-FIRM'
    when '8' then 'CUST-PRO'
    when 'J' then 'JBO'
    else ''
    end || ',' || --Range
OT.ORDER_TYPE_SHORT_NAME || ',' || --PriceQualifier
TIF.TIF_SHORT_NAME || ',' || --TimeQualifier
EX.EXCH_EXEC_ID || ',' || --ExchangeTransactionID
coalesce(CL.EXCH_ORDER_ID, '') || ',' || --ExchangeOrderID
'' || ',' || --MPID
'' || ',' || --Comment
--bid_qty, bid_price, ask_qty, ask_price
coalesce(amex.bid_qty::text, '') || ',' || --BidSzA
coalesce(to_char(amex.bid_price, 'FM999999.0099'), '') || ',' || --BidA
coalesce(to_char(amex.ask_price, 'FM999999.0099'), '') || ',' || --AskA
coalesce(amex.ask_qty::text, '') || ',' || --AskSzA

coalesce(bato.bid_qty::text, '') || ',' || --BidSzZ
coalesce(to_char(bato.bid_price, 'FM999999.0099'), '') || ',' || --BidZ
coalesce(to_char(bato.ask_price, 'FM999999.0099'), '') || ',' || --AskZ
coalesce(bato.ask_qty::text, '') || ',' || --AskSzZ

coalesce(box.bid_qty::text, '') || ',' || --BidSzB
coalesce(to_char(box.bid_price, 'FM999999.0099'), '') || ',' || --BidB
coalesce(to_char(box.ask_price, 'FM999999.0099'), '') || ',' || --AskB
coalesce(box.ask_qty::text, '') || ',' || --AskSzB
--
coalesce(cboe.bid_qty::text, '') || ',' || --BidSzC
coalesce(to_char(cboe.bid_price, 'FM999999.0099'), '') || ',' || --BidC
coalesce(to_char(cboe.ask_price, 'FM999999.0099'), '') || ',' || --AskC
coalesce(cboe.ask_qty::text, '') || ',' || --AskSzC

coalesce(c2ox.bid_qty::text, '') || ',' || --BidSzW
coalesce(to_char(c2ox.bid_price, 'FM999999.0099'), '') || ',' || --BidW
coalesce(to_char(c2ox.ask_price, 'FM999999.0099'), '') || ',' || --AskW
coalesce(c2ox.ask_qty::text, '') || ',' || --AskSzW

coalesce(nqbxo.bid_qty::text, '') || ',' || --BidSzT
coalesce(to_char(nqbxo.bid_price, 'FM999999.0099'), '') || ',' || --BidT
coalesce(to_char(nqbxo.ask_price, 'FM999999.0099'), '') || ',' || --AskT
coalesce(nqbxo.ask_qty::text, '') || ',' || --AskSzT

coalesce(ise.bid_qty::text, '') || ',' || --BidSzI
coalesce(to_char(ise.bid_price, 'FM999999.0099'), '') || ',' || --BidI
coalesce(to_char(ise.ask_price, 'FM999999.0099'), '') || ',' || --AskI
coalesce(ise.ask_qty::text, '') || ',' || --AskSzI

coalesce(arca.bid_qty::text, '') || ',' || --BidSzP
coalesce(to_char(arca.bid_price, 'FM999999.0099'), '') || ',' || --BidP
coalesce(to_char(arca.ask_price, 'FM999999.0099'), '') || ',' || --AskP
coalesce(arca.ask_qty::text, '') || ',' || --AskSzP

coalesce(miax.bid_qty::text, '') || ',' || --BidSzM
coalesce(to_char(miax.bid_price, 'FM999999.0099'), '') || ',' || --BidM
coalesce(to_char(miax.ask_price, 'FM999999.0099'), '') || ',' || --AskM
coalesce(miax.ask_qty::text, '') || ',' || --AskSzM

coalesce(gemini.bid_qty::text, '') || ',' || --BidSzH
coalesce(to_char(gemini.bid_price, 'FM999999.0099'), '') || ',' || --BidH
coalesce(to_char(gemini.ask_price, 'FM999999.0099'), '') || ',' || --AskH
coalesce(gemini.ask_qty::text, '') || ',' || --AskSzH

coalesce(nsdqo.bid_qty::text, '') || ',' || --BidSzQ
coalesce(to_char(nsdqo.bid_price, 'FM999999.0099'), '') || ',' || --BidQ
coalesce(to_char(nsdqo.ask_price, 'FM999999.0099'), '') || ',' || --AskQ
coalesce(nsdqo.ask_qty::text, '') || ',' || --AskSzQ

coalesce(phlx.bid_qty::text, '') || ',' || --BidSzX
coalesce(to_char(phlx.bid_price, 'FM999999.0099'), '') || ',' || --BidX
coalesce(to_char(phlx.ask_price, 'FM999999.0099'), '') || ',' || --AskX
coalesce(phlx.ask_qty::text, '') || ',' || --AskSzX

coalesce(edgo.bid_qty::text, '') || ',' || --BidSzE
coalesce(to_char(edgo.bid_price, 'FM999999.0099'), '') || ',' || --BidE
coalesce(to_char(edgo.ask_price, 'FM999999.0099'), '') || ',' || --AskE
coalesce(edgo.ask_qty::text, '') || ',' || --AskSzE

coalesce(mcry.bid_qty::text, '') || ',' || --BidSzJ
coalesce(to_char(mcry.bid_price, 'FM999999.0099'), '') || ',' || --BidJ
coalesce(to_char(mcry.ask_price, 'FM999999.0099'), '') || ',' || --AskJ
coalesce(mcry.ask_qty::text, '') || ',' || --AskSzJ

case
    when l_firm = 'aostb01'
        then
        --Add NBBO
                                    coalesce(mprl.bid_qty::text, '') || ',' || --BidSzNBBO
                                    coalesce(to_char(mprl.bid_price, 'FM999999.0099'), '') || ',' || --BidNBBO
                                    coalesce(to_char(mprl.ask_price, 'FM999999.0099'), '') || ',' || --AskNBBO
                                    coalesce(mprl.ask_qty::text, '') || ',' --AskSzNBBO
    else ''
    end ||
coalesce(mprl.bid_qty::text, '') || ',' || --BidSzR
coalesce(to_char(mprl.bid_price, 'FM999999.0099'), '') || ',' || --BidR
coalesce(to_char(mprl.ask_price, 'FM999999.0099'), '') || ',' || --AskR
coalesce(mprl.ask_qty::text, '') || ',' || --AskSzR
'' || ',' || --ULBidSz
'' || ',' || --ULBid
'' || ',' || --ULAsk
'' || ',' || --ULAskSz
''
    as rec
        from dwh.client_order cl
                 inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
                 inner join dwh.execution ex on cl.order_id = ex.order_id and ex.exec_date_id >= cl.create_date_id
                 left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 inner join dwh.d_account ac on ac.account_id = cl.account_id
                 inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 left join lateral (select orig.client_order_id
                                    from dwh.client_order orig
                                    where orig.order_id = cl.orig_order_id
                                      and orig.create_date_id <= cl.create_date_id
                                    limit 1) orig on true
                 left join lateral (select min(cxl.client_order_id) as client_order_id
                                    from client_order cxl
                                    where cxl.orig_order_id = cl.order_id
                                    limit 1) cxl on true
                 left join lateral (select po.client_order_id
                                    from client_order po
                                    where po.order_id = cl.parent_order_id
                                      and po.create_date_id <= cl.create_date_id
                                    limit 1) po on true
                 left join dwh.d_clearing_account ca
                           on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                               ca.market_type = 'o' and ca.clearing_account_type = '1')
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
            --left join liquidity_indicator tli on (tli.trade_liquidity_indicator = ex.trade_liquidity_indicator and tli.exchange_id = exc.real_exchange_id)
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
            --          left join CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID
--          left join dwh.STRATEGY_IN SIT
--                    on (SIT.TRANSACTION_ID = CL.TRANSACTION_ID and SIT.STRATEGY_IN_TYPE_ID in ('Ab', 'H'))
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'AMEX'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
----                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) amex on true
-- bato
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'BATO'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) bato on true
-- box
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'BOX'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) box on true
-- cboe
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'CBOE'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) cboe on true
-- c2ox
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'C2OX'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) c2ox on true
-- nqbxo
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'NQBXO'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) nqbxo on true
-- ise
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'ISE'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) ise on true
-- arca
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'ARCA'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) arca on true
-- miax
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'MIAX'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) miax on true
-- gemini
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'GEMINI'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) gemini on true
-- nsdqo
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'NSDQO'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) nsdqo on true
-- phlx
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'PHLX'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) phlx on true
-- edgo
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'EDGO'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) edgo on true
-- mcry
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'MCRY'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) mcry on true
-- mprl
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'MPRL'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) mprl on true
-- emld
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'EMLD'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                    limit 1
            ) emld on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'SPHR'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                    limit 1
            ) sphr on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'MXOP'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                    limit 1
            ) mxop on true
                 left join lateral (select ls.ask_price,
                                           ls.bid_price,
                                           ls.ask_quantity as ask_qty,
                                           ls.bid_quantity as bid_qty
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = cl.transaction_id
                                      and ls.exchange_id = 'NBBO'
                                      and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
                                    limit 1
            ) nbbo on true

        where CL.CREATE_date_id between in_start_date_id and in_end_date_id
--             and AC.TRADING_FIRM_ID = in_firm
          and cl.account_id = any (in_account_ids)
          --and CL.PARENT_ORDER_ID is null -- all orders
          and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
          --and EX.EXEC_TYPE = 'F'
          and EX.IS_BUSTED = 'N'
          and EX.EXEC_TYPE not in ('3', 'a', '5', 'E')
          and CL.TRANS_TYPE <> 'F'
          and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
-- and ex.order_id = 13454466648
    ;
end;
$function$
;
select * from dash360.report_rps_lpeod_fills(in_start_date_id := 20231019, in_end_date_id := 20231019, in_account_ids := '{13687,13411,9374,68613,13686}');
------------------------------------------------------------------------------------------------------------------
select *
from dash360.report_rps_lpeod_fills(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                    in_account_ids := '{13687,13411,9374,68613,13686}');

select *
from dash360.report_rps_lpeod_fees(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                    in_account_ids := '{13687,13411,9374,68613,13686}');

create or replace function dash360.report_rps_lpeod_fills(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[])
 returns table(ret_row text)
 language plpgsql
as $function$
begin
    return query
        select 'CreateDate,CreateTime,EntityCode,Login,SystemOrderID,Underlying,ExpirationDate,Strike,TypeCode,BuySell,Quantity,OpenClose,AvgPrice,ExchangeCode,GiveUpFirm,CMTAFirm,Range';
    return query
        select cl.create_date_id::text || ',' ||
               to_char(ex.exec_time, 'HH24:MI:SS:US') || ',' ||
               ac.trading_firm_id || ',' ||
                   --cl.client_id||','||
               ac.account_name || ',' ||
               cl.client_order_id || ',' ||
               ui.symbol || ',' ||
               to_char(oc.maturity_month, 'FM00') || '/' || to_char(oc.maturity_day, 'FM00') || '/' ||
               oc.maturity_year ||
               ',' ||
               oc.strike_price || ',' ||
               case when oc.put_call = '0' then 'P' else 'C' end || ',' ||
               case when cl.side = '1' then 'B' else 'S' end || ',' ||
                   --ODCS.DAY_CUM_QTY||','||
               ex.last_qty || ',' ||
               cl.open_close || ',' ||
                   --AvgPx
               to_char(tr.avg_px, 'FM999990D0099') || ',' ||
               case ex.exchange_id
                   when 'AMEX' then 'A'
                   when 'BATO' then 'Z'
                   when 'BOX' then 'B'
                   when 'CBOE' then 'C'
                   when 'C2OX' then 'W'
                   when 'NQBXO' then 'T'
                   when 'ISE' then 'I'
                   when 'ARCA' then 'P'
                   when 'MIAX' then 'M'
                   when 'GMNI' then 'H'
                   when 'NSDQO' then 'Q'
                   when 'PHLX' then 'X'
                   when 'EDGO' then 'E'
                   when 'MCRY' then 'J'
                   when 'MPRL' then 'R'
                   else '' end || ',' ||
               coalesce((select opt_exec_broker
                         from dwh.d_opt_exec_broker dbr
                         where dbr.opt_exec_broker_id = coalesce(cl.opt_exec_broker_id, opx.opt_exec_broker_id)
                         limit 1), '') || ',' ||
               case
                   when ac.opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
                   else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '') || ',' ||
                        case (case ac.opt_is_fix_custfirm_processed
                                  when 'Y' then coalesce(cl.customer_or_firm_id, ac.opt_customer_or_firm)
                                  else ac.opt_customer_or_firm
                            end)
                            when '0' then 'CUST'
                            when '1' then 'FIRM'
                            when '2' then 'BD'
                            when '3' then 'BD-CUST'
                            when '4' then 'MM'
                            when '5' then 'AMM'
                            when '7' then 'BD-FIRM'
                            when '8' then 'CUST-PRO'
                            when 'J' then 'JBO'
                            else '' end end--Range
                   as rec
        from dwh.client_order cl
                 inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                 inner join lateral (select exchange_id, exec_time, last_qty
                                     from dwh.execution ex
                                     where cl.order_id = ex.order_id
                                       and ex.exec_date_id = cl.create_date_id
                                       and ex.exec_type = 'F'
                                       and ex.is_busted = 'N'
                                       and ex.exec_date_id between in_start_date_id and in_end_date_id
            ) ex on true
                 left join dwh.d_exchange exc on exc.exchange_id = ex.exchange_id and exc.is_active
                 inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 left join dwh.d_clearing_account ca
                           on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                               ca.market_type = 'O' and ca.clearing_account_type = '1')
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                 left join lateral (select sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px
                                    from dwh.flat_trade_record tr
                                    where true
                                      and tr.order_id = cl.order_id
                                      and tr.is_busted <> 'Y'
                                      and tr.date_id = cl.create_date_id
                                    limit 1) tr on true
        where cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.account_id = any(in_account_ids)
          and ac.is_active
--           and ac.trading_firm_id = in_firm
          and cl.parent_order_id is null;
end;

$function$
;

create or replace function dash360.report_rps_lpeod_fees(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[])
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
begin
    return query
        select 'CreateDate,CreateTime,EntityCode,Login,BuySell,Underlying,Quantity,Price,ExpirationDate,Strike,TypeCode,ExchangeCode,SystemOrderID,GiveUpFirm,CMTA,Range,isSpread,isALGO,isPennyName,RouteName,LiquidityTag,Handling,' ||
               'StandardFee,MakeTakeFee,LinkageFee,SurchargeFee,Total';
    return query
        select x.date_id::text || ',' ||
               to_char(x.trade_record_time, 'HH24MISSFF3') || ',' ||
               x.TRADING_FIRM_ID || ',' ||
                   --CL.CLIENT_ID||','||
               x.ACCOUNT_NAME || ',' ||
               case when x.SIDE = '1' then 'B' else 'S' end || ',' ||
               x.SYMBOL || ',' ||
               x.LAST_QTY || ',' ||
               to_char(x.LAST_PX, 'FM999990D0099') || ',' ||
               to_char(x.MATURITY_MONTH, 'FM00') || '/' || to_char(x.MATURITY_DAY, 'FM00') || '/' ||
               x.MATURITY_YEAR || ',' ||
               coalesce(staging.trailing_dot(x.strike_price), '') || ',' ||
               case when x.PUT_CALL = '0' then 'P' else 'C' end || ',' ||
                   --ODCS.DAY_CUM_QTY||','||
                   --CL.OPEN_CLOSE||','||
               case x.EXCHANGE_ID
                   when 'AMEX' then 'A'
                   when 'BATO' then 'Z'
                   when 'BOX' then 'B'
                   when 'CBOE' then 'C'
                   when 'C2OX' then 'W'
                   when 'NQBXO' then 'T'
                   when 'ISE' then 'I'
                   when 'ARCA' then 'P'
                   when 'MIAX' then 'M'
                   when 'GMNI' then 'H'
                   when 'NSDQO' then 'Q'
                   when 'PHLX' then 'X'
                   when 'EDGO' then 'E'
                   when 'MCRY' then 'J'
                   when 'MPRL' then 'R'
                   else '' end || ',' ||
               x.CLIENT_ORDER_ID || ',' ||
-- 			NVL(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER)||','||
               coalesce(x.opt_exec_broker::text, '') || ',' ||
                   -- 			case
-- 			  when AC.OPT_IS_FIX_CLFIRM_PROCESSED = 'Y' then CL.OPT_CLEARING_FIRM_ID
-- 			  else NVL(lpad(CA.CMTA, 3, 0),CL.OPT_CLEARING_FIRM_ID)
-- 			end||','||
               coalesce(x.cmta::text, '') || ',' ||
               case x.opt_customer_firm
                   when '0' then 'CUST'
                   when '1' then 'FIRM'
                   when '2' then 'BD'
                   when '3' then 'BD-CUST'
                   when '4' then 'MM'
                   when '5' then 'AMM'
                   when '7' then 'BD-FIRM'
                   when '8' then 'CUST-PRO'
                   when 'J' then 'JBO'
                   else '' end || ',' ||--Range
               case x.MULTILEG_REPORTING_TYPE when '1' then 'N' else 'Y' end || ',' || --isSpread
               case x.SUB_STRATEGY when 'DMA' then 'N' else 'Y' end || ',' || --isALGO
               case x.MIN_TICK_INCREMENT when 0.01 then 'Y' else 'N' end || ',' ||
               coalesce(x.SUB_STRATEGY, '') || ',' ||
               coalesce(x.TRADE_LIQUIDITY_INDICATOR, '') || ',' ||
               case x.LIQUIDITY_INDICATOR_TYPE_ID
                   when '1' then '128'
                   when '2' then '129'
                   when '3' then '140'
                   else '' end || ',' || --Handling Code
-- 			to_char(ROUND(BEX.TRANSACTION_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--StandardFee
               to_char(ROUND(coalesce(x.tcce_transaction_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--StandardFee
-- 			to_char(ROUND(BEX.MAKER_TAKER_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--MakeTakeFee
               to_char(ROUND(coalesce(x.tcce_maker_taker_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--MakeTakeFee
-- 			''||','||--LinkageFee
-- 			to_char(ROUND(BEX.ROYALTY_FEE, 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')||','||--SurchargeFee
               to_char(ROUND(coalesce(x.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') || ',' ||--SurchargeFee
               to_char(ROUND(coalesce(x.tcce_transaction_fee_amount, 0) + coalesce(x.tcce_maker_taker_fee_amount, 0) +
                             coalesce(x.tcce_royalty_fee_amount, 0), 4), 'FM999990.0000') --Total
-- 			to_char(ROUND(NVL(BEX.TRANSACTION_FEE,0)+NVL(BEX.MAKER_TAKER_FEE,0)+NVL(BEX.ROYALTY_FEE,0), 4),'FM999990.0000', 'NLS_NUMERIC_CHARACTERS = ''. ''')--Total

                   as rec
-- select cl.order_id, exec_id
        from (select distinct on (cl.order_id, exec_id) cl.order_id,
                                                        exec_id,
                                                        ---
                                                        cl.date_id,
                                                        cl.trade_record_time,
                                                        ac.trading_firm_id,
                                                        ac.account_name,
                                                        cl.side,
                                                        ui.symbol,
                                                        ftr.last_qty,
                                                        cl.last_px,
                                                        oc.maturity_month,
                                                        oc.maturity_day,
                                                        oc.maturity_year,
                                                        oc.strike_price,
                                                        oc.put_call,
                                                        cl.exchange_id,
                                                        cl.client_order_id,
                                                        opx.opt_exec_broker,
                                                        cl.cmta,
                                                        cl.opt_customer_firm,
                                                        cl.multileg_reporting_type,
                                                        cl.sub_strategy,
                                                        os.min_tick_increment,
                                                        cl.trade_liquidity_indicator,
                                                        tli.liquidity_indicator_type_id,
                                                        ftr.tcce_transaction_fee_amount,
                                                        ftr.tcce_maker_taker_fee_amount,
                                                        ftr.tcce_royalty_fee_amount

              from dwh.flat_trade_record CL
                       inner join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                       inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                       inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                       inner join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                       inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
                       left join dwh.d_clearing_account ca
                                 on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                                     ca.market_type = 'O' and ca.clearing_account_type = '1')
                       left join dwh.d_opt_exec_broker opx
                                 on (opx.account_id = ac.account_id and opx.is_default = 'Y' and opx.is_active)
                       left join dwh.d_LIQUIDITY_INDICATOR TLI
                                 on (TLI.TRADE_LIQUIDITY_INDICATOR = cl.TRADE_LIQUIDITY_INDICATOR and
                                     TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID and tli.is_active)
                       left join lateral (select sum(last_qty)                                 as last_qty,
                                                 sum(coalesce(tcce_transaction_fee_amount, 0)) as tcce_transaction_fee_amount,
                                                 sum(coalesce(tcce_maker_taker_fee_amount, 0)) as tcce_maker_taker_fee_amount,
                                                 sum(coalesce(tcce_royalty_fee_amount, 0))     as tcce_royalty_fee_amount
                                          from dwh.flat_trade_record ftr
                                          where ftr.order_id = cl.order_id
                                            and ftr.exec_id = cl.exec_id
                                            and ftr.date_id = cl.date_id
                                            and ftr.is_busted <> 'Y'
                                          limit 1) ftr on true
              where cl.date_id between in_start_date_id and in_end_date_id
                and ac.is_active
                and cl.account_id = any (in_account_ids)
                and cl.IS_BUSTED = 'N') x;
end;
$fn$;


select *
from dash360.report_rps_lpeod_fees(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                    in_account_ids := '{13687,13411,9374,68613,13686}');


select * from dash360.report_fintech_eod_zuercher_ecr(20231024, 20231027);
create function dash360.report_fintech_eod_zuercher_ecr(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
declare
    l_symbols text[] := array ['AMJ','AUM','AUX','BACD','BPX','BRB','BSZ','BVZ','CDD','CITD','DBA','DBB','DBC','DBO','DIA','DJX','EEM','EFA','EUI','EUU','GBP','GLD',
        'GSSD','IWM','IWN','IWO','IWV','JJC','JPMD','KBE','KRE','MDY','MNX','MOO','MRUT','MSTD','NANOS','NDO','NDX','NDXP','NQX','NZD','OEF',
        'OEX','OIL','PZO','QQQ','RTY','RUT','RUTQ','RUTW','RVX','SFC','SKA','SPIKE','SPX','SPXPM','SPXQ','SPXW','SPY','SPY7','SVIX','SVXY',
        'UNG','UNG1','UNG2','UUP','UVIX','UVXY','UVXY1','UVXY2','VIIX','VIX','VIXM','VIXW','VIXY','VIXY1','VXEEM','VXX','VXX1','VXX2','VXXB',
        'VXZ','VXZ1','VXZB','XEO','XHB','XLB','XLC','XLE','XLF','XLF1','XLI','XLK','XLP','XLRE','XLU','XLV','XLY','XME','XND','XRT','XSP',
        'XSPAM','YUK','1SPY','2SPY','3SPY','4SPY','1QQQ','2QQQ','3QQQ','4QQQ','1EFA','2EFA','3EFA','4EFA','1GLD','2GLD','3GLD','4GLD','1IWM',
        '2IWM','3IWM','4IWM','1SPX','2SPX','3SPX','4SPX','1RUT','2RUT','3RUT','4RUT','1XSP','2XSP','3XSP','4XSP','1SPXW','2SPXW','3SPXW','4SPXW'];
begin

    return query
        select 'Trading Firm,User,Exchange,Symbol,Expiration,Expiry Time,Strike,C/P,Multiplier,Exercise Type,Settlement Type,B/S,Qty,Price,Date,Execution time,Giveup,CMTA,Range,Account,Single/Complex,Security Type,Strategy,ClOrdID,ReportID,Liquidity Flag,Commission Rate,Commission Total';


        return query
            select tf.trading_firm_name                                                 ||','||-- as "Trading Firm",
                   tr.client_id                                                         ||','||-- as "User",
                   tr.exchange_id                                                       ||','||-- as "Exchange",
                   hsd.symbol                                                           ||','||-- as "Symbol",
                   coalesce(to_char(hsd.maturity_date, 'MM/DD/YYYY')::text, '')         ||','||-- as "Expiration",
                   case
                       when tr.instrument_type_id = 'E' then ''
                       when hsd.symbol = any (l_symbols) then '22:15:00.000'
                       else '22:00:00.000'
                       end                                                              ||','||-- as "Expiry Time",
                   coalesce(hsd.strike_px::text, '')                                    ||','||-- as "Strike",
                   case
                       when hsd.put_call = '0' then 'P'
                       when hsd.put_call = '1' then 'C'
                       else 'S' end                                                     ||','||-- as "C/P",
                   case
                       when tr.instrument_type_id = 'O'
                           then coalesce(hsd.contract_multiplier, 100)::text
                       else '' end                                                      ||','||-- as "Multiplier",
                   case
                       when hsd.exercise_style = 'A' then 'American'
                       when hsd.exercise_style = 'E'
                           then 'European'
                       else '' end                                                      ||','||-- as "Exercise Type",
                   case
                       when tr.instrument_type_id = 'O' and hsd.symbol = any (l_symbols) then 'Cash'
                       else 'Physical'
                       end                                                              ||','||-- as "Settlement Type",
                   case
                       when tr.side = '1' then 'BUY'
                       when tr.side in ('2', '5', '6')
                           then 'SELL'
                       else '' end                                                      ||','||-- as "B/S",
                   tr.last_qty                                                          ||','||-- as "Qty",
                   tr.last_px                                                           ||','||-- as "Price",
                   to_char(tr.trade_record_time, 'MM/DD/YYYY')::varchar                 ||','||-- as "Date",
                   to_char(tr.trade_record_time, 'HH24:MI:SS.MS')::varchar              ||','||-- as "Execution time",
                   coalesce(tr.exec_broker, '')                                         ||','||-- as "Giveup",
                   coalesce(tr.cmta, '')                                                ||','||-- as "CMTA",
                   coalesce(cf.customer_or_firm_name, '')                               ||','||-- as "Range",
                   a.account_name                                                       ||','||-- as "Account",
                   case
                       when tr.multileg_reporting_type <> '1' then 'Complex'
                       else 'Single-Leg' end                                            ||','||-- as "Single/Complex",
                   case
                       when tr.instrument_type_id = 'E' then 'Equity'
                       when tr.instrument_type_id = 'O'
                           then 'Option'
                       else '' end                                                      ||','||-- as "Security Type",
                   tr.sub_strategy                                                      ||','||-- as "Strategy",
                   tr.client_order_id                                                   ||','||-- as "ClOrdID",
                   tr.trade_record_id::text                                             ||','||-- as "ReportID",
                   tr.trade_liquidity_indicator                                         ||','||-- as "Liquidity Flag",
                   round(tr.tcce_account_dash_commission_amount / tr.last_qty, 4)::text ||','||-- as "Commission Rate",
                   tr.tcce_account_dash_commission_amount::text                                -- as "Commission Total"
            from dwh.flat_trade_record tr
                     join dwh.d_account a on (a.account_id = tr.account_id)
                     join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                     join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                     left join dwh.d_customer_or_firm cf
                               on (cf.customer_or_firm_id = opt_customer_or_firm and cf.is_active)
            where tr.date_id between in_start_date_id and in_end_date_id
              and tr.trading_firm_id = 'zuercher'
              and tr.is_busted = 'N'
            order by tr.date_id, tr.instrument_type_id, tr.trade_record_id;

    end;
$fx$;






        return query
--     select "Trading Firm",
--     "User",
--     "Exchange",
--     "Symbol",
--     "Expiration",
--     "Expiry Time",
--     "Strike",
--     "C/P",
--     "Multiplier",
--     "Exercise Type",
--     "Settlement Type",
--     "B/S",
--     "Qty",
--     "Price",
--     "Date",
--     "Execution time",
--     "Giveup",
--     "CMTA",
--     "Range",
--     "Account",
--     "Single/Complex",
--     "Security Type",
--     "Strategy",
--     "ClOrdID",
--     "ReportID",
--     "Liquidity Flag",
--     "Commission Rate",
--     "Commission Total"
--     from (
    select
        tr.instrument_id,
        di.instrument_id,
        os.exercise_style,
        tf.trading_firm_name                                               as "Trading Firm",
                 tr.client_id                                                       as "User",
                 tr.exchange_id                                                     as "Exchange",
--                  hsd.symbol                                                         as "Symbol",
                 di.symbol as "Symbol",
--                  to_char(hsd.maturity_date, 'MM/DD/YYYY')::varchar                  as "Expiration",
                 oc.maturity_month::text||'/'||maturity_day::text||'/'||maturity_year::text as "Expiration",
                 case
                     when tr.instrument_type_id = 'E' then null
--                      when hsd.symbol = any (symbols) then '22:15:00.000'
                     when di.symbol in (
			'AMJ','AUM','AUX','BACD','BPX','BRB','BSZ','BVZ','CDD','CITD','DBA','DBB','DBC','DBO','DIA','DJX','EEM','EFA','EUI','EUU','GBP','GLD',
			'GSSD','IWM','IWN','IWO','IWV','JJC','JPMD','KBE','KRE','MDY','MNX','MOO','MRUT','MSTD','NANOS','NDO','NDX','NDXP','NQX','NZD','OEF',
			'OEX','OIL','PZO','QQQ','RTY','RUT','RUTQ','RUTW','RVX','SFC','SKA','SPIKE','SPX','SPXPM','SPXQ','SPXW','SPY','SPY7','SVIX','SVXY',
			'UNG','UNG1','UNG2','UUP','UVIX','UVXY','UVXY1','UVXY2','VIIX','VIX','VIXM','VIXW','VIXY','VIXY1','VXEEM','VXX','VXX1','VXX2','VXXB',
			'VXZ','VXZ1','VXZB','XEO','XHB','XLB','XLC','XLE','XLF','XLF1','XLI','XLK','XLP','XLRE','XLU','XLV','XLY','XME','XND','XRT','XSP',
			'XSPAM','YUK','1SPY','2SPY','3SPY','4SPY','1QQQ','2QQQ','3QQQ','4QQQ','1EFA','2EFA','3EFA','4EFA','1GLD','2GLD','3GLD','4GLD','1IWM',
			'2IWM','3IWM','4IWM','1SPX','2SPX','3SPX','4SPX','1RUT','2RUT','3RUT','4RUT','1XSP','2XSP','3XSP','4XSP','1SPXW','2SPXW','3SPXW','4SPXW'
		) then '22:15:00.000'
                     else '22:00:00.000'
                     end::varchar                                                   as "Expiry Time",
--                  hsd.strike_px                                                      as "Strike",
        oc.strike_price as "Strike",
                 (case
--                       when hsd.put_call = '0' then 'P'
                     when oc.put_call = '0' then 'P'
--                       when hsd.put_call = '1' then 'C'
                     when oc.put_call = '1' then 'C'
                      else 'S' end)::varchar                                        as "C/P",
                 case
                      when tr.instrument_type_id = 'O'
--                           then coalesce(hsd.contract_multiplier, 100) end)::varchar as "Multiplier",
                     then coalesce(os.contract_multiplier, 100) end::varchar as "Multiplier",
                 case
--                       when hsd.exercise_style = 'A' then 'American'
                         when os.exercise_style = 'A' then 'American'
--                       when hsd.exercise_style = 'E'
                         when os.exercise_style = 'E' then 'European' end          as "Exercise Type",
--                      then 'European' end)::varchar     )                        as "Exercise Type",
                 case
--                      when tr.instrument_type_id = 'O' and hsd.symbol = any (symbols) then 'Cash'
                     when tr.instrument_type_id = 'O' and di.symbol in (
			'AMJ','AUM','AUX','BACD','BPX','BRB','BSZ','BVZ','CDD','CITD','DBA','DBB','DBC','DBO','DIA','DJX','EEM','EFA','EUI','EUU','GBP','GLD',
			'GSSD','IWM','IWN','IWO','IWV','JJC','JPMD','KBE','KRE','MDY','MNX','MOO','MRUT','MSTD','NANOS','NDO','NDX','NDXP','NQX','NZD','OEF',
			'OEX','OIL','PZO','QQQ','RTY','RUT','RUTQ','RUTW','RVX','SFC','SKA','SPIKE','SPX','SPXPM','SPXQ','SPXW','SPY','SPY7','SVIX','SVXY',
			'UNG','UNG1','UNG2','UUP','UVIX','UVXY','UVXY1','UVXY2','VIIX','VIX','VIXM','VIXW','VIXY','VIXY1','VXEEM','VXX','VXX1','VXX2','VXXB',
			'VXZ','VXZ1','VXZB','XEO','XHB','XLB','XLC','XLE','XLF','XLF1','XLI','XLK','XLP','XLRE','XLU','XLV','XLY','XME','XND','XRT','XSP',
			'XSPAM','YUK','1SPY','2SPY','3SPY','4SPY','1QQQ','2QQQ','3QQQ','4QQQ','1EFA','2EFA','3EFA','4EFA','1GLD','2GLD','3GLD','4GLD','1IWM',
			'2IWM','3IWM','4IWM','1SPX','2SPX','3SPX','4SPX','1RUT','2RUT','3RUT','4RUT','1XSP','2XSP','3XSP','4XSP','1SPXW','2SPXW','3SPXW','4SPXW'
		) then 'Cash'
                     else 'Physical'
                     end::varchar                                                   as "Settlement Type",
                 case
                      when tr.side = '1' then 'BUY'
                      when tr.side in ('2', '5', '6')
                          then 'SELL' end::varchar                                 as "B/S",
                 tr.last_qty                                                        as "Qty",
                 tr.last_px                                                         as "Price",
                 to_char(tr.trade_record_time, 'MM/DD/YYYY')::varchar               as "Date",
                 to_char(tr.trade_record_time, 'HH24:MI:SS.MS')::varchar            as "Execution time",
                 tr.exec_broker                                                     as "Giveup",
                 tr.cmta                                                            as "CMTA",
                 cf.customer_or_firm_name                                           as "Range",
                 a.account_name                                                     as "Account",
                 (case
                      when tr.multileg_reporting_type <> '1' then 'Complex'
                      else 'Single-Leg' end)::varchar                               as "Single/Complex",
                 (case
                      when tr.instrument_type_id = 'E' then 'Equity'
                      when tr.instrument_type_id = 'O'
                          then 'Option' end)::varchar                               as "Security Type",
                 tr.sub_strategy                                                    as "Strategy",
                 tr.client_order_id                                                 as "ClOrdID",
                 tr.trade_record_id                                                 as "ReportID",
                 tr.trade_liquidity_indicator                                       as "Liquidity Flag",
                 round(tr.tcce_account_dash_commission_amount / tr.last_qty, 4)     as "Commission Rate",
                 tr.tcce_account_dash_commission_amount                             as "Commission Total"
          from dwh.flat_trade_record tr
                   join dwh.d_account a on (a.account_id = tr.account_id)
               join dwh.d_instrument di on di.instrument_id = tr.instrument_id
                   join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
--                    join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                       left join dwh.d_option_contract oc on (oc.instrument_id = tr.instrument_id)
                       left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                   left join dwh.d_customer_or_firm cf
                             on (cf.customer_or_firm_id = opt_customer_or_firm and cf.is_active)
          where tr.date_id between :in_start_date_id and :in_end_date_id
            and tr.trading_firm_id = 'zuercher'
            and tr.is_busted = 'N'
          order by tr.date_id, tr.instrument_type_id, tr.trade_record_id
;



*/

--  select sub_strategy_id from dwh.client_order where client_order.sub_strategy_desc in ('DMA', 'SMOKE')

create or replace function trash.report_rps_ebsrbc_s3_uni(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[],
                                           in_is_multi_leg boolean default false)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
begin
    -- header
    create temp table t_report on commit drop as
    select 'H'                                                                                        as record_type,
           0::int8                                                                                    as order_id,
           null                                                                                       as time_id,
           'A'                                                                                        as record_id,
           0                                                                                          as record_type_id,
           'H' || '|' ||
           'V2.0.4' || '|' ||
           to_char(clock_timestamp(), 'YYYYMMDD') || 'T' || to_char(clock_timestamp(), 'HH24MISSFF3') as rec;

      ----Parent/Street orders----
      insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
      select 'NO'                                      as record_type,
             coalesce(cl.parent_order_id, cl.order_id) as order_id,
             to_char(cl.process_time, 'HH24MISSFF3')   as time_id,
             cl.client_order_id                        as record_id,
             1                                         as record_type_id,
             'O' || '|' ||
             case
                 when (in_is_multi_leg and cl.multileg_reporting_type = '3' or
                 cl.parent_order_id is null) then 'NO'
                 else 'RO'
                 end || '|' ||
             cl.client_order_id || '|' ||
             cl.order_id::text || '|' || --source_order_id
             case when in_is_multi_leg and cl.multileg_reporting_type = '2' then cl.client_order_id::text
             when not in_is_multi_leg then coalesce(cl.parent_order_id::text, '') end|| '|' || --source_parent_id
             coalesce(cl.orig_order_id::text, '') || '|' ||
                 --
             case
                 when not in_is_multi_leg
                     then ''
                 else
                     case
                         when cl.multileg_reporting_type = '3' then cl.order_id::text
                         when cl.multileg_reporting_type = '2' then cl.multileg_order_id::text
                         end
                 end || '|' || --
             case
                 when not in_is_multi_leg then ac.broker_dealer_mpid
                 else
                     case
                         when cl.parent_order_id is null and ac.broker_dealer_mpid = 'NONE' then ''
                         when cl.parent_order_id is null then ac.broker_dealer_mpid
                         else 'DFIN'
                         end
                 end || '|' ||
             case
                 when not in_is_multi_leg then 'DFIN'
                 else
                     case
                         when cl.parent_order_id is null then 'DFIN'
                         else coalesce(exc.mic_code, exc.eq_mpid, '') end
                 end
                ||'|'||
             '' || '|' ||
             '' || '|' ||
             case cl.multileg_reporting_type when '3' then '' else i.instrument_type_id end || '|' ||
             case i.instrument_type_id when 'E' then i.display_instrument_id when 'O' then oc.opra_symbol else '' end ||
             '|' ||
             '' || '|' || --primary Exchange
             case cl.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SSE' else '' end ||
             '|' || --OrderAction
             to_char(cl.process_time, 'YYYYMMDD') || 'T' || to_char(cl.process_time, 'HH24MISSFF3') || '|' ||
             ot.order_type_short_name || '|' || --order_type
             case
                 when not in_is_multi_leg then cl.order_qty::text
                 else
                     case when cl.multileg_reporting_type = '3' then '' else cl.order_qty::text end
                 end || '|' || --order_volume
             to_char(cl.price, 'FM99990D0099') || '|' ||
             coalesce(to_char(cl.stop_price, 'FM99990D0099'), '') || '|' ||
             tif.tif_short_name || '|' ||
             case
                 when not in_is_multi_leg then
                                 coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                 coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                 else
                     case
                         when cl.expire_time is not null then
                                     coalesce(to_char(cl.expire_time, 'YYYYMMDD'), '') || 'T' ||
                                 coalesce(to_char(cl.expire_time, 'HH24MISSFF3'), '')
                         when cl.time_in_force_id = '6' then
                             (select fmj.fix_message ->> '432' || 'T235959000'
                              from fix_capture.fix_message_json fmj
                              where fix_message_id = cl.fix_message_id
                                and fmj.date_id = cl.create_date_id
                              limit 1)
                         end
                 end || '|' || --22
             '0' || '|' || --PRE_MARKET_IND
             '' || '|' ||
             '0' || '|' || --POST_MARKET_IND
             '' || '|' ||
             case
                 when cl.parent_order_id is null then case cl.sub_strategy_desc when 'DMA' then '1' else '0' end
                 else case po.sub_strategy_desc when 'DMA' then '1' else '0' end
                 end || '|' || --DIRECTED_ORDER_IND
             case
                 when (cl.parent_order_id is null or in_is_multi_leg)
                     then case cl.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                 else case po.sub_strategy_desc when 'SMOKE' then '1' else '0' end
                 end || '|' || --NON_DISPLAY_IND
             '0' || '|' || --DO_NOT_REDUCE
             case cl.exec_instruction when 'G' then '1' else '0' end || '|' ||
             case cl.exec_instruction when '1' then '1' else '0' end || '|' || --NOT_HELD_IND [31]
             '0' || '|' || --[32]
             '0' || '|' || --[33]
             '0' || '|' || --[34]
             '' || '|' || --[35]
             '' || '|' || --[36]
             '' || '|' || --[37]
             '' || '|' || --[38]
             case
                 when in_is_multi_leg then cl.ex_destination
                 else '' end || '|' || --[39]
             '' || '|' || --[40]
             '' || '|' || --[41]
             '' || '|' || --[42]
             '' || '|' || --[43]
             '' || '|' || --[44]
             '' || '|' || --[45]
             '' || '|' || --[46]
             '' || '|' || --[47]
             '' --[48]
                      as REC
      from dwh.client_order cl
               inner join dwh.d_account ac on ac.account_id = cl.account_id
               inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
               left join lateral (select po.sub_strategy_desc
                                  from client_order po
                                  where po.order_id = cl.parent_order_id
                                    and po.create_date_id <= cl.create_date_id
                                  limit 1) po on true
               left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
               left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
               left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
               left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
      left join lateral (select * from dwh.d_exchange exc where exc.exchange_id = cl.exchange_id and exc.is_active limit 1) exc on true
      where true
        and cl.account_id = any (in_account_ids)
        and cl.create_date_id between in_start_date_id and in_end_date_id
        and cl.trans_type <> 'F'
        and case when in_is_multi_leg then cl.parent_order_id is null else true end
        and case
                when in_is_multi_leg then cl.multileg_reporting_type in ('2', '3')
                else cl.multileg_reporting_type = '1' end;


      insert into t_report (record_type, order_id, time_id, record_id, record_type_id, rec)
      with base as (select case when ex.exec_type in ('4', '8') then 2 else 3 end as tp,
                           cl.parent_order_id,
                           cl.order_id,
                           cl.process_time,
                           cl.client_order_id,
                           ex.exec_type,
                           cl.multileg_reporting_type,
                           i.instrument_type_id,
                           i.display_instrument_id,
                           oc.opra_symbol,
                           ex.exec_time,
                           ex.exec_id,
                           ex.last_qty,
                           ex.last_px,
                           ex.exchange_id
                    from dwh.execution ex
                             join dwh.client_order cl
                                  on ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id
                        and case when in_is_multi_leg then cl.parent_order_id is null else cl.parent_order_id is not null end
                             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                             left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id
                    where true
                      and ex.exec_date_id between in_start_date_id and in_end_date_id
                      and ex.exec_type in ('4', '8', 'F')
                      and cl.account_id = any (in_account_ids)
                      and cl.trans_type <> 'F'
                      and case
                              when in_is_multi_leg then cl.multileg_reporting_type in ('2', '3')
                              else cl.multileg_reporting_type = '1' end
          )
      --order activity: cancel
            select 'A'                                  as record_type,
                   coalesce(parent_order_id, order_id)  as order_id,
                   to_char(process_time, 'HH24MISSFF3') as time_id,
                   client_order_id                      as record_id,
                   3                                    as record_type_id,
                   'A' || '|' ||
                   order_id::text || '|' ||
                   case exec_type when '4' then 'c' when '8' then 'RJ' else '' end || '|' || --EVENT
                   '' || '|' || --SYSTEM_ID
                   case multileg_reporting_type when '3' then '' else coalesce(instrument_type_id, '') end || '|' ||
                   case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol else '' end ||
                   '|' ||
                   '' || '|' || --SYMBOL_EXCHANGE
                   coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
                   coalesce(to_char(exec_time, 'HH24MISSFF3'), '') || '|' ||
                   '' || '|' || --DESCRIPTION
                   '' || '|' || --[10]
                   '' || '|' || --[11]
                   '' || '|' || --[12]
                   '' || '|' || --[13]
                   '' --[14]
            from base
            where tp = 2
            and case when in_is_multi_leg then parent_order_id is null else true end

            union all

      select 'T'                                 as record_type,
             coalesce(parent_order_id, order_id) as order_id,
             to_char(exec_time, 'HH24MISSFF3')   as time_id,
             client_order_id                     as record_id,
             2                                   as record_type_id,
             'T' || '|' ||
             order_id::text || '|' ||
             order_id::text || '_' || exec_id::text || '|' ||
             '' || '|' ||
             '' || '|' ||
             instrument_type_id || '|' ||
             case instrument_type_id when 'E' then display_instrument_id when 'O' then opra_symbol else '' end ||
             '|' ||
             '' || '|' || --SYMBOL_EXCHANGE
             coalesce(to_char(exec_time, 'YYYYMMDD'), '') || 'T' ||
             coalesce(to_char(exec_time, 'HH24MISSFF3'), '') || '|' || --ACTION_DATETIME
             last_qty || '|' ||
             to_char(last_px, 'fm99990d0099') || '|' ||
             exchange_id || '|' ||
             '' || '|' || --[12]
             '' || '|' || --[13]
             case when in_is_multi_leg and multileg_reporting_type = '2' then 'COMPLEX' else '' || '|' || --[14]
             '' || '|' || --[15]
             '' || '|' || --[16]
             '' || '|' || --[17]
             '' || '|' || --[18]
             '' || '|' || --[19]
             '' || '|' || --[20]
             '' || '|' || --[21]
             '' || '|' || --[22]
             '' --[23]
      from base
      where tp = 3
        and case
                when in_is_multi_leg then (multileg_reporting_type = '2' and parent_order_id is null)
                else multileg_reporting_type = '1' end;

    return query
        select case
                   when record_type = 'H' then rec || '|' ||
                                               in_start_date_id::text || 'T' || min_time || '|' || --Starting Event
                                               in_end_date_id::text || 'T' || max_time || '|' || --Ending Event
                                               'DFIN' || '|' ||
                                               'DAIN' || '|' ||
                                               'tradedesk@dashfinancial.com' || '|' ||
                                               ''
                   else rec
                   end
        from (select min(time_id) over () as min_time,
                     max(time_id) over () as max_time,
                     record_type,
                     rec
              from t_report

              order by order_id, time_id, record_id, record_type_id) x;

end;
$fx$;


select distinct account_id
from dwh.client_order
where create_date_id = 20231025
and account_id in (select account_id from dwh.d_account where trading_firm_id = 'ebsrbc')

select * from dwh.execution
where exec_id = 44922360291

select * from trash.report_rps_ebsrbc_s3 (in_start_date_id := 20231025, in_end_date_id := 20231025, in_account_ids := '{54855}');


select *from dash360.report_rps_lpeod_fees(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                    in_account_ids := '{13687,13411,9374,68613,13686}');


select *from dash360.report_rps_lpeod_exch_fees(in_start_date_id := 20231019, in_end_date_id := 20231019,
                                    in_account_ids := '{13687,13411,9374,68613,13686}');