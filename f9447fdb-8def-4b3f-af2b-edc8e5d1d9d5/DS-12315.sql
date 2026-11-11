-- https://dashfinancial.atlassian.net/browse/DS-12315

alter table genesis2.sg_allocation_configuration add column if not exists operation character;
comment on column genesis2.sg_allocation_configuration.operation is 'operation type (Create, Update, Delete)';


-- DROP FUNCTION dash360.set_sg_alloc_config(int4, text, int4);

CREATE OR REPLACE FUNCTION dash360.set_sg_alloc_config(in_user_id integer, in_json text, in_sg_alloc_config_id integer DEFAULT NULL::integer)
 RETURNS SETOF tp_sg_allocation_configuration
 LANGUAGE plpgsql
AS $function$
-- SO 20260313 https://dashfinancial.atlassian.net/browse/DS-11208
-- SO 20261111 https://dashfinancial.atlassian.net/browse/DS-12315 Add operation column and refactor delete/set logic for SG_ALLOCATION_CONFIGURATION
declare
    l_sg_alloc_config_id int4;
    l_new_json           jsonb := in_json::jsonb;
--     l_old_json           jsonb;
    oblig_arr            text[];
    error_string         text;
    l_row_count          int4;
begin
    oblig_arr = array ['sg_parent_account_id', 'market_type'];
    select string_agg(x.key, ', ' order by key)
    into error_string
    from (select unnest(oblig_arr) as key
          except
          select *
          from jsonb_object_keys(l_new_json)) x;

    if error_string is not null then
        RAISE EXCEPTION 'Missed obligatory input parameters: %', error_string;
    end if;


    if in_sg_alloc_config_id is not null then

        update genesis2.sg_allocation_configuration
        set is_deleted  = 'Y',
            delete_time = clock_timestamp()
        where sg_alloc_config_id = in_sg_alloc_config_id
          and is_deleted = 'N';
        get diagnostics l_row_count = row_count;

        -- If the wrong id was passed as the input parameter raise error
        if l_row_count = 0 then
            RAISE EXCEPTION 'Passed id % was not found in the table sg_allocation_configuration', in_sg_alloc_config_id;
        end if;


    end if;

    insert
    into genesis2.sg_allocation_configuration(sg_parent_account_id, sg_alloc_config_nickname, market_type,
                                              clearing_firm, occ_actionable_id, sg_sub_account_name, sg_mint_account,
                                              sg_bdr, sg_opt_brid, sg_equity_brid, user_id, orig_sg_alloc_config_id,
                                              sg_sales_trader,
                                              sg_fund_id,
                                              sg_portfolio_id, is_deleted, operation, delete_time)
    select sg_parent_account_id,
           sg_alloc_config_nickname,
           market_type,
           clearing_firm,
           occ_actionable_id,
           sg_sub_account_name,
           sg_mint_account,
           sg_bdr,
           sg_opt_brid,
           sg_equity_brid,
           in_user_id,
           in_sg_alloc_config_id,
           sg_sales_trader,
           sg_fund_id,
           sg_portfolio_id,
           coalesce(is_deleted, 'N'),
           case
               when in_sg_alloc_config_id is not null and is_deleted = 'Y' then 'D'
               when in_sg_alloc_config_id is not null  and coalesce(is_deleted, 'N') = 'N' then 'U'
               else 'C' end,
           case
               when is_deleted = 'Y' then clock_timestamp() end
    from jsonb_populate_record(null::genesis2.sg_allocation_configuration, l_new_json)
    returning sg_alloc_config_id into l_sg_alloc_config_id;

    return query
        select sg_alloc_config_id,
               sg_parent_account_id,
               sg_alloc_config_nickname,
               market_type,
               clearing_firm,
               occ_actionable_id,
               sg_sub_account_name,
               sg_mint_account,
               sg_bdr,
               sg_opt_brid,
               sg_equity_brid,
               orig_sg_alloc_config_id,
               sg_sales_trader,
               sg_fund_id
        from genesis2.sg_allocation_configuration
        where sg_alloc_config_id = l_sg_alloc_config_id;
end
$function$
;

COMMENT ON FUNCTION dash360.set_sg_alloc_config(int4, text, int4) IS 'Creates\Updates a SG Allocation Config record depanding on passed input parameter';




-- DROP FUNCTION dash360.delete_sg_alloc_config(int4, int4);

create or replace function dash360.delete_sg_alloc_config(in_sg_alloc_config_id integer, in_user_id integer)
    returns integer
    language plpgsql
as
$function$
-- SO 20261111 https://dashfinancial.atlassian.net/browse/DS-12315 Add operation column and refactor delete/set logic for SG_ALLOCATION_CONFIGURATION
declare
    l_sg_alloc_config_id int4;
    l_row_cnt            int4;
    l_json               jsonb;
begin
    select row_to_json(sa.*)
    into l_json
    from genesis2.sg_allocation_configuration sa
    where sa.sg_alloc_config_id = in_sg_alloc_config_id;

    select count(*)
    into l_row_cnt
    from dash360.set_sg_alloc_config(in_sg_alloc_config_id,
                                     l_json::jsonb || '{
                                       "is_deleted": "Y"
                                     }'::jsonb,
                                     in_user_id);
    --     update genesis2.sg_allocation_configuration;
    --     set is_deleted  = 'Y',
    --         delete_time = clock_timestamp(),
    --         user_id     = in_user_id
    --     where sg_alloc_config_id = in_sg_alloc_config_id;
    return l_sg_alloc_config_id;
end;
$function$
;

comment on function dash360.delete_sg_alloc_config(int4, int4) is 'Deleting an existing SG Allocation Config record';
