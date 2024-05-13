drop table t_so;

select export_row
from t_so
where src = 'N'
--   and export_row ilike '%illed%'
except
select export_row
from t_so
where src = 'o'
--   and export_row ilike '%illed%'

create temp table t_so as
-- insert into t_so
select *
from dash360.report_lpeod_aos_compliance(
	p_start_date_id => 20240411,
	p_end_date_id => 20240412,
	p_account_ids => '{24172}'
);

CREATE OR REPLACE FUNCTION dash360.report_lpeod_aos_compliance(p_start_date_id integer DEFAULT NULL::integer,
                                                             p_end_date_id integer DEFAULT NULL::integer,
                                                             p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                             p_account_ids bigint[] DEFAULT '{}'::bigint[])
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_start_date_id int4;
    l_end_date_id   int4;
    l_add_acc       int4;
    text_var1       varchar;
    text_var2       varchar;
    text_var3       varchar;
begin

        select  nextval('public.load_timing_seq')  into  l_load_id;
        l_step_id  :=  1;

        l_start_date_id  =  coalesce(p_start_date_id,  to_char(current_date,  'YYYYMMDD')::int4);
        l_end_date_id  =  coalesce(p_end_date_id,  l_start_date_id);

        select  public.load_log(l_load_id,  l_step_id,  'dash360.get_lpeod_compliance  for  '||  l_start_date_id::text  ||  '  -  '||  l_end_date_id::text  ||  '  STARTED===',  0,  'O')
        into  l_step_id;

        select  public.load_log(l_load_id,  l_step_id,  left('  p_trading_firm_ids  =  '||p_trading_firm_ids::varchar,  200),  0,  'O')
          into  l_step_id;
        select  public.load_log(l_load_id,  l_step_id,  left('  p_account_ids  =  '||p_account_ids::varchar,  200),  0,  'O')
          into  l_step_id;

        select count(1)
         into l_add_acc
        from dwh.d_account ac
        where ac.trading_firm_id in ('aostb01', 'vision01') and false
          and (ac.account_id = any (p_account_ids) or ac.trading_firm_id = any (p_trading_firm_ids));

        raise notice 'l_add_acc - %', l_add_acc;

        execute  'DROP  TABLE  IF  EXISTS  tmp_lpeod_aos_orders;';
        create temp table tmp_lpeod_aos_orders with (parallel_workers = 4)
                                               ON COMMIT drop as --  7  min
        --  explain
        select ac.account_id
             , ac.account_name
             , tf.trading_firm_name
             , ac.trading_firm_id                                                                                as ac_trading_firm_id
             , tf.trading_firm_id                                                                                as tf_trading_firm_id
             , ac.trading_firm_unq_id                                                                            as ac_trading_firm_unq_id
             , ac.opt_is_fix_custfirm_processed                                                                  as ac_opt_is_fix_custfirm_processed
             , ac.opt_customer_or_firm                                                                           as ac_opt_customer_or_firm
             , ac.opt_is_fix_clfirm_processed                                                                    as ac_opt_is_fix_clfirm_processed
             , cl.order_id
             , cl.create_date_id
             , cl.fix_connection_id
             , cl.exchange_id
             , cl.instrument_id
             , cl.order_type_id
             , cl.time_in_force_id
             , cl.transaction_id
             , cl.create_time
             , cl.multileg_reporting_type
             , cl.trans_type
             , cl.parent_order_id
             , cl.exch_order_id
             , cl.customer_or_firm_id
             , cl.open_close
             , cl.side
             , cl.clearing_firm_id
             , cl.sub_strategy_desc
             , (select po.client_order_id
                from dwh.client_order po
                where po.order_id = cl.parent_order_id)                                                          as parent_client_order_id
             , (select orig.client_order_id
                from dwh.client_order orig
                where orig.order_id = cl.orig_order_id)                                                          as orig_client_order_id
             , (select min(cxl.client_order_id)
                from dwh.client_order cxl
                where cxl.orig_order_id = cl.order_id)                                                           as next_min_client_order_id --  cancel_request_client_order_id  +  replace
             , cl.client_order_id
             , cl.order_qty
             , cl.price
             , cl.multileg_order_id
             , staging.get_multileg_leg_number(cl.order_id)::text                                                as leg_number
             , (select cnl.no_legs::text
                from dwh.client_order cnl
                where cnl.order_id = cl.multileg_order_id)                                                       as leg_count
             , compliance.get_sor_handl_inst(in_order_id := cl.order_id, in_instrument_type_id := di.instrument_type_id,
                                             in_date_id := cl.create_date_id)                                    as handl_inst
             , cco.initiator
             , cco.create_time                                                                                   as cco_create_time
        from dwh.client_order cl
                 join dwh.d_account ac on ac.account_id = cl.account_id
                 join lateral (select di.instrument_type_id
                               from dwh.d_instrument di
                               where di.instrument_id = cl.instrument_id
                               limit 1) di on true
                 left join dwh.d_trading_firm tf on ac.trading_firm_unq_id = tf.trading_firm_unq_id
                 left join lateral
            (select 'C' as initiator, co.create_time
             from client_order co
             where co.orig_order_id = cl.order_id
               and co.trans_type = 'F'
               and co.create_date_id = cl.create_date_id
             limit 1) cco on true
        where true
          and case
                  when coalesce(p_trading_firm_ids, '{}') = '{}' then true
                  else ac.trading_firm_id = any (p_trading_firm_ids) end
          and case
                  when coalesce(p_account_ids, '{}') = '{}' then true
                  else ac.account_id = any (p_account_ids) end
          --and  ac.account_id  =  32710
          and cl.create_date_id between l_start_date_id and l_end_date_id --  20220101  and  20220531  --
          and cl.multileg_reporting_type in ('1', '2')
          and cl.trans_type <> 'F'
