-- DROP FUNCTION dash360.executions_blotter_child_executions(_int8, int4, int4, timestamp, timestamp, varchar, bpchar, int4);

CREATE OR REPLACE FUNCTION dash360.executions_blotter_child_executions(account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                       start_status_date_id integer DEFAULT NULL::integer,
                                                                       end_status_date_id integer DEFAULT NULL::integer,
                                                                       start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                       end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                       user_filter character varying DEFAULT NULL::character varying,
                                                                       is_demo character DEFAULT 'N'::bpchar,
                                                                       in_limit integer DEFAULT 30)
    RETURNS TABLE
            (
                trade_record_id                     bigint,
                orig_trade_record_id                bigint,
                trade_record_time                   timestamp without time zone,
                exec_id                             bigint,
                client_order_id                     character varying,
                street_client_order_id              character varying,
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
                opt_customer_firm                   character,
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
                principal_amount                    numeric,
                ask_price                           numeric,
                bid_price                           numeric,
                ask_qty                             integer,
                bid_qty                             integer,
                trade_record_reason                 character,
                fee_sensitivity                     smallint,
                instrument_type_id                  character,
                client_commission_rate              numeric,
                customer_review_status              character,
                remarks                             character varying,
                blaze_account_alias                 character varying,
                street_exec_broker                  character varying,
                street_account_name                 character varying,
                street_cross_type                   character,
                post_trade_allocation_status        character,
                auction_id                          bigint,
                order_id                            bigint,
                subsystem_id                        character varying,
                street_order_id                     bigint,
                opt_customer_or_firm                character varying,
                put_call                            character,
                strike_price                        numeric,
                symbol_suffix                       character varying,
                clearing_account_number             character varying,
                sub_account                         character varying,
                allocation_avg_price                numeric,
                account_nickname                    character varying,
                date_id                             integer,
                street_mpid                         character varying,
                chain_id                            text,
                linked_id                           text,
                source_id                           text,
                chain_exec_id                       text,
                soc_gen_sub_account                 text,
                soc_gen_contributor_id              text
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
declare
    select_stmt text;
    sql_params  text;
    part_where  varchar;
    main_where  varchar := '';
    n           int     := 2;
begin
/*
    08-04-2021 - MG - DS-3277 - allocation_avg_price, occ_actionable_id, account_nickname column added to the output
    10-05-2021 - MG - DS-3277 - remove occ_actionable_id field from output
    22-08-2021 - OS - DS-2624 - replaced int4 by int8 for trade_record_id and orig_trade_record_id
    09-11-2021 - SY - DS-4388 - date_id field has been introduced
    01-11-2022 - SY - No task - join to clearing_instruction_entry has been refactored as lateral to improve performance
    29-11-2022 - AK - DS-5931 - Added  street_mpid to return table
    13-12-2023 - AK - DS-7642 - added coalesce to returns table for  tcce_maker_taker_fee_amount and tcce_transaction_fee_amount
	14-03-2025 - AK - DS-8725 - changed inner join to inner join laterall to dwh.d_instrument to avoid full table scan
    09-10-2025 - AAv - DS-10558 - [DB] Extend dash360.executions_blotter_child_executions procedure to return new parameters
    28-10-2025 - AAv - DS-10641 - [Dash360] Implement new logic to dash360.executions_blotter_child_executions procedure for populating tag 10710 if it is empty in the fix message.
*/

    LOOP
        SELECT trim(FROM split_part(coalesce(user_filter, ''), 'and', n)) INTO part_where;  -- the first entry is allways '' if user filter starts from 'and'
        exit when part_where = '';
        n := n + 1;
        --raise info '%', part_where;

        -- The IF below added by SO to avoid ambiglous select for some colmns
        IF trim(leading FROM part_where) ~~* ANY(ARRAY['last_mkt%', 'account_id%', 'trade_record_id%']) THEN
            part_where = 'tr.'||trim(leading FROM part_where);
        END IF;
        main_where := main_where || ' and ' || part_where;
    END LOOP;

    user_filter = main_where;

    select  ' '
          ||case when account_ids<>'{}' then ' and a.account_id=any($3)' else '' end
          ||case when start_status_date is not null and end_status_date is not null then ' and tr.trade_record_time between $4 and $5 ' else '' end
          ||case when user_filter is not null then user_filter else '' end
    into sql_params;

    select_stmt='
select
    tr.trade_record_id::int8,
    tr.orig_trade_record_id::int8,
    tr.trade_record_time,
    tr.exec_id::bigint as exec_id,
    tr.client_order_id,
    tr.street_client_order_id,
    a.trading_firm_id,
    tr.side,
    tr.account_id,
    tr.open_close,
    tr.last_qty,
    tr.last_px,
    tr.last_mkt,
    tr.trade_liquidity_indicator as trade_liquidity_indicator_text,
    liq_ind.description,
    tr.ex_destination,
    tr.sub_strategy,
    tr.opt_customer_firm,
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

-- SY Temporary commended use of staging.edw_trading_firm_all_in while EDW is unstable
    case when tr.trading_firm_id in(select etrf.trading_firm_id from staging.edw_trading_firm_all_in etrf)
--    case when tr.trading_firm_id in(select etrf.trading_firm_id from trash.edw_trading_firm_all_in etrf where 1=2)

-- case when tr.trading_firm_id in(select etrf.trading_firm_id from trash.edw_trading_firm_all_in etrf)
    then coalesce(tr.tcce_admin_maker_taker_fee_amount,tr.tcce_maker_taker_fee_amount) else tr.tcce_maker_taker_fee_amount
    end as tcce_maker_taker_fee_amount,
    tr.tcce_occ_fee_amount,
    tr.tcce_option_regulatory_fee_amount,
    tr.tcce_royalty_fee_amount,
    tr.tcce_sec_fee_amount,

-- SY Temporary commended use of staging.edw_trading_firm_all_in while EDW is unstable
    case when tr.trading_firm_id in(select etrf.trading_firm_id from staging.edw_trading_firm_all_in etrf)
--    case when tr.trading_firm_id in(select etrf.trading_firm_id from trash.edw_trading_firm_all_in etrf where 1=2)

-- case when tr.trading_firm_id in(select etrf.trading_firm_id from trash.edw_trading_firm_all_in etrf)
    then coalesce(tr.tcce_admin_transaction_fee_amount,tr.tcce_transaction_fee_amount) else tr.tcce_transaction_fee_amount
    end as tcce_transaction_fee_amount,
    tr.tcce_trade_processing_fee_amount,
    i.symbol,
    i.display_instrument_id2 display_instrument_id,
    i.last_trade_date,
    coalesce(e.real_exchange_id, e.exchange_id) real_exchange_id,
    tr.principal_amount,
    tr.ask_price,
    tr.bid_price,
    tr.ask_qty,
    tr.bid_qty,
    tr.trade_record_reason,
    tr.fee_sensitivity,
    i.instrument_type_id,
    tr.client_commission_rate,
    tr.customer_review_status,
    tr.remarks,
    tr.blaze_account_alias,
    tr.street_exec_broker,
    tr.street_account_name,
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
    tr.clearing_account_number,
    tr.sub_account,
    tr.allocation_avg_price,
    tr.account_nickname,
	tr.date_id,
	tr.street_mpid,
    fmj.fix_message_jsonb ->> ''10707'' AS chain_id,
    fmj.fix_message_jsonb ->> ''10708'' AS linked_id,
    fmj.fix_message_jsonb ->> ''10709'' AS source_id,
    COALESCE(fmj.fix_message_jsonb ->> ''10710'', fmj.fix_message_jsonb ->> ''9769'') AS chain_exec_id,
    fmj2.fix_message_jsonb ->> ''10701'' AS soc_gen_sub_account,
    fmj2.fix_message_jsonb ->> ''10711'' AS soc_gen_contributor_id
    from dwh.flat_trade_record tr
    --inner join dwh.d_instrument i on i.instrument_id = tr.instrument_id
    inner join lateral(select * from dwh.d_instrument i where i.instrument_id = tr.instrument_id limit 1)i on true
    inner join dwh.d_account a on tr.account_id = a.account_id and a.is_active
    left join dwh.d_exchange e on tr.exchange_id = e.exchange_id and e.is_active = true
    left join dwh.d_exchange real_exch on real_exch.exchange_id = coalesce(e.real_exchange_id, e.exchange_id) and real_exch.is_active = true
    left join lateral (select distinct description from dwh.d_liquidity_indicator li where tr.trade_liquidity_indicator=li.trade_liquidity_indicator and real_exch.exchange_id=li.exchange_id and li.is_active) liq_ind on 1=1
--    left join (select max(clearing_instr_id) clearing_instr_id, coalesce(new_trade_record_id, trade_record_id) as trade_record_id
--                FROM dwh.clearing_instruction_entry
--                GROUP BY coalesce(new_trade_record_id, trade_record_id)
--              ) cin on tr.trade_record_id = cin.trade_record_id
    left join lateral (select max(clearing_instr_id) clearing_instr_id
                FROM dwh.clearing_instruction_entry c
                where tr.trade_record_id = coalesce(c.new_trade_record_id, c.trade_record_id)
                limit 1
              ) cin on true
    left join dwh.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
    left  join dwh.d_option_contract oc on oc.instrument_id=i.instrument_id
    left join fix_capture.fix_message_json fmj on fmj.date_id = tr.date_id and fmj.fix_message_id = tr.trade_fix_message_id
    left join fix_capture.fix_message_json fmj2 on fmj2.date_id = tr.date_id and fmj2.fix_message_id = tr.order_fix_message_id
where
    tr.is_busted = ''N''
    and tr.date_id >= $1 and tr.date_id <= $2
    '||sql_params||'
order by trade_record_time desc
limit $8';


RETURN QUERY
execute select_stmt using start_status_date_id, end_status_date_id, account_ids, start_status_date, end_status_date, user_filter, is_demo, in_limit;

end;
$function$
;
