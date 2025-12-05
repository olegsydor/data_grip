alter table genesis2.clearing_account
    add column if not exists sg_brid varchar;
comment on column genesis2.clearing_account.sg_brid is 'SG allocation field used for populating tag in 35=J. Copy from SG_ACCOUNT value';

alter table genesis2.clearing_account
    add column if not exists sg_sub_account_name varchar;
comment on column genesis2.clearing_account.sg_sub_account_name is 'SG allocation field used for populating tag in 35=J. Copy from SG_SUB_ACCOUNT value';

alter table genesis2.clearing_account
    add column if not exists sg_mint_account varchar;
comment on column genesis2.clearing_account.sg_mint_account is 'SG allocation field used for populating tag in 35=J. Copy from SG_MINT_ACCOUNT value';


create or replace function dash360.get_data_for_allocations(in_alloc_instr_id int8, in_date_id int4 default null)
    returns jsonb
    language plpgsql
as
$fx$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay',
                                                  case
                                                      when di.instrument_type_id = 'O'
                                                          then to_char(oc.maturity_day, 'FM00') end,
                                                  'maturityMonthYear', case
                                                                           when di.instrument_type_id = 'O' then
                                                                               to_char(oc.maturity_year, 'FM0000') ||
                                                                               to_char(oc.maturity_month, 'FM00') end,
                                                  'totalQty', ai.total_qty,
                                                  'avgPx', ai.avg_px,
                                                  'noExecs', aitr.trade_cnt,
                                                  'trades', aitr.trades,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'brid', ca.sg_brid,
                                                               'subAccount', ca.sg_sub_account_name,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'sgMintAccount', ca.sg_mint_account))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
--                                                  and ca.clearing_account_type = '1'
--                                                  and ca.market_type = di.instrument_type_id
                                                  )
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             join lateral (select count(*) as trade_cnt,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )        as trades
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                                    join lateral (select fix_message ->> '10710' as chain_exec_id
                                                  from staging.fix_message_json fmj
                                                  where fmj.date_id = aitr.date_id
                                                    and fmj.fix_message_id = tr.trade_fix_message_id
                                                  limit 1) fmj on true
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
--                              and is_busted = 'N'
                           limit 1) aitr on true

             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end;
$fx$;

select alloc_instr_id, dash360.get_data_for_allocations(ai.alloc_instr_id, ai.date_id)
from genesis2.allocation_instruction ai
where date_id = 20251023;


select dash360.get_data_for_allocations(-99683, 20251023);
select dash360.get_data_for_allocations(-99683);



comment on column genesis2.clearing_account.clearing_account_type is '0: DVP,1: CMTA,2: Domicile,3: Non-allocated';


-- DROP FUNCTION dash360.allocations_get_accounts_config(bpchar, _int8);

