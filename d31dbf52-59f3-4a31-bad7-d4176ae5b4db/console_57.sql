(select dex.ex_destination_desc from dwh.d_ex_destination dex where dex.ex_destination_code = tr.ex_destination limit 1) as ex_destination,

-- DROP FUNCTION dash360.dash360_export_bunched_executions(_int8, int4, int4, timestamp, timestamp, varchar, bpchar);
select distinct tr.account_id
from dwh.flat_trade_record tr
inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
inner join dwh.d_account a on a.account_id = tr.account_id
left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
left join dwh.d_trading_firm dtf on dtf.trading_firm_unq_id = tr.trading_firm_unq_id
left join lateral (select dex.ex_destination_desc from dwh.d_ex_destination dex where dex.ex_destination_code = tr.ex_destination limit 1) dst on true
where
	tr.is_busted = 'N'
	and date_id >= 20240409 and date_id <= 20240409

select * from drop function  dash360.dash360_export_bunched_executions2('{14532,50009,59930,13736}', 20240409, 20240409);
select * from dash360.dash360_export_bunched_executions('{14532,50009,59930,13736}', 20240409, 20240409);

CREATE or replace FUNCTION dash360.dash360_export_bunched_executions(account_ids bigint[] DEFAULT '{}'::bigint[], start_status_date_id integer DEFAULT NULL::integer, end_status_date_id integer DEFAULT NULL::integer, start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone, end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone, user_filter character varying DEFAULT NULL::character varying, is_demo character DEFAULT 'N'::bpchar)
 RETURNS TABLE(trade_date date, account_id integer, client_id character varying, account_name character varying, side character, instrument_id integer, instrument_type_id character, display_instrument_id character varying, open_close character, opra_symbol character varying, last_trade_date timestamp without time zone, exec_broker character varying, cmta character varying, opt_customer_firm character, principal_amount numeric, exec_qty bigint, avg_px numeric, exec_cost numeric, customer_review_status character, remarks character varying, blaze_account_alias character varying, ex_destination character varying, fix_comp_id character varying, subsystem_id character varying, trade_liquidity_indicator character varying, opt_customer_or_firm character varying, put_call character, strike_price numeric, symbol_suffix character varying, trading_firm_name character varying, date_id integer, street_mpid character varying)
 LANGUAGE plpgsql
 COST 1
AS $function$
-- AK: 20211118 DS-4430 added date_id column to return result
-- OS: 20240410 https://dashfinancial.atlassian.net/browse/DS-8185 Return user friendly value ex_destination
DECLARE
	select_stmt text;
	sql_params text;
begin

	select  ' '
          ||case when account_ids<>'{}' then ' and a.account_id=any($3)' else '' end
          ||case when start_status_date is not null and end_status_date is not null then ' and tr.trade_record_time between $4 and $5 ' else '' end
          ||case when user_filter is not null then user_filter else '' end
    into sql_params;

	select_stmt='