--            and  cl.order_id  =  15205853573
--           and cl.client_order_id = 'ACTACCREATIVE205060000043'
        --  all  streets  +  parents  in  case  when  we  have  any  exec  types  except  Acc.  So,  here  we  take  everything  -  parent  +  street  level  orders
--          limit  5
        ;
        GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;
        execute  'analyze  tmp_lpeod_aos_orders';

        select  public.load_log(l_load_id,  l_step_id,  'Inserted  orders  into  tmp_lpeod_aos_orders  ',  l_row_cnt,  'I')
      into  l_step_id;

      --execute  'DROP  TABLE  IF  EXISTS  trash.sdn_tmp_lpeod_aos_orders;';
      --create  table  trash.sdn_tmp_lpeod_aos_orders  as  select  *  from  tmp_lpeod_aos_orders;



        --  transactions
        execute  'DROP  TABLE  IF  EXISTS  tmp_lpeod_aos_orders_md;';
        create temp table tmp_lpeod_aos_orders_md with (parallel_workers = 4)
                                                  ON COMMIT drop as --  14  min
        --  explain
        select cl.*
             , ls.*
        from tmp_lpeod_aos_orders cl
                 --trash.sdn_tmp_lpeod_aos_orders  cl
                 left join lateral
            (
            select --ls.transaction_id
                 --  'NBBO'
                max(case when ls.exchange_id = 'NBBO' then ls.ask_price end)         as nbbo_ask_price
                 , max(case when ls.exchange_id = 'NBBO' then ls.bid_price end)      as nbbo_bid_price
                 , max(case when ls.exchange_id = 'NBBO' then ls.ask_quantity end)   as nbbo_ask_quantity
                 , max(case when ls.exchange_id = 'NBBO' then ls.bid_quantity end)   as nbbo_bid_quantity
                 --  'AMEX'
                 , max(case when ls.exchange_id = 'AMEX' then ls.ask_price end)      as amex_ask_price
                 , max(case when ls.exchange_id = 'AMEX' then ls.bid_price end)      as amex_bid_price
                 , max(case when ls.exchange_id = 'AMEX' then ls.ask_quantity end)   as amex_ask_quantity
                 , max(case when ls.exchange_id = 'AMEX' then ls.bid_quantity end)   as amex_bid_quantity
                 --  'BATO'
                 , max(case when ls.exchange_id = 'BATO' then ls.ask_price end)      as bato_ask_price
                 , max(case when ls.exchange_id = 'BATO' then ls.bid_price end)      as bato_bid_price
                 , max(case when ls.exchange_id = 'BATO' then ls.ask_quantity end)   as bato_ask_quantity
                 , max(case when ls.exchange_id = 'BATO' then ls.bid_quantity end)   as bato_bid_quantity
                 --  'BOX'
                 , max(case when ls.exchange_id = 'BOX' then ls.ask_price end)       as box_ask_price
                 , max(case when ls.exchange_id = 'BOX' then ls.bid_price end)       as box_bid_price
                 , max(case when ls.exchange_id = 'BOX' then ls.ask_quantity end)    as box_ask_quantity
                 , max(case when ls.exchange_id = 'BOX' then ls.bid_quantity end)    as box_bid_quantity
                 --  'CBOE'
                 , max(case when ls.exchange_id = 'CBOE' then ls.ask_price end)      as cboe_ask_price
                 , max(case when ls.exchange_id = 'CBOE' then ls.bid_price end)      as cboe_bid_price
                 , max(case when ls.exchange_id = 'CBOE' then ls.ask_quantity end)   as cboe_ask_quantity
                 , max(case when ls.exchange_id = 'CBOE' then ls.bid_quantity end)   as cboe_bid_quantity
                 --  'C2OX'
                 , max(case when ls.exchange_id = 'C2OX' then ls.ask_price end)      as c2ox_ask_price
                 , max(case when ls.exchange_id = 'C2OX' then ls.bid_price end)      as c2ox_bid_price
                 , max(case when ls.exchange_id = 'C2OX' then ls.ask_quantity end)   as c2ox_ask_quantity
                 , max(case when ls.exchange_id = 'C2OX' then ls.bid_quantity end)   as c2ox_bid_quantity
                 --  'NQBXO'
                 , max(case when ls.exchange_id = 'NQBXO' then ls.ask_price end)     as nqbxo_ask_price
                 , max(case when ls.exchange_id = 'NQBXO' then ls.bid_price end)     as nqbxo_bid_price
                 , max(case when ls.exchange_id = 'NQBXO' then ls.ask_quantity end)  as nqbxo_ask_quantity
                 , max(case when ls.exchange_id = 'NQBXO' then ls.bid_quantity end)  as nqbxo_bid_quantity
                 --  'ISE'
                 , max(case when ls.exchange_id = 'ISE' then ls.ask_price end)       as ise_ask_price
                 , max(case when ls.exchange_id = 'ISE' then ls.bid_price end)       as ise_bid_price
                 , max(case when ls.exchange_id = 'ISE' then ls.ask_quantity end)    as ise_ask_quantity
                 , max(case when ls.exchange_id = 'ISE' then ls.bid_quantity end)    as ise_bid_quantity
                 --  'ARCA'
                 , max(case when ls.exchange_id = 'ARCA' then ls.ask_price end)      as arca_ask_price
                 , max(case when ls.exchange_id = 'ARCA' then ls.bid_price end)      as arca_bid_price
                 , max(case when ls.exchange_id = 'ARCA' then ls.ask_quantity end)   as arca_ask_quantity
                 , max(case when ls.exchange_id = 'ARCA' then ls.bid_quantity end)   as arca_bid_quantity
                 --  'MIAX'
                 , max(case when ls.exchange_id = 'MIAX' then ls.ask_price end)      as miax_ask_price
                 , max(case when ls.exchange_id = 'MIAX' then ls.bid_price end)      as miax_bid_price
                 , max(case when ls.exchange_id = 'MIAX' then ls.ask_quantity end)   as miax_ask_quantity
                 , max(case when ls.exchange_id = 'MIAX' then ls.bid_quantity end)   as miax_bid_quantity
                 --  'GEMINI'
                 , max(case when ls.exchange_id = 'GEMINI' then ls.ask_price end)    as gemini_ask_price
                 , max(case when ls.exchange_id = 'GEMINI' then ls.bid_price end)    as gemini_bid_price
                 , max(case when ls.exchange_id = 'GEMINI' then ls.ask_quantity end) as gemini_ask_quantity
                 , max(case when ls.exchange_id = 'GEMINI' then ls.bid_quantity end) as gemini_bid_quantity
                 --  'NSDQO'
                 , max(case when ls.exchange_id = 'NSDQO' then ls.ask_price end)     as nsdqo_ask_price
                 , max(case when ls.exchange_id = 'NSDQO' then ls.bid_price end)     as nsdqo_bid_price
                 , max(case when ls.exchange_id = 'NSDQO' then ls.ask_quantity end)  as nsdqo_ask_quantity
                 , max(case when ls.exchange_id = 'NSDQO' then ls.bid_quantity end)  as nsdqo_bid_quantity
                 --  'PHLX'
                 , max(case when ls.exchange_id = 'PHLX' then ls.ask_price end)      as phlx_ask_price
                 , max(case when ls.exchange_id = 'PHLX' then ls.bid_price end)      as phlx_bid_price
                 , max(case when ls.exchange_id = 'PHLX' then ls.ask_quantity end)   as phlx_ask_quantity
                 , max(case when ls.exchange_id = 'PHLX' then ls.bid_quantity end)   as phlx_bid_quantity
                 --  'EDGO'
                 , max(case when ls.exchange_id = 'EDGO' then ls.ask_price end)      as edgo_ask_price
                 , max(case when ls.exchange_id = 'EDGO' then ls.bid_price end)      as edgo_bid_price
                 , max(case when ls.exchange_id = 'EDGO' then ls.ask_quantity end)   as edgo_ask_quantity
                 , max(case when ls.exchange_id = 'EDGO' then ls.bid_quantity end)   as edgo_bid_quantity
                 --  'MCRY'
                 , max(case when ls.exchange_id = 'MCRY' then ls.ask_price end)      as mcry_ask_price
                 , max(case when ls.exchange_id = 'MCRY' then ls.bid_price end)      as mcry_bid_price
                 , max(case when ls.exchange_id = 'MCRY' then ls.ask_quantity end)   as mcry_ask_quantity
                 , max(case when ls.exchange_id = 'MCRY' then ls.bid_quantity end)   as mcry_bid_quantity
                 --  'MPRL'
                 , max(case when ls.exchange_id = 'MPRL' then ls.ask_price end)      as mprl_ask_price
                 , max(case when ls.exchange_id = 'MPRL' then ls.bid_price end)      as mprl_bid_price
                 , max(case when ls.exchange_id = 'MPRL' then ls.ask_quantity end)   as mprl_ask_quantity
                 , max(case when ls.exchange_id = 'MPRL' then ls.bid_quantity end)   as mprl_bid_quantity
                 --  'EMLD'
                 , max(case when ls.exchange_id = 'EMLD' then ls.ask_price end)      as emld_ask_price
                 , max(case when ls.exchange_id = 'EMLD' then ls.bid_price end)      as emld_bid_price
                 , max(case when ls.exchange_id = 'EMLD' then ls.ask_quantity end)   as emld_ask_quantity
                 , max(case when ls.exchange_id = 'EMLD' then ls.bid_quantity end)   as emld_bid_quantity
            from dwh.l1_snapshot ls
            where ls.transaction_id = cl.transaction_id
              and ls.start_date_id = to_char(cl.create_time, 'YYYYMMDD')::int4
            --  is  the  following  filter  helps?
            --and  ls.start_date_id  between  l_start_date_id  and  l_end_date_id  --  20220101  and  20220531  --
            group by ls.transaction_id
            limit 1
            ) ls on true;
        GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;
        execute  'analyze  tmp_lpeod_aos_orders_md';

        select  public.load_log(l_load_id,  l_step_id,  'Inserted  market  data  into  tmp_lpeod_aos_orders_md  ',  l_row_cnt,  'I')
      into  l_step_id;

      --execute  'DROP  TABLE  IF  EXISTS  trash.sdn_tmp_lpeod_aos_orders_md;';
      --create  table  trash.sdn_tmp_lpeod_aos_orders_md  as  select  *  from  tmp_lpeod_aos_orders_md;


        --  executions
        execute  'DROP  TABLE  IF  EXISTS  tmp_lpeod_aos_orders_md_ex;';
        create  temp  table  tmp_lpeod_aos_orders_md_ex  with  (parallel_workers  =  4)  ON  COMMIT  drop  as  --9  min
        --  explain
        select cl.*
             , ex.*
        from tmp_lpeod_aos_orders_md cl
                 --trash.sdn_tmp_lpeod_aos_orders_md  cl
                 left join lateral
            (
            select ex.order_id     as ex_order_id
                 , ex.exec_id      as ex_exec_id
                 , ex.exch_exec_id as ex_exch_exec_id
                 , ex.exec_type    as ex_exec_type
                 , ex.order_status as ex_order_status
                 , ex.leaves_qty   as ex_leaves_qty
                 , ex.last_px      as ex_last_px
                 , ex.exec_time    as ex_exec_time
            from dwh.execution ex
            where cl.order_id = ex.order_id
              and ex.exec_date_id >= cl.create_date_id
              and ex.exec_date_id between l_start_date_id and l_end_date_id --  20220101  and  20220531  --
              and ex.is_busted = 'N'
              and ex.exec_type not in ('3', 'a', '5', 'E', 'D')             --  exclude  also  D  -  Restate
              and ((cl.parent_order_id is null and ex.exec_type <> '0') or
                   cl.parent_order_id is not null)                          --  Remove  Ack  entries  for  parent  orders
            limit 10050000 --  executions  per  one  order
            ) ex on true
        where true
        ;
        GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;
        execute  'analyze  tmp_lpeod_aos_orders_md_ex';

        select  public.load_log(l_load_id,  l_step_id,  'Inserted  executions  into  tmp_lpeod_aos_orders_md_ex  ',  l_row_cnt,  'I')
      into  l_step_id;

      --execute  'DROP  TABLE  IF  EXISTS  trash.sdn_tmp_lpeod_aos_orders_md_ex;';
      --create  table  trash.sdn_tmp_lpeod_aos_orders_md_ex  as  select  *  from  tmp_lpeod_aos_orders_md_ex;

        --  check  if  dwh.executions  are  missing  for  some  dates.
        --select  cl.create_date_id
        --    ,  count(1)  as  cnt
        --from  trash.sdn_tmp_lpeod_aos_orders_md_ex  cl
        --where  cl.ex_order_id  is  null
        --group  by  cl.create_date_id
        --order  by  1
        --;


        --  "report_tmp"  temp  table
        execute 'DROP  TABLE  IF  EXISTS  report_tmp;';
        create temp table report_tmp with (parallel_workers = 4)
                                     ON COMMIT drop as
        select cl.ex_order_id as rec_type,
               cl.ex_exec_id  as order_status,
               array_to_string(ARRAY [

                                   cl.account_name, --UserLogin
                                   fc.fix_comp_id, --SendingUserLogin
                                   cl.ac_trading_firm_id, --EntityCode
                                   cl.trading_firm_name,--EntityName
                                   '', --DestinationEntity
                                   '',--Owner
                                   to_char(cl.create_time, 'YYYYMMDD'), --CreateDate
                                   to_char(cl.ex_exec_time, 'HH24MISSFF3'), --CreateTime
                                   '',--StatusDate
                                   '',--StatusTime
                                   oc.opra_symbol, --OSI
                                   coalesce(ui.symbol, i.symbol) , --BaseCode
                                   os.root_symbol, --Root
                                   coalesce(ui.instrument_type_id, i.instrument_type_id), --BaseAssetType
                                   to_char(oc.maturity_month, 'fm00') || '/' || to_char(oc.maturity_day, 'fm00') ||
                                   '/' || to_char(oc.maturity_year, 'fm0000') , --ExpirationDate
                                   staging.trailing_dot(oc.strike_price),
                                   case oc.put_call when '0' then 'P' when '1' then 'C' else 'S' end, --TypeCode
                                   case
                                       when cl.side = '1' and cl.open_close = 'C' then 'BC'
                                       else case cl.side
                                                when '1' then 'B'
                                                when '2' then 'S'
                                                when '5' then 'SS'
                                                when '6' then 'SS'
                                                else '' end
                                       end,
                                   cl.leg_count, --LegCount
                                   cl.leg_number, --LegNumber
                                   '', --OrderType
                                   case
                                       when CL.PARENT_ORDER_ID is null then case cl.EX_ORDER_STATUS
                                                                                when 'A' then 'Pnd  Open'
                                                                                when 'b' then 'Pnd  Cxl'
                                                                                when 'S' then 'Pnd  Rep'
                                                                                when '1' then 'Partial'
                                                                                when '2' then 'Filled'
                                                                                when '6' then 'PendingCancel'
                                                                                else case cl.EX_EXEC_TYPE
                                                                                         when '4' then 'Canceled'
                                                                                         when 'W' then 'Replaced'
                                                                                         else cl.EX_EXEC_TYPE end
                                           end
                                       else case cl.EX_ORDER_STATUS
                                                when 'A' then 'Ex  Pnd  Open'
                                                when '0' then 'Ex  Open'
                                                when '8' then 'Ex  Rej'
                                                when 'b' then 'Ex  Pnd  Cxl'
                                                when '1' then 'Ex  Partial'
                                                when '2' then 'Ex  Rpt  Fill'
                                                when '4' then 'Ex  Rpt  Out'
                                                else cl.EX_ORDER_STATUS
                                           end
                                       end, --Status
                                   to_char(cl.price, 'FM999990D0099'),
                                   to_char(cl.ex_last_px, 'FM999990D0099'), --StatusPrice
                                   cl.order_qty::text, --Entered  Qty
                   --  ask++
                                   cl.ex_leaves_qty::text, --StatusQty
                   --Order
                                   cl.client_order_id,
                                   case
                                       when cl.ex_exec_type in ('S', 'W') then
                                           cl.orig_client_order_id
                                       end , --Replaced  Order
                                   case
                                       when cl.ex_exec_type in ('b', '4') then
                                           cl.next_min_client_order_id
                                       end, --CancelOrderID
                                   cl.parent_client_order_id,
                                   cl.order_id::text,--SystemOrderID
                                   '', --Generation
                                   coalesce(cl.sub_strategy_desc, exc.mic_code), --ExchangeCode
                                   opx.opt_exec_broker, --GiveUpFirm
                                   case
                                       when cl.ac_opt_is_fix_clfirm_processed = 'Y' then cl.clearing_firm_id
                                       else coalesce(lpad(ca.cmta, 3), cl.clearing_firm_id)
                                       end, --CMTAFirm
                                   '', --AccountAlias
                                   cl.account_name, --Account
                                   '', --SubAccount
                                   '', --SubAccount2
                                   '',--SubAccount3
                                   cl.open_close,
                                   case (case cl.ac_opt_is_fix_custfirm_processed
                                             when 'Y' then coalesce(cl.customer_or_firm_id, cl.ac_opt_customer_or_firm)
                                             else cl.ac_opt_customer_or_firm
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
                                   ot.order_type_short_name, --PriceQualifier
                                   tif.tif_short_name, --TimeQualifier
                                   cl.ex_exch_exec_id, --ExchangeTransactionID
                                   cl.exch_order_id, --ExchangeOrderID
                                   '', --MPID
                                   '', --Comment

                                   amex_bid_quantity::text, --BidSzA
                                   to_char(amex_bid_price, 'FM999999.0099'), --BidA
                                   to_char(amex_ask_price, 'FM999999.0099'), --AskA
                                   amex_ask_quantity::text, --AskSzA

                                   bato_bid_quantity::text, --BidSzZ
                                   to_char(bato_bid_price, 'FM999999.0099'), --BidZ
                                   to_char(bato_ask_price, 'FM999999.0099'), --AskZ
                                   bato_ask_quantity::text, --AskSzZ

                                   box_bid_quantity::text, --BidSzB
                                   to_char(box_bid_price, 'FM999999.0099'), --BidB
                                   to_char(box_ask_price, 'FM999999.0099'), --AskB
                                   box_ask_quantity::text, --AskSzB

                                   cboe_bid_quantity::text, --BidSzC
                                   to_char(cboe_bid_price, 'FM999999.0099'), --BidC
                                   to_char(cboe_ask_price, 'FM999999.0099'), --AskC
                                   cboe_ask_quantity::text, --AskSzC

                                   c2ox_bid_quantity::text, --BidSzW
                                   to_char(c2ox_bid_price, 'FM999999.0099'), --BidW
                                   to_char(c2ox_ask_price, 'FM999999.0099'), --AskW
                                   c2ox_ask_quantity::text, --AskSzW

                                   nqbxo_bid_quantity::text, --BidSzT
                                   to_char(nqbxo_bid_price, 'FM999999.0099'), --BidT
                                   to_char(nqbxo_ask_price, 'FM999999.0099'), --AskT
                                   nqbxo_ask_quantity::text, --AskSzT

                                   ise_bid_quantity::text, --BidSzI
                                   to_char(ise_bid_price, 'FM999999.0099'), --BidI
                                   to_char(ise_ask_price, 'FM999999.0099'), --AskI
                                   ise_ask_quantity::text, --AskSzI

                                   arca_bid_quantity::text, --BidSzP
                                   to_char(arca_bid_price, 'FM999999.0099'), --BidP
                                   to_char(arca_ask_price, 'FM999999.0099'), --AskP
                                   arca_ask_quantity::text, --AskSzP

                                   miax_bid_quantity::text, --BidSzM
                                   to_char(miax_bid_price, 'FM999999.0099'), --BidM
                                   to_char(miax_ask_price, 'FM999999.0099'), --AskM
                                   miax_ask_quantity::text, --AskSzM

                                   gemini_bid_quantity::text, --BidSzH
                                   to_char(gemini_bid_price, 'FM999999.0099'), --BidH
                                   to_char(gemini_ask_price, 'FM999999.0099'), --AskH
                                   gemini_ask_quantity::text, --AskSzH

                                   nsdqo_bid_quantity::text, --BidSzQ
                                   to_char(nsdqo_bid_price, 'FM999999.0099'), --BidQ
                                   to_char(nsdqo_ask_price, 'FM999999.0099'), --AskQ
                                   nsdqo_ask_quantity::text, --AskSzQ

                                   phlx_bid_quantity::text, --BidSzX
                                   to_char(phlx_bid_price, 'FM999999.0099'), --BidX
                                   to_char(phlx_ask_price, 'FM999999.0099'), --AskX
                                   phlx_ask_quantity::text, --AskSzX

                                   edgo_bid_quantity::text, --BidSzE
                                   to_char(edgo_bid_price, 'FM999999.0099'), --BidE
                                   to_char(edgo_ask_price, 'FM999999.0099'), --AskE
                                   edgo_ask_quantity::text, --AskSzE

                                   mcry_bid_quantity::text, --BidSzJ
                                   to_char(mcry_bid_price, 'FM999999.0099'), --BidJ
                                   to_char(mcry_ask_price, 'FM999999.0099'), --AskJ
                                   mcry_ask_quantity::text --AskSzJ
                                   ], ',', '') ||','||
                   --Add  NBBO
               case
                   when l_add_acc > 0 then
                       array_to_string(ARRAY [
                                           nbbo_bid_quantity::text, --  nbbo_bq
                                           to_char(nbbo_bid_price, 'FM999999.0099'), --  nbbo_bp
                                           to_char(nbbo_ask_price, 'FM999999.0099'), --  nbbo_ap
                                           nbbo_ask_quantity::text --  nbbo_aq
                                           ], ',', '') ||','
               else '' end ||
               array_to_string(ARRAY [
                                   mprl_bid_quantity::text, --BidSzR
                                   to_char(mprl_bid_price, 'FM999999.0099'), --BidR
                                   to_char(mprl_ask_price, 'FM999999.0099'), --AskR
                                   mprl_ask_quantity::text, --AskSzR
                                   '', --ULBidSz
                                   '', --ULBid
                                   '', --ULAsk
                                   '', --ULAskSz
                                   cl.handl_inst,
                                   initiator,
                                   to_char(cco_create_time, 'YYYYMMDD  HH24MISS.MS'),
                                   'C',
                                   to_char(create_time, 'YYYYMMDD  HH24MISS.MS'),
                                   ''
                                   ], ',', '')
                              as rec
        from tmp_lpeod_aos_orders_md_ex cl
                 --trash.sdn_tmp_lpeod_aos_orders_md_ex  cl
                 left join dwh.d_clearing_account ca
                           on (cl.account_id = ca.account_id and ca.is_default = 'Y' and ca.is_active and
                               ca.market_type = 'O' and ca.clearing_account_type = '1')
                 inner join dwh.d_fix_connection fc on (fc.fix_connection_id = cl.fix_connection_id)
                 left join dwh.d_exchange exc on exc.exchange_id = cl.exchange_id and exc.is_active
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join dwh.d_instrument ui on ui.instrument_id = os.underlying_instrument_id
                 left join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = cl.account_id and opx.is_default = 'Y' and opx.is_active)
                 left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
        where true