CREATE OR REPLACE FUNCTION dash360.allocations_get_accounts_config(in_market_type character DEFAULT 'O'::character(1),
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
begin
    return query
        select acc.account_id::bigint,
               (case
                    when in_market_type = 'E' then acc.is_auto_allocate
                    when in_market_type = 'O' then acc.is_option_auto_allocate
                    else acc.is_auto_allocate
                   end) as is_auto_allocate,
               jsonb_agg(jsonb_object(
                       array ['ca_number', 'def' , 'ca_name', 'oaid', 'visible', 'alloc_ratio', 'auto_alloc_to', 'sg_brid', 'sg_sub_account_name', 'sg_mint_account'],
                       array [ca.clearing_account_number, ca.is_default , ca.clearing_account_name, ca.occ_actionable_id, ca.is_visible_for_manual_allocation::text, ca.auto_alloc_ratio::text, ca.is_auto_alloc_to, ca.sg_brid, ca.sg_sub_account_name, ca.sg_mint_account])),
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

CREATE OR REPLACE FUNCTION dash360.allocations_set_account_config(in_account_id bigint, in_clearing_accounts text,
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

declare
    l_clearing_account_type smallint;
    l_row_cnt               int;
    l_clearing_accounts     jsonb;

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
                                           user_id, is_visible_for_manual_allocation, auto_alloc_ratio,
                                           is_auto_alloc_to,
                                           sg_brid, sg_sub_account_name, sg_mint_account)
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
           sj ->> 'sg_brid',
           sj ->> 'sg_sub_account_name',
           sj ->> 'sg_mint_account'
    from (select value as sj
          from jsonb_array_elements(l_clearing_accounts)) l1;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    return l_row_cnt;

end;
$function$
;

create table if not exists genesis2.alloc_drop_message_status
(
    drop_message_status_id     int4      not null
        constraint alloc_drop_message_status_pk primary key generated by default as identity,
    alloc_instr_id             int8
        constraint alloc_drop_message_status_alloc_instruction_fk references genesis2.allocation_instruction (alloc_instr_id),
    drop_message_type          bpchar    not null default 'N',
    drop_message_status        bpchar    not null default 'N',
    drop_message_reject_reason text,
    db_create_time             timestamp not null default clock_timestamp()
);
comment on table genesis2.alloc_drop_message_status is 'Store and return 35=J Accept/Reject status and Reject Reason for an allocation';
comment on column genesis2.alloc_drop_message_status.drop_message_status_id is 'PK auto incremental column';
comment on column genesis2.alloc_drop_message_status.alloc_instr_id is 'alloc_instr_id from genesis2.allocation_instruction';
comment on column genesis2.alloc_drop_message_status.drop_message_type is 'Message type. N - New - default';
comment on column genesis2.alloc_drop_message_status.drop_message_status is 'N : new, S : sent, A : accepted, R : rejected, I : internally rejected';
comment on column genesis2.alloc_drop_message_status.drop_message_reject_reason is 'text taken from 35=P, tag_88 in case of tag_87 is reject';
comment on column genesis2.alloc_drop_message_status.db_create_time is 'Created time';

create index if not exists alloc_drop_message_status_alloc_instr_id_drop_message_type_idx on genesis2.alloc_drop_message_status (alloc_instr_id, drop_message_type);


create or replace function dash360.alloc_drop_message_status_init(in_alloc_instr_id int8,
                                                                  in_drop_message_type bpchar)
    returns int4
    language plpgsql
as
$fx$
declare
    l_drop_message_status_id int4;
begin
    if in_drop_message_type in ('N', 'C') and not exists (select null
                                                          from genesis2.alloc_drop_message_status
                                                          where alloc_instr_id = in_alloc_instr_id
                                                            and drop_message_type = in_drop_message_type) then
        insert into genesis2.alloc_drop_message_status(alloc_instr_id, drop_message_type)
        values (in_alloc_instr_id, in_drop_message_type)
        returning drop_message_status_id into l_drop_message_status_id;
    else
        l_drop_message_status_id := -1;
    end if;
    return l_drop_message_status_id;
end;
$fx$;
comment on function dash360.alloc_drop_message_status_init is 'Insert data into alloc_drop_message_status';


create function dash360.alloc_drop_message_status_update(in_drop_message_status_id int4,
                                                         in_drop_message_status bpchar,
                                                         in_drop_message_reject_reason text
)
    returns int4
    language plpgsql
as
$fx$
declare
    l_drop_message_status_id int4;
begin
    update genesis2.alloc_drop_message_status adms
    set drop_message_status        = in_drop_message_status,
        drop_message_reject_reason = in_drop_message_reject_reason
    where adms.drop_message_status_id = in_drop_message_status_id
    returning drop_message_status_id into l_drop_message_status_id;

    return l_drop_message_status_id;
end;
$fx$;


drop function if exists dash360.allocations_clearing_accounts_by_account_id;
create or replace function dash360.allocations_clearing_accounts_by_account_id(in_account_id bigint, in_market_type character)
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
                is_auto_alloc_to                 character,
                sg_brid                          varchar,
                sg_sub_account_name              varchar,
                sg_mint_account                  varchar

            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY: 20240430 https://dashfinancial.atlassian.net/browse/DS-8208
-- SO: 20250610 https://dashfinancial.atlassian.net/browse/D360-15839
-- SO: 20251103 https://dashfinancial.atlassian.net/browse/D360-16593
-- SO: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
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
               ca.is_auto_alloc_to,
               ca.sg_brid,
               ca.sg_sub_account_name,
               ca.sg_mint_account
        from genesis2.clearing_account ca
        where ca.account_id = in_account_id
          and ca.market_type = in_market_type
          and ca.is_deleted = 'N'
        order by ca.is_default desc, ca.clearing_account_number;

end;
$function$
;

DROP FUNCTION if exists dash360.allocations_instruction_entries;

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_entries(in_alloc_instr_id integer, in_date_id integer)
    RETURNS TABLE
            (
                clearing_account_number character varying,
                clearing_account_name   character varying,
                clearing_account_type   character,
                cmta                    character varying,
                is_default              character,
                alloc_qty               integer,
                occ_actionable_id       character varying,
                clearing_account_id     integer,
                account_nickname        character varying,
                account_id              integer,
                sg_brid                 varchar,
                sg_sub_account_name     varchar,
                sg_mint_account         varchar
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SO: 20251103 https://dashfinancial.atlassian.net/browse/D360-16593
    -- SO: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
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
               ca.sg_brid,
               ca.sg_sub_account_name,
               ca.sg_mint_account
        from genesis2.allocation_instruction_entry e
                 inner join genesis2.allocation_instruction a
                            on a.alloc_instr_id = e.alloc_instr_id and a.is_deleted = 'N' and a.date_id = in_date_id
                 inner join genesis2.clearing_account ca
                            on e.clearing_account_id = ca.clearing_account_id /*and ca.is_deleted = 'N'*/ /* No need to is_deleted ='N' because clearing_account_id is surrogate key and we SCD inside the dimension*/
        where e.alloc_instr_id = in_alloc_instr_id
          and e.date_id = in_date_id
          and e.alloc_qty > 0;

end;
$function$
;

select *
from dash360.allocations_snapshot(in_date_id := 20251201)
-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                        in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                        in_reported_status character DEFAULT NULL::character(1))
    RETURNS TABLE
            (
                date_id                    integer,
                trade_record_id            bigint,
                account_id                 integer,
                instrument_id              bigint,
                side                       character,
                open_close                 character,
                avg_px                     numeric,
                exec_qty                   integer,
                display_instrument_id      character varying,
                last_trade_date            date,
                instrument_type_id         character,
                alloc_instr_id             integer,
                alloc_time                 timestamp without time zone,
                is_allocated               boolean,
                is_bundle                  boolean,
                cmta                       character varying,
                exec_broker                character varying,
                principal_amount           numeric,
                client_commission_rate     numeric,
                username                   character varying,
                blaze_account_alias        character varying,
                street_exec_time           timestamp without time zone,
                expiration_date            timestamp without time zone,
                opt_customer_firm          character,
                reported_status            character,
                reported_time              timestamp without time zone,
                claimed_by                 integer,
                claim_status               character,
                is_prev_reported           boolean,
                db_create_time             timestamp without time zone,
                drop_message_status        bpchar,
                drop_message_reject_reason text
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --in_date_id = 20190301;
    -- VP 20231030 https://dashfinancial.atlassian.net/browse/DS-7465 [ALLOC] Return street_exec_time in dash360.allocations_snapshot()
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters and removed if-else condition for empty in_account_id
    -- OS 20250116 https://dashfinancial.atlassian.net/browse/DS-9337 is_prev_reported will use is_billed
    -- OS 20250212 https://dashfinancial.atlassian.net/browse/DS-9550 Add "GUP" (exec_broker) column to Allocations procedure
begin
    drop table if exists t_trade_record;
    create temp table t_trade_record
    as
    select distinct on (atr.trade_record_id, br.to_report, br.alloc_instr_id) atr.trade_record_id,
                                                                              br.to_report,
                                                                              br.alloc_instr_id,
                                                                              br.db_create_time,
                                                                              'B' as alloc_rep_type
    from dash_reporting.bofa_allocation_report br
             join genesis2.alloc_instr2trade_record atr
                  on atr.alloc_instr_id = br.alloc_instr_id and atr.date_id = br.date_id
    where br.date_id = in_date_id
    union all
    select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
    from dash_reporting.bofa_trade_record btr
    where btr.date_id = in_date_id;

    create index on t_trade_record (trade_record_id);

    return query
        select tr.date_id,
               tr.trade_record_id::int8,
               tr.account_id::int4,
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               null                                                        as alloc_instr_id,
               null                                                        as alloc_time,
               false                                                       as is_allocated,
               false                                                       as is_bundle,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                        principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
                   else CCRU.rate end                                      as client_commission_rate,
               null::varchar                                               as user_name,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               coalesce(nullif(tr.is_billed, 'N'), rep.to_report)          as reported_status,
               case
                   when coalesce(nullif(tr.is_billed, 'N'), rep.to_report) = 'R' then
                       coalesce((select bar.db_create_time
                                 from dash_reporting.bofa_allocation_report bar
                                          join genesis2.alloc_instr2trade_record aitr
                                               on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                          join genesis2.trade_record tri
                                               on tri.date_id = bar.date_id and
                                                  tri.trade_record_id = aitr.trade_record_id
                                 where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                                   and tri.exec_id = tr.exec_id
                                   and tri.is_billed = 'R'
                                 order by 1
                                 limit 1), rep.db_create_time) end         as reported_time,
               bas.claimed_by                                              as claimed_by,
               bas.claim_status                                            as claim_status,
               case when tr.is_billed = 'R' then true end                  as is_prev_reported,
               msg.db_create_time                                          as db_create_time,
               msg.drop_message_status                                     as alloc_drop_msg_status,
               msg.drop_message_reject_reason                              as alloc_drop_msg_reject_reason
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join genesis2.account acc on acc.account_id = tr.account_id
                 left join (select ai2tr.trade_record_id, a.alloc_instr_id, a.date_id
                            from genesis2.allocation_instruction a
                                     inner join genesis2.alloc_instr2trade_record ai2tr
                                                on (a.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = a.date_id)
                            where true
                              and case when in_account_ids = '{}' then true else a.account_id = any (in_account_ids) end
                              and a.date_id = in_date_id
                              and a.is_deleted = 'N') allocated_trades
                           on allocated_trades.trade_record_id = TR.TRADE_RECORD_ID
                 left join lateral (select rep.to_report, rep.db_create_time
                                    from t_trade_record rep
                                    where rep.trade_record_id = tr.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and bas.date_id = allocated_trades.date_id
                                      and 1 = 2
                                    limit 1) bas on true
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = in_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
                 left join lateral (select *
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = allocated_trades.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                    limit 1) msg on true
        where tr.date_id = in_date_id
          and case when in_account_ids = '{}' then true else tr.account_id = any (in_account_ids) end
          and tr.is_busted = 'N'
          and allocated_trades.alloc_instr_id is NULL
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C')
                  when in_reported_status is null then true end
        union all
        select ai.date_id,
               null::int8                     as trade_record_id,
               ai.account_id::int4,
               ai.instrument_id,
               ai.side,
               ai.open_close,
               ai.avg_px,
               ai.total_qty                   as exec_qty,
               i.display_instrument_id,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               ai.alloc_instr_id,
               ai.create_time                 as alloc_time,
               true                           as is_allocated,
               true                           as is_bundle,
               null                           as cmta,
               ccr.exec_broker                as exec_broker,
               case i.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                           principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end          as client_commission_rate,
               coalesce(ui.user_name, 'auto') as user_name,
               ccr.blaze_account_alias,
               null                           as street_exec_time,
               -------
               i.last_trade_date,
               null                           as opt_customer_or_firm,
               rep.to_report                  as reported_status,
               rep.db_create_time             as reported_time,
               bas.claimed_by                 as claimed_by,
               bas.claim_status               as claim_status,
               null::boolean                  as is_prev_reported,
               msg.db_create_time             as db_create_time,
               msg.drop_message_status        as alloc_drop_msg_status,
               msg.drop_message_reject_reason as alloc_drop_msg_reject_reason
        from genesis2.allocation_instruction ai
                 inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
                 left join lateral (select case
                                               when rep.to_report = 'U' and
                                                    staging.get_fully_reported_trade(rep.alloc_instr_id, in_date_id) =
                                                    1 -- means that only one value is possible in related trade_records and it can be only R
                                                   then 'U'
                                               when rep.to_report = 'U' then 'W'
                                               else rep.to_report end as to_report,
                                           rep.db_create_time
                                    from t_trade_record rep
                                    where rep.alloc_instr_id = ai.alloc_instr_id
                                    limit 1) rep on true
                 left join genesis2.account acc on acc.account_id = ai.account_id
                 left join genesis2.user_identifier ui on ai.created_by_user_id = ui.user_id
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = ai.alloc_instr_id
                                      and bas.date_id = ai.date_id
                                    limit 1) bas on true
                 left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as rate,
                                           case
                                               when count(distinct tr.blaze_account_alias) = 1
                                                   then max(tr.blaze_account_alias)
                                               when count(distinct tr.blaze_account_alias) > 1 then '-'
                                               else null
                                               end                                                  as blaze_account_alias,
                                           string_agg(distinct tr.exec_broker, ', ')                as exec_broker
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                             left join lateral (select rate,
                                                                       row_number()
                                                                       over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                                from genesis2.trade_level_book_record tl
                                                                         inner join genesis2.book_record_creator cr
                                                                                    on tl.book_record_creator_id = cr.book_record_creator_id
                                                                where tl.date_id = in_date_id
                                                                  AND tl.book_record_type_id = 'CCRU'
                                                                  and tl.trade_record_id = alt.trade_record_id) l1
                                                       on true
                                    where alt.alloc_instr_id = ai.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and (l1.rn = 1 or l1.rn is null)
            ) ccr on true
                 left join lateral (select *
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = ai.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                    limit 1) msg on true
        where ai.date_id = in_date_id
          and case when in_account_ids = '{}' then true else ai.account_id = any (in_account_ids) end
          and ai.is_deleted = 'N'
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C', 'W') -- C the same as U
                  when in_reported_status is null then true end;

