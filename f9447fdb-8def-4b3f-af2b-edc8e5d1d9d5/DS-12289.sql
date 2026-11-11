create function dash360.report_sg_allocation_config_audit_trail(in_trading_firm_ids varchar(9)[] default null[],
                                                                in_account_ids int8 default null[],
                                                                in_start_date_id int4 default null,
                                                                in_end_date_id int4 default null)
    returns table
            (
                "Account"                varchar,
                "AccountID"              int8,
                "Trading Firm"           varchar,
                "Configuration Nickname" varchar,
                "Mint Account"           varchar,
                "BDR"                    varchar,
                "Sales Trader"           varchar,
                "Security Type"          text,
                "OCC AID"                varchar,
                "Option BRID"            varchar,
                "CMTA"                   varchar,
                "Equity BRID"            varchar,
                "Fund ID"                varchar,
                "Time"                   text,
                "User Name"              varchar,
                "Change Type"            varchar
            )
    language plpgsql
as
$fx$
    -- 20261110 SO https://dashfinancial.atlassian.net/browse/DS-12289
declare
    l_account_ids   int8[];
    l_start_date_id date := coalesce(in_start_date_id::text::date, current_date);
    l_end_date_id   date := coalesce(in_end_date_id::text::date, l_start_date_id + interval '1 day');
begin
    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from genesis2.account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}'::varchar[]) <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}'::integer[]) <> '{}'::integer[]
                      then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    return query
        select a.account_name,
               a.account_id,
               tf.trading_firm_name,
               sac.sg_alloc_config_nickname,
               sac.sg_mint_account,
               sac.sg_bdr,
               sac.sg_sales_trader,
               case when sac.market_type = 'E' then 'Equity' when sac.market_type = 'O' then 'Option' end,
               sac.occ_actionable_id,
               sac.sg_opt_brid,
               sac.clearing_firm,
               sac.sg_equity_brid,
               sac.sg_fund_id,
               to_char(sac.db_create_time, 'DD/Mon/YYYY HH12:MI:SS AM'),--??
               ui.user_name,
               ''
--         select sg_alloc_config_id, orig_sg_alloc_config_id, *
        from genesis2.sg_allocation_configuration sac
                 join genesis2.account a on sac.sg_parent_account_id = a.account_id
                 join genesis2.trading_firm tf on tf.trading_firm_id = a.trading_firm_id
                 join genesis2.user_identifier ui on ui.user_id = sac.user_id
        where sac.is_deleted = 'N'
          and case when l_account_ids = '{}' then true else sac.sg_parent_account_id = any (l_account_ids) end --check performance
          and db_create_time between l_start_date_id and l_end_date_id;
    ;

end ;
$fx$;



        select sg_alloc_config_id, orig_sg_alloc_config_id, db_create_time, delete_time, is_deleted, *
        from genesis2.sg_allocation_configuration sac
--         where sg_parent_account_id = 267645
        order by sg_parent_account_id, sg_alloc_config_nickname, sg_alloc_config_id, orig_sg_alloc_config_id;

        select sg_alloc_config_id, orig_sg_alloc_config_id, db_create_time, delete_time, is_deleted, *
        from genesis2.sg_allocation_configuration sac
            where orig_sg_alloc_config_id = 3292