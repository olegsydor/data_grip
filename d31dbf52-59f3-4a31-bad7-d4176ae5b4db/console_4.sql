CREATE OR REPLACE FUNCTION dash360.get_street_orders_trade_activity(in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                    in_exchange_ids character varying[] DEFAULT '{}'::character varying(6)[],
                                                                    in_start_date date DEFAULT CURRENT_DATE,
                                                                    in_end_date date DEFAULT CURRENT_DATE)
    RETURNS TABLE
            (
                parent_client_order_id    character varying,
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                exec_time_orig            timestamp without time zone,
                exec_time                 text,
                exec_type                 character varying,
                order_status              character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
-- 2023-06-29 https://dashfinancial.atlassian.net/browse/DS-6950
begin
    return query
        select po.client_order_id                     as parent_client_order_id,
               co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name
/*        from dwh.execution ex
                 inner join dwh.client_order co on co.order_id = ex.order_id
                 inner join dwh.client_order po on po.order_id = co.parent_order_id
                 inner join dwh.d_account acc on co.account_id = acc.account_id
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
          and case when coalesce(in_account_ids, '{}') = '{}' then true else co.account_id = any (in_account_ids) end
          and case when coalesce(in_exchange_ids, '{}') = '{}' then true else ex.exchange_id = any (in_exchange_ids) end
          and ex.exec_date_id >= public.get_dateid(in_start_date)
          and ex.exec_date_id <= public.get_dateid(in_end_date + 1)
          and co.parent_order_id is not null;
*/
        from dwh.execution ex
                 join lateral (select client_order_id,
                                      exch_order_id,
                                      order_id,
                                      side,
                                      order_qty,
                                      price,
                                      parent_order_id,
                                      account_id,
                                      instrument_id,
                                      time_in_force_id,
                                      sub_system_unq_id,
                                      multileg_reporting_type,
                                      create_date_id
                               from dwh.client_order co
                               where co.order_id = ex.order_id
                                 and case
                                         when coalesce(:in_account_ids, '{}') = '{}' then true
                                         else co.account_id = any (:in_account_ids) end
                                 and co.create_date_id <= ex.exec_date_id
                               limit 1) co on true
                 inner join dwh.client_order po
                            on po.order_id = co.parent_order_id and po.create_date_id <= co.create_date_id
                 inner join dwh.d_account acc on co.account_id = acc.account_id
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
--           and case when coalesce(in_exchange_ids, '{}') = '{}' then true else ex.exchange_id = any (in_exchange_ids) end
          and ex.exec_date_id >= public.get_dateid(:in_start_date)
          and ex.exec_date_id <= public.get_dateid(:in_end_date + 1)
    and not ex.is_parent_level;
end;
$function$
;


with aliasesToInsert as (
    SELECT distinct
        update_time,
        is_deleted,
        deleted_time,
        deleted_by,
        reference_alias_id,
        user_id,
        account_alias,
        account,
        CASE
            WHEN option_range = ANY (@RangeNames)
                THEN option_range
            ELSE
                null
            END AS option_range,
        equity_range,
        CASE
            WHEN cmta = ANY (@CMTAs)
                THEN cmta
            ELSE
                null
            END AS cmta,
        CASE
            WHEN give_up = ANY (@GiveUps)
                THEN give_up
            ELSE
                null
            END as give_up,
        mpid,
        ftid,
        CASE
            WHEN customer_user_id = user_id
                THEN @TargetUserId
            WHEN customer_user_id = ANY (@CustomerUserIds)
                THEN customer_user_id
            WHEN customer_user_id IS NULL OR customer_user_id = 0
                THEN @TargetUserId
            ELSE
                @TargetUserId
        END as customer_user_id,
        CASE
            WHEN dash_alias_id = ANY (@DashAliases)
                THEN dash_alias_id
            ELSE
                null
            END as dash_alias_id,
        locate_id,
        sub_acct_1,
        sub_acct_2,
        sub_acct_3,
        commission,
        soc_gen_salestrader,
        soc_gen_capacity,
        NULL::int4 AS soc_gen_portfolio_id, -- portfolios are not shared between users
        broker_dealer,
        fdid,
        account_holder_type,
        imid,
        affiliate_flag,
        is_representative,
        alias_button_orig_side,
        alias_button_contra_side,
        creation_source,
        last_updated_source,
        actionable_id_ref,
        updated_by,
        equity_route_type,
        equity_route_destination,
        equity_destination_entity_id,
        single_option_route_type,
        single_option_route_destination,
        spread_option_route_type,
        spread_option_route_destination,
        spread_with_stock_route_type,
        spread_with_stock_route_destination,
        cross_single_option_route_type,
        cross_single_option_route_destination,
        cross_single_option_mechanism,
        cross_spread_option_route_type,
        cross_spread_option_route_destination,
        cross_spread_option_mechanism,
        cross_spread_with_stock_route_type,
        cross_spread_with_stock_route_destination,
        cross_spread_with_stock_mechanism,
        single_option_destination_entity_id,
        spread_option_destination_entity_id,
        spread_with_stock_destination_entity_id,
        cross_single_option_destination_entity_id,
        cross_spread_option_destination_entity_id,
        cross_spread_with_stock_destination_entity_id,
        еquity_сboe_par_destination,
        single_option_сboe_par_destination,
        spread_option_сboe_par_destination,
        spread_with_stock_сboe_par_destination,
        client_info
        FROM blaze7_settings.user_account_alias
        where user_id <> 0 and is_deleted is not true
        and alias_id = ANY(@AliasesIds)
    )
    insert into blaze7_settings.user_account_alias(update_time, is_deleted, deleted_time,
    deleted_by, reference_alias_id, user_id, account_alias, account, option_range, equity_range,
    cmta, give_up, mpid, ftid, customer_user_id, dash_alias_id, locate_id, sub_acct_1, sub_acct_2,
    sub_acct_3, commission, soc_gen_salestrader, soc_gen_capacity, soc_gen_portfolio_id, broker_dealer, fdid,
    account_holder_type, imid, affiliate_flag, is_representative, alias_button_orig_side, alias_button_contra_side, creation_source,
    last_updated_source, actionable_id_ref, updated_by, manual_create_time,
    equity_route_type,
    equity_route_destination,
    equity_destination_entity_id,
    single_option_route_type,
    single_option_route_destination,
    spread_option_route_type,
    spread_option_route_destination,
    spread_with_stock_route_type,
    spread_with_stock_route_destination,
    cross_single_option_route_type,
    cross_single_option_route_destination,
    cross_single_option_mechanism,
    cross_spread_option_route_type,
    cross_spread_option_route_destination,
    cross_spread_option_mechanism,
    cross_spread_with_stock_route_type,
    cross_spread_with_stock_route_destination,
    cross_spread_with_stock_mechanism,
    single_option_destination_entity_id,
    spread_option_destination_entity_id,
    spread_with_stock_destination_entity_id,
    cross_single_option_destination_entity_id,
    cross_spread_option_destination_entity_id,
    cross_spread_with_stock_destination_entity_id,
    еquity_сboe_par_destination,
    single_option_сboe_par_destination,
    spread_option_сboe_par_destination,
    spread_with_stock_сboe_par_destination,
    client_info)
    SELECT NOW(), is_deleted, deleted_time,
    deleted_by, NULL, @TargetUserId, account_alias, account, option_range, equity_range,
    cmta, give_up, mpid, ftid, customer_user_id, dash_alias_id, locate_id, sub_acct_1, sub_acct_2,
    sub_acct_3, commission, soc_gen_salestrader, soc_gen_capacity, soc_gen_portfolio_id, broker_dealer, fdid,
    account_holder_type, imid, affiliate_flag, is_representative, 'N', 'N', 'A',
    'A', actionable_id_ref, @UserId, NOW(),
    equity_route_type,
    equity_route_destination,
    equity_destination_entity_id,
    single_option_route_type,
    single_option_route_destination,
    spread_option_route_type,
    spread_option_route_destination,
    spread_with_stock_route_type,
    spread_with_stock_route_destination,
    cross_single_option_route_type,
    cross_single_option_route_destination,
    cross_single_option_mechanism,
    cross_spread_option_route_type,
    cross_spread_option_route_destination,
    cross_spread_option_mechanism,
    cross_spread_with_stock_route_type,
    cross_spread_with_stock_route_destination,
    cross_spread_with_stock_mechanism,
    single_option_destination_entity_id,
    spread_option_destination_entity_id,
    spread_with_stock_destination_entity_id,
    cross_single_option_destination_entity_id,
    cross_spread_option_destination_entity_id,
    cross_spread_with_stock_destination_entity_id,
    еquity_сboe_par_destination,
    single_option_сboe_par_destination,
    spread_option_сboe_par_destination,
    spread_with_stock_сboe_par_destination,
    client_info
    from aliasesToInsert
    WHERE option_range is not null AND give_up is not null
    ON conflict(user_id, account_alias) WHERE (is_deleted is null or is_deleted <> true )
DO UPDATE SET
    account = excluded.account,
    option_range = excluded.option_range,
    equity_range = excluded.equity_range,
    cmta = excluded.cmta,
    give_up = excluded.give_up,
    mpid = excluded.mpid,
    ftid = excluded.ftid,
    customer_user_id = excluded.customer_user_id,
    dash_alias_id = excluded.dash_alias_id,
    locate_id = excluded.locate_id,
    sub_acct_1 = excluded.sub_acct_1,
    sub_acct_2 = excluded.sub_acct_2,
    sub_acct_3 = excluded.sub_acct_3,
    commission = excluded.commission,
    soc_gen_salestrader = excluded.soc_gen_salestrader,
    soc_gen_capacity = excluded.soc_gen_capacity,
    soc_gen_portfolio_id = excluded.soc_gen_portfolio_id,
    broker_dealer = excluded.broker_dealer,
    fdid = excluded.fdid,
    account_holder_type = excluded.account_holder_type,
    imid = excluded.imid,
    affiliate_flag = excluded.affiliate_flag,
    is_representative = excluded.is_representative,
    alias_button_orig_side = 'N',
    alias_button_contra_side = 'N',
    actionable_id_ref = excluded.actionable_id_ref,
    update_time = NOW(),
    last_updated_source = 'A',
    equity_route_type = excluded.equity_route_type,
    equity_route_destination = excluded.equity_route_destination,
    equity_destination_entity_id = excluded.equity_destination_entity_id,
    single_option_route_type = excluded.single_option_route_type,
    single_option_route_destination = excluded.single_option_route_destination,
    spread_option_route_type = excluded.spread_option_route_type,
    spread_option_route_destination = excluded.spread_option_route_destination,
    spread_with_stock_route_type = excluded.spread_with_stock_route_type,
    spread_with_stock_route_destination = excluded.spread_with_stock_route_destination,
    cross_single_option_route_type = excluded.cross_single_option_route_type,
    cross_single_option_route_destination = excluded.cross_single_option_route_destination,
    cross_single_option_mechanism = excluded.cross_single_option_mechanism,
    cross_spread_option_route_type = excluded.cross_spread_option_route_type,
    cross_spread_option_route_destination = excluded.cross_spread_option_route_destination,
    cross_spread_option_mechanism = excluded.cross_spread_option_mechanism,
    cross_spread_with_stock_route_type = excluded.cross_spread_with_stock_route_type,
    cross_spread_with_stock_route_destination = excluded.cross_spread_with_stock_route_destination,
    cross_spread_with_stock_mechanism = excluded.cross_spread_with_stock_mechanism,
    single_option_destination_entity_id  = excluded.single_option_destination_entity_id,
    spread_option_destination_entity_id = excluded.spread_option_destination_entity_id,
    spread_with_stock_destination_entity_id = excluded.spread_with_stock_destination_entity_id,
    cross_single_option_destination_entity_id = excluded.cross_single_option_destination_entity_id,
    cross_spread_option_destination_entity_id = excluded.cross_spread_option_destination_entity_id,
    cross_spread_with_stock_destination_entity_id = excluded.cross_spread_with_stock_destination_entity_id,
    еquity_сboe_par_destination = excluded.еquity_сboe_par_destination,
    single_option_сboe_par_destination = excluded.single_option_сboe_par_destination,
    spread_option_сboe_par_destination = excluded.spread_option_сboe_par_destination,
    spread_with_stock_сboe_par_destination = excluded.spread_with_stock_сboe_par_destination,
    client_info = excluded.client_info
    RETURNING *;


CREATE OR REPLACE FUNCTION dash360.get_parent_orders_trade_activity(in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                    in_exchange_ids character varying[] DEFAULT '{}'::character varying(6)[],
                                                                    in_start_date date DEFAULT CURRENT_DATE,
                                                                    in_end_date date DEFAULT CURRENT_DATE)
    RETURNS TABLE
            (
                client_order_id           character varying,
                exch_order_id             character varying,
                order_id                  bigint,
                side                      character,
                order_qty                 integer,
                price                     numeric,
                time_in_force             character varying,
                instrument_name           character varying,
                last_trade_date           timestamp without time zone,
                account_name              character varying,
                sub_system_id             character varying,
                multileg_reporting_type   character,
                exec_id                   bigint,
                ref_exec_id               bigint,
                exch_exec_id              character varying,
                exec_time_orig            timestamp without time zone,
                exec_time                 text,
                exec_type                 character varying,
                order_status              character varying,
                leaves_qty                bigint,
                cum_qty                   bigint,
                avg_px                    numeric,
                last_qty                  bigint,
                last_px                   numeric,
                bust_qty                  bigint,
                last_mkt                  character varying,
                last_mkt_name             character varying,
                text_                     character varying,
                trade_liquidity_indicator character varying,
                is_busted                 character,
                exec_broker               character varying,
                exchange_id               character varying,
                exchange_name             character varying
            )
    LANGUAGE plpgsql
AS
$function$
declare
-- 2023-06-29 https://dashfinancial.atlassian.net/browse/DS-6950
begin
    return query
        select co.client_order_id,
               co.exch_order_id,
               ex.order_id,
               co.side,
               co.order_qty,
               co.price,
               tif.tif_short_name                        time_in_force,
               inst.instrument_name,
               inst.last_trade_date,
               acc.account_name,
               dss.sub_system_id,
               co.multileg_reporting_type,
               ex.exec_id,
               ex.ref_exec_id,
               ex.exch_exec_id,
               ex.exec_time                           as exec_time_orig,
               to_char(ex.exec_time, 'HH12:MI:SS.MS') as exec_time,
               et.exec_type_description               as exec_type,
               os.order_status_description            as order_status,
               ex.leaves_qty,
               ex.cum_qty,
               ex.avg_px,
               ex.last_qty,
               ex.last_px,
               ex.bust_qty,
               ex.last_mkt,
               lm.last_mkt_name                       as last_mkt_name,
               ex.text_,
               ex.trade_liquidity_indicator,
               ex.is_busted,
               ex.exec_broker,
               ex.exchange_id,
               e.exchange_name
        from dwh.execution ex
--                  inner join dwh.client_order co on ex.order_id = co.order_id
                 join lateral (select co.client_order_id,
                                      co.exch_order_id,
                                      co.order_id,
                                      co.side,
                                      co.order_qty,
                                      co.price,
                                      co.parent_order_id,
                                      co.account_id,
                                      co.instrument_id,
                                      co.time_in_force_id,
                                      co.sub_system_unq_id,
                                      co.multileg_reporting_type,
                                      co.create_date_id
                               from dwh.client_order co
                               where co.order_id = ex.order_id
                                 and case
                                         when coalesce(in_account_ids, '{}') = '{}' then true
                                         else co.account_id = any (in_account_ids) end
                                 and co.create_date_id <= ex.exec_date_id
                                 and co.parent_order_id is null
                               limit 1) co on true
                 inner join dwh.d_account acc on co.account_id = acc.account_id
                 inner join dwh.d_instrument inst on co.instrument_id = inst.instrument_id
                 left join dwh.d_time_in_force tif on co.time_in_force_id = tif.tif_id
                 left join dwh.d_order_status os on os.order_status = ex.order_status
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = co.sub_system_unq_id
                 left join dwh.d_last_market lm on lm.last_mkt = ex.last_mkt and lm.is_active
                 left join dwh.d_exchange e on e.exchange_id = ex.exchange_id and e.is_active
                 left join dwh.d_exec_type et on et.exec_type = ex.exec_type
        where ex.exec_type in ('F', 'H')
--           and case when in_account_ids is null then true else co.account_id = any (in_account_ids) end
          and case when coalesce(in_exchange_ids, '{}') = '{}' then true else ex.exchange_id = any (in_exchange_ids) end
          and ex.exec_date_id >= public.get_dateid(in_start_date)
          and ex.exec_date_id < public.get_dateid(in_start_date + 1)
          and ex.is_parent_level;
end;
$function$
;