end ;
$function$
;

COMMENT ON FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar) IS 'The report allocations_snapshot temp nsme with the prefix os_ until it is tested';



create or replace function dash360.get_data_for_allocation_drop(in_alloc_instr_id bigint, in_date_id integer default null::integer)
    returns jsonb
    language plpgsql
as
$function$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
    -- 20251205 SO https://dashfinancial.atlassian.net/browse/DS-10739 New atrributes in the result json were added
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay',
                                                  case
                                                      when di.instrument_type_id = 'O'
                                                          then to_char(oc.maturity_day, 'FM00') end,
                                                  'maturityMonthYear', case
                                                                           when di.instrument_type_id = 'O' then
                                                                               to_char(oc.maturity_year, 'FM0000') ||
                                                                               to_char(oc.maturity_month, 'FM00') end,
                                                  'totalQty', ai.total_qty,
                                                  'avgPx', ai.avg_px,
                                                  'noExecs', aitr.trade_cnt,
                                                  'trades', aitr.trades,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries,
                                                  'CCRURate', ccr.rate,
                                                  'CCRUTotalAmount', ccr.amount
                               )
    from genesis2.allocation_instruction ai
             join genesis2.instrument di on di.instrument_id = ai.instrument_id
             left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as rate,
                                       sum(amount)                                              as amount
                                from genesis2.alloc_instr2trade_record alt
                                         inner join genesis2.trade_record tr
                                                    on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                         left join lateral (select tl.rate,
                                                                   tl.amount,
                                                                   row_number()
                                                                   over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                            from genesis2.trade_level_book_record tl
                                                                     inner join genesis2.book_record_creator cr
                                                                                on tl.book_record_creator_id = cr.book_record_creator_id
                                                            where tl.date_id = in_date_id
                                                              AND tl.book_record_type_id = 'CCRU'
                                                              and tl.trade_record_id = alt.trade_record_id) l1
                                                   on true
                                where alt.alloc_instr_id = ai.alloc_instr_id
                                  and tr.is_busted = 'N'
                                  and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'brid', ca.sg_brid,
                                                               'subAccount', ca.sg_sub_account_name,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'sgMintAccount', ca.sg_mint_account,
                                                               'AllocEntryCCRURate', ccr.rate,
                                            'AllocEntryCCRUTotalAmount', round(ccr.amount * 1.0 * aie.alloc_qty / total_qty, 2)
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
--                                                  and ca.clearing_account_type = '1'
--                                                  and ca.market_type = di.instrument_type_id
                                                  )
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             join lateral (select count(*) as trade_cnt,
                                  jsonb_agg(jsonb_build_object('dashExecId', tr.exch_exec_id,
                                                               'secondaryExchExecId', tr.secondary_exch_exec_id,
                                                               'lastQty', tr.last_qty,
                                                               'legRefId', tr.leg_ref_id,
                                                               'chainExecId', fmj.chain_exec_id)
                                  )        as trades
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                                    join lateral (select fix_message ->> '10710' as chain_exec_id
                                                  from staging.fix_message_json fmj
                                                  where fmj.date_id = aitr.date_id
                                                    and fmj.fix_message_id = tr.trade_fix_message_id
                                                  limit 1) fmj on true
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
--                             and is_busted = 'N'
                           limit 1) aitr on true

             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end ;
$function$
;


select alloc_instr_id, dash360.get_data_for_allocation_drop(ai.alloc_instr_id, ai.date_id)
from genesis2.allocation_instruction ai
where date_id = 20251107;


select dash360.get_data_for_allocation_drop(-101187, 20251107);
select dash360.get_data_for_allocations(-99683);