--                  and  cl.handl_inst  <>  ''
        ;
        GET  DIAGNOSTICS  l_row_cnt  =  ROW_COUNT;
        execute  'analyze  report_tmp';

        select  public.load_log(l_load_id,  l_step_id,  'Inserted  the  report  data  into  report_tmp  ',  l_row_cnt,  'I')
      into  l_step_id;

      --execute  'DROP  TABLE  IF  EXISTS  trash.sdn_tmp_lpeod_aos_report_data;';
      --create  table  trash.sdn_tmp_lpeod_aos_report_data  as  select  *  from  report_tmp;


        return  query
            select rec
            from (select 1       as rec_type,
                         0       as order_status,
                         case
                             when l_add_acc > 0
                                 then
                                 'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,' ||
                                 'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,' ||
                                 'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,' ||
                                 'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,' ||
                                 'BidSzNBBO,BidNBBO,AskNBBO,AskSzNBBO,BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz,HandlInstr,Initiator,RequestTimestamp,IReplaceInitiator,ReplaceRequestTimestamp'
                             else
                                 'UserLogin,SendingUserLogin,EntityCode,EntityName,DestinationEntity,Owner,CreateDate,CreateTime,StatusDate,StatusTime,OSI,BaseCode,RootCode,BaseAssetType,ExpirationDate,Strike,TypeCode,BuySell,LegCount,LegNumber,OrderType,' ||
                                 'Status,EnteredPrice,StatusPrice,EnteredQty,StatusQty,OrderID,ReplacedOrderID,CancelOrderID,ParentOrderID,SystemOrderID,Generation,ExchangeCode,GiveUpFirm,CMTAFirm,AccountAlias,Account,SubAccount,SubAccount2,SubAccount3,' ||
                                 'OpenClose,Range,PriceQualifier,TimeQualifier,ExchangeTransactionID,ExchangeOrderID,MPID,Comment,BidSzA,BidA,AskA,AskSzA,BidSzZ,BidZ,AskZ,AskSzZ,BidSzB,BidB,AskB,AskSzB,BidSzC,BidC,AskC,AskSzC,BidSzW,BidW,AskW,AskSzW,' ||
                                 'BidSzT,BidT,AskT,AskSzT,BidSzI,BidI,AskI,AskSzI,BidSzP,BidP,AskP,AskSzP,BidSzM,BidM,AskM,AskSzM,BidSzH,BidH,AskH,AskSzH,BidSzQ,BidQ,AskQ,AskSzQ,BidSzX,BidX,AskX,AskSzX,BidSzE,BidE,AskE,AskSzE,BidSzJ,BidJ,AskJ,AskSzJ,' ||
                                 'BidSzR,BidR,AskR,AskSzR,ULBidSz,ULBid,ULAsk,ULAskSz,HandlInstr,Initiator,RequestTimestamp,ReplaceInitiator,ReplaceRequestTimestamp'
                             end as rec

                  union all

                  select rec_type, order_status, rec
                  from report_tmp) x
            order by rec_type, order_status;


      select  public.load_log(l_load_id,  l_step_id,  'dash360.get_lpeod_compliance  COMPLETED===',  coalesce(l_row_cnt,0),  'O')
      into  l_step_id;


      EXCEPTION  when  others  then
        GET  STACKED  DIAGNOSTICS  text_var1  =  MESSAGE_TEXT,
                                                    text_var2  =  PG_EXCEPTION_DETAIL,
                                                    text_var3  =  PG_EXCEPTION_HINT;
      raise  notice  '%  %  %',  text_var1,  text_var2,  text_var3;

end;
$function$