select
   date(tr.trade_record_time) trade_date,
   tr.account_id,
   case $7 when ''Y'' then null :: character varying else tr.client_id end client_id,
   case $7 when ''Y'' then a.account_demo_mnemonic else a.account_name end account_name,
   tr.side,
   tr.instrument_id,
   i.instrument_type_id,
   i.display_instrument_id2 display_instrument_id,
   tr.open_close,
   oc.opra_symbol,
   i.last_trade_date,
   case when i.instrument_type_id=''E'' then null else tr.exec_broker end as exec_broker,
   tr.cmta,
   tr.opt_customer_firm,
   sum(tr.principal_amount) principal_amount,
   sum(tr.last_qty) exec_qty,
   case when sum(tr.last_qty)=0 then null else round(sum(tr.last_qty * tr.last_px)/sum(tr.last_qty),6) end avg_px,
   ROUND(SUM(tr.TCCE_Account_Execution_Cost),6) exec_cost,
   (case when 1 = count(distinct(coalesce(tr.customer_review_status, ''''))) then max(tr.customer_review_status) else ''-'' end)::bpchar customer_review_status,
   (case when 1 = count(distinct(coalesce(tr.remarks, ''''))) then max(tr.remarks) else ''-'' end)::varchar remarks,
   (case when 1 = count(distinct(coalesce(tr.blaze_account_alias, ''''))) then max(tr.blaze_account_alias) else ''-'' end)::varchar blaze_account_alias,

	(case when 1 = count(distinct(coalesce(dst.ex_destination_desc, ''''))) then max(dst.ex_destination_desc) else ''-'' end)::varchar ex_destination,
	(case when 1 = count(distinct(coalesce(tr.fix_comp_id, ''''))) then max(tr.fix_comp_id) else ''-'' end)::varchar fix_comp_id,
	(case when 1 = count(distinct(coalesce(tr.subsystem_id, ''''))) then max(tr.subsystem_id) else ''-'' end)::varchar subsystem_id,
	(case when 1 = count(distinct(coalesce(tr.trade_liquidity_indicator, ''''))) then max(tr.trade_liquidity_indicator) else ''-'' end)::varchar trade_liquidity_indicator,
	(case when 1 = count(distinct(coalesce(a.opt_customer_or_firm, ''''))) then max(a.opt_customer_or_firm) else ''-'' end)::varchar opt_customer_or_firm,
	(case when 1 = count(distinct(coalesce(oc.put_call, ''''))) then max(oc.put_call) else ''-'' end)::character put_call,
	--(case when 1 = count(distinct(coalesce(oc.strike_price, 0))) then max(oc.strike_price)::numeric else sum(oc.strike_price)::numeric end) strike_price,
	(case when 1 = count(distinct(coalesce(oc.strike_price, 0))) then max(oc.strike_price)::numeric else Null::numeric end) strike_price,
	(case when 1 = count(distinct(coalesce(i.symbol_suffix, ''''))) then max(i.symbol_suffix) else ''-'' end)::varchar symbol_suffix,
	--(case when 1 = count(distinct(coalesce(a.trading_firm_id, ''''))) then max(a.trading_firm_id) else ''-'' end)::varchar trading_firm_id
	(case when 1 = count(distinct(coalesce(dtf.trading_firm_name, ''''))) then max(case $7 when ''Y'' then dtf.trading_firm_demo_mnemonic else dtf.trading_firm_name end) else ''-'' end)::varchar trading_firm_name,
	tr.date_id,
	tr.street_mpid
from dwh.flat_trade_record tr
inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
inner join dwh.d_account a on a.account_id = tr.account_id
left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
left join dwh.d_trading_firm dtf on dtf.trading_firm_unq_id = tr.trading_firm_unq_id
left join lateral (select dex.ex_destination_desc from dwh.d_ex_destination dex where dex.ex_destination_code = tr.ex_destination limit 1) dst on true
where
	tr.is_busted = ''N''
	and date_id >= $1 and date_id <= $2
	'||sql_params||'
group by trade_date,tr.date_id, tr.account_id, case $7 when ''Y'' then null :: character varying else tr.client_id end, side, tr.instrument_id, case $7 when ''Y'' then a.account_demo_mnemonic else a.account_name end, i.instrument_type_id, display_instrument_id2, open_close, opra_symbol, i.last_trade_date, case when i.instrument_type_id=''E'' then null else tr.exec_broker end, cmta,tr.opt_customer_firm,tr.street_mpid --,tr.ex_destination,tr.fix_comp_id,tr.subsystem_id,tr.trade_liquidity_indicator,a.opt_customer_or_firm,oc.put_call,oc.strike_price,i.symbol_suffix,a.trading_firm_id,a.opt_customer_or_firm
order by trade_date, tr.account_id, instrument_type_id, display_instrument_id2, last_trade_date, open_close';

RETURN QUERY
execute select_stmt using start_status_date_id, end_status_date_id, account_ids, start_status_date, end_status_date, user_filter, is_demo;

end;
$function$
;
