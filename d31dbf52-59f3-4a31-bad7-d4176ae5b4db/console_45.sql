select co.sub_strategy_desc,
       fmj.fix_message->>'9281',
       case
-- 			when in_reporter_imid in ('FLTU') then 'ALL'
			when fmj.fix_message->>'9281' in ('A','D','G') or fmj.fix_message->>'22017' = 'A' then 'ALL'
			when fmj.fix_message->>'9281' in ('F','C') or fmj.fix_message->>'22017' = 'B' then 'REGPOST'
			else 'REG'
		end,
    compliance.get_sor_trading_session(in_order_id := co.order_id, in_instrument_type_id := instrument_type_id, in_date_id := create_date_id),
    compliance.get_sor_handl_inst_2d(in_order_id := co.order_id, in_instrument_type_id := instrument_type_id, in_date_id := create_date_id, in_fix_msg := fmj.fix_message),
    compliance.get_handl_inst_2c(co.client_order_id, co.no_legs, create_date_id),
    compliance.get_sor_handl_inst(in_order_id := co.order_id, in_instrument_type_id := instrument_type_id, in_date_id := create_date_id),
    compliance.get_sor_handl_inst_sy(in_order_id := co.order_id, in_instrument_type_id := instrument_type_id, in_date_id := create_date_id, in_fix_msg := fmj.fix_message)
from dwh.client_order co
join fix_capture.fix_message_json fmj on fmj.fix_message_id = co.fix_message_id
join dwh.d_instrument di on di.instrument_id = co.instrument_id
join dwh.d_account da on da.account_id = co.account_id
where co.client_order_id = 'e90634a2-c4-0092-41'

------------------------------------------------------------------


-- DROP FUNCTION dash360.report_lpeod_aos_compliance(int4, int4, _varchar, _int8);

CREATE or replace FUNCTION trash.report_lpeod_aos_compliance(p_start_date_id integer DEFAULT NULL::integer, p_end_date_id integer DEFAULT NULL::integer, p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], p_account_ids bigint[] DEFAULT '{}'::bigint[])
 RETURNS TABLE(export_row text)
 LANGUAGE plpgsql
AS $function$
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_start_date_id int4;
    l_end_date_id   int4;

    text_var1 varchar;
    text_var2 varchar;
    text_var3 varchar;
begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    l_start_date_id = coalesce(p_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id = coalesce(p_end_date_id, l_start_date_id);

    select public.load_log(l_load_id, l_step_id, 'dash360.get_lpeod_compliance for '|| l_start_date_id::text || ' - '|| l_end_date_id::text || ' STARTED===', 0, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, left(' p_trading_firm_ids = '||p_trading_firm_ids::varchar, 200), 0, 'O')
     into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(' p_account_ids = '||p_account_ids::varchar, 200), 0, 'O')
     into l_step_id;

    execute 'DROP TABLE IF EXISTS tmp_lpeod_aos_orders;';
    create temp table tmp_lpeod_aos_orders with (parallel_workers = 4) ON COMMIT drop as -- 7 min
    -- explain
    select ac.account_id, ac.account_name, tf.trading_firm_name
      , ac.trading_firm_id as ac_trading_firm_id, tf.trading_firm_id as tf_trading_firm_id
      , ac.trading_firm_unq_id as ac_trading_firm_unq_id
      , ac.opt_is_fix_custfirm_processed as ac_opt_is_fix_custfirm_processed
      , ac.opt_customer_or_firm as ac_opt_customer_or_firm
      , ac.opt_is_fix_clfirm_processed as ac_opt_is_fix_clfirm_processed
      , cl.order_id, cl.create_date_id, cl.fix_connection_id, cl.exchange_id, cl.instrument_id, cl.order_type_id, cl.time_in_force_id, cl.transaction_id, cl.create_time
      , cl.multileg_reporting_type, cl.trans_type, cl.parent_order_id
      , cl.exch_order_id, cl.customer_or_firm_id, cl.open_close, cl.side, cl.clearing_firm_id, cl.sub_strategy_desc
      , coalesce((select po.client_order_id from dwh.client_order po where po.order_id = cl.parent_order_id), '') as parent_client_order_id
      , coalesce((select orig.client_order_id from dwh.client_order orig where orig.order_id = cl.orig_order_id), '') as orig_client_order_id
      , (select coalesce(min(cxl.client_order_id), '') from dwh.client_order cxl where cxl.orig_order_id = cl.order_id) as next_min_client_order_id -- cancel_request_client_order_id + replace
      , cl.client_order_id, cl.order_qty, cl.price, cl.multileg_order_id
      , coalesce(staging.get_multileg_leg_number(cl.order_id)::text, '') as leg_number
      , coalesce((select cnl.no_legs::text from dwh.client_order cnl where cnl.order_id = cl.multileg_order_id), '') as leg_count
      , compliance.get_sor_handl_inst(in_order_id := cl.order_id, in_instrument_type_id := di.instrument_type_id, in_date_id := cl.create_date_id) as handl_inst
    from dwh.d_account ac
      join dwh.client_order cl on ac.account_id = cl.account_id
        join lateral(select di.instrument_type_id from dwh.d_instrument di where di.instrument_id = cl.instrument_id limit 1) di on true
      left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
    where 1=1
      and case when coalesce(p_trading_firm_ids, '{}') = '{}' then true else ac.trading_firm_id = any(p_trading_firm_ids) end
      and case when coalesce(p_account_ids, '{}') = '{}' then true else ac.account_id = any(p_account_ids) end
      --and ac.account_id = 32710
      and cl.create_date_id between l_start_date_id and l_end_date_id -- 20220101 and 20220531 --
      and cl.multileg_reporting_type in ('1', '2')
      and cl.trans_type <> 'F'
      -- all streets + parents in case when we have any exec types except Acc. So, here we take everything - parent + street level orders
