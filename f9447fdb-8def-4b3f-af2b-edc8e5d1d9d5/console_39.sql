-- dash360_export_executions
-- DROP FUNCTION dash360.dash360_export_executions(_int8, int4, int4, timestamp, timestamp, varchar, bpchar);

CREATE OR REPLACE FUNCTION dash360.dash360_export_executions(account_ids bigint[] DEFAULT '{}'::bigint[],
                                                             start_status_date_id integer DEFAULT NULL::integer,
                                                             end_status_date_id integer DEFAULT NULL::integer,
                                                             start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                             end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                             user_filter character varying DEFAULT NULL::character varying,
                                                             is_demo character DEFAULT 'N'::bpchar)
    RETURNS TABLE
            (
                trade_record_id                     bigint,
                orig_trade_record_id                bigint,
                trade_record_time                   timestamp without time zone,
                exec_id                             bigint,
                parent_client_order_id              character varying,
                street_client_order_id              character varying,
                trading_firm_name                   character varying,
                account_name                        character varying,
                trading_firm_id                     character varying,
                side                                character,
                account_id                          integer,
                open_close                          character,
                last_qty                            integer,
                last_px                             numeric,
                last_mkt                            character varying,
                trade_liquidity_indicator           character varying,
                trade_liquidity_indicator_text      character varying,
                ex_destination                      character varying,
                sub_strategy                        character varying,
                customer_or_firm                    character,
                exec_broker                         character varying,
                cmta                                character varying,
                client_id                           character varying,
                multileg_reporting_type             character,
                is_cross_order                      character,
                exch_exec_id                        character varying,
                secondary_exch_exec_id              character varying,
                fix_comp_id                         character varying,
                tcce_account_dash_commission_amount numeric,
                tcce_account_execution_cost         numeric,
                tcce_firm_dash_commission_amount    numeric,
                tcce_firm_execution_cost            numeric,
                tcce_mss_fee_amount                 numeric,
                tcce_maker_taker_fee_amount         numeric,
                tcce_occ_fee_amount                 numeric,
                tcce_option_regulatory_fee_amount   numeric,
                tcce_royalty_fee_amount             numeric,
                tcce_sec_fee_amount                 numeric,
                tcce_transaction_fee_amount         numeric,
                tcce_trade_processing_fee_amount    numeric,
                symbol                              character varying,
                display_instrument_id               character varying,
                last_trade_date                     timestamp without time zone,
                real_exchange_id                    character varying,
                exchange_name                       character varying,
                principal_amount                    numeric,
                ask_price                           numeric,
                bid_price                           numeric,
                ask_qty                             integer,
                bid_qty                             integer,
                trade_record_reason                 character,
                fee_sensitivity                     smallint,
                opra_symbol                         character varying,
                instrument_type_id                  character,
                clearing_submitted_away             character
            )
    LANGUAGE plpgsql
    COST 1
AS $function$
DECLARE
	select_stmt text;
	sql_params text;
begin


    select  ' '
          ||case when account_ids<>'{}' then ' and a.account_id=any($3)' else '' end
          ||case when start_status_date is not null and end_status_date is not null then ' and tr.trade_record_time between $4 and $5 ' else '' end
          ||case when user_filter is not null then ' and $6' else '' end
    into sql_params;

	select_stmt='
select
   tr.trade_record_id::bigint,
   tr.orig_trade_record_id::bigint,
   tr.trade_record_time,
   tr.exec_id,
   tr.client_order_id as parent_client_order_id,
   tr.street_client_order_id,
   case $7 when ''Y'' then tf.trading_firm_demo_mnemonic else tf.trading_firm_name end trading_firm_name,
   case $7 when ''Y'' then a.account_demo_mnemonic else a.account_name end account_name,
   a.trading_firm_id,
   tr.side,
   tr.account_id,
   tr.open_close,
   tr.last_qty,
   tr.last_px,
   tr.last_mkt,
   tr.trade_liquidity_indicator,
   li.description trade_liquidity_indicator_text,
   tr.ex_destination,
   tr.sub_strategy,
   tr.opt_customer_firm as customer_or_firm,
   tr.exec_broker,
   tr.cmta,
   case $7 when ''Y'' then null :: character varying else tr.client_id :: character varying end client_id,
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
   i.display_instrument_id,
   i.last_trade_date,
   coalesce(e.real_exchange_id, e.exchange_id) real_exchange_id,
   real_exch.exchange_name,
   case i.instrument_type_id
    when ''O'' then tr.last_qty * tr.last_px * os.contract_multiplier
    else tr.last_qty * tr.last_px
  end principal_amount,
  tr.ask_price,
  tr.bid_price,
  tr.ask_qty,
  tr.bid_qty,
  tr.trade_record_reason,
  tr.fee_sensitivity,
  oc.opra_symbol,
  i.instrument_type_id
from dwh.flat_trade_record tr
inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
left join dwh.d_exchange e on tr.exchange_id = e.exchange_id and e.is_active = true
left join dwh.d_exchange real_exch on real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and real_exch.is_active = true
inner join dwh.d_account a on tr.account_id = a.account_id
inner join dwh.d_trading_firm tf on tf.trading_firm_id = a.trading_firm_id
left join dwh.d_liquidity_indicator li on tr.trade_liquidity_indicator=li.trade_liquidity_indicator and real_exch.exchange_id=li.exchange_id and li.is_active
left join dwh.D_option_contract oc on i.instrument_id = oc.instrument_id
left join dwh.D_option_series os on oc.option_series_id = os.option_series_id
where
	tr.is_busted = ''N''
	and tr.date_id >= $1 and tr.date_id <= $2
	'||sql_params||'
order by trade_record_time desc';


RETURN QUERY
execute select_stmt using start_status_date_id, end_status_date_id, account_ids, start_status_date, end_status_date, user_filter, is_demo;

end;
$function$
;
