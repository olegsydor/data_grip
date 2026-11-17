-- DROP FUNCTION dash360.report_sg_allocation_config_audit_trail(_varchar, _int8, int4, int4);

create or replace function dash360.report_sg_allocation_config_audit_trail(in_trading_firm_ids character varying[] default null::character varying(9)[],
                                                                           in_account_ids bigint[] default null::bigint[],
                                                                           in_start_date_id integer default null::integer,
                                                                           in_end_date_id integer default null::integer)
    returns table
            (
                "Account"                character varying,
                "AccountID"              bigint,
                "Trading Firm"           character varying,
                "Configuration Nickname" character varying,
                "Mint Account"           character varying,
                "BDR"                    character varying,
                "Sales Trader"           character varying,
                "Security Type"          text,
                "OCC AID"                character varying,
                "Option BRID"            character varying,
                "CMTA"                   character varying,
                "Equity BRID"            character varying,
                "Fund ID"                character varying,
                "Time"                   text,
                "User Name"              character varying,
                "Change Type"            character
            )
    language plpgsql
as
$function$
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
                  when coalesce(in_account_ids, '{}'::integer[]) <> '{}'::int8[]
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
               concat_ws('-', sac.sg_equity_brid, firm_name)::character varying,
               sac.sg_fund_id,
               to_char(coalesce(/*sac.delete_time, */sac.db_create_time), 'DD/Mon/YYYY HH12:MI:SS AM'),
               ui.user_name,
               sac.operation
--         select sg_alloc_config_id, orig_sg_alloc_config_id, *
        from genesis2.sg_allocation_configuration sac
                 join genesis2.account a on sac.sg_parent_account_id = a.account_id
                 join genesis2.trading_firm tf on tf.trading_firm_id = a.trading_firm_id
                 join genesis2.user_identifier ui on ui.user_id = sac.user_id
        left join lateral (select firm_name from staging.occ_member_directory omd where omd.firm_num = sac.clearing_firm limit 1) omd on true
        where sac.is_deleted = 'N'
          and case
                  when l_account_ids = '{}' then true
                  else sac.sg_parent_account_id = any (l_account_ids) end --check performance
          and db_create_time between l_start_date_id and l_end_date_id;

end ;
$function$
;


select *
from dash360.report_sg_allocation_config_audit_trail(in_account_ids := '{263455,263774}', in_start_date_id := 20260101,
                                                     in_end_date_id := 20261112)


)
SERVER postgresbig_data
OPTIONS (schema_name 'dwh', table_name 'd_account');


select distinct t.table_schema
                , t.table_name
--                , c.column_name
--                , data_type
from information_schema.tables t
         inner join information_schema.columns c on (c.table_name = t.table_name and c.table_schema = t.table_schema)
where true
and t.table_schema not in
      ('trash', 'information_schema', 'pg_catalog', 'dm_partitions', 'ot_partitions', 'partitions', 'cmp_partitions',
       'md_partitions', 'fc_partitions', 'fc_partitions_tmp_hft', 'external_data_partitions', 'daily_partitions', 'billing_partition', 'exchange_data_partition')
  and t.table_name ilike '%occ_member%'

select * from external_data.occ_members_2_billingcustomer;


SERVER
OPTIONS (schema_name 'dwh', table_name 'd_option_series');


IMPORT FOREIGN SCHEMA external_data LIMIT TO (occ_member_directory)
FROM SERVER postgres_big_data
into staging;

select * from staging.occ_member_directory