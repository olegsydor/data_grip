do
$$
    declare
    select_stmt        text;
    sql_params         text;
    sub_request_params text;
    n                  int  := 2;
    main_where         text := '';
    sub_where          text := '';
    part_where         text;
        having_sub_request_params  text  :=  '';
        user_filter text := $x$  and ci.STATUS in ('C','D')$x$;
begin
	loop
		select trim(from split_part(coalesce(user_filter, ''), 'and', n)) into part_where;  -- the first entry is allways '' if user filter starts from 'and'
		exit when part_where = '';
		raise notice 'part_where - %', part_where;
		n := n + 1;
		case
			when  substring(part_where  from  '\s*(.+)\.')  =  'CI'  then
				having_sub_request_params  :=    'HAVING  (case  when  count(distinct(coalesce(ci.status,  '''')))  =  1  then  max(ci.status)  else  null  end)  in  ('''  ||  substring(part_where  from  '\''(.+)\''')||''')';
				raise  notice  'having  %',  having_sub_request_params;
			else
				main_where := main_where || ' and ' || part_where;
				raise  notice  'main  where  %',  main_where;
		end case;
	end loop;
	end;
$$
;
create temp table t_01 as
select tr.trade_record_id::int8,
       tr.trade_record_time,
       tr.exec_id::int8 as                                                                         exec_id,
       tr.order_id::bigint,
       tr.street_order_id::bigint,
       tr.client_order_id,
       tr.street_client_order_id,
       case 'N' when 'Y' then tf.trading_firm_demo_mnemonic else tf.trading_firm_name end          trading_firm_name,
       case 'N' when 'Y' then a.account_demo_mnemonic else a.account_name end                      account_name,
       a.trading_firm_id,
       tr.side,
       tr.account_id,
       tr.open_close,
       tr.last_qty,
       tr.last_px,
       lm.last_mkt_name as                                                                         last_mkt,
       tr.trade_liquidity_indicator,
       liq_ind.description                                                                         trade_liquidity_indicator_text,
       --tr.ex_destination,
       (select dex.ex_destination_desc
        from dwh.d_ex_destination dex
        where dex.ex_destination_code = tr.ex_destination
        limit 1)        as                                                                         ex_destination,
       tr.sub_strategy,
       tr.opt_customer_firm,
       tr.exec_broker,
       tr.cmta,
       case 'N' when 'Y' then null :: character varying else tr.client_id :: character varying end client_id,
       tr.multileg_reporting_type,
       tr.is_cross_order,
       tr.exch_exec_id,
       tr.secondary_exch_exec_id,
       tr.fix_comp_id,
       tr.tcce_account_dash_commission_amount,
       tr.tcce_account_execution_cost,
       tr.tcce_firm_dash_commission_amount,
       tr.tcce_firm_execution_cost,
       tr.tcce_mss_fee_amount,
       tr.tcce_maker_taker_fee_amount,
       tr.tcce_occ_fee_amount,
       tr.tcce_option_regulatory_fee_amount,
       tr.tcce_royalty_fee_amount,
       tr.tcce_sec_fee_amount,
       tr.tcce_transaction_fee_amount,
       tr.tcce_trade_processing_fee_amount,
       i.symbol,
       i.display_instrument_id2                                                                    display_instrument_id,
       i.last_trade_date,
       coalesce(re.real_exchange_id, re.exchange_id)                                               real_exchange_id,
       re.real_exchange_name,
       tr.principal_amount,
       tr.ask_price,
       tr.bid_price,
       tr.ask_qty,
       tr.bid_qty,
       tr.trade_record_reason,
       tr.fee_sensitivity,
       i.instrument_type_id,
       tr.customer_review_status,
       tr.remarks,
       tr.blaze_account_alias,
       tr.street_cross_type,
       ci.status        as                                                                         post_trade_allocation_status,
       tr.auction_id,
       tr.subsystem_id,
       a.opt_customer_or_firm,
       oc.put_call,
       oc.strike_price,
       i.symbol_suffix,
       tr.date_id,
       tr.street_mpid
