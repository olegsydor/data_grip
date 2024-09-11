update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE FUNCTION dwh.reload_historic_tds_gtc(in_date_id integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- 2024-09-11 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
declare
 l_row_cnt int;
begin



	insert into dwh.historic_trade_details_storage("OrderID","ExecID","RefExecID","TransactTime","ExecType",
	             "LeavesQty","CumQty","AvgPx","LastQty","LastPx",
	             "LastMkt","TradeLiquidityIndicator","Text","ExchExecID", "SecondaryOrderID", "ExchangeID",
	             "PrincipalAmount","AliasLastMkt", "AuctionID", "TradeDateID",
	             "StatusDate", "Status_Date_id" )
	select
	        "OrderID",
	        "ExecID",
	        "RefExecID"::bigint,
	        "TransactTime",
	        "ExecType",
	        "LeavesQty",
	        "CumQty",
	        "AvgPx",
	        "LastQty",
	        "LastPx",
	        "LastMkt",
	        "TradeLiquidityIndicator",
	        "Text",
	        "ExchExecID",
	        "SecondaryOrderID",
	        "ExchangeID",
	        /*"StreetCustomerOrFirm",
	        "StreetExecBroker",
	        "StreetClearingFirm",
	        "StreetAccount",*/
	        "PrincipalAmount",
	        "LastMkt",
	        "AuctionID",
	        "TradeDateID",
	        "TradeDateID"::varchar::date,
	        "Status_Date_id"
	    FROM
	        (
	            SELECT
	                co.order_id "OrderID",
	                ex.exec_id "ExecID",
	                NULL "RefExecID",
	                ex.exec_time "TransactTime",
	                ex.exec_type "ExecType",
	                ex.leaves_qty "LeavesQty",
	                ex.cum_qty "CumQty",
	                ex.avg_px "AvgPx",
	                ex.last_qty "LastQty",
	                ex.last_px "LastPx",
	                    CASE
	                        WHEN ex.exec_type NOT IN (
	                            'F','G'
	                        ) THEN NULL
	                        WHEN co.parent_order_id IS NULL THEN ex.last_mkt
	                        ELSE co.ex_destination
	                    END
	                "LastMkt",
	                ex.trade_liquidity_indicator "TradeLiquidityIndicator",
	                ex.exec_text "Text",
	                ex.exch_exec_id "ExchExecID",
	                ex.secondary_order_id "SecondaryOrderID",
	                ex.auction_id "AuctionID",
	                coch.exchange_id "ExchangeID",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'BATO','BOX','C2OX','CBOE','NQBXO','NSDQO'
	                        ) THEN coch.eq_order_capacity --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 47 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','GEMINI','ISE','MIAX','PHLX'
	                        ) THEN coch.customer_or_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 204 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetCustomerOrFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO'
	                        ) THEN coch.market_participant_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 115 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'BOX','C2OX','CBOE','GEMINI','ISE'
	                        ) THEN doeb.opt_exec_broker --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 76 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'MIAX','PHLX'
	                        ) THEN ( fmj.fix_message->>'50')
	                        WHEN coch.exchange_id IN (
	                            'NQBXO','NSDQO'
	                        ) THEN coch.client_id_text --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 109 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        ELSE NULL
	                    END
	                "StreetExecBroker",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','C2OX','CBOE','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX'
	                        ) THEN coch.clearing_firm_id  --(SELECT F.FIELD_VALUE FROM FIX_MESSAGE_FIELD F WHERE F.TAG_NUM = 439 AND F.FIX_MESSAGE_ID = COCH.FIX_MESSAGE_ID)
	                        WHEN coch.exchange_id IN (
	                            'AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN ( right(fmj.fix_message->>'1',3))
	                        ELSE NULL
	                    END
	                "StreetClearingFirm",
	                    CASE
	                        WHEN coch.exchange_id IN (
	                            'AMEX','ARCA','BATO','BOX','GEMINI','ISE','MIAX','NQBXO','NSDQO','PHLX','AMEXML','BATOML','CBOEML','GMNIML','ISEML','MIAXML','PHLXML'
	                        ) THEN (fmj.fix_message->>'1')
	                        WHEN coch.exchange_id IN (
	                            'C2OX','CBOE'
	                        ) THEN (fmj.fix_message->>'440')
	                        ELSE NULL
	                    END
	                "StreetAccount",
		--
	                    CASE i.INSTRUMENT_TYPE_ID
	                        WHEN 'O' THEN ex.last_qty * ex.last_px * os.contract_multiplier
	                        ELSE ex.last_qty * ex.last_px
	                    END
	                "PrincipalAmount",
	                ex.exec_date_id  "TradeDateID",
	                ex.exec_date_id as "Status_Date_id",
		--
	                coalesce(coch.parent_order_id, co.order_id) AS virtual_order_id
	            from dwh.gtc_order_status gto
		   		join dwh.execution ex on ex.order_id = gto.order_id
		   		join dwh.client_order co on ex.order_id = co.order_id and gto.create_date_id = co.create_date_id
	               LEFT JOIN client_order coch ON (
						ex.secondary_order_id = coch.client_order_id
						AND co.order_id = coch.parent_order_id
						--and co.create_date_id = coch.create_date_id
	                )
	                JOIN dwh.d_instrument i ON i.instrument_id = co.instrument_id
	                LEFT JOIN dwh.d_option_contract oc ON co.instrument_id = oc.instrument_id
	                LEFT JOIN dwh.d_option_series os ON os.option_series_id = oc.option_series_id
	                left join fix_capture.fix_message_json fmj on fmj.fix_message_id = coch.fix_message_id and fmj.date_id = coch.create_date_id
	                left join dwh.d_opt_exec_broker doeb on doeb.opt_exec_broker_id = coch.opt_exec_broker_id
	            WHERE ex.order_status <> '3'
	                AND co.multileg_reporting_type IN ('1','2')
	                AND co.trans_type <> 'F'
	                AND ex.exec_type = 'F'
	                AND ex.is_busted <> 'Y'
	                and ex.exec_date_id = in_date_id
	                and (gto.close_date_id is null or gto.close_date_id = in_date_id)
			AND i.instrument_type_id IN ('E','O')
			AND i.is_active = 'Y'
	        ) abc
	    WHERE
	        virtual_order_id = "OrderID";

	   raise  INFO  '%: temp table has been created',  clock_timestamp()::text;

	   return l_row_cnt;

end
$function$
;


    $insert$
where true
  and routine_schema = 'dwh'
  and routine_name = 'reload_historic_tds_gtc'
  and new_script is null;