
IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (SG_ACCOUNT)
FROM SERVER oracle_prod INTO staging;


select * from staging.sg_account
-- DROP FUNCTION dash360.allocations_set_account_config(int8, text, bpchar, bpchar, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_set_account_config(in_account_id bigint, in_clearing_accounts text, in_is_auto_allocate character DEFAULT NULL::character(1), in_instrumnt_type_id character DEFAULT 'O'::bpchar, in_user_id integer DEFAULT NULL::integer, in_is_intraday_auto_allocate character DEFAULT NULL::bpchar)
 RETURNS integer
 LANGUAGE plpgsql
 COST 1
AS $function$
    -- MG: 20210413 add support to is_option_auto_allocate field
-- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208 is_visible_for_manual_allocation  and user_id fields have been introduced
-- OS: 20250604 https://dashfinancial.atlassian.net/browse/DS-10060 added is_intraday_auto_allocate, removed #variable_conflict use_variable
-- OS: 20251031 https://dashfinancial.atlassian.net/browse/DS-10634 added 'sg_brid', 'sg_sub_account_name'
-- OS: 20251113 https://dashfinancial.atlassian.net/browse/DS-10719 Supress BRID and SubAccount in clone function

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
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio, is_auto_alloc_to,
                                           sg_brid, sg_sub_account_name)
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
           sj ->> 'auto_alloc_to',
           case when in_account_id in (select account_id from staging.sg_account) then  sj ->> 'sg_brid' end,
           case when in_account_id in (select account_id from staging.sg_account) then  sj ->> 'sg_sub_account_name' end
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;