from dwh.flat_trade_record tr
         inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
    -- left join lateral (select e.real_exchange_id, e.exchange_id from dwh.d_exchange e where tr.exchange_id = e.exchange_id and e.is_active = true) e on true
-- left join lateral (select exchange_id, exchange_name from dwh.d_exchange real_exch where real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and real_exch.is_active = true) real_exch on true
         left join lateral (select e.real_exchange_id, e.exchange_id, re.exchange_name as real_exchange_name
                            from dwh.d_exchange e
                                     join dwh.d_exchange re
                                          on re.exchange_id = coalesce(e.real_exchange_id, e.exchange_id)
                            where e.is_active
                              and re.is_active
                              and e.exchange_id = tr.exchange_id
    ) re on true
         left join lateral (select last_mkt_name
                            from dwh.d_last_market lm
                            where lm.last_mkt = tr.last_mkt and lm.is_active
                            limit 1) lm on true
         inner join dwh.d_account a on tr.account_id = a.account_id
         inner join dwh.d_trading_firm tf on tf.trading_firm_id = a.trading_firm_id and tf.is_active is True
         left join lateral (select description
                            from dwh.d_liquidity_indicator li
                            where tr.trade_liquidity_indicator = li.trade_liquidity_indicator
                              and re.real_exchange_id = li.exchange_id
                              and li.is_active) liq_ind on 1 = 1
/*
         inner join (select tr.order_id,
                            max(tr.trade_record_time)                                                      trade_record_time,
                            case when count(distinct (ci.status)) = 1 then max(ci.status) else null end as pta_status
                     from dwh.flat_trade_record tr
                              inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
                              left join (select max(clearing_instr_id)                            clearing_instr_id,
                                                coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                                         FROM clearing_instruction_entry
                                         GROUP BY coalesce(new_trade_record_id, trade_record_id)) cin
                                        on tr.trade_record_id = cin.trade_record_id
                              left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
                              left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                     where tr.is_busted = 'N'
                       and tr.date_id >= 20250828
                       and tr.date_id <= 20250828
                     group by tr.order_id
                     order by trade_record_time desc) orders on orders.order_id = tr.order_id --100000022092026351

 */
         left join lateral (select max(clearing_instr_id)                            clearing_instr_id
--                            , coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                    FROM dwh.clearing_instruction_entry
                    where date_id >= 20250828
                      and date_id <= 20250828
                    and coalesce(new_trade_record_id, trade_record_id) = tr.trade_record_id
                    GROUP BY coalesce(new_trade_record_id, trade_record_id)
                    limit 1) cin on true
         left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
         left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
where tr.is_busted = 'N'
  and tr.date_id >= 20250828
  and tr.date_id <= 20250828
  and ci.STATUS in ('C', 'D')
order by trade_record_time desc  ;



----


select tr.trade_record_id::int8,
       tr.trade_record_time,
       tr.exec_id::int8 as                                                                        exec_id,
       tr.order_id::bigint,
       tr.street_order_id::bigint,
       tr.client_order_id,
       tr.street_client_order_id,
       case $6 when 'Y' then tf.trading_firm_demo_mnemonic else tf.trading_firm_name end          trading_firm_name,
       case $6 when 'Y' then a.account_demo_mnemonic else a.account_name end                      account_name,
       a.trading_firm_id,
       tr.side,
       tr.account_id,
       tr.open_close,
       tr.last_qty,
       tr.last_px,
       lm.last_mkt_name as                                                                        last_mkt,
       tr.trade_liquidity_indicator,
       liq_ind.description                                                                        trade_liquidity_indicator_text,
       --tr.ex_destination,
       (select dex.ex_destination_desc
        from dwh.d_ex_destination dex
        where dex.ex_destination_code = tr.ex_destination
        limit 1)        as                                                                        ex_destination,
       tr.sub_strategy,
       tr.opt_customer_firm,
       tr.exec_broker,
       tr.cmta,
       case $6 when 'Y' then null :: character varying else tr.client_id :: character varying end client_id,
       tr.multileg_reporting_type,
       tr.is_cross_order,
       tr.exch_exec_id,
       tr.secondary_exch_exec_id,
       tr.fix_comp_id,
       tr.tcce_account_dash_commission_amount,
       tr.tcce_account_execution_cost,
       tr.tcce_firm_dash_commission_amount,
       tr.tcce_firm_execution_cost,
       tr.tcce_mss_fee_amount,
       tr.tcce_maker_taker_fee_amount,
       tr.tcce_occ_fee_amount,
       tr.tcce_option_regulatory_fee_amount,
       tr.tcce_royalty_fee_amount,
       tr.tcce_sec_fee_amount,
       tr.tcce_transaction_fee_amount,
       tr.tcce_trade_processing_fee_amount,
       i.symbol,
       i.display_instrument_id2                                                                   display_instrument_id,
       i.last_trade_date,
       coalesce(re.real_exchange_id, re.exchange_id)                                              real_exchange_id,
       re.real_exchange_name,
       tr.principal_amount,
       tr.ask_price,
       tr.bid_price,
       tr.ask_qty,
       tr.bid_qty,
       tr.trade_record_reason,
       tr.fee_sensitivity,
       i.instrument_type_id,
       tr.customer_review_status,
       tr.remarks,
       tr.blaze_account_alias,
       tr.street_cross_type,
       ci.status        as                                                                        post_trade_allocation_status,
       tr.auction_id,
       tr.subsystem_id,
       a.opt_customer_or_firm,
       oc.put_call,
       oc.strike_price,
       i.symbol_suffix,
       tr.date_id,
       tr.street_mpid
