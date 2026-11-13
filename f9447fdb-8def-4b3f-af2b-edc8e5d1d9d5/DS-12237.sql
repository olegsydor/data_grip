-- https://dashfinancial.atlassian.net/browse/DS-12237
-- DROP FUNCTION dash360.allocations_clearing_accounts_by_account_id(int8, bpchar);

CREATE FUNCTION dash360.allocations_clearing_accounts_by_account_id_vers2(in_account_id bigint, in_market_type character)
    RETURNS TABLE
            (
                clearing_account_id              integer,
                clearing_account_number          character varying,
                clearing_account_name            character varying,
                is_default                       character,
                clearing_account_type            character,
                market_type                      character,
                cmta                             character varying,
                occ_actionable_id                character varying,
                account_id                       integer,
                is_visible_for_manual_allocation boolean,
                auto_alloc_ratio                 numeric,
                is_auto_alloc_to                 character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208
-- SO: 20250610 https://dashfinancial.atlassian.net/browse/D360-15839
-- SO: 20251103 https://dashfinancial.atlassian.net/browse/D360-16593
-- SO: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
-- SO: 20261113 https://dashfinancial.atlassian.net/browse/DS-12237 Remove depreciated SocGen Functionality from some Allocation functions
begin

    return query
        select ca.clearing_account_id::integer,
               ca.clearing_account_number,
               ca.clearing_account_name,
               ca.is_default::character,
               ca.clearing_account_type::character,
               ca.market_type::character,
               ca.cmta,
               ca.occ_actionable_id,
               ca.account_id,
               ca.is_visible_for_manual_allocation,
               ca.auto_alloc_ratio,
               ca.is_auto_alloc_to
        from genesis2.clearing_account ca
        where ca.account_id = in_account_id
          and ca.market_type = in_market_type
          and ca.is_deleted = 'N'
        order by ca.is_default desc, ca.clearing_account_number;

end;
$function$
;

-- DROP FUNCTION dash360.allocations_get_accounts_config(bpchar, _int8);

CREATE FUNCTION dash360.allocations_get_accounts_config_vers2(in_market_type character DEFAULT 'O'::character(1),
                                                                   in_account_ids bigint[] DEFAULT '{}'::bigint[])
    RETURNS TABLE
            (
                account_id                bigint,
                is_auto_allocate          character,
                clearing_accounts         jsonb,
                is_intraday_auto_allocate character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- MG: 20210413 -- add is_option_auto_allocate field to output
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208   The is_visible_for_manual_allocation field has been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20250626 without ticket added new input parameter in_account_ids (back-end will call this procedure per account instead of cache)
-- OS: 20251031 https://dashfinancial.atlassian.net/browse/DS-10634 added 'sg_brid', 'sg_sub_account_name'
-- OS: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
-- OS: 20261113 https://dashfinancial.atlassian.net/browse/DS-12237 Remove depreciated SocGen Functionality from some Allocation functions
begin
    return query
        select acc.account_id::bigint,
               (case
                    when in_market_type = 'E' then acc.is_auto_allocate
                    when in_market_type = 'O' then acc.is_option_auto_allocate
                    else acc.is_auto_allocate
                   end) as is_auto_allocate,
               jsonb_agg(jsonb_object(
                       array ['ca_number', 'def' , 'ca_name', 'oaid', 'visible', 'alloc_ratio', 'auto_alloc_to'],
                       array [ca.clearing_account_number, ca.is_default , ca.clearing_account_name, ca.occ_actionable_id, ca.is_visible_for_manual_allocation::text, ca.auto_alloc_ratio::text, ca.is_auto_alloc_to])),
               acc.is_intraday_auto_allocate
        from genesis2.account acc
                 inner join genesis2.clearing_account ca
                            on acc.account_id = ca.account_id
                                and ca.is_deleted = 'N'
                                and ca.market_type = in_market_type
        where acc.is_deleted = 'N'
          and case when coalesce(in_account_ids, '{}') = '{}' then true else acc.account_id = any (in_account_ids) end
        group by acc.account_id,
                 (case
                      when in_market_type = 'E' then acc.is_auto_allocate
                      when in_market_type = 'O' then acc.is_option_auto_allocate
                      else acc.is_auto_allocate
                     end)
--limit 10
    ;

end;
$function$
;


-- DROP FUNCTION dash360.allocations_set_account_config(int8, text, bpchar, bpchar, int4, bpchar);

CREATE FUNCTION dash360.allocations_set_account_config_vers2(in_account_id bigint, in_clearing_accounts text,
                                                                  in_is_auto_allocate character DEFAULT NULL::character(1),
                                                                  in_instrumnt_type_id character DEFAULT 'O'::bpchar,
                                                                  in_user_id integer DEFAULT NULL::integer,
                                                                  in_is_intraday_auto_allocate character DEFAULT NULL::bpchar)
    RETURNS integer
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- MG: 20210413 add support to is_option_auto_allocate field
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208 is_visible_for_manual_allocation  and user_id fields have been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20251031 https://dashfinancial.atlassian.net/browse/DS-10634 added 'sg_brid', 'sg_sub_account_name'
-- OS: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
-- OS: 20261113 https://dashfinancial.atlassian.net/browse/DS-12237 Remove depreciated SocGen Functionality from some Allocation functions

declare
    l_clearing_account_type smallint;
    l_row_cnt               int;
    l_clearing_accounts jsonb;

begin
    l_clearing_accounts := in_clearing_accounts::jsonb;
    if in_instrumnt_type_id = 'E' and in_is_auto_allocate is not null
    then
-- set is_autoallocate value
        update account acc
        set is_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_instrumnt_type_id = 'O' and in_is_auto_allocate is not null
    then
-- set is_option_auto_allocate value
        update account acc
        set is_option_auto_allocate = in_is_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
          and acc.is_option_auto_allocate <> in_is_auto_allocate;
    end if;

    if in_is_intraday_auto_allocate is not null then
        update account acc
        set is_intraday_auto_allocate = in_is_intraday_auto_allocate
        where acc.account_id = in_account_id
          and acc.is_deleted = 'N'
--           and acc.is_option_auto_allocate <> in_is_auto_allocate
        ;
    end if;


-- close all current configuration for the account if any

    update genesis2.clearing_account
    set is_deleted  = 'Y',
        delete_time = clock_timestamp(),
        user_id     = in_user_id
    where account_id = in_account_id
      and market_type = in_instrumnt_type_id
      and is_deleted = 'N';

    -- get  clearing_account_type

--  select case sum(case instrument_type_id when in_instrumnt_type_id then 1 else 0 end)
--          when 1 then count(1)
--          else 2 -- Temporary solution. For some reason account_id could be missed in account2instrument_type
--          end  as  clearing_account_type
--  into l_clearing_account_type
--  from staging.account2instrument_type ait
--  where account_id = in_account_id
--    and instrument_type_id  in ('E', 'O');

    -- Temporary logc SY:20201215 as per chat with Tim Miller
    l_clearing_account_type := 1;


    insert into genesis2.clearing_account (account_id, clearing_account_type, clearing_account_number, is_default,
                                           market_type, is_deleted, cmta, clearing_account_name, occ_actionable_id,
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio, is_auto_alloc_to
                                           )
    select in_account_id,
           l_clearing_account_type::varchar,
           sj ->> 'ca_number'             as clearing_account_number,
           sj ->> 'def'                   as is_default,
           in_instrumnt_type_id           as market_type,
           --clock_timestamp() as  create_time,
           'N'                            as is_deleted,
           sj ->> 'ca_number'             as cmta,
           coalesce(sj ->> 'ca_name', '') as clearing_account_name,
           sj ->> 'oaid'                  as occ_actionable_id,
           in_user_id,
           (sj ->> 'visible')::bool       as is_visible_for_manual_allocation,
           coalesce((sj ->> 'alloc_ratio')::numeric, 1),
           sj ->> 'auto_alloc_to'
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;

-- DROP FUNCTION dash360.allocations_instruction_entries(int4, int4);

CREATE FUNCTION dash360.allocations_instruction_entries_vers2(in_alloc_instr_id integer, in_date_id integer)
    RETURNS TABLE
            (
                clearing_account_number         character varying,
                clearing_account_name           character varying,
                clearing_account_type           character,
                cmta                            character varying,
                is_default                      character,
                alloc_qty                       integer,
                occ_actionable_id               character varying,
                clearing_account_id             integer,
                account_nickname                character varying,
                account_id                      integer,
                sg_alloc_config_id              integer,
                allocation_instruction_entry_id bigint,
                clearing_submitted_away         character
            )
    LANGUAGE plpgsql
    COST 1
AS $function$
    -- SO: 20251103 https://dashfinancial.atlassian.net/browse/D360-16593
    -- SO: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
    -- SO: 20260210 https://dashfinancial.atlassian.net/browse/DS-11079 added sg_allocation_configuration
    -- SO: 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
    -- SO: 20261113 https://dashfinancial.atlassian.net/browse/DS-12237 Remove depreciated SocGen Functionality from some Allocation functions
begin

    return query
        select ca.clearing_account_number,
               ca.clearing_account_name,
               ca.clearing_account_type::character,
               ca.cmta,
               ca.is_default::character,
               e.alloc_qty,
               e.occ_actionable_id,
               ca.clearing_account_id,
               e.account_nickname,
               a.account_id,
               e.sg_alloc_config_id,
               e.allocation_instruction_entry_id,
               a.clearing_submitted_away
        from genesis2.allocation_instruction_entry e
                 inner join genesis2.allocation_instruction a
                            on a.alloc_instr_id = e.alloc_instr_id and a.is_deleted = 'N' and a.date_id = in_date_id
                 inner join genesis2.clearing_account ca
                            on e.clearing_account_id = ca.clearing_account_id /*and ca.is_deleted = 'N'*/ /* No need to is_deleted ='N' because clearing_account_id is surrogate key and we SCD inside the dimension*/
        where true
        and e.alloc_instr_id = in_alloc_instr_id
          and e.date_id = in_date_id
          and e.alloc_qty > 0;
end;
$function$
;
