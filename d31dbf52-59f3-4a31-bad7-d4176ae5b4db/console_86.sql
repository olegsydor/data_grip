select * from dash360.get_lp_eod_compliance(20240828, 'aostb01');
create or replace function dash360.get_lp_eod_compliance(in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4, in_firm text default 'aostb01')
    returns table (ret_row text)
    language plpgsql
as
$fx$
declare
    l_load_id           int;
    l_row_cnt           int;
    l_step_id           int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'get_lp_eod_compliance for ' || in_date_id::text || 'and firm' ||in_firm ||' STARTED ===',
                           0, 'O')
    into l_step_id;

create temp table t_report on commit drop as
select EX.ORDER_ID                     as rec_type,
       EX.EXEC_ID                      as order_status,
       array_to_string(ARRAY [
                           AC.ACCOUNT_NAME, --UserLogin
                           FC.FIX_COMP_ID, --SendingUserLogin
                           AC.TRADING_FIRM_ID, --EntityCode
                           TF.TRADING_FIRM_NAME, --EntityName
                           '', --DestinationEntity
                           '', --Owner
                           '', --Generation
                           '', --ChildOrders
                           to_char(CL.CREATE_TIME, 'YYYYMMDD'), --CreateDate
                           to_char(EX.EXEC_TIME, 'HH24MISSFF3'), --CreateTime
                           '', --StatusDate
                           '', --StatusTime
                           OC.OPRA_SYMBOL, --OSI
                           UI.SYMBOL,--BaseCode
                           OS.ROOT_SYMBOL, --Root
                           UI.INSTRUMENT_TYPE_ID, --BaseAssetType
                           to_char(OC.MATURITY_MONTH, 'FM00') || '/' || to_char(OC.MATURITY_DAY, 'FM00') || '/' ||
                           OC.MATURITY_YEAR, --ExpirationDate
                           OC.STRIKE_PRICE::text,
                           case OC.PUT_CALL when '0' then 'P' else 'C' end, --TypeCode
                           case
                               when CL.SIDE = '1' and CL.OPEN_CLOSE = 'C' then 'BC'
                               when CL.SIDE = '1' then 'B'
                               when CL.SIDE = '2' then 'S'
                               when CL.SIDE in ('5', '6') then 'SS'
                               end, -- Side

                           (select NO_LEGS::text
                            from dwh.CLIENT_ORDER
                            where ORDER_ID = CL.MULTILEG_ORDER_ID), --LegCount
                           rn.LEG_NUMBER::text, --LegNumber
                           '', --OrderType
                           case
                               when CL.PARENT_ORDER_ID is null
                                   then case
                                            when EX.ORDER_STATUS = 'A' then 'Pnd Open'
                                            when EX.ORDER_STATUS = 'b' then 'Pnd Cxl'
                                            when EX.ORDER_STATUS = 'S' then 'Pnd Rep'
                                            when EX.ORDER_STATUS = '1' then 'Partial'
                                            when EX.ORDER_STATUS = '2' then 'Filled'
                                            when EX.EXEC_TYPE = '4' then 'Canceled'
                                            when EX.EXEC_TYPE = 'W' then 'Replaced'
                                            else EX.EXEC_TYPE end
                               else
                                   case
                                       when EX.ORDER_STATUS = 'A' then 'Ex Pnd Open'
                                       when EX.ORDER_STATUS = '0' then 'Ex Open'
                                       when EX.ORDER_STATUS = '8' then 'Ex Rej'
                                       when EX.ORDER_STATUS = 'b' then 'Ex Pnd Cxl'
                                       when EX.ORDER_STATUS = '1' then 'Ex Partial'
                                       when EX.ORDER_STATUS = '2' then 'Ex Rpt Fill'
                                       when EX.ORDER_STATUS = '4' then 'Ex Rpt Out'
                                       else EX.ORDER_STATUS end
                               end, --Status
                           to_char(CL.PRICE, 'FM999990D0099'),
                           to_char(EX.LAST_PX, 'FM999990D0099'), --StatusPrice
                           CL.ORDER_QTY::text, --Entered Qty
           -- ask++
                           EX.LEAVES_QTY::text, --StatusQty
           --Order
                           CL.CLIENT_ORDER_ID,

                           case
                               when EX.EXEC_TYPE in ('S', 'W') then
                                   (select ORIG.CLIENT_ORDER_ID
                                    from CLIENT_ORDER ORIG
                                    where ORIG.ORDER_ID = CL.ORIG_ORDER_ID)
                               end, --Replaced Order

                           case
                               when EX.EXEC_TYPE in ('b', '4') then
                                   (select CXL.CLIENT_ORDER_ID
                                    from CLIENT_ORDER CXL
                                    where CXL.ORIG_ORDER_ID = CL.ORDER_ID
                                    order by CxL.order_id
                                    limit 1)
                               end, --CancelOrderID
                           (select PO.CLIENT_ORDER_ID from CLIENT_ORDER PO where PO.ORDER_ID = CL.PARENT_ORDER_ID),
                           CL.ORDER_ID::text, --SystemOrderID
                           EX.EXEC_ID::text, --ExecutionID
                           coalesce(CL.sub_strategy_desc, EXC.MIC_CODE), --ExchangeCode
                           '', --ExConnection
-- 			coalesce(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER), --GiveUpFirm
                           opx.opt_exec_broker, --GiveUpFirm
                           case
                               when ac.opt_is_fix_clfirm_processed = 'Y' then cl.clearing_firm_id
                               else coalesce(lpad(ca.cmta, 3, '0'), cl.clearing_firm_id)
                               end, --CMTAFirm
                           '', --AccountAlias
                           '', --Account
                           '', --SubAccount
                           '', --SubAccount2
                           '', --SubAccount3
                           CL.OPEN_CLOSE,
                           case (case ac.opt_is_fix_custfirm_processed
                                     when 'Y' then coalesce(CL.customer_or_firm_id, ac.opt_customer_or_firm)
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
                               end, --Range

                           OT.ORDER_TYPE_SHORT_NAME, --PriceQualifier
                           TIF.TIF_SHORT_NAME, --TimeQualifier
                           EX.EXCH_EXEC_ID, --ExchangeTransactionID
                           CL.EXCH_ORDER_ID, --ExchangeOrderID
                           '', --MPID
                           '', --Comment
                           md.amex_bid_quantity::text , --as BidSzA,
                           to_char(md.amex_bid_price, 'FM999999.0099') , --as BidA,
                           to_char(md.amex_ask_price, 'FM999999.0099') , --as AskA,
                           md.amex_ask_quantity::text , --as AskSzA,

                           md.bato_bid_quantity::text , --as BidSzZ,
                           to_char(md.bato_bid_price, 'FM999999.0099') , --as BidZ,
                           to_char(md.bato_ask_price, 'FM999999.0099') , --as AskZ,
                           md.bato_ask_quantity::text , --as AskSzZ,

                           md.box_bid_quantity::text , --as BidSzB,
                           to_char(md.box_bid_price, 'FM999999.0099') , --as BidB,
                           to_char(md.box_ask_price, 'FM999999.0099') , --as AskB,
                           md.box_ask_quantity::text , --as AskSzB,

                           md.cboe_bid_quantity::text , --as BidSzC,
                           to_char(md.cboe_bid_price, 'FM999999.0099') , --as BidC,
                           to_char(md.cboe_ask_price, 'FM999999.0099') , --as AskC,
                           md.cboe_ask_quantity::text , --as AskSzC,

                           md.c2ox_bid_quantity::text , --as BidSzW,
                           to_char(md.c2ox_bid_price, 'FM999999.0099') , --as BidW,
                           to_char(md.c2ox_ask_price, 'FM999999.0099') , --as AskW,
                           md.c2ox_ask_quantity::text , --as AskSzW,

                           md.nqbxo_bid_quantity::text , --as BidSzT,
                           to_char(md.nqbxo_bid_price, 'FM999999.0099') , --as BidT,
                           to_char(md.nqbxo_ask_price, 'FM999999.0099') , --as AskT,
                           md.nqbxo_ask_quantity::text , --as AskSzT,

                           md.ise_bid_quantity::text , --as BidSzI,
                           to_char(md.ise_bid_price, 'FM999999.0099') , --as BidI,
                           to_char(md.ise_ask_price, 'FM999999.0099') , --as AskI,
                           md.ise_ask_quantity::text , --as AskSzI,

                           md.arca_bid_quantity::text , --as BidSzP,
                           to_char(md.arca_bid_price, 'FM999999.0099') , --as BidP,
                           to_char(md.arca_ask_price, 'FM999999.0099') , --as AskP,
                           md.arca_ask_quantity::text , --as AskSzP,

                           md.miax_bid_quantity::text , --as BidSzM,
                           to_char(md.miax_bid_price, 'FM999999.0099') , --as BidM,
                           to_char(md.miax_ask_price, 'FM999999.0099') , --as AskM,
                           md.miax_ask_quantity::text , --as AskSzM,

                           md.gemini_bid_quantity::text , --as BidSzH,
                           to_char(md.gemini_bid_price, 'FM999999.0099') , --as BidH,
                           to_char(md.gemini_ask_price, 'FM999999.0099') , --as AskH,
                           md.gemini_ask_quantity::text , --as AskSzH,

                           md.nsdqo_bid_quantity::text , --as BidSzQ,
                           to_char(md.nsdqo_bid_price, 'FM999999.0099') , --as BidQ,
                           to_char(md.nsdqo_ask_price, 'FM999999.0099') , --as AskQ,
                           md.nsdqo_ask_quantity::text , --as AskSzQ,

                           md.phlx_bid_quantity::text , --as BidSzX,
                           to_char(md.phlx_bid_price, 'FM999999.0099') , --as BidX,
                           to_char(md.phlx_ask_price, 'FM999999.0099') , --as AskX,
                           md.phlx_ask_quantity::text , --as AskSzX,

                           md.edgo_bid_quantity::text , --as BidSzE,
                           to_char(md.edgo_bid_price, 'FM999999.0099') , --as BidE,
                           to_char(md.edgo_ask_price, 'FM999999.0099') , --as AskE,
                           md.edgo_ask_quantity::text , --as AskSzE,

                           md.mprl_bid_quantity::text , --as BidSzR,
                           to_char(md.mprl_bid_price, 'FM999999.0099') , --as BidR,
                           to_char(md.mprl_ask_price, 'FM999999.0099') , --as AskR,
                           md.mprl_ask_quantity::text , --as AskSzR,
                           '', --ULBidSz
                           '', --ULBid
                           '', --ULAsk
                           '', --ULAskSz
                           ''
                           ], '|', '') as rec
from CLIENT_ORDER CL
         --left join CLIENT_ORDER ORIG on ORIG.ORDER_ID = CL.ORIG_ORDER_ID
         inner join dwh.d_FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
         inner join dwh.EXECUTION EX on CL.ORDER_ID = EX.ORDER_ID and ex.exec_date_id >= cl.create_date_id
         left join dwh.d_EXCHANGE EXC on EXC.EXCHANGE_ID = CL.EXCHANGE_ID and exc.is_active
         inner join dwh.d_OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
         inner join dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
         inner join dwh.d_INSTRUMENT UI on UI.INSTRUMENT_ID = OS.UNDERLYING_INSTRUMENT_ID
         inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID and ac.is_active
         inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
         left join dwh.d_CLEARING_ACCOUNT CA
                   on (CL.ACCOUNT_ID = CA.ACCOUNT_ID and CA.IS_DEFAULT = 'Y' and CA.is_active and
                       CA.MARKET_TYPE = 'O' and CA.CLEARING_ACCOUNT_TYPE = '1')
         left join dwh.d_OPT_EXEC_BROKER OPX
                   on (OPX.ACCOUNT_ID = AC.ACCOUNT_ID and OPX.IS_DEFAULT = 'Y' and OPX.is_active)
    --left join LIQUIDITY_INDICATOR TLI on (TLI.TRADE_LIQUIDITY_INDICATOR = EX.TRADE_LIQUIDITY_INDICATOR and TLI.EXCHANGE_ID = EXC.REAL_EXCHANGE_ID)
         left join dwh.d_ORDER_TYPE OT on OT.ORDER_TYPE_ID = CL.ORDER_TYPE_id
         left join dwh.d_TIME_IN_FORCE TIF on TIF.TIF_ID = CL.TIME_IN_FORCE_id

    -- 		  left join dwh.CLIENT_ORDER_LEG_NUM LN on LN.ORDER_ID = CL.ORDER_ID
-- 		  left join dwh.d_STRATEGY_IN SIT on (SIT.TRANSACTION_ID = CL.TRANSACTION_ID and SIT.STRATEGY_IN_TYPE_ID in ('Ab','H'))
         left join lateral (
    select leg_number
    from (select order_id,
                 dense_rank() over (partition by co.multileg_order_id order by co.order_id) as leg_number
          from dwh.client_order co
          where co.multileg_order_id = cl.multileg_order_id
            and co.create_date_id >= cl.create_date_id) x
    where x.order_id = cl.order_id
      and cl.multileg_order_id is not null
    limit 1
    ) rn on true

         left join lateral (select
                                -- AMEX
                                max(case when ls.exchange_id = 'AMEX' then ls.ask_price end)      as amex_ask_price,
                                max(case when ls.exchange_id = 'AMEX' then ls.bid_price end)      as amex_bid_price,
                                max(case when ls.exchange_id = 'AMEX' then ls.ask_quantity end)   as amex_ask_quantity,
                                max(case when ls.exchange_id = 'AMEX' then ls.bid_quantity end)   as amex_bid_quantity,
                                -- BATO
                                max(case when ls.exchange_id = 'BATO' then ls.ask_price end)      as bato_ask_price,
                                max(case when ls.exchange_id = 'BATO' then ls.bid_price end)      as bato_bid_price,
                                max(case when ls.exchange_id = 'BATO' then ls.ask_quantity end)   as bato_ask_quantity,
                                max(case when ls.exchange_id = 'BATO' then ls.bid_quantity end)   as bato_bid_quantity,
                                -- BOX
                                max(case when ls.exchange_id = 'BOX' then ls.ask_price end)       as box_ask_price,
                                max(case when ls.exchange_id = 'BOX' then ls.bid_price end)       as box_bid_price,
                                max(case when ls.exchange_id = 'BOX' then ls.ask_quantity end)    as box_ask_quantity,
                                max(case when ls.exchange_id = 'BOX' then ls.bid_quantity end)    as box_bid_quantity,
                                -- CBOE
                                max(case when ls.exchange_id = 'CBOE' then ls.ask_price end)      as cboe_ask_price,
                                max(case when ls.exchange_id = 'CBOE' then ls.bid_price end)      as cboe_bid_price,
                                max(case when ls.exchange_id = 'CBOE' then ls.ask_quantity end)   as cboe_ask_quantity,
                                max(case when ls.exchange_id = 'CBOE' then ls.bid_quantity end)   as cboe_bid_quantity,
                                -- C2OX
                                max(case when ls.exchange_id = 'C2OX' then ls.ask_price end)      as c2ox_ask_price,
                                max(case when ls.exchange_id = 'C2OX' then ls.bid_price end)      as c2ox_bid_price,
                                max(case when ls.exchange_id = 'C2OX' then ls.ask_quantity end)   as c2ox_ask_quantity,
                                max(case when ls.exchange_id = 'C2OX' then ls.bid_quantity end)   as c2ox_bid_quantity,
                                -- NQBXO
                                max(case when ls.exchange_id = 'NQBXO' then ls.ask_price end)     as nqbxo_ask_price,
                                max(case when ls.exchange_id = 'NQBXO' then ls.bid_price end)     as nqbxo_bid_price,
                                max(case when ls.exchange_id = 'NQBXO' then ls.ask_quantity end)  as nqbxo_ask_quantity,
                                max(case when ls.exchange_id = 'NQBXO' then ls.bid_quantity end)  as nqbxo_bid_quantity,
                                -- ISE
                                max(case when ls.exchange_id = 'ISE' then ls.ask_price end)       as ise_ask_price,
                                max(case when ls.exchange_id = 'ISE' then ls.bid_price end)       as ise_bid_price,
                                max(case when ls.exchange_id = 'ISE' then ls.ask_quantity end)    as ise_ask_quantity,
                                max(case when ls.exchange_id = 'ISE' then ls.bid_quantity end)    as ise_bid_quantity,
                                -- ARCA
                                max(case when ls.exchange_id = 'ARCA' then ls.ask_price end)      as arca_ask_price,
                                max(case when ls.exchange_id = 'ARCA' then ls.bid_price end)      as arca_bid_price,
                                max(case when ls.exchange_id = 'ARCA' then ls.ask_quantity end)   as arca_ask_quantity,
                                max(case when ls.exchange_id = 'ARCA' then ls.bid_quantity end)   as arca_bid_quantity,
                                -- MIAX
                                max(case when ls.exchange_id = 'MIAX' then ls.ask_price end)      as miax_ask_price,
                                max(case when ls.exchange_id = 'MIAX' then ls.bid_price end)      as miax_bid_price,
                                max(case when ls.exchange_id = 'MIAX' then ls.ask_quantity end)   as miax_ask_quantity,
                                max(case when ls.exchange_id = 'MIAX' then ls.bid_quantity end)   as miax_bid_quantity,
                                -- GEMINI
                                max(case when ls.exchange_id = 'GEMINI' then ls.ask_price end)    as gemini_ask_price,
                                max(case when ls.exchange_id = 'GEMINI' then ls.bid_price end)    as gemini_bid_price,
                                max(case when ls.exchange_id = 'GEMINI' then ls.ask_quantity end) as gemini_ask_quantity,
                                max(case when ls.exchange_id = 'GEMINI' then ls.bid_quantity end) as gemini_bid_quantity,
                                -- NSDQO
                                max(case when ls.exchange_id = 'NSDQO' then ls.ask_price end)     as nsdqo_ask_price,
                                max(case when ls.exchange_id = 'NSDQO' then ls.bid_price end)     as nsdqo_bid_price,
                                max(case when ls.exchange_id = 'NSDQO' then ls.ask_quantity end)  as nsdqo_ask_quantity,
                                max(case when ls.exchange_id = 'NSDQO' then ls.bid_quantity end)  as nsdqo_bid_quantity,
                                -- PHLX
                                max(case when ls.exchange_id = 'PHLX' then ls.ask_price end)      as phlx_ask_price,
                                max(case when ls.exchange_id = 'PHLX' then ls.bid_price end)      as phlx_bid_price,
                                max(case when ls.exchange_id = 'PHLX' then ls.ask_quantity end)   as phlx_ask_quantity,
                                max(case when ls.exchange_id = 'PHLX' then ls.bid_quantity end)   as phlx_bid_quantity,
                                -- EDGO
                                max(case when ls.exchange_id = 'EDGO' then ls.ask_price end)      as edgo_ask_price,
                                max(case when ls.exchange_id = 'EDGO' then ls.bid_price end)      as edgo_bid_price,
                                max(case when ls.exchange_id = 'EDGO' then ls.ask_quantity end)   as edgo_ask_quantity,
                                max(case when ls.exchange_id = 'EDGO' then ls.bid_quantity end)   as edgo_bid_quantity,
                                -- MCRY
                                max(case when ls.exchange_id = 'MCRY' then ls.ask_price end)      as mcry_ask_price,
                                max(case when ls.exchange_id = 'MCRY' then ls.bid_price end)      as mcry_bid_price,
                                max(case when ls.exchange_id = 'MCRY' then ls.ask_quantity end)   as mcry_ask_quantity,
                                max(case when ls.exchange_id = 'MCRY' then ls.bid_quantity end)   as mcry_bid_quantity,
                                -- MPRL
                                max(case when ls.exchange_id = 'MPRL' then ls.ask_price end)      as mprl_ask_price,
                                max(case when ls.exchange_id = 'MPRL' then ls.bid_price end)      as mprl_bid_price,
                                max(case when ls.exchange_id = 'MPRL' then ls.ask_quantity end)   as mprl_ask_quantity,
                                max(case when ls.exchange_id = 'MPRL' then ls.bid_quantity end)   as mprl_bid_quantity,
                                -- EMLD
                                max(case when ls.exchange_id = 'EMLD' then ls.ask_price end)      as emld_ask_price,
                                max(case when ls.exchange_id = 'EMLD' then ls.bid_price end)      as emld_bid_price,
                                max(case when ls.exchange_id = 'EMLD' then ls.ask_quantity end)   as emld_ask_quantity,
                                max(case when ls.exchange_id = 'EMLD' then ls.bid_quantity end)   as emld_bid_quantity,
                                -- SPHR
                                max(case when ls.exchange_id = 'SPHR' then ls.ask_price end)      as sphr_ask_price,
                                max(case when ls.exchange_id = 'SPHR' then ls.bid_price end)      as sphr_bid_price,
                                max(case when ls.exchange_id = 'SPHR' then ls.ask_quantity end)   as sphr_ask_quantity,
                                max(case when ls.exchange_id = 'SPHR' then ls.bid_quantity end)   as sphr_bid_quantity,
                                -- MXOP
                                max(case when ls.exchange_id = 'MXOP' then ls.ask_price end)      as mxop_ask_price,
                                max(case when ls.exchange_id = 'MXOP' then ls.bid_price end)      as mxop_bid_price,
                                max(case when ls.exchange_id = 'MXOP' then ls.ask_quantity end)   as mxop_ask_quantity,
                                max(case when ls.exchange_id = 'MXOP' then ls.bid_quantity end)   as mxop_bid_quantity,
                                -- NBBO
                                max(case when ls.exchange_id = 'NBBO' then ls.ask_price end)      as nbbo_ask_price,
                                max(case when ls.exchange_id = 'NBBO' then ls.bid_price end)      as nbbo_bid_price,
                                max(case when ls.exchange_id = 'NBBO' then ls.ask_quantity end)   as nbbo_ask_quantity,
                                max(case when ls.exchange_id = 'NBBO' then ls.bid_quantity end)   as nbbo_bid_quantity
                            from dwh.l1_snapshot ls
                            where ls.transaction_id = cl.transaction_id
                              and ls.start_date_id = cl.create_date_id
                            group by ls.transaction_id
                            limit 1
    ) md on true
where true
  and cl.create_date_id = 20240827
  and AC.TRADING_FIRM_ID = 'LPTF286'
  and CL.MULTILEG_REPORTING_TYPE in ('1', '2')

  and EX.IS_BUSTED = 'N'
  and EX.EXEC_TYPE not in ('3', 'a', '5', 'E')
  and CL.TRANS_TYPE <> 'F'
  and ((CL.PARENT_ORDER_ID is null and EX.EXEC_TYPE <> '0') or CL.PARENT_ORDER_ID is not null)
--   and cl.order_id in (16861524498, 16862144103)
    ;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'get_lp_eod_compliance for ' || in_date_id::text || 'and firm' ||in_firm ||' temp table created ===',
                           l_row_cnt, 'O')
    into l_step_id;

    create index on t_report (rec_type, order_status);

    return query
        select 'UserLogin|SendingUserLogin|EntityCode|EntityName|DestinationEntity|Owner|Generation|ChildOrders|CreateDate|CreateTime|StatusDate|StatusTime|OSI|BaseCode|RootCode|BaseAssetType|ExpirationDate|Strike|TypeCode|BuySell|LegCount|LegNumber|OrderType|'||
			'Status|EnteredPrice|StatusPrice|EnteredQty|StatusQty|OrderID|ReplacedOrderID|CancelOrderID|ParentOrderID|SystemOrderID|ExecutionID|ExchangeCode|ExConnection|GiveUpFirm|CMTAFirm|AccountAlias|Account|SubAccount|SubAccount2|SubAccount3|'||
			'OpenClose|Range|PriceQualifier|TimeQualifier|ExchangeTransactionID|ExchangeOrderID|MPID|Comment|BidSzA|BidA|AskA|AskSzA|BidSzZ|BidZ|AskZ|AskSzZ|BidSzB|BidB|AskB|AskSzB|BidSzC|BidC|AskC|AskSzC|BidSzW|BidW|AskW|AskSzW|'||
			'BidSzT|BidT|AskT|AskSzT|BidSzI|BidI|AskI|AskSzI|BidSzP|BidP|AskP|AskSzP|BidSzM|BidM|AskM|AskSzM|BidSzH|BidH|AskH|AskSzH|BidSzQ|BidQ|AskQ|AskSzQ|BidSzX|BidX|AskX|AskSzX|BidSzE|BidE|AskE|AskSzE|BidSzJ|BidJ|AskJ|AskSzJ|'||
			'BidSzR|BidR|AskR|AskSzR|ULBidSz|ULBid|ULAsk|ULAskSz';

    return query
        select rec
        from t_report
        order by rec_type, order_status;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'get_lp_eod_compliance for ' || in_date_id::text || 'and firm' ||in_firm ||' COMPLETED ===',
                           l_row_cnt, 'O')
    into l_step_id;

end;
$fx$