from dwh.flat_trade_record tr
         inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
    -- left join lateral (select e.real_exchange_id, e.exchange_id from dwh.d_exchange e where tr.exchange_id = e.exchange_id and e.is_active = true) e on true
-- left join lateral (select exchange_id, exchange_name from dwh.d_exchange real_exch where real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and real_exch.is_active = true) real_exch on true
         left join lateral (select e.real_exchange_id, e.exchange_id, re.exchange_name as real_exchange_name
                            from dwh.d_exchange e
                                     join dwh.d_exchange re
                                          on re.exchange_id = coalesce(e.real_exchange_id, e.exchange_id)
                            where e.is_active
                              and re.is_active
                              and e.exchange_id = tr.exchange_id
    ) re on true
         left join lateral (select last_mkt_name
                            from dwh.d_last_market lm
                            where lm.last_mkt = tr.last_mkt and lm.is_active
                            limit 1) lm on true
         inner join dwh.d_account a on tr.account_id = a.account_id
         inner join dwh.d_trading_firm tf on tf.trading_firm_id = a.trading_firm_id and tf.is_active is True
         left join lateral (select description
                            from dwh.d_liquidity_indicator li
                            where tr.trade_liquidity_indicator = li.trade_liquidity_indicator
                              and re.real_exchange_id = li.exchange_id
                              and li.is_active) liq_ind on true
         inner join lateral (select --tri.order_id,
                            max(tri.trade_record_time)                                                      trade_record_time,
                            case when count(distinct (ci.status)) = 1 then max(ci.status) else null end as pta_status
                     from dwh.flat_trade_record tri
--                               inner join dwh.d_instrument i on i.instrument_id = tri.instrument_id
                              left join (select max(clearing_instr_id)                            clearing_instr_id,
                                                coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                                         FROM clearing_instruction_entry
                                         GROUP BY coalesce(new_trade_record_id, trade_record_id)) cin
                                        on tri.trade_record_id = cin.trade_record_id
                              left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
--                               left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
                     where tri.is_busted = 'N'
                       and tri.date_id >= $1
                       and tri.date_id <= $2
                       and tri.order_id = tr.order_id
                       limit 1
                     ) orders on true
         left join (select max(clearing_instr_id)                            clearing_instr_id,
                           coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                    FROM dwh.clearing_instruction_entry
                    where date_id >= $1
                      and date_id <= $2
                    GROUP BY coalesce(new_trade_record_id, trade_record_id)) cin
                   on tr.trade_record_id = cin.trade_record_id
         left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
         left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id
where tr.is_busted = 'N'
  and tr.date_id >= $1
  and tr.date_id <= $2
  and ci.STATUS in ('C', 'D')
order by trade_record_time desc