--     limit 5
      ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    execute 'analyze tmp_lpeod_aos_orders';

    select public.load_log(l_load_id, l_step_id, 'Inserted orders into tmp_lpeod_aos_orders ', l_row_cnt, 'I')
   into l_step_id;

   --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_lpeod_aos_orders;';
   --create table trash.sdn_tmp_lpeod_aos_orders as select * from tmp_lpeod_aos_orders;



    -- transactions
    execute 'DROP TABLE IF EXISTS tmp_lpeod_aos_orders_md;';
    create temp table tmp_lpeod_aos_orders_md with (parallel_workers = 4) ON COMMIT drop as  -- 14 min
    -- explain
    select cl.*
      , ls.*
    from tmp_lpeod_aos_orders cl
         --trash.sdn_tmp_lpeod_aos_orders cl
      left join lateral
        (
          select --ls.transaction_id
            -- 'NBBO'
              max(case when ls.exchange_id = 'NBBO' then ls.ask_price end) as nbbo_ask_price
            , max(case when ls.exchange_id = 'NBBO' then ls.bid_price end) as nbbo_bid_price
            , max(case when ls.exchange_id = 'NBBO' then ls.ask_quantity end) as nbbo_ask_quantity
            , max(case when ls.exchange_id = 'NBBO' then ls.bid_quantity end) as nbbo_bid_quantity
            -- 'AMEX'
            , max(case when ls.exchange_id = 'AMEX' then ls.ask_price end) as amex_ask_price
            , max(case when ls.exchange_id = 'AMEX' then ls.bid_price end) as amex_bid_price
            , max(case when ls.exchange_id = 'AMEX' then ls.ask_quantity end) as amex_ask_quantity
            , max(case when ls.exchange_id = 'AMEX' then ls.bid_quantity end) as amex_bid_quantity
            -- 'BATO'
            , max(case when ls.exchange_id = 'BATO' then ls.ask_price end) as bato_ask_price
            , max(case when ls.exchange_id = 'BATO' then ls.bid_price end) as bato_bid_price
            , max(case when ls.exchange_id = 'BATO' then ls.ask_quantity end) as bato_ask_quantity
            , max(case when ls.exchange_id = 'BATO' then ls.bid_quantity end) as bato_bid_quantity
            -- 'BOX'
            , max(case when ls.exchange_id = 'BOX' then ls.ask_price end) as box_ask_price
            , max(case when ls.exchange_id = 'BOX' then ls.bid_price end) as box_bid_price
            , max(case when ls.exchange_id = 'BOX' then ls.ask_quantity end) as box_ask_quantity
            , max(case when ls.exchange_id = 'BOX' then ls.bid_quantity end) as box_bid_quantity
            -- 'CBOE'
            , max(case when ls.exchange_id = 'CBOE' then ls.ask_price end) as cboe_ask_price
            , max(case when ls.exchange_id = 'CBOE' then ls.bid_price end) as cboe_bid_price
            , max(case when ls.exchange_id = 'CBOE' then ls.ask_quantity end) as cboe_ask_quantity
            , max(case when ls.exchange_id = 'CBOE' then ls.bid_quantity end) as cboe_bid_quantity
            -- 'C2OX'
            , max(case when ls.exchange_id = 'C2OX' then ls.ask_price end) as c2ox_ask_price
            , max(case when ls.exchange_id = 'C2OX' then ls.bid_price end) as c2ox_bid_price
            , max(case when ls.exchange_id = 'C2OX' then ls.ask_quantity end) as c2ox_ask_quantity
            , max(case when ls.exchange_id = 'C2OX' then ls.bid_quantity end) as c2ox_bid_quantity
            -- 'NQBXO'
            , max(case when ls.exchange_id = 'NQBXO' then ls.ask_price end) as nqbxo_ask_price
            , max(case when ls.exchange_id = 'NQBXO' then ls.bid_price end) as nqbxo_bid_price
            , max(case when ls.exchange_id = 'NQBXO' then ls.ask_quantity end) as nqbxo_ask_quantity
            , max(case when ls.exchange_id = 'NQBXO' then ls.bid_quantity end) as nqbxo_bid_quantity
            -- 'ISE'
            , max(case when ls.exchange_id = 'ISE' then ls.ask_price end) as ise_ask_price
            , max(case when ls.exchange_id = 'ISE' then ls.bid_price end) as ise_bid_price
            , max(case when ls.exchange_id = 'ISE' then ls.ask_quantity end) as ise_ask_quantity
            , max(case when ls.exchange_id = 'ISE' then ls.bid_quantity end) as ise_bid_quantity
            -- 'ARCA'
            , max(case when ls.exchange_id = 'ARCA' then ls.ask_price end) as arca_ask_price
            , max(case when ls.exchange_id = 'ARCA' then ls.bid_price end) as arca_bid_price
            , max(case when ls.exchange_id = 'ARCA' then ls.ask_quantity end) as arca_ask_quantity
            , max(case when ls.exchange_id = 'ARCA' then ls.bid_quantity end) as arca_bid_quantity
            -- 'MIAX'
            , max(case when ls.exchange_id = 'MIAX' then ls.ask_price end) as miax_ask_price
            , max(case when ls.exchange_id = 'MIAX' then ls.bid_price end) as miax_bid_price
            , max(case when ls.exchange_id = 'MIAX' then ls.ask_quantity end) as miax_ask_quantity
            , max(case when ls.exchange_id = 'MIAX' then ls.bid_quantity end) as miax_bid_quantity
            -- 'GEMINI'
            , max(case when ls.exchange_id = 'GEMINI' then ls.ask_price end) as gemini_ask_price
            , max(case when ls.exchange_id = 'GEMINI' then ls.bid_price end) as gemini_bid_price
            , max(case when ls.exchange_id = 'GEMINI' then ls.ask_quantity end) as gemini_ask_quantity
            , max(case when ls.exchange_id = 'GEMINI' then ls.bid_quantity end) as gemini_bid_quantity
            -- 'NSDQO'
            , max(case when ls.exchange_id = 'NSDQO' then ls.ask_price end) as nsdqo_ask_price
            , max(case when ls.exchange_id = 'NSDQO' then ls.bid_price end) as nsdqo_bid_price
            , max(case when ls.exchange_id = 'NSDQO' then ls.ask_quantity end) as nsdqo_ask_quantity
            , max(case when ls.exchange_id = 'NSDQO' then ls.bid_quantity end) as nsdqo_bid_quantity
            -- 'PHLX'
            , max(case when ls.exchange_id = 'PHLX' then ls.ask_price end) as phlx_ask_price
            , max(case when ls.exchange_id = 'PHLX' then ls.bid_price end) as phlx_bid_price
            , max(case when ls.exchange_id = 'PHLX' then ls.ask_quantity end) as phlx_ask_quantity
            , max(case when ls.exchange_id = 'PHLX' then ls.bid_quantity end) as phlx_bid_quantity
            -- 'EDGO'
            , max(case when ls.exchange_id = 'EDGO' then ls.ask_price end) as edgo_ask_price
            , max(case when ls.exchange_id = 'EDGO' then ls.bid_price end) as edgo_bid_price
            , max(case when ls.exchange_id = 'EDGO' then ls.ask_quantity end) as edgo_ask_quantity
            , max(case when ls.exchange_id = 'EDGO' then ls.bid_quantity end) as edgo_bid_quantity
            -- 'MCRY'
            , max(case when ls.exchange_id = 'MCRY' then ls.ask_price end) as mcry_ask_price
            , max(case when ls.exchange_id = 'MCRY' then ls.bid_price end) as mcry_bid_price
            , max(case when ls.exchange_id = 'MCRY' then ls.ask_quantity end) as mcry_ask_quantity
            , max(case when ls.exchange_id = 'MCRY' then ls.bid_quantity end) as mcry_bid_quantity
            -- 'MPRL'
            , max(case when ls.exchange_id = 'MPRL' then ls.ask_price end) as mprl_ask_price
            , max(case when ls.exchange_id = 'MPRL' then ls.bid_price end) as mprl_bid_price
            , max(case when ls.exchange_id = 'MPRL' then ls.ask_quantity end) as mprl_ask_quantity
            , max(case when ls.exchange_id = 'MPRL' then ls.bid_quantity end) as mprl_bid_quantity
            -- 'EMLD'
            , max(case when ls.exchange_id = 'EMLD' then ls.ask_price end) as emld_ask_price
            , max(case when ls.exchange_id = 'EMLD' then ls.bid_price end) as emld_bid_price
            , max(case when ls.exchange_id = 'EMLD' then ls.ask_quantity end) as emld_ask_quantity
            , max(case when ls.exchange_id = 'EMLD' then ls.bid_quantity end) as emld_bid_quantity
          from dwh.l1_snapshot ls
          where ls.transaction_id = cl.transaction_id
            and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
            -- is the following filter helps?
            --and ls.start_date_id between l_start_date_id and l_end_date_id -- 20220101 and 20220531 --
          group by ls.transaction_id
          limit 1
        ) ls on true
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    execute 'analyze tmp_lpeod_aos_orders_md';

    select public.load_log(l_load_id, l_step_id, 'Inserted market data into tmp_lpeod_aos_orders_md ', l_row_cnt, 'I')
   into l_step_id;

   --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_lpeod_aos_orders_md;';
   --create table trash.sdn_tmp_lpeod_aos_orders_md as select * from tmp_lpeod_aos_orders_md;


    -- executions
    execute 'DROP TABLE IF EXISTS tmp_lpeod_aos_orders_md_ex;';
    create temp table tmp_lpeod_aos_orders_md_ex with (parallel_workers = 4) ON COMMIT drop as --9 min
    -- explain
    select cl.*
      , ex.*
    from tmp_lpeod_aos_orders_md cl
         --trash.sdn_tmp_lpeod_aos_orders_md cl
      left join lateral
        (
          select ex.order_id as ex_order_id, ex.exec_id as ex_exec_id
            , ex.exch_exec_id as ex_exch_exec_id
            , ex.exec_type as ex_exec_type, ex.order_status as ex_order_status, ex.leaves_qty as ex_leaves_qty, ex.last_px as ex_last_px, ex.exec_time as ex_exec_time
          from dwh.execution ex
          where cl.order_id = ex.order_id
            and ex.exec_date_id >= cl.create_date_id  and ex.exec_date_id between l_start_date_id and l_end_date_id -- 20220101 and 20220531 --
            and ex.is_busted = 'N'
            and ex.exec_type not in ('3', 'a', '5', 'E', 'D') -- exclude also D - Restate
            and ((cl.parent_order_id is null and ex.exec_type <> '0') or cl.parent_order_id is not null) -- Remove Ack entries for parent orders
          limit 10050000 -- executions per one order
        ) ex on true
    where 1=1
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    execute 'analyze tmp_lpeod_aos_orders_md_ex';

    select public.load_log(l_load_id, l_step_id, 'Inserted executions into tmp_lpeod_aos_orders_md_ex ', l_row_cnt, 'I')
   into l_step_id;

   --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_lpeod_aos_orders_md_ex;';
   --create table trash.sdn_tmp_lpeod_aos_orders_md_ex as select * from tmp_lpeod_aos_orders_md_ex;

    -- check if dwh.executions are missing for some dates.
    --select cl.create_date_id
    --  , count(1) as cnt
    --from trash.sdn_tmp_lpeod_aos_orders_md_ex cl
    --where cl.ex_order_id is null
    --group by cl.create_date_id
    --order by 1
    --;


    -- "report_tmp" temp table
    execute 'DROP TABLE IF EXISTS report_tmp;';
    create temp table report_tmp with (parallel_workers = 4) ON COMMIT drop as
    select cl.ex_order_id as rec_type,
           cl.ex_exec_id  as order_status,
           coalesce(cl.account_name, '') || ',' || --UserLogin
           fc.fix_comp_id || ',' || --SendingUserLogin
           coalesce(cl.ac_trading_firm_id, '') || ',' || --EntityCode
           coalesce(cl.trading_firm_name, '') || ',' || --EntityName
           '' || ',' || --DestinationEntity
           '' || ',' || --Owner
           to_char(cl.create_time, 'YYYYMMDD') || ',' || --CreateDate
           to_char(cl.ex_exec_time, 'HH24MISSFF3') || ',' || --CreateTime
           '' || ',' || --StatusDate
           '' || ',' || --StatusTime
           coalesce(oc.opra_symbol, '') || ',' || --OSI
           coalesce(ui.symbol, i.symbol)|| ',' ||--BaseCode
           coalesce(os.root_symbol, '') || ',' || --Root
           coalesce(ui.instrument_type_id,i.instrument_type_id, '') || ',' || --BaseAssetType
           coalesce(to_char(oc.maturity_month, 'fm00') || '/' || to_char(oc.maturity_day, 'fm00') || '/' || oc.maturity_year, '') ||',' || --ExpirationDate
           coalesce(staging.trailing_dot(oc.strike_price), '')||','||
           case oc.put_call when '0' then 'P' when '1' then 'C' else 'S' end || ',' || --TypeCode
           case
               when cl.side = '1' and cl.open_close = 'C' then 'BC'
               else case cl.side when '1' then 'B' when '2' then 'S' when '5' then 'SS' when '6' then 'SS' else '' end
               end || ',' ||
           --coalesce((select no_legs::text from dwh.client_order where order_id = cl.multileg_order_id), '') || ',' || --LegCount
           cl.leg_count || ',' || --LegCount
           --coalesce(staging.get_multileg_leg_number(cl.order_id)::text, '') || ',' || --LegNumber
           cl.leg_number || ',' || --LegNumber
           '' || ',' || --OrderType
                case
                    when CL.PARENT_ORDER_ID is null then case cl.EX_ORDER_STATUS
                                                             when 'A' then 'Pnd Open'
                                                             when 'b' then 'Pnd Cxl'
                                                             when 'S' then 'Pnd Rep'
                                                             when '1' then 'Partial'
                                                             when '2' then 'Filled'
                                                             else case cl.EX_EXEC_TYPE
                                                                      when '4' then 'Canceled'
                                                                      when 'W' then 'Replaced'
                                                                      else cl.EX_EXEC_TYPE end
                        end
                    else case cl.EX_ORDER_STATUS
                             when 'A' then 'Ex Pnd Open'
                             when '0' then 'Ex Open'
                             when '8' then 'Ex Rej'
                             when 'b' then 'Ex Pnd Cxl'
                             when '1' then 'Ex Partial'
                             when '2' then 'Ex Rpt Fill'
                             when '4' then 'Ex Rpt Out'
                             else cl.EX_ORDER_STATUS
                        end
             end||','||  --Status
          coalesce(to_char(cl.price, 'FM999990D0099'), '')||','||
          coalesce(to_char(cl.ex_last_px, 'FM999990D0099'), '')||','||  --StatusPrice
          coalesce(cl.order_qty::text, '')||','|| --Entered Qty
          -- ask++
          coalesce(cl.ex_leaves_qty::text, '')||','|| --StatusQty
          --Order
          coalesce(cl.client_order_id, '')||','||
          case
            when cl.ex_exec_type in ('S','W') then
            --(select coalesce(orig.client_order_id, '') from client_order orig where orig.order_id = cl.orig_order_id)
            cl.orig_client_order_id
              else ''
          end||','|| --Replaced Order
          case
            when cl.ex_exec_type in ('b','4') then
            --(select coalesce(min(cxl.client_order_id), '') from dwh.client_order cxl where cxl.orig_order_id = cl.order_id)
            cl.next_min_client_order_id
              else ''
          end||','|| --CancelOrderID
          --coalesce((select po.client_order_id from dwh.client_order po where po.order_id = cl.parent_order_id), '')||','||
          cl.parent_client_order_id ||','||
          cl.order_id::text||','|| --SystemOrderID
          ''||','|| --Generation
          coalesce(cl.sub_strategy_desc, exc.mic_code)||','|| --ExchangeCode
          --coalesce(CL.OPT_EXEC_BROKER,OPX.OPT_EXEC_BROKER)||','|| --GiveUpFirm
          coalesce(opx.opt_exec_broker, '')||','|| --GiveUpFirm
          case
            when cl.ac_opt_is_fix_clfirm_processed = 'Y' then coalesce(cl.clearing_firm_id, '')
            else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id, '')
          end||','|| --CMTAFirm
          ''||','||  --AccountAlias
          ''||','||  --Account
          ''||','||  --SubAccount
          ''||','||  --SubAccount2
          ''||','||  --SubAccount3
          coalesce(cl.open_close, '')||','||
          case (case cl.ac_opt_is_fix_custfirm_processed
              when 'Y' then coalesce(cl.customer_or_firm_id, cl.ac_opt_customer_or_firm)
               else coalesce(cl.ac_opt_customer_or_firm, '')
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
          end||','||  --Range
          coalesce(ot.order_type_short_name, '')||','|| --PriceQualifier
          coalesce(tif.tif_short_name, '')||','|| --TimeQualifier
          coalesce(cl.ex_exch_exec_id, '')||','|| --ExchangeTransactionID
          coalesce(cl.exch_order_id, '')||','|| --ExchangeOrderID
          ''||','||  --MPID
          ''||','||  --Comment

            coalesce(amex_bid_quantity::text,'')||','|| --BidSzA
        coalesce(to_char(amex_bid_price,'FM999999.0099'),'')||','|| --BidA
        coalesce(to_char(amex_ask_price,'FM999999.0099'),'')||','||  --AskA
        coalesce(amex_ask_quantity::text,'')||','||  --AskSzA

        coalesce(bato_bid_quantity::text,'')||','|| --BidSzZ
        coalesce(to_char(bato_bid_price,'FM999999.0099'),'')||','|| --BidZ
        coalesce(to_char(bato_ask_price,'FM999999.0099'),'')||','||  --AskZ
        coalesce(bato_ask_quantity::text,'')||','||  --AskSzZ

        coalesce(box_bid_quantity::text,'')||','|| --BidSzB
        coalesce(to_char(box_bid_price,'FM999999.0099'),'')||','|| --BidB
        coalesce(to_char(box_ask_price,'FM999999.0099'),'')||','||  --AskB
        coalesce(box_ask_quantity::text,'')||','||  --AskSzB

        coalesce(cboe_bid_quantity::text,'')||','|| --BidSzC
        coalesce(to_char(cboe_bid_price,'FM999999.0099'),'')||','|| --BidC
        coalesce(to_char(cboe_ask_price,'FM999999.0099'),'')||','||  --AskC
        coalesce(cboe_ask_quantity::text,'')||','||  --AskSzC

        coalesce(c2ox_bid_quantity::text,'')||','|| --BidSzW
        coalesce(to_char(c2ox_bid_price,'FM999999.0099'),'')||','|| --BidW
        coalesce(to_char(c2ox_ask_price,'FM999999.0099'),'')||','||  --AskW
        coalesce(c2ox_ask_quantity::text,'')||','||  --AskSzW

        coalesce(nqbxo_bid_quantity::text,'')||','|| --BidSzT
        coalesce(to_char(nqbxo_bid_price,'FM999999.0099'),'')||','|| --BidT
        coalesce(to_char(nqbxo_ask_price,'FM999999.0099'),'')||','||  --AskT
        coalesce(nqbxo_ask_quantity::text,'')||','||  --AskSzT

        coalesce(ise_bid_quantity::text,'')||','|| --BidSzI
        coalesce(to_char(ise_bid_price,'FM999999.0099'),'')||','|| --BidI
        coalesce(to_char(ise_ask_price,'FM999999.0099'),'')||','||  --AskI
        coalesce(ise_ask_quantity::text,'')||','||  --AskSzI

        coalesce(arca_bid_quantity::text,'')||','|| --BidSzP
        coalesce(to_char(arca_bid_price,'FM999999.0099'),'')||','|| --BidP
        coalesce(to_char(arca_ask_price,'FM999999.0099'),'')||','||  --AskP
        coalesce(arca_ask_quantity::text,'')||','||  --AskSzP

            coalesce(miax_bid_quantity::text,'')||','|| --BidSzM
        coalesce(to_char(miax_bid_price,'FM999999.0099'),'')||','|| --BidM
        coalesce(to_char(miax_ask_price,'FM999999.0099'),'')||','||  --AskM
        coalesce(miax_ask_quantity::text,'')||','||  --AskSzM

            coalesce(gemini_bid_quantity::text,'')||','|| --BidSzH
        coalesce(to_char(gemini_bid_price,'FM999999.0099'),'')||','|| --BidH
        coalesce(to_char(gemini_ask_price,'FM999999.0099'),'')||','||  --AskH
        coalesce(gemini_ask_quantity::text,'')||','||  --AskSzH

            coalesce(nsdqo_bid_quantity::text,'')||','|| --BidSzQ
        coalesce(to_char(nsdqo_bid_price,'FM999999.0099'),'')||','|| --BidQ
        coalesce(to_char(nsdqo_ask_price,'FM999999.0099'),'')||','||  --AskQ
        coalesce(nsdqo_ask_quantity::text,'')||','||  --AskSzQ

            coalesce(phlx_bid_quantity::text,'')||','|| --BidSzX
        coalesce(to_char(phlx_bid_price,'FM999999.0099'),'')||','|| --BidX
        coalesce(to_char(phlx_ask_price,'FM999999.0099'),'')||','||  --AskX
        coalesce(phlx_ask_quantity::text,'')||','||  --AskSzX

            coalesce(edgo_bid_quantity::text,'')||','|| --BidSzE
        coalesce(to_char(edgo_bid_price,'FM999999.0099'),'')||','|| --BidE
        coalesce(to_char(edgo_ask_price,'FM999999.0099'),'')||','||  --AskE
        coalesce(edgo_ask_quantity::text,'')||','||  --AskSzE

            coalesce(mcry_bid_quantity::text,'')||','|| --BidSzJ
        coalesce(to_char(mcry_bid_price,'FM999999.0099'),'')||','|| --BidJ
        coalesce(to_char(mcry_ask_price,'FM999999.0099'),'')||','||  --AskJ
        coalesce(mcry_ask_quantity::text,'')||','||  --AskSzJ

        case when -- 'aostb01' = any(p_trading_firm_ids)
                  (select count(1) from dwh.d_account ac where ac.trading_firm_id in ('aostb01','vision01') and (ac.account_id = any(p_account_ids) or ac.trading_firm_id = any(p_trading_firm_ids))) > 0
            then   ---- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        --Add NBBO
            coalesce(nbbo_bid_quantity::text,'')||','|| -- nbbo_bq
        coalesce(to_char(nbbo_bid_price,'FM999999.0099'),'')||','|| -- nbbo_bp
        coalesce(to_char(nbbo_ask_price,'FM999999.0099'),'')||','||  -- nbbo_ap
        coalesce(nbbo_ask_quantity::text,'')||','  -- nbbo_aq
        else '' end ||
            coalesce(mprl_bid_quantity::text,'')||','|| --BidSzR
        coalesce(to_char(mprl_bid_price,'FM999999.0099'),'')||','|| --BidR
        coalesce(to_char(mprl_ask_price,'FM999999.0099'),'')||','||  --AskR
        coalesce(mprl_ask_quantity::text,'')||','||  --AskSzR
          ''||','|| --ULBidSz
          ''||','|| --ULBid
          ''||','|| --ULAsk
          ''||','|| --ULAskSz
        cl.handl_inst||','||
           ''
          as rec
    from tmp_lpeod_aos_orders_md_ex cl
         --trash.sdn_tmp_lpeod_aos_orders_md_ex cl
      left join dwh.d_clearing_account ca
        on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
            ca.market_type = 'O' and ca.clearing_account_type = '1')
      inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
      left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
      left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
      left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
      left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
      left join dwh.d_instrument i on i.instrument_id = cl.instrument_id
      left join dwh.d_opt_exec_broker opx on (opx.account_id = cl.account_id and opx.is_default = 'Y' and opx.is_active)
      left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
      left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    execute 'analyze report_tmp';

    select public.load_log(l_load_id, l_step_id, 'Inserted the report data into report_tmp ', l_row_cnt, 'I')
   into l_step_id;

   --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_lpeod_aos_report_data;';
   --create table trash.sdn_tmp_lpeod_aos_report_data as select * from report_tmp;


    return query
    select rec from (select 1       as rec_type,
                            0       as order_status,
                            case
                                when --'aostb01' = any(p_trading_firm_ids)
                                    --'aostb01' = any(p_trading_firm_ids) or (select count(1) from dwh.d_account ac where ac.trading_firm_id in ('aostb01','vision01') and ac.account_id = any(p_account_ids)) > 0
                                    (select count(1) from dwh.d_account ac where ac.trading_firm_id in ('aostb01','vision01') and (ac.account_id = any(p_account_ids) or ac.trading_firm_id = any(p_trading_firm_ids))) > 0
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
                                end as rec

                     union all

                     select rec_type, order_status, rec
                     from report_tmp) x
    order by rec_type, order_status;


   select public.load_log(l_load_id, l_step_id, 'dash360.get_lpeod_compliance COMPLETED===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;


   EXCEPTION when others then
    GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                          text_var2 = PG_EXCEPTION_DETAIL,
                          text_var3 = PG_EXCEPTION_HINT;
   raise notice '% % %', text_var1, text_var2, text_var3;

end;
$function$
;


select *
from trash.report_lpeod_aos_compliance(
	p_start_date_id => 20230712,
	p_end_date_id => 20230712,
	p_account_ids => '{68415,29549,66296}'
);