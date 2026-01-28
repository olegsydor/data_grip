-- DROP FUNCTION dash360.get_trade_record_exchange_fees(int4, varchar, bpchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION dash360.get_trade_record_exchange_fees(in_date_id integer, in_cl_order_id character varying,
                                                                  in_side character, in_dash_exec_id character varying,
                                                                  in_sec_order_id character varying DEFAULT NULL::character varying,
                                                                  in_sec_exec_id character varying DEFAULT NULL::character varying,
                                                                  in_account_name character varying DEFAULT NULL::character varying)
    RETURNS TABLE
            (
                trade_record_id                  bigint,
                tcce_maker_taker_fee_amount      numeric,
                tcce_transaction_fee_amount      numeric,
                tcce_trade_processing_fee_amount numeric,
                tcce_royalty_fee_amount          numeric,
                is_exchange_fee_computed         boolean
            )
    LANGUAGE plpgsql
AS
$function$
    -- 20260128 SO https://dashfinancial.atlassian.net/browse/DS-10874
declare
    l_account_ids int4[];
begin
    if in_account_name is not null then
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where account_name = in_account_name;
    end if;
    return query
        select ftr.trade_record_id,
               ftr.tcce_maker_taker_fee_amount,
               ftr.tcce_transaction_fee_amount,
               ftr.tcce_trade_processing_fee_amount,
               ftr.tcce_royalty_fee_amount,
               (select max_trade_record_id >= ftr.trade_record_id
                from staging.incrementalbilling
                where table_name = 'MIRA_to_GENESIS2_inc') as is_exchange_fee_computed
        --                 ,
--                ftr.client_order_id,
--                ftr.secondary_order_id,
--                ftr.exch_exec_id,
--                ftr.secondary_exch_exec_id,
--                ftr.side
        from dwh.flat_trade_record ftr
        where true
          and ftr.date_id = in_date_id
          and ftr.client_order_id = in_cl_order_id
          and ftr.side = in_side
          and ftr.exch_exec_id = in_dash_exec_id
          and ftr.orig_trade_record_id is null
          and case when in_sec_order_id is not null then ftr.secondary_order_id = in_sec_order_id else true end
          and case when in_sec_exec_id is not null then ftr.secondary_exch_exec_id = in_sec_exec_id else true end
          and case when in_account_name is not null then ftr.account_id = any (l_account_ids) else true end
--         limit 1
    ;
end;
$function$
;

-- DROP FUNCTION dash360.dash360_export_executions(_int8, int4, int4, timestamp, timestamp, varchar, bpchar);

CREATE OR REPLACE FUNCTION dash360.dash360_export_executions(account_ids bigint[] DEFAULT '{}'::bigint[], start_status_date_id integer DEFAULT NULL::integer, end_status_date_id integer DEFAULT NULL::integer, start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone, end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone, user_filter character varying DEFAULT NULL::character varying, is_demo character DEFAULT 'N'::bpchar)
 RETURNS TABLE(trade_record_id bigint, trade_record_time timestamp without time zone, exec_id bigint, parent_client_order_id character varying, street_client_order_id character varying, trading_firm_name character varying, account_name character varying, trading_firm_id character varying, side character, account_id integer, open_close character, last_qty integer, last_px numeric, last_mkt character varying, trade_liquidity_indicator character varying, trade_liquidity_indicator_text character varying, ex_destination character varying, sub_strategy character varying, customer_or_firm character, exec_broker character varying, cmta character varying, client_id character varying, multileg_reporting_type character, is_cross_order character, exch_exec_id character varying, secondary_exch_exec_id character varying, fix_comp_id character varying, tcce_account_dash_commission_amount numeric, tcce_account_execution_cost numeric, tcce_firm_dash_commission_amount numeric, tcce_firm_execution_cost numeric, tcce_mss_fee_amount numeric, tcce_maker_taker_fee_amount numeric, tcce_occ_fee_amount numeric, tcce_option_regulatory_fee_amount numeric, tcce_royalty_fee_amount numeric, tcce_sec_fee_amount numeric, tcce_transaction_fee_amount numeric, tcce_trade_processing_fee_amount numeric, symbol character varying, display_instrument_id character varying, last_trade_date timestamp without time zone, real_exchange_id character varying, exchange_name character varying, principal_amount numeric, ask_price numeric, bid_price numeric, ask_qty integer, bid_qty integer, trade_record_reason character, fee_sensitivity smallint, opra_symbol character varying, instrument_type_id character, client_commission_rate numeric, customer_review_status character, remarks character varying, blaze_account_alias character varying, street_cross_type character, post_trade_allocation_status character, auction_id bigint, order_id bigint, subsystem_id character varying, street_order_id bigint, opt_customer_or_firm character varying, put_call character, strike_price numeric, symbol_suffix character varying, street_account_name character varying, clearing_account_number character varying, sub_account character varying, allocation_avg_price numeric, date_id integer, street_mpid character varying, client_commission_amount numeric)
 LANGUAGE plpgsql
 COST 1
AS $function$
declare
    select_stmt text;
    sql_params  text;
begin
-- OS: 20210822 DS-2624. replaced int4 by int8 for trade_record_id and orig_trade_record_id
-- AK: 20211118 DS-4430 added date_id column to return result
-- AK: 20221024 DS-5735 added "using(last_mkt)" condition in join to prevent ambiguous column name issue
-- AK: 20221129 DS-5931 added street_mpid to return table
-- PD: 20230117 PD added the tf.is_active to avoid the duplication of record with non-active firms
-- OS: 20260119 DS-10976
    select  ' '
          ||case when account_ids<>'{}' then ' and a.account_id=any($3)' else '' end
          ||case when start_status_date is not null and end_status_date is not null then ' and tr.trade_record_time between $4 and $5 ' else '' end
          ||case when user_filter is not null then user_filter else '' end
    into sql_params;

    select_stmt='
select
   tr.trade_record_id::int8,
   tr.trade_record_time,
   tr.exec_id :: bigint exec_id,
   tr.client_order_id as parent_client_order_id,
   tr.street_client_order_id,
   case $6 when ''Y'' then tf.trading_firm_demo_mnemonic else tf.trading_firm_name end trading_firm_name,
   case $6 when ''Y'' then a.account_demo_mnemonic else a.account_name end account_name,
   a.trading_firm_id,
   tr.side,
   tr.account_id,
   tr.open_close,
   tr.last_qty,
   tr.last_px,
   lm.last_mkt_name as last_mkt,
   tr.trade_liquidity_indicator,
   liq_ind.description trade_liquidity_indicator_text,
   --tr.ex_destination,
   (select dex.ex_destination_desc from dwh.d_ex_destination dex where dex.ex_destination_code = tr.ex_destination limit 1) as ex_destination,
   tr.sub_strategy,
   tr.opt_customer_firm as customer_or_firm,
   tr.exec_broker,
   tr.cmta,
   case $6 when ''Y'' then null :: character varying else tr.client_id :: character varying end client_id,
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
   i.display_instrument_id2 display_instrument_id,
   i.last_trade_date,
   coalesce(e.real_exchange_id, e.exchange_id) real_exchange_id,
   real_exch.exchange_name,
   tr.principal_amount,
   tr.ask_price,
   tr.bid_price,
   tr.ask_qty,
   tr.bid_qty,
   tr.trade_record_reason,
   tr.fee_sensitivity,
   oc.opra_symbol,
   i.instrument_type_id,
   tr.client_commission_rate,
   tr.customer_review_status,
   tr.remarks,
   tr.blaze_account_alias,
   tr.street_cross_type,
   ci.status as post_trade_allocation_status,
   tr.auction_id,
   tr.order_id,
   tr.subsystem_id,
   tr.street_order_id,
   a.opt_customer_or_firm,
   oc.put_call,
   oc.strike_price,
  i.symbol_suffix,
  tr.street_account_name,
  tr.clearing_account_number,
  tr.sub_account,
  tr.allocation_avg_price,
  tr.date_id,
  tr.street_mpid,
  tr.client_commission_rate * tr.last_qty as client_commission_amount
from dwh.flat_trade_record tr
inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
inner join dwh.d_account a on tr.account_id = a.account_id
left join dwh.d_last_market lm using(last_mkt)
left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
left join lateral (select e.real_exchange_id, e.exchange_id from dwh.d_exchange e where  tr.exchange_id = e.exchange_id and e.is_active = true limit 1) e on true
left join lateral (select real_exch.exchange_name,real_exch.exchange_id from dwh.d_exchange real_exch where  real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and real_exch.is_active = true limit 1) real_exch on true
inner join dwh.d_trading_firm tf on tf.trading_firm_id = a.trading_firm_id and tf.is_active
left join lateral (select description from dwh.d_liquidity_indicator li where tr.trade_liquidity_indicator=li.trade_liquidity_indicator and real_exch.exchange_id=li.exchange_id and li.is_active) liq_ind on 1=1
left join (
                select max(clearing_instr_id) clearing_instr_id, coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                FROM dwh.clearing_instruction_entry
                GROUP BY coalesce(new_trade_record_id, trade_record_id)
           ) cin on tr.trade_record_id::int8 = cin.trade_record_id::int8
left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
where
    tr.is_busted = ''N''
    and tr.date_id >= $1 and tr.date_id <= $2
    '||sql_params||'
order by trade_record_time desc';


return query
execute select_stmt using start_status_date_id, end_status_date_id, account_ids, start_status_date, end_status_date, is_demo;

end;
$function$
;
