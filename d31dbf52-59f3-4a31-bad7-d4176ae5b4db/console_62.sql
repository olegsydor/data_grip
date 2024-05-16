select cl.parent_order_id, cl.order_id, fmj.fix_message_id, fix_message::jsonb->>'9730' as "9730", fix_message::jsonb->>'9882' as "9882", cl.strtg_decision_reason_code, * from dwh.client_order cl
         join fix_capture.fix_message_json fmj on fmj.client_order_id = cl.client_order_id
where cl.client_order_id = 'CDAB2262-20240423';



select cl.parent_order_id,
       cl.order_id,
       fmj.fix_message_id,
       fix_message::jsonb ->> '9730' as "9730",
       fix_message::jsonb ->> '9882' as "9882",
       cl.strtg_decision_reason_code,
       *
from dwh.client_order cl
    join dwh.execution ex on ex.order_id = cl.order_id and ex.exec_date_id >= cl.create_date_id
         left join fix_capture.fix_message_json fmj on fmj.fix_message_id = ex.fix_message_id--and fmj.date_id = ex.exec_date_id--fmj.client_order_id = cl.client_order_id
where cl.client_order_id = 'CDAB2262-20240423'
and cl.create_date_id = 20240423;


select fix_message::jsonb->>'9730' as "9730", fix_message::jsonb->>'9882' as "9882", fix_message::jsonb, * from fix_capture.fix_message_json
where client_order_id = 'CDAB2262-20240423';

select 1,
       case
           when cl.STRATEGY_DECISION_REASON_CODE) in ('74') and ex.exchange_id in ('AMEX', 'BOX', 'CBOE', 'EDGO', 'GEMINI', 'ISE', 'MCRY', 'MIAX', 'NQBXO', 'PHLX')
    and exists (
select upper(description)
from dwh.d_liquidity_indicator li
where (upper(description) like '%FLASH%'
   or upper(description) like '%EXPOSURE%')
  and li.trade_liquidity_indicator = ex.trade_liquidity_indicator)
    then 'FLASH'
    when NVL(CL.STRATEGY_DECISION_REASON_CODE
    , STR.STRATEGY_DECISION_REASON_CODE) in ('74')
  and ex.exchange_id in ('AMEX'
    , 'BOX'
    , 'CBOE'
    , 'EDGO'
    , 'GEMINI'
    , 'ISE'
    , 'MCRY'
    , 'MIAX'
    , 'NQBXO'
    , 'PHLX')
  and exists (
select null
from liquidity_indicator li
where (upper(description) like '%FLASH%'
   or upper(description) like '%EXPOSURE%')
  and li.trade_liquidity_indicator = ex.trade_liquidity_indicator)
    then 'FLASH'
    when CL.STRATEGY_DECISION_REASON_CODE in ('74')
    when CL.STRATEGY_DECISION_REASON_CODE in ('74')
  and substring (fmj.t9730
    , 2
    , 1) in ('B'
    , 'b'
    , 's') then 'FLASH'
    when CL.STRATEGY_DECISION_REASON_CODE in ('32'
    , '62'
    , '96'
    , '99') then 'FLASH'
    when Cl.CROSS_TYPE = 'P' then 'PIM' when Cl.CROSS_TYPE = 'Q' then 'QCC'
    when Cl.CROSS_TYPE = 'F' then 'Facilitation'
    when Cl.CROSS_TYPE = 'S' then 'Solicitation'
    else coalesce (CL.CROSS_TYPE
    , '')
end||','|| --Auc.type


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
