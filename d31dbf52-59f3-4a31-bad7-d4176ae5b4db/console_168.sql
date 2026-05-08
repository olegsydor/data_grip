-- DROP FUNCTION dash360.report_price_improvement(_varchar, _int8, int4, int4, varchar, bpchar, _varchar, bpchar, _bpchar);

CREATE OR REPLACE FUNCTION dash360.report_price_improvement(p_trading_firm_ids character varying[] DEFAULT NULL::character varying[],
                                                            p_account_ids bigint[] DEFAULT NULL::bigint[],
                                                            p_start_status_date_id integer DEFAULT NULL::integer,
                                                            p_end_status_date_id integer DEFAULT NULL::integer,
                                                            p_instrument_type_id character varying DEFAULT 'E'::character varying,
                                                            p_is_demo character DEFAULT 'N'::bpchar,
                                                            in_client_ids character varying[] DEFAULT '{}'::character varying[],
                                                            in_customer_or_firm_name character DEFAULT NULL::character varying,
                                                            in_capacity_ids character[] DEFAULT '{}'::bpchar[])
    RETURNS TABLE
            (
                trading_firm_name     character varying,
                account_name          character varying,
                order_process_time    timestamp without time zone,
                trade_record_time     timestamp without time zone,
                order_id              bigint,
                side                  character,
                instrument_type_id    character,
                display_instrument_id character varying,
                last_trade_date       timestamp without time zone,
                order_qty             integer,
                street_order_qty      integer,
                last_qty              integer,
                order_price           numeric,
                last_px               numeric,
                bid_price             numeric,
                ask_price             numeric,
                bid_qty               integer,
                ask_qty               integer,
                complex_single        character varying,
                sub_strategy          character varying,
                improved_qty          numeric,
                value_saved           numeric,
                street_order_id       bigint,
                exchange_name         character varying,
                client_order_id       character varying,
                client_id             character varying,
                int_liq_source_type   character varying,
                customer_or_firm_name character varying,
                value_saved_vs_mid    numeric,
                client_algo_alias     character varying,
                nbbo_bid_qty          bigint,
                nbbo_bid_price        numeric,
                nbbo_ask_qty          bigint,
                nbbo_ask_price        numeric
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY: 20220318 https://dashfinancial.atlassian.net/browse/DS-4898. Negative values of price improvement allowed
-- AK: 20221208 https://dashfinancial.atlassian.net/browse/DS-6016. Added customer_or_firm_name field to output
-- PD: 20230612 https://dashfinancial.atlassian.net/browse/DS-6857. Added capacity_ids input param
-- PD: 20240617 https://dashfinancial.atlassian.net/browse/DS-8454. Added new column value_saved_vs_mid
-- PD: 20240629 https://dashfinancial.atlassian.net/browse/DS-8589. Added new column client_algo_alias
-- SY: 20260213 https://dashfinancial.atlassian.net/browse/DS-11095 Parent level NBBO has been added  
-- SY: 20260218 https://dashfinancial.atlassian.net/browse/DS-11109 The value_saved_vs_mid logic has been adjusted to multiplier  
declare
    l_account_ids int8[];
    begin

    select *--array_agg(account_id)
--      into l_account_ids
    from dwh.d_account
    where true
      and case
              when coalesce(:p_trading_firm_ids, '{}'::varchar[]) <> '{}'::varchar[]
                  then trading_firm_id = ANY (:p_trading_firm_ids::varchar[])
              else true end
      and case
              when coalesce(:p_account_ids, '{}'::int8[]) <> '{}'::int8[] then account_id = ANY (:p_account_ids::int8[])
              else true
        end;

    RETURN QUERY
        select case p_is_demo
                   when 'Y' then tf.trading_firm_demo_mnemonic
                   else tf.trading_firm_name end                                                                trading_firm_name,
               case p_is_demo
                   when 'Y' then a.account_demo_mnemonic
                   else a.account_name end                                                                      account_name,
               ft.order_process_time,
               ft.trade_record_time,
               ft.order_id :: bigint,
               ft.side,
               (case
                    when i.INSTRUMENT_TYPE_ID is null then 'O'
                    else i.INSTRUMENT_TYPE_ID end)                                                              instrument_type_id,
               i.display_instrument_id,
               i.last_trade_date,
               ft.order_qty,
               ft.street_order_qty,
               ft.last_qty,
               ft.order_price,
               ft.last_px,
               ft.bid_price,
               ft.ask_price,
               ft.bid_qty,
               ft.ask_qty,
               (case ft.multileg_reporting_type when '1' then 'Single' else 'Complex' end) :: character varying complex_single,
               upper(coalesce(bsn.bloomberg_strategy_name, ft.sub_strategy))::character varying                 sub_strategy,
               case
                   when ft.side = '1' and ft.ask_price > 0 then ft.last_qty * case
                                                                                  when ft.ask_price > ft.last_px then 1
                                                                                  when ft.ask_price < ft.last_px then -1
                                                                                  else 0 end
                   when ft.side in ('2', '5') and ft.bid_price > 0 then ft.last_qty * case
                                                                                          when ft.last_px > ft.bid_price
                                                                                              then 1
                                                                                          when ft.last_px < ft.bid_price
                                                                                              then -1
                                                                                          else 0 end
                   else 0
                   end::numeric                                                                                 improved_qty,
               (case
                    when i.instrument_type_id = 'O' then os.contract_multiplier
                    else 1
                    end
                   *
                case
                    when ft.side = '1' and ft.ask_price > 0 then (ft.ask_price - ft.last_px) * ft.last_qty
                    when ft.side in ('2', '5') and ft.bid_price > 0 then (ft.last_px - ft.bid_price) * ft.last_qty
                    else 0
                    end)                                                                                        value_saved,
               ft.street_order_id::bigint                                                                       street_order_id,
               real_exch.exchange_name,
               ft.client_order_id,
               ft.client_id,
               ft.int_liq_source_type,
               cf.customer_or_firm_name,
               (case
                    when i.instrument_type_id = 'O' then os.contract_multiplier
                    else 1
                    end
                   *
                CASE
                    WHEN ft.side = '1' THEN coalesce(
                            (((nullif(ft.ask_price, 0) + nullif(ft.bid_price, 0)) / 2) - ft.last_px) * ft.last_qty,
                            0) -- (ft.ask_price + ft.bid_price) / 2 as mid_price
                    WHEN ft.side IN ('2', '5') THEN coalesce(
                            (ft.last_px - ((nullif(ft.ask_price, 0) + nullif(ft.bid_price, 0)) / 2)) * ft.last_qty,
                            0) -- (ft.ask_price + ft.bid_price) / 2 as mid_price
                    ELSE 0
                    END)              AS                                                                        value_saved_vs_mid,
               fmj1.tag_9310::varchar as                                                                        client_algo_alias,
               l1.bid_qty             as                                                                        bid_qty_nbbo,
               l1.bid_price           as                                                                        bid_price_nbbo,
               l1.ask_qty             as                                                                        ask_qty_nbbo,
               l1.ask_price           as                                                                        ask_price_nbbo
        ;

    select *
        from dwh.flat_trade_record ft
                 inner join dwh.d_instrument i on i.instrument_id = ft.instrument_id
                 inner join dwh.d_account a on a.account_id = ft.account_id and a.is_active
                 inner join dwh.d_trading_firm tf on a.trading_firm_unq_id = tf.trading_firm_unq_id
                 left join dwh.d_exchange exch on exch.exchange_id = ft.exchange_id and exch.is_active
                 left join dwh.d_exchange real_exch
                           on (exch.real_exchange_id = real_exch.exchange_id and real_exch.is_active)
                 left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
                 left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
                 left join dwh.client_order fm on (ft.order_id = fm.order_id and
                                                   fm.create_date_id between p_start_status_date_id and p_end_status_date_id)
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = ft.opt_customer_firm::varchar)
                 left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and
                                                                 ft.sub_strategy = bsn.original_sub_strategy and
                                                                 coalesce(fm.aggression_level, -1) =
                                                                 coalesce(bsn.aggression_level, -1))
                 left join lateral (select fix_message ->> '9310' as tag_9310
                                    from fix_capture.fix_message_json fmj
                                    where fmj.date_id between p_start_status_date_id and p_end_status_date_id
                                      and fmj.fix_message_id = ft.order_fix_message_id
                                    limit 1) fmj1 on true
                 left join lateral (select grmd.bid_qty, grmd.bid_price, grmd.ask_qty, grmd.ask_price
                                    from dwh.get_routing_market_data(in_transaction_id=>ft.transaction_id,
                                                                     in_exchange_id=>'NBBO',
                                                                     in_multileg_reporting_type=>ft.multileg_reporting_type,
                                                                     in_instrument_id=>ft.instrument_id,
                                                                     in_date_id=>ft.date_id) grmd
                                    limit 1) l1 on true
        where ft.is_busted = 'N'
          and ft.date_id between p_start_status_date_id and p_end_status_date_id
          and case when p_trading_firm_ids is null then true else ft.trading_firm_id = any (p_trading_firm_ids) end
          and case when p_account_ids is null then true else ft.account_id = any (p_account_ids) end
          and i.instrument_type_id = p_instrument_type_id
          and ft.order_id > 0
          and case in_client_ids
                  when '{}'::varchar[]
                      then true
                  else ft.client_id = any (in_client_ids)
            end
          and case
                  when in_customer_or_firm_name = 'Customer'
                      then cf.customer_or_firm_name in ('Customer', 'Professional Customer')
                  when in_customer_or_firm_name = 'Firm'
                      then cf.customer_or_firm_name not in ('Customer', 'Professional Customer')
                  else true end
          and case when in_capacity_ids <> '{}' then ft.opt_customer_firm = any (in_capacity_ids) else true end;
end;
$function$
;
