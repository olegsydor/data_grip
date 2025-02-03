CREATE FUNCTION dash360.report_fintech_eod_ofp0058_trades(in_start_date_id int4, in_end_date_id int4)
    RETURNS TABLE
            (
                trade_record_id                     bigint,
                orig_trade_record_id                bigint,
                trade_record_time                   timestamp without time zone,
                exec_id                             bigint,
                order_id                            bigint,
                street_order_id                     bigint,
                client_order_id                     character varying,
                street_client_order_id              character varying,
                trading_firm_name                   character varying,
                account_name                        character varying,
                side                                character,
                open_close                          character,
                last_qty                            integer,
                last_px                             numeric,
                last_mkt                            character varying,
                trade_liquidity_indicator           character varying,
                trade_liquidity_indicator_text      character varying,
                ex_destination                      character varying,
                sub_strategy                        character varying,
                customer_or_firm_name               character varying,
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
                sec_type                            character,
                symbol                              character varying,
                display_instrument_id               character varying,
                last_trade_date                     timestamp without time zone,
                real_exchange_id                    character varying,
                exchange_name                       character varying,
                real_exchange_name                  character varying,
                principal_amount                    numeric,
                execution_time_ask_price            numeric,
                execution_time_bid_price            numeric,
                execution_time_ask_qty              integer,
                execution_time_bid_qty              integer,
                routing_time_ask_price              numeric,
                routing_time_bid_price              numeric,
                routing_time_ask_qty                integer,
                routing_time_bid_qty                integer,
                trade_record_reason                 character,
                fee_sensitivity                     smallint,
                optional_data                       character varying,
                opra_symbol                         character varying,
                compliance_id                       character varying,
                put_call                            character,
                strike_px                           numeric
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
l_account_ids int4[];

begin

    --DROP FUNCTION dash360.dash360_report_trades(character varying[], bigint[], character varying, integer, integer, timestamp without time zone, timestamp without time zone, character)
    -- 20210323 ak added new input parametr in_client_ids and filtering
    -- OS: 20211104 DS-4333 removing dynamic sql
    -- OS: 20230607 DS-6786 add mpid to the parameters list
    -- OS: 20250203 https://dashfinancial.atlassian.net/browse/DEVREQ-5501 used the old script for this custom report

    select array_agg(account_id)
     into l_account_ids
    from dwh.d_account
        where trading_firm_id = 'OFP0058';

    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_time,
               tr.exec_id::bigint,
               tr.order_id::bigint,
               tr.street_order_id::bigint,
               tr.client_order_id,
               tr.street_client_order_id,
               tf.trading_firm_name,
               acc.account_name,
               tr.side,
               tr.open_close,
               tr.last_qty,
               tr.last_px,
               lm.last_mkt_name                            as last_mkt,
               tr.trade_liquidity_indicator,
               li.description                              as trade_liquidity_indicator_text,
               tr.ex_destination,
               tr.sub_strategy,
               cf.customer_or_firm_name,
               tr.exec_broker,
               tr.cmta,
               tr.client_id,
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
               tr.tcce_trade_Processing_Fee_Amount,
               i.instrument_type_id                        as sec_type,
               i.symbol,
               i.display_instrument_id,
               i.last_trade_date,
               coalesce(e.real_exchange_id, e.exchange_id) as real_exchange_id,
               e.exchange_name,
               real_exch.exchange_name                     as real_exchange_name,
               tr.principal_amount,
               tr.ask_price                                as execution_time_ask_price,
               tr.bid_price                                as execution_time_bid_price,
               tr.ask_qty                                  as execution_time_ask_qty,
               tr.bid_qty                                  as execution_time_bid_qty,
               tr.routing_time_ask_price,
               tr.routing_time_bid_price,
               tr.routing_time_ask_qty,
               tr.routing_time_bid_qty,
               tr.trade_record_reason,
               tr.fee_sensitivity,
               tr.optional_data,
               oc.opra_symbol,
               tr.compliance_id,
               oc.put_call                                 as put_call,
               oc.strike_price                             as strike_px
        from dwh.flat_trade_record tr
                 inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
                 inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)
                 left join dwh.d_exchange e on (tr.exchange_id = e.exchange_id and e.is_active = true)
                 left join dwh.d_exchange real_exch
                           on (real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and
                               real_exch.is_active = true)
                 inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
                 left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
                 left join dwh.d_liquidity_indicator li
                           on (tr.trade_liquidity_indicator = li.trade_liquidity_indicator and
                               real_exch.exchange_id = li.exchange_id and li.is_active)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = opt_customer_firm and cf.is_active)
                 left join dwh.d_last_market lm on (lm.last_mkt = tr.last_mkt and lm.is_active)
        where tr.date_id between :in_start_date_id and :in_end_date_id
          and i.symbol not in
              ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
          and tr.is_busted = 'N'
          and tr.account_id = any(:l_account_ids)
        order by tr.trade_record_time;

end;
$function$
;