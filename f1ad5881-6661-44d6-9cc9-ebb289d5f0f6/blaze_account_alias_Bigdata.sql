-- DROP FUNCTION dash360.clearing_post_trade_history(int8);

CREATE OR REPLACE FUNCTION dash360.clearing_post_trade_history(in_trade_record_id bigint)
 RETURNS TABLE(trade_record_id bigint, orig_trade_record_id bigint, trade_record_reason character, is_busted character, trade_record_time timestamp without time zone, db_create_time timestamp without time zone, user_id integer, account_id integer, side character, open_close character, last_qty integer, last_px numeric, exec_broker character varying, opt_customer_firm character, clearing_account_number character varying, sub_account character varying, cmta character varying, remarks character varying, trade_liquidity_indicator character varying, real_exchange_id character varying, display_instrument_id character varying, last_trade_date timestamp without time zone, client_commission_rate numeric, street_exec_broker character varying, frequent_trader_id character varying, account_nickname character varying, occ_actionable_id character varying, allocation_avg_price numeric, branch_sequence_number character varying, trade_text character varying, blaze_account_alias character varying)
 LANGUAGE plpgsql
AS $function$
    -- SY: 20210426 Performance improvement of the query
    -- SY: 20210506 DS-3441. Added a few fields
    -- OS: 20210822 DS-2624. replaced int4 by int8 for trade_record_id and orig_trade_record_id
    -- OS: 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
begin

    return query
        WITH RECURSIVE r AS (SELECT tr.trade_record_id::bigint,
							tr.orig_trade_record_id::bigint ,
							tr.trade_record_reason,
							tr.is_busted,
							tr.trade_record_time,
							tr.db_create_time,
							tr.user_id,
							tr.account_id,
							tr.side,
							tr.open_close,
							tr.last_qty,
							tr.last_px,
							tr.exec_broker,
							tr.opt_customer_firm,
							tr.clearing_account_number,
							tr.sub_account,
							tr.cmta,
							tr.remarks,
							tr.trade_liquidity_indicator,
							tr.exchange_id,
							tr.instrument_id,
							tr.client_commission_rate,
							tr.street_exec_broker,
							tr.frequent_trader_id,
							tr.account_nickname,
							tr.street_account_name  as occ_actionable_id,
							tr.allocation_avg_price,
							tr.branch_sequence_number,
							tr.trade_text,
							tr.blaze_account_alias
						FROM dwh.flat_trade_record tr
						WHERE tr.trade_record_id = in_trade_record_id  --and tr.date_id >= 20170901
						UNION
						SELECT tr.trade_record_id::bigint,
							tr.orig_trade_record_id::bigint ,
							tr.trade_record_reason,
							tr.is_busted,
							tr.trade_record_time,
							tr.db_create_time,
							tr.user_id,
							tr.account_id,
							tr.side,
							tr.open_close,
							tr.last_qty,
							tr.last_px,
							tr.exec_broker,
							tr.opt_customer_firm,
							tr.clearing_account_number,
							tr.sub_account,
							tr.cmta,
							tr.remarks,
							tr.trade_liquidity_indicator,
							tr.exchange_id,
							tr.instrument_id,
							tr.client_commission_rate,
							tr.street_exec_broker,
							tr.frequent_trader_id,
							tr.account_nickname,
							tr.street_account_name  as occ_actionable_id,
							tr.allocation_avg_price,
							tr.branch_sequence_number,
							tr.trade_text,
							tr.blaze_account_alias
						FROM r
						INNER JOIN dwh.flat_trade_record tr ON tr.trade_record_id = r.orig_trade_record_id --and tr.date_id >= 20170901
)
SELECT r.trade_record_id::bigint,
		r.orig_trade_record_id::bigint ,
		r.trade_record_reason,
		r.is_busted,
		r.trade_record_time,
		r.db_create_time,
		r.user_id,
		r.account_id,
		r.side,
		r.open_close,
		r.last_qty,
		r.last_px,
		r.exec_broker,
		r.opt_customer_firm,
		r.clearing_account_number,
		r.sub_account,
		r.cmta,
		r.remarks,
		r.trade_liquidity_indicator,
		e.real_exchange_id,
		di.display_instrument_id2 display_instrument_id,
		di.last_trade_date,
		r.client_commission_rate,
		r.street_exec_broker,
		r.frequent_trader_id,
		r.account_nickname,
		r.occ_actionable_id,
		r.allocation_avg_price,
		r.branch_sequence_number,
		r.trade_text,
		r.blaze_account_alias
FROM r
inner join dwh.d_instrument di on r.instrument_id = di.instrument_id
LEFT JOIN dwh.d_exchange e on r.exchange_id = e.exchange_id
ORDER BY db_create_time DESC;

end;
$function$
;
