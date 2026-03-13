-- genesis2.tp_sg_allocation_configuration definition

SELECT oid FROM pg_type WHERE typname = 'tp_sg_allocation_configuration';

SELECT
    dep.objid::regclass AS dependent_object,
    dep.classid::regclass AS dependent_object_type,
    dep.objsubid AS dependent_attribute_number,
    dep.refobjid::regclass AS referenced_object,
    p.*
FROM
    pg_depend dep
   JOIN pg_proc p ON dep.objid = p.oid
WHERE
    dep.refobjid = 436442723::regclass -- Use your type's OID here
    AND dep.deptype = 'n';


alter type genesis2.tp_sg_allocation_configuration drop attribute sg_portfolio_id;


CREATE OR REPLACE FUNCTION dash360.set_sg_alloc_config(in_user_id integer, in_json text, in_sg_alloc_config_id integer DEFAULT NULL::integer)
 RETURNS SETOF tp_sg_allocation_configuration
 LANGUAGE plpgsql
AS $function$
-- SO 20260313 https://dashfinancial.atlassian.net/browse/DS-11208
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
            delete_time = clock_timestamp(),
            user_id     = in_user_id
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
                                              sg_portfolio_id)
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
           sg_portfolio_id
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
--                sg_portfolio_id
        from genesis2.sg_allocation_configuration
        where sg_alloc_config_id = l_sg_alloc_config_id;
end
$function$
;

COMMENT ON FUNCTION dash360.set_sg_alloc_config(int4, text, int4) IS 'Creates\Updates a SG Allocation Config record depanding on passed input parameter';


-- DROP FUNCTION dash360.get_sg_alloc_config(_int8, _int4, bool);

CREATE OR REPLACE FUNCTION dash360.get_sg_alloc_config(in_parent_account_id bigint[] DEFAULT NULL::integer[], in_sg_alloc_config_id integer[] DEFAULT NULL::integer[], in_include_deleted boolean DEFAULT false)
 RETURNS SETOF tp_sg_allocation_configuration
 LANGUAGE plpgsql
AS $function$
declare
-- SO 20260208 https://dashfinancial.atlassian.net/browse/DS-11067 init
-- SO 20260212 https://dashfinancial.atlassian.net/browse/DS-11090 add in_include_deleted
-- SO 20260313 https://dashfinancial.atlassian.net/browse/DS-11208
begin
    return query
        select sac.sg_alloc_config_id,
               sac.sg_parent_account_id,
               sac.sg_alloc_config_nickname,
               sac.market_type,
               sac.clearing_firm,
               sac.occ_actionable_id,
               sac.sg_sub_account_name,
               sac.sg_mint_account,
               sac.sg_bdr,
               sac.sg_opt_brid,
               sac.sg_equity_brid,
               sac.orig_sg_alloc_config_id,
               sac.sg_sales_trader,
               sac.sg_fund_id
--                sac.sg_portfolio_id
        from genesis2.sg_allocation_configuration sac
        where true
          and case
                  when in_parent_account_id is null then true
                  else sg_parent_account_id = any (in_parent_account_id) end
          and case
                  when in_sg_alloc_config_id is null then true
                  else sg_alloc_config_id = any (in_sg_alloc_config_id) end
          and case
                  when coalesce(in_include_deleted, true) then true
                  when not in_include_deleted then is_deleted = 'N' end;
end;
$function$
;

COMMENT ON FUNCTION dash360.get_sg_alloc_config(_int8, _int4, bool) IS 'Returns SG Allocation Config by provided filter';
