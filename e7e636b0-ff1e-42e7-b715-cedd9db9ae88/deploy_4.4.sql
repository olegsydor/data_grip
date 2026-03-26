-- TABLES
alter table genesis2.allocation_instruction
    add column if not exists clearing_submitted_away bpchar null default 'N';
alter table genesis2.clearing_instruction
    add column if not exists clearing_submitted_away bpchar null default 'N';

-- FOREIGN TABLES
/*
IMPORT FOREIGN SCHEMA data_marts LIMIT TO (f_parent_order)
    FROM SERVER postgresbig_data
    into staging;
*/


-- USER TYPES
alter type genesis2.tp_sg_allocation_configuration drop attribute sg_portfolio_id;


-- FUNCTIONS
DROP FUNCTION dash360.clearing_complete_instruction(int4, int4, int4, bpchar, varchar, text);
CREATE OR REPLACE FUNCTION dash360.clearing_complete_instruction(in_date_id integer, in_user_id integer,
                                                                 in_instr_id integer, in_status character,
                                                                 in_remarks character varying DEFAULT NULL::character varying,
                                                                 in_change_vector text DEFAULT NULL::text)
    RETURNS TABLE
            (
                new_trade_record_id bigint,
                date_id             integer,
                account_id          bigint
            )
    LANGUAGE plpgsql
AS
$function$
-- PD 20210623 https://dashfinancial.atlassian.net/browse/DS-3677 The initial creation
-- PD 20240206 https://dashfinancial.atlassian.net/browse/DS-7937 cie.clearing_instr_id = in_instr_id has been added. Also date_id conditions have been added
-- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
-- PD 20250418 https://dashfinancial.atlassian.net/browse/DS-9907 in_status='P' works the same was as in_status='C'
-- OS 20260324 https://dashfinancial.atlassian.net/browse/DS-11302 Add dateId (from tr.trade_date), accountID, to dash360.clearing_complete_instruction
declare
    l_inserted int8[];
    l_row_cnt  int;

begin

    if in_change_vector is not null then

        select *
        from dash360.ptm_process_trades(in_date_id, in_user_id, in_change_vector::jsonb)
        into l_inserted;

        with cte as (select trade_record_id,
                            orig_trade_record_id,
                            last_qty,
                            row_number() over (partition by orig_trade_record_id order by orig_trade_record_id) as rn
                     from genesis2.trade_record tr
                     where tr.trade_record_id = any (l_inserted)
                       and tr.date_id = in_date_id),
             cie_cte as (select cie.clearing_instr_entry_id,
                                cie.trade_record_id,
                                row_number() over (partition by cie.trade_record_id order by cie.trade_record_id ) as rn
                         from genesis2.clearing_instruction_entry cie
                         where cie.trade_record_id in (select orig_trade_record_id from cte)
                           and cie.clearing_instr_id = in_instr_id),
             upd as (update genesis2.clearing_instruction_entry cie set new_trade_record_id = c.trade_record_id
                 from cie_cte cc
                     join cte c on c.orig_trade_record_id = cc.trade_record_id and cc.rn = c.rn
                 where cc.clearing_instr_entry_id = cie.clearing_instr_entry_id
                 --and cte.last_qty = cie.last_qty
                 returning cie.new_trade_record_id, cie.client_commission_rate, cie.last_qty)
        --last_qty*ccr= amount

        select count(1)
        into l_row_cnt
        from (select dash360.trade_record_update_ccru(in_user_id, in_date_id, u.new_trade_record_id, u.ccru,
                                                      u.ccru * u.last_qty,
                                                      nextval('load_batch_load_batch_id_seq'::regclass)::int)
              from (select upd.new_trade_record_id, upd.client_commission_rate as ccru, upd.last_qty
                    from upd) u) subscr_cte;
    else
        select null::bigint[] into l_inserted;
    end if;

    --claim block
    case
        when in_status in ('C', 'P')
            then update genesis2.clearing_instruction
                 set status               = in_status,
                     process_time         = now(),
                     claim_time           = now(),
                     processed_by_user_id = in_user_id,
                     remarks              = coalesce(in_remarks, remarks),
                     claimed_by_user_id   = in_user_id
                 where clearing_instr_id = in_instr_id;
        else update genesis2.clearing_instruction
             set status               = in_status,
                 process_time         = now(),
                 processed_by_user_id = in_user_id,
                 remarks              = coalesce(in_remarks, remarks)
             where clearing_instr_id = in_instr_id;
        end case;

    return query
        select tr.trade_record_id as new_trade_record_id, in_date_id as date_id, tr.account_id::int8
        from genesis2.trade_record tr
        where tr.trade_record_id = any (l_inserted)
          and tr.date_id = in_date_id
          and l_inserted is not null;

end;
$function$
;


DROP FUNCTION dash360.allocations_instruction_commission_rate(int4, int4);
CREATE OR REPLACE FUNCTION dash360.allocations_instruction_commission_rate(in_alloc_instr_id integer,
                                                                           in_date_id integer DEFAULT get_dateid(CURRENT_DATE))
    RETURNS TABLE
            (
                date_id                  integer,
                trade_record_id          bigint,
                account_id               integer,
                instrument_id            bigint,
                side                     character,
                open_close               character,
                avg_px                   numeric,
                exec_qty                 integer,
                display_instrument_id    character varying,
                last_trade_date          date,
                instrument_type_id       character,
                alloc_instr_id           integer,
                alloc_time               timestamp without time zone,
                is_allocated             boolean,
                is_bundle                boolean,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                username                 character varying,
                client_commission_amount numeric,
                client_order_id          character varying,
                clearing_submitted_away  character,
                client_order_status      character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SO 20260319 https://dashfinancial.atlassian.net/browse/DS-11284 Support client_order_id in dash360.allocations_instruction_commission_rate
    -- SO 20260323 https://dashfinancial.atlassian.net/browse/DS-11290 Support client_order_status in dash360.allocations_instruction_commission_rate
declare
    l_sg_accounts int8[];
begin

    /*
select array_agg(account_id)
--     into l_sg_accounts
from genesis2.account
where false
*/
    return query
        select a.date_id,
               null::bigint                                                  as trade_record_id,
               a.account_id,
               a.instrument_id,
               a.side,
               a.open_close,
               a.avg_px,
               a.total_qty                                                   as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               a.alloc_instr_id,
               a.create_time                                                 as alloc_time,
               true                                                          as is_allocated,
               true                                                          as is_bundle,
               null::character varying                                       as cmta,
               null::character varying                                       as exec_broker,
               case i.instrument_type_id
                   when 'O' then a.total_qty * a.avg_px * os.contract_multiplier
                   else a.total_qty * a.avg_px
                   end                                                       as principal_amount,
               ccr.rate                                                      as client_commission_rate,
               ui.user_name,
               amount                                                        as client_commission_amount,
               (case
                    when array_length(ccr.client_order_id, 1) > 1 then '-'
                    else ccr.client_order_id[1] end)::character varying(256) as client_order_id,
               a.clearing_submitted_away::character,
               (case
                    when array_length(ccr.client_order_status, 1) > 1 then '-'
                    else ccr.client_order_status[1] end)::character          as client_order_status
        from allocation_instruction a
                 inner join instrument i on (a.instrument_id = i.instrument_id)
                 left join user_identifier ui on a.created_by_user_id = ui.user_id
                 left join option_contract oc on i.instrument_id = oc.instrument_id
                 left join option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select sum(/*coalesce(*/ l1.rate /*,0)*/ * tr.last_qty) /
                                           nullif(sum(tr.last_qty), 0)                 as rate,
                                           sum(amount)                                 as amount,
                                           array_agg(distinct tr.client_order_id)      as client_order_id,
                                           array_agg(distinct fpo.client_order_status) as client_order_status
                                    from alloc_instr2trade_record alt
                                             inner join trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                             left join lateral (select fpo.order_status as client_order_status
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id
                                                                limit 1) fpo
                                                       on true --and tr.account_id = any(l_sg_accounts)

                                             left join lateral (select rate,
                                                                       tl.amount,
                                                                       row_number()
                                                                       over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn
                                                                from trade_level_book_record tl
                                                                         inner join book_record_creator cr
                                                                                    on tl.book_record_creator_id = cr.book_record_creator_id
                                                                where tl.date_id = in_date_id
                                                                  AND tl.book_record_type_id = 'CCRU'
                                                                  and tl.trade_record_id = alt.trade_record_id) l1
                                                       on true


                                    where alt.alloc_instr_id = a.alloc_instr_id
                                      and (l1.rn = 1 or l1.rn is null)
            ) ccr on true
        where a.alloc_instr_id = in_alloc_instr_id
          and a.is_deleted = 'N';

end;
$function$
;


-- DROP FUNCTION dash360.get_data_for_allocation_drop_v2(int8, int4);

CREATE OR REPLACE FUNCTION dash360.get_data_for_allocation_drop_v2(in_alloc_instr_id bigint, in_date_id integer DEFAULT NULL::integer)
    RETURNS jsonb
    LANGUAGE plpgsql
AS
$function$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
    -- 20251205 SO https://dashfinancial.atlassian.net/browse/DS-10739 New atrributes in the result json were added
    -- 20260217 SO https://dashfinancial.atlassian.net/browse/DS-11116 v2
    -- 20260223 SO https://dashfinancial.atlassian.net/browse/DS-11134 applied filter for is_busted for cancels only
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11173 Add new output param
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11289 Add new output param Add `ClearingSumbittedAway` to get_data_for_allocation_drop_v2
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'side', ai.side,
                                                  'symbol', di.symbol,
                                                  'secType',
                                                  case when di.instrument_type_id = 'O' then 'OPT' else 'CS' end,
                                                  'putOrCall',
                                                  case when di.instrument_type_id = 'O' then oc.put_call end,
                                                  'strikePx',
                                                  case when di.instrument_type_id = 'O' then oc.strike_price end,
                                                  'maturityDay', case
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
                                                  'CCRUTotalAmount', ccr.amount,
                                                  'AllocInstrId', ai.alloc_instr_id,
                                                  'instrumentTypeId', di.instrument_type_id,
                                                  'clearingSumbittedAway', ai.clearing_submitted_away
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
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
                                  and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_account_number,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'AllocEntryCCRURate', ccr.rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.clearing_account ca
                                              on (ca.clearing_account_id = aie.clearing_account_id
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

COMMENT ON FUNCTION dash360.get_data_for_allocation_drop_v2(int8, int4) IS 'The same get_data_for_allocation_drop but without SG attributes';


DROP FUNCTION dash360.clearing_instruction_modifications(int4);
CREATE OR REPLACE FUNCTION dash360.clearing_instruction_modifications(in_clearing_instr_id integer)
    RETURNS TABLE
            (
                trade_record_id                 bigint,
                parent_order_id                 bigint,
                parent_client_order_id          character varying,
                client_order_id                 character varying,
                symbol                          character varying,
                instrument_type_id              character,
                trade_record_reason             character,
                maturity_date                   timestamp without time zone,
                side                            character,
                last_px                         numeric,
                exec_time                       timestamp without time zone,
                client_id                       character varying,
                exchange_name                   character varying,
                exchange_id                     character varying,
                liquidity_indicator             character varying,
                account_id                      integer,
                orig_account_id                 bigint,
                account_name                    character varying,
                orig_account_name               character varying,
                capacity                        character,
                orig_capacity                   character,
                open_close                      character,
                orig_open_close                 character,
                last_qty                        integer,
                orig_last_qty                   integer,
                gup                             character varying,
                orig_gup                        character varying,
                cmta                            character varying,
                orig_cmta                       character varying,
                clearing_account_number         character varying,
                orig_clearing_account_number    character varying,
                sub_account                     character varying,
                orig_sub_account                character varying,
                remarks                         character varying,
                orig_remarks                    character varying,
                tf_name                         character varying,
                modified_time                   timestamp without time zone,
                alloc_instr_id                  integer,
                report_status                   character,
                street_account_name             character varying,
                orig_street_account_name        character varying,
                street_exec_broker              character varying,
                orig_street_exec_broker         character varying,
                client_commission_rate          numeric,
                orig_client_commission_rate     numeric,
                branch_sequence_number          character varying,
                orig_branch_sequence_number     character varying,
                trade_text                      character varying,
                orig_trade_text                 character varying,
                frequent_trader_id              character varying,
                orig_frequent_trader_id         character varying,
                electronic_report_error_text    character varying,
                box_additional_firm             character varying,
                orig_box_additional_firm        character varying,
                cboe_reason_code                character varying,
                box_additional_client_memo      character varying,
                orig_box_additional_client_memo character varying,
                blaze_account_alias             character varying,
                orig_blaze_account_alias        character varying,
                clearing_submitted_away         character
            )
    LANGUAGE plpgsql
AS
$function$
-- AK 20240130 https://dashfinancial.atlassian.net/browse/DS-7912 added cboe_reason_code to return query
-- PD 20240530 https://dashfinancial.atlassian.net/browse/DS-8362 box_additional_client_memo and orig_box_additional_client_memo added to the output
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
-- OS 20250128 hotfix replaced 78 row with 79: join to trade_record using lateral instead of join
-- OS 20250328 https://dashfinancial.atlassian.net/browse/DS-9719 added condition date_id = date_id in a few joins
-- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
begin
    return query
        select cin.trade_record_id::bigint,
               tr.order_id                                       as parent_order_id,
               tr.client_order_id                                as parent_client_order_id,
               tr.street_client_order_id                         as client_order_id,
               i.display_instrument_id2                          as symbol,
               i.instrument_type_id,
               tr.trade_record_reason,
               i.last_trade_date                                 as maturity_date,
               tr.side,
               cin.last_px,
               cin.trade_record_time                             as exec_time,
               tr.client_id,
               real_exch.exchange_name,
               real_exch.exchange_id,
               tr.trade_liquidity_indicator                      as liquidity_indicator,
               cin.account_id                                    as account_id,
               tr.account_id::bigint                             as orig_account_id,
               acc.account_name,
               orig_acc.account_name                             as orig_account_name,
               cin.opt_customer_firm                             as capacity,
               tr.opt_customer_firm                              as orig_capacity,
               cin.open_close,
               tr.open_close                                     as orig_open_close,
               cin.last_qty,
               tr.last_qty                                       as orig_last_qty,
               cin.exec_broker                                   as gup,
               tr.exec_broker                                    as orig_gup,
               cin.cmta,
               tr.cmta                                           as orig_cmta,
               cin.clearing_account_number,
               tr.clearing_account_number                        as orig_clearing_account_number,
               cin.sub_account,
               tr.sub_account                                    as orig_sub_account,
               cin.remarks,
               tr.remarks                                        as orig_remarks,
               tf.trading_firm_name                              as tf_name,
               ci.create_time                                    as modified_time,
               alc.alloc_instr_id,
               cin.electronic_report_status                      as report_status,
               cin.street_account_name,
               tr.street_account_name                            as orig_street_account_name,
               cin.street_exec_broker,
               tr.street_exec_broker                             as orig_street_exec_broker,
               cin.client_commission_rate,
               CCRU.rate                                         as orig_client_commission_rate,
               cin.branch_sequence_number,
               tr.branch_sequence_number                         as orig_branch_sequence_number,
               cin.trade_text,
               tr.trade_text                                     as orig_trade_text,
               cin.frequent_trader_id,
               tr.frequent_trader_id                             as orig_frequent_trader_id,
               case
                   when cin.electronic_report_status in ('I', 'R')
                       then cin.electronic_report_error_text end as electronic_report_error_text,
               cin.box_additional_firm,
               cie.box_additional_firm                           as orig_box_additional_firm,
               cin.cboe_reason_code,
               cin.box_additional_client_memo,
               cie.box_additional_client_memo                    as orig_box_additional_client_memo,
               cin.blaze_account_alias,
               tr.blaze_account_alias,
               ci.clearing_submitted_away
        from genesis2.clearing_instruction_entry cin
                 inner join genesis2.clearing_instruction ci on ci.clearing_instr_id = cin.clearing_instr_id
            and cin.date_id = ci.date_id -- DS-9719 checked on PROD
                 inner join genesis2.account acc on acc.account_id = cin.account_id
                 inner join genesis2.trading_firm as tf
                            on tf.trading_firm_id = acc.trading_firm_id and tf.is_deleted = 'N'
--                 left join trade_record orig_tr on orig_tr.trade_record_id = tr.trade_record_id
                 left join lateral (select *
                                    from genesis2.trade_record orig_tr
                                    where orig_tr.trade_record_id = cin.trade_record_id
                                      and cin.date_id = orig_tr.date_id -- DS-9719
                                    limit 1) tr on true
                 left join genesis2.clearing_instruction_entry cie on cie.new_trade_record_id = tr.trade_record_id and
                                                                      cie.opt_customer_firm = tr.opt_customer_firm
            and cie.date_id = cin.date_id -- DS-9719 checked on prod
                 left join genesis2.account orig_acc on tr.account_id = orig_acc.account_id
                 left join genesis2.exchange exch on exch.exchange_id = tr.exchange_id
                 left join genesis2.exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
                 left join genesis2.instrument i on i.instrument_id = tr.instrument_id
                 left join (select AT.TRADE_RECORD_ID, A.alloc_instr_id, at.date_id
                            from genesis2.ALLOC_INSTR2TRADE_RECORD AT
                                     inner join genesis2.ALLOCATION_INSTRUCTION A
                                                on A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID AND A.IS_DELETED = 'N'
                                                    and a.date_id = at.date_id -- DS-9719 checked on PROD
        ) alc
                           on (alc.trade_record_id = coalesce(cin.new_trade_record_id, cin.trade_record_id)
                               and alc.date_id = cin.date_id)
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where ci.clearing_instr_id = in_clearing_instr_id;

end;
$function$
;


DROP FUNCTION dash360.clearing_get_change_requests(timestamp, timestamp, int8, int4);
CREATE OR REPLACE FUNCTION dash360.clearing_get_change_requests(start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                                user_id bigint DEFAULT NULL::bigint,
                                                                clearing_instruction_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                clearing_instr_id                integer,
                date_id                          integer,
                status                           character,
                remarks                          character varying,
                trading_firm_names               character varying[],
                display_instrument_ids           character varying[],
                create_time                      timestamp without time zone,
                created_by_user_id               integer,
                claim_time                       timestamp without time zone,
                claimed_by_user_id               integer,
                process_time                     timestamp without time zone,
                claimed_by_user_name             character varying,
                created_by_user_name             character varying,
                modification_type                character,
                alloc_instrument_ids             integer[],
                new_trading_firm_ids             character varying[],
                account_ids                      bigint[],
                cie_agg_electronic_report_status integer,
                cie_sent_count                   integer,
                cie_rejected_count               integer,
                cie_pending_count                integer,
                cie_total_count                  integer,
                cie_accepted_count               integer,
                cie_invalid_count                integer,
                cie_not_supported_count          integer,
                clearing_submitted_away          character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY 20211112 Performance improvement https://dashfinancial.atlassian.net/browse/DS-4402
    -- SY 20211115 GTH related bug fixed https://dashfinancial.atlassian.net/browse/DS-4431
    -- SY 20220305 Joind condition by date_id has been added inside lateral join
    -- SO 20230920 removed dynamic sql
    -- SO 20230920 Add returned parameters for dash360.clearing_get_change_requests https://dashfinancial.atlassian.net/browse/DS-7287
    -- SO 20231019 cie_status -> cie_agg_electronic_report_status, cie_sent -> cie_sent_count, cie_rejected -> cie_rejected_count, cie_pending -> cie_pending_count
    -- SO 20231115 DS-7287 add cie_total_count, cie_accepted_count, count only Accepted, cie_invalid_count, count only Invalid. change counting logic for cie_rejected_count
    -- SO 20231120 DS-7287 add cie_not_supported_count
    -- MB 20260225 DS-11150 Replaced trading_firm_admin with trading_firm_admin2firm table due to Oracle DDL changes
    -- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
DECLARE
--    l_clearing_instruction_id int4   := clearing_get_change_requests.clearing_instruction_id ;
--    l_user_id                 bigint := clearing_get_change_requests.user_id;
    l_clearing_instruction_id int4   := $4;
    l_user_id                 bigint := $3;
begin


    /*
=================== RUN this is performance is too pure
analyse genesis2.clearing_instruction;
analyse genesis2.user_identifier;
analyse genesis2.clearing_instruction_entry;
do $$ begin  execute 'analyse daily_partitions.trade_record_'||to_char(current_date, 'YYYYMM'); end $$;
analyse genesis2.instrument;
analyse genesis2.account;
analyse genesis2.trading_firm;
analyse clearing_instruction_entry;
analyse genesis2.alloc_instr2trade_record;
analyse genesis2.allocation_instruction;

     * */

    raise info '%: start_status_date = %', clock_timestamp(), start_status_date::text;
    raise info '%: end_status_date = %', clock_timestamp(), end_status_date::text;
    raise info '%: user_id = %', clock_timestamp(), l_user_id::text;
    raise info '%: clearing_instruction_id = %', clock_timestamp(), l_clearing_instruction_id::text;

    drop table if exists ci;
    create temp table ci on commit drop as
    select ci.clearing_instr_id,
           ci.date_id,
           ci.status,
           ci.remarks,
           ci.create_time,
           ci.created_by_user_id,
           ci.claim_time,
           ci.claimed_by_user_id,
           ci.process_time,
           claim_user.user_name  claimed_by_user_name,
           create_user.user_name created_by_user_name,
           ci.modification_type,
           ci.clearing_submitted_away
    from genesis2.clearing_instruction ci
             inner join genesis2.user_identifier create_user on create_user.user_id = ci.created_by_user_id
             left join genesis2.user_identifier claim_user on claim_user.user_id = ci.claimed_by_user_id
        -->> add
             left join lateral (select --ce.clearing_instr_id,
                                       count(*)::int                                                                as total_cnt,
                                       sum(case when electronic_report_status is not null then 1 else 0 end)::int   as status_sent,
                                       sum(case when electronic_report_status in ('I', 'R') then 1 else 0 end)::int as status_rejected,
                                       sum(case when electronic_report_status = 'P' then 1 else 0 end)::int         as status_pending,
                                       sum(case when electronic_report_status = 'A' then 1 else 0 end)::int         as status_accepted,
                                       sum(case when electronic_report_status is null then 1 else 0 end)::int       as status_null
                                from genesis2.clearing_instruction_entry ce
                                where true
                                  and ce.clearing_instr_id = ci.clearing_instr_id
                                limit 1) ce on true
    --<<
    where ci.is_deleted = 'N'
      and case
              when start_status_date is not null and end_status_date is not null
                  then ci.create_time between start_status_date and end_status_date
              else true end
      and case
              when clearing_instruction_id is not null then ci.clearing_instr_id = l_clearing_instruction_id
              else true end
      and case
              when l_user_id is not null then exists (select null
                                                      from genesis2.user_identifier ua
                                                      where ua.user_id = l_user_id
                                                        and ua.user_role = 'A'
                                                        and ua.is_deleted = 'N')
                  or (ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join staging.user2account ua
                                                                  on e.account_id = ua.account_id and
                                                                     ua.user_id = l_user_id and ua.user_role = 'P'
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(ua.account_id))
                      or
                      ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join (select acc.account_id
                                                                   from staging.trading_firm_admin2firm tf
                                                                            inner join genesis2.account acc
                                                                                       on tf.trading_firm_id = acc.trading_firm_id and acc.is_deleted = 'N'
                                                                            inner join genesis2.user_identifier ui
                                                                                       on ui.user_id = tf.user_id and ui.is_deleted = 'N'
                                                                   where ui.user_role = 'T'
                                                                     and tf.user_id = l_user_id) l
                                                                  on e.account_id = l.account_id
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(l.account_id))
                                                  )
              else true end;

    raise info '%: create temp  table ci on commit drop as', clock_timestamp();


    RETURN QUERY
        SELECT ci.clearing_instr_id,
               ci.date_id,
               ci.status,
               ci.remarks,
               o.trading_firm_names,
               o.display_instrument_ids,
               ci.create_time,
               ci.created_by_user_id,
               ci.claim_time,
               ci.claimed_by_user_id,
               ci.process_time,
               ci.claimed_by_user_name,
               ci.created_by_user_name,
               ci.modification_type,
               alc.alloc_instrument_ids,
               o.trading_firm_ids as new_trading_firm_ids,
               o.account_ids,
               case
                   when o.status_pending + o.status_rejected + o.status_invalid > 0 then 1
                   when status_accepted > 0 and total_cnt - status_accepted - not_supported = 0 then 2
                   else null end  as cie_agg_electronic_report_status,
               o.status_sent      as cie_sent_count,
               o.status_rejected  as cie_rejected_count,
               o.status_pending   as cie_pending_count,
               o.total_cnt        as cie_total_count,
               o.status_accepted  as cie_accepted_count,
               o.status_invalid   as cie_invalid_count,
               o.not_supported    as cie_not_supported_count,
               ci.clearing_submitted_away
        FROM ci
                 left join lateral (select array_agg(distinct orig_tf.trading_firm_name)                                 trading_firm_names,
                                           array_agg(distinct ce.account_id::int8)                                       account_ids,
                                           array_agg(distinct acc.trading_firm_id)                                       trading_firm_ids,
                                           array_agg(distinct i.display_instrument_id2)                                  display_instrument_ids,
                                           count(*)::int                                                              as total_cnt,
                                           sum(case when electronic_report_status is not null then 1 else 0 end)::int as status_sent,
                                           sum(case when electronic_report_status in ('R') then 1 else 0 end)::int    as status_rejected,
                                           sum(case when electronic_report_status = 'P' then 1 else 0 end)::int       as status_pending,
                                           sum(case when electronic_report_status = 'A' then 1 else 0 end)::int       as status_accepted,
                                           sum(case when electronic_report_status is null then 1 else 0 end)::int     as status_null,
                                           sum(case when electronic_report_status in ('I') then 1 else 0 end)::int    as status_invalid,
                                           sum(case when electronic_report_status in ('N') then 1 else 0 end)::int    as not_supported
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.trade_record tr on tr.trade_record_id =
                                                                                    coalesce(ce.new_trade_record_id, ce.trade_record_id) and
                                                                                    tr.date_id = ce.date_id
                                             inner join genesis2.instrument i
                                                        on i.instrument_id = tr.instrument_id and i.is_deleted = 'N'
                                             inner join genesis2.account acc
                                                        on acc.account_id = ce.account_id and acc.is_deleted = 'N'
                                             inner join genesis2.account orig_acc
                                                        on orig_acc.account_id = tr.account_id and orig_acc.is_deleted = 'N'
                                             inner join genesis2.trading_firm orig_tf
                                                        on orig_tf.trading_firm_id = orig_acc.trading_firm_id and
                                                           orig_tf.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
            ) o on 1 = 1
                 left join lateral (select ce.clearing_instr_id,
                                           array_agg(distinct a.alloc_instr_id) alloc_instrument_ids
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.alloc_instr2trade_record ai2tr
                                                        on ai2tr.trade_record_id =
                                                           coalesce(ce.new_trade_record_id, ce.trade_record_id)
                                             inner join genesis2.allocation_instruction a
                                                        on a.alloc_instr_id = ai2tr.alloc_instr_id and a.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
                                    group by ce.clearing_instr_id
                                    limit 1 ) alc on true
        order by ci.clearing_instr_id desc;

    raise info '%: DONE', clock_timestamp();

end;
$function$
;

DROP FUNCTION dash360.clearing_instruction_create(int4, bpchar, int4, bpchar, varchar);
CREATE OR REPLACE FUNCTION dash360.clearing_instruction_create(in_date_id integer, in_clearing_status character,
                                                               in_user_id integer, in_modification_type character,
                                                               in_json_values character varying,
                                                               in_clearing_submitted_away character DEFAULT 'N'::bpchar)
    RETURNS TABLE
            (
                trade_json    character varying[],
                clearing_json character varying[]
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- AK 20231129 : https://dashfinancial.atlassian.net/browse/D360-12491 added cboe_reason_code field to insert into genesis2.clearing_instruction_entry
-- PD 20240530 : https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo field to insert statement
-- OS 20241202 https://dashfinancial.atlassian.net/browse/DS-9047 added blaze_account_alias to output
-- OS 20250129 https://dashfinancial.atlassian.net/browse/DS-9502 add logging
-- OS 20260319 https://dashfinancial.atlassian.net/browse/DS-11283 Introduce new optional param "ClearingSubmittedAway" to PG. procedure dash360.clearing_instruction_create
declare

    l_clearing_instr_id int;
    trade_json          varchar[];
    clearing_json       varchar[];
    l_msg_text          text;
    l_load_id           int;
    l_step_id           int;
    l_row_cnt           int4;

begin
    l_msg_text :=
            'clearing_instruction_create for ' || in_date_id::text || ', clearing status: ' || in_clearing_status ||
            ', user_id: ' || in_user_id::text || ', modification_type: ' || in_modification_type ||
            ', clearing_submitted_away: ' || in_clearing_submitted_away::text || '. ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || '  STARTED ====', 0, 'O')
    into l_step_id;

    --VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
--insert into clearing_instruction
    insert into genesis2.clearing_instruction
    (clearing_instr_id, date_id, status, created_by_user_id, modification_type, clearing_submitted_away)
    values (nextval('clearing_instruction_clearing_instr_id_seq'::regclass), in_date_id, in_clearing_status, in_user_id,
            in_modification_type, in_clearing_submitted_away)
    returning clearing_instr_id into l_clearing_instr_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || '  Step 1 - insert into genesis2.clearing_instruction',
                           l_row_cnt, 'I')
    into l_step_id;
    /*INSERT INTO genesis2.clearing_instruction_entry
    (clearing_instr_entry_id, date_id, clearing_instr_id, trade_record_id, account_id, opt_customer_firm, open_close, last_qty, last_px, exec_broker, cmta, clearing_account_number, sub_account, remarks, trade_record_time, street_exec_broker, client_commission_rate, branch_sequence_number, trade_text, frequent_trader_id)
    VALUES(nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass), in_date_id, l_clearing_instr_id, @TradeRecordId, @AccountId, @Capacity, @OpenClose, @LastQty, @LastPx, @ExecBroker, @CMTA, @ClearingAccountNumber, @SubAccount, @Remarks, @TradeRecordTime, @StreetExecBroker, @CommissionRate, @BranchSeqNbr, @TradeText, @FrequentTraderId)
    returning clearing_instr_entry_id;*/

--insert into clearing_instruction_entry (most of values are from input param in_json_values)
    with ct as (select in_json_values::json as jsn),
         trd_ids as (select json_object_keys(jsn) as old_trade_record_id
                     from ct),
         tr_values as (select trd_ids.old_trade_record_id,
                              ct.jsn -> trd_ids.old_trade_record_id val_arr
                       from ct,
                            trd_ids)
    insert
    into genesis2.clearing_instruction_entry (clearing_instr_entry_id, date_id, clearing_instr_id, new_trade_record_id,
                                              trade_record_id, account_id, opt_customer_firm, open_close, last_qty,
                                              last_px, exec_broker, cmta, clearing_account_number,
                                              trade_liquidity_indicator, sub_account, remarks, trade_record_time,
                                              electronic_report_status, street_account_name, street_exec_broker,
                                              client_commission_rate, trade_text, branch_sequence_number,
                                              frequent_trader_id, box_additional_firm, electronic_report_error_text,
                                              cboe_reason_code, box_additional_client_memo, blaze_account_alias)
    select nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass),
           in_date_id,
           l_clearing_instr_id,
           (l.value ->> 'new_trade_record_id')::bigint,
           tr_values.old_trade_record_id::bigint,
           (l.value ->> 'account_id')::int,
           (l.value ->> 'opt_customer_firm')::bpchar,
           (l.value ->> 'open_close')::bpchar,
           (l.value ->> 'last_qty')::int,
           (l.value ->> 'last_px')::numeric,
           (l.value ->> 'exec_broker')::varchar,
           (l.value ->> 'cmta')::varchar,
           (l.value ->> 'clearing_account_number')::varchar,
           (l.value ->> 'trade_liquidity_indicator')::varchar,
           (l.value ->> 'sub_account')::varchar,
           (l.value ->> 'remarks')::varchar,
           (l.value ->> 'trade_record_time')::timestamp,
           (l.value ->> 'electronic_report_time')::varchar,
           (l.value ->> 'street_account_name')::varchar,
           (l.value ->> 'street_exec_broker')::varchar,
           (l.value ->> 'client_commission_rate')::numeric,
           (l.value ->> 'trade_text')::varchar,
           (l.value ->> 'branch_sequence_number')::varchar,
           (l.value ->> 'frequent_trader_id')::varchar,
           (l.value ->> 'box_additional_firm')::varchar,
           (l.value ->> 'electronic_report_error_text')::varchar,
           (l.value ->> 'cboe_reason_code')::varchar as r,
           (l.value ->> 'box_additional_client_memo')::varchar,
           l.value ->> 'blaze_account_alias'
    from tr_values,
         json_array_elements(tr_values.val_arr) l;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_msg_text || '  Step 2 - insert into genesis2.clearing_instruction_entry', l_row_cnt, 'I')
    into l_step_id;

    select array_agg(row_to_json(cte))
    into trade_json
    from (select l_clearing_instr_id as clearing_instr_id, *
          from dash360.clearing_instruction_modifications(l_clearing_instr_id)) cte;

    select public.load_log(l_load_id, l_step_id, l_msg_text || '  Step 3 - clearing_instruction_modifications',
                           l_row_cnt, 'O')
    into l_step_id;

    select array_agg(row_to_json(cte))
    into clearing_json
    from (select *
          from dash360.clearing_get_change_requests(clearing_instruction_id=>l_clearing_instr_id)) cte;

    select public.load_log(l_load_id, l_step_id,
                           l_msg_text || '  Step 4 - clearing_get_change_requests and COMPLETED ========', 0, 'O')
    into l_step_id;

    return query
        select trade_json, clearing_json;


end;
$function$
;


DROP FUNCTION dash360.allocations_snapshot(_int8, int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                        in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                        in_reported_status character DEFAULT NULL::character(1),
                                                        in_hide_non_customer_bphops boolean DEFAULT false)
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
                drop_message_status        character,
                drop_message_reject_reason text,
                client_commission_amount   numeric,
                client_order_id            character varying,
                client_order_status        character,
                clearing_submitted_away    character
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
    -- OS 20250305 hotfix for empty account_id list returns nothing
    -- OS 20250307 hotfix performance improvement
    -- OS 20251219 https://dashfinancial.atlassian.net/browse/DS-10632
    -- OS 20260107 https://dashfinancial.atlassian.net/browse/D360-16941 Return Total CCRU Amount for Execution Blotter, Change Clearing Pop-up, Allocations
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260313 https://dashfinancial.atlassian.net/browse/DS-11254 Adjust allocation_snapshot procedure to have a capability to filter out non-final BP trades by chain_id vs client_order_id
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
    -- OS 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
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

    /*
    select array_agg(account_id)
    into l_sg_accounts
    from genesis2.account
    where
    */

    analyze t_trade_record;
    create index on t_trade_record (trade_record_id);
    create index on t_trade_record (alloc_instr_id);
--     raise notice '2 - %', clock_timestamp();

    return query
        select tr.date_id::int4,
               tr.trade_record_id::int8,
               tr.account_id::int4,
               tr.instrument_id::int8,
               tr.side::character,
               tr.open_close::character,
               tr.last_px                                                                               as avg_px,
               tr.last_qty::int4                                                                        as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id::character,
               null::int4                                                                               as alloc_instr_id,
               null::timestamp without time zone                                                        as alloc_time,
               false                                                                                    as is_allocated,
               false                                                                                    as is_bundle,
               tr.cmta::character varying,
               tr.exec_broker::character varying,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                                  as principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
                   else CCRU.rate end                                                                   as client_commission_rate,
               null::character varying                                                                  as user_name,
               tr.blaze_account_alias::character varying,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)::timestamp without time zone as street_exec_time,
               ----------------
               i.last_trade_date                                                                        as expiration_date,
               tr.opt_customer_firm::character,
               coalesce(nullif(tr.is_billed, 'N'), rep.to_report)::character                            as reported_status,
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
                                   and tri.date_id = tr.date_id
                                 order by 1
                                 limit 1),
                                rep.db_create_time) end                                                 as reported_time,
               bas.claimed_by::int4                                                                     as claimed_by,
               bas.claim_status::character                                                              as claim_status,
               case when tr.is_billed = 'R' then true end                                               as is_prev_reported,
               msg.db_create_time                                                                       as db_create_time,
               msg.drop_message_status                                                                  as alloc_drop_msg_status,
               msg.drop_message_reject_reason                                                           as alloc_drop_msg_reject_reason,
               CCRU.amount                                                                              as client_commission_amount,
               tr.client_order_id                                                                       as client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = in_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1)
                   else null end::character                                                             as client_order_status,
               null::character                                                                          as clearing_submitted_away
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
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
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
                 left join lateral (select fix_message ->> '10707' as chain_id
                                    from staging.fix_message_json fmj
                                    where fmj.date_id = tr.date_id
                                      and fmj.fix_message_id = tr.trade_fix_message_id
                                    limit 1) fmj on in_hide_non_customer_bphops
        where tr.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then true else tr.account_id = any (in_account_ids) end
          and tr.is_busted = 'N'
--and false
          and allocated_trades.alloc_instr_id is NULL
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C')
                  when in_reported_status is null then true end
          and case
                  when in_hide_non_customer_bphops and (chain_id is not null and chain_id != tr.client_order_id)
                      then false
                  else true end;

--     raise notice '3 - %', clock_timestamp();

    return query
        select ai.date_id,
               null::int8                                        as trade_record_id,
               ai.account_id::int4,
               ai.instrument_id::int8,
               ai.side::character,
               ai.open_close::character,
               ai.avg_px::numeric,
               ai.total_qty::int4                                as exec_qty,
               i.display_instrument_id::character varying,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id::character,
               ai.alloc_instr_id::int4,
               ai.create_time::timestamp without time zone       as alloc_time,
               true                                              as is_allocated,
               true                                              as is_bundle,
               null::character varying                           as cmta,
               ccr.exec_broker::character varying                as exec_broker,
               case i.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                                              principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end                             as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying as user_name,
               ccr.blaze_account_alias::character varying,
               null::timestamp without time zone                 as street_exec_time,
               -------
               i.last_trade_date,
               null::character                                   as opt_customer_or_firm,
               rep.to_report::character                          as reported_status,
               rep.db_create_time                                as reported_time,
               bas.claimed_by                                    as claimed_by,
               bas.claim_status                                  as claim_status,
               null::boolean                                     as is_prev_reported,
               msg.db_create_time                                as db_create_time,
               msg.drop_message_status                           as alloc_drop_msg_status,
               msg.drop_message_reject_reason                    as alloc_drop_msg_reject_reason,
               ccr.amount                                        as client_commission_amount,
               case
                   when array_length(ccr.client_order_id, 1) > 1 then '-'
                   else ccr.client_order_id[1] end               as client_order_id,
               case
                   when array_length(ccr.order_status, 1) > 1 then '-'
                   else ccr.order_status[1] end ::char           as client_order_status,
               ai.clearing_submitted_away                        as clearing_submitted_away
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
                                           string_agg(distinct tr.exec_broker, ', ')                as exec_broker,
                                           sum(amount)                                              as amount,
                                           array_agg(distinct tr.client_order_id)                   as client_order_id,
                                           array_agg(distinct fpo.order_status)                     as order_status
                                    from genesis2.alloc_instr2trade_record alt
                                             inner join genesis2.trade_record tr
                                                        on alt.trade_record_id = tr.trade_record_id and alt.date_id = tr.date_id
                                             left join lateral (select rate,
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
                                             left join lateral (select distinct fpo.order_status
                                                                from staging.f_parent_order fpo
                                                                where fpo.status_date_id = in_date_id
                                                                  and fpo.parent_order_id = tr.order_id) fpo on true
                                    where alt.alloc_instr_id = ai.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and (l1.rn = 1 or l1.rn is null)
                                      and alt.date_id = in_date_id
                                      and tr.date_id = in_date_id
                                    limit 1
            ) ccr on true
                 left join lateral (select *
                                    from genesis2.alloc_drop_message_status msg
                                    where msg.alloc_instr_id = ai.alloc_instr_id
                                      and msg.drop_message_type = 'N'
                                    limit 1) msg on true

        where ai.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then true else ai.account_id = any (in_account_ids) end
          and ai.is_deleted = 'N'
--and false
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C', 'W') -- C the same as U
                  when in_reported_status is null then true end;
--     raise notice '4 - %', clock_timestamp();

end ;
$function$
;


DROP FUNCTION dash360.allocations_instruction_trades(int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_trades(in_alloc_instr_id integer)
    RETURNS TABLE
            (
                date_id                  integer,
                trade_record_id          bigint,
                account_id               integer,
                instrument_id            bigint,
                side                     character,
                open_close               character,
                avg_px                   numeric,
                exec_qty                 integer,
                display_instrument_id    character varying,
                last_trade_date          date,
                instrument_type_id       character,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                blaze_account_alias      character varying,
                street_exec_time         timestamp without time zone,
                expiration_date          timestamp without time zone,
                opt_customer_firm        character,
                reported_status          character,
                reported_time            timestamp without time zone,
                claimed_by               integer,
                claim_status             character,
                is_prev_reported         boolean,
                client_commission_amount numeric,
                client_order_id          character varying,
                client_order_status      character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
    -- OS 20250116 https://dashfinancial.atlassian.net/browse/DS-9337 changes in report_time using is_billed in trade_record
    -- OS 20260123 no ticket yet added client_commission_amount
    -- OS 20260309 https://dashfinancial.atlassian.net/browse/DS-11204 Support client_order_id in Allocation Procedures
    -- OS 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
declare
    l_date_id integer;
begin

    select ai.date_id
    from genesis2.allocation_instruction ai
    where ai.alloc_instr_id = in_alloc_instr_id
    into l_date_id;

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id::int8,
               tr.side,
               tr.open_close,
               tr.last_px                                                                       as avg_px,
               tr.last_qty                                                                      as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                          as principal_amount,
               CCRU.rate                                                                        as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                      as street_exec_time,
               ----------------
               i.last_trade_date                                                                as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                                  as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
                                                                                  from dash_reporting.bofa_allocation_report bar
                                                                                           join genesis2.alloc_instr2trade_record aitr
                                                                                                on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                                                                           join genesis2.trade_record tri
                                                                                                on tri.date_id =
                                                                                                   bar.date_id and
                                                                                                   tri.trade_record_id =
                                                                                                   aitr.trade_record_id
                                                                                  where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                                                                                    and tri.exec_id = tr.exec_id
                                                                                    and tri.is_billed = 'R'
                                                                                  order by 1
                                                                                  limit 1)) end as reported_time,
               null::int4                                                                       as claimed_by,
               null::character                                                                  as claim_status,
               case when tr.is_billed = 'R' then true else false end                            as is_prev_reported,
               CCRU.amount                                                                      as client_commission_amount,
               tr.client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = l_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1) end::character                                      as client_order_status
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 inner join genesis2.alloc_instr2trade_record ai2tr on (ai2tr.trade_record_id = tr.trade_record_id)
                 inner join genesis2.allocation_instruction a on (a.alloc_instr_id = ai2tr.alloc_instr_id)
                 left join lateral (select to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
                 left join lateral (select to_report, bar.db_create_time
                                    from dash_reporting.bofa_allocation_report bar
                                    where bar.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bar.date_id = ai2tr.date_id
                                    limit 1) bar on true
            --                  left join lateral (select bas.claimed_by, bas.claim_status
--                                     from dash_reporting.bofa_allocation_instruction_status bas
--                                     where bas.alloc_instr_id = ai2tr.alloc_instr_id
--                                       and bas.date_id = ai2tr.date_id
--                                     limit 1) bas on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , tl.book_record_type_id , tl.billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM genesis2.trade_level_book_record tl
                                                   inner join genesis2.book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND tl.book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;


DROP FUNCTION dash360.allocations_instruction_delete(int4, int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_delete(in_alloc_instr_id integer, in_user_id integer)
    RETURNS TABLE
            (
                date_id                  integer,
                trade_record_id          bigint,
                account_id               integer,
                instrument_id            bigint,
                side                     character,
                open_close               character,
                avg_px                   numeric,
                exec_qty                 bigint,
                display_instrument_id    character varying,
                last_trade_date          date,
                instrument_type_id       character,
                cmta                     character varying,
                exec_broker              character varying,
                principal_amount         numeric,
                client_commission_rate   numeric,
                blaze_account_alias      character varying,
                orig_trade_record_id     bigint,
                street_exec_time         timestamp without time zone,
                opt_customer_firm        character,
                reported_status          character,
                reported_time            timestamp without time zone,
                client_commission_amount numeric,
                client_order_id          character varying,
                client_order_status      character
            )
    LANGUAGE plpgsql
AS
$function$

-- SY 20210531 DS-3420 return type has been changed from id into query
   -- The logic to modify trade_record has been implemented
-- SY 20210617 https://dashfinancial.atlassian.net/browse/DS-3642 CMTA field has been added to revertion process
-- VP 20231130 https://dashfinancial.atlassian.net/browse/DS-7591 Added field street_exec_time
-- SO 20250116 https://dashfinancial.atlassian.net/browse/DS-9407 Add new fields is_prev_reported, opt_customer_firm
-- SO 20250528 https://dashfinancial.atlassian.net/browse/DS-10041 Added status='U' for deleted instruction
-- SO 20261112 https://dashfinancial.atlassian.net/browse/DS-11248 Support client_order_id in dash360.allocations_instruction_delete()
-- SO 20260317 https://dashfinancial.atlassian.net/browse/DS-11268 Support client_order_status for Allocation Instructions - allocation_snapshot, allocation_instruction_trades, allocation_insttuction_delete
declare
    l_user_id              int;
    l_system_id            varchar;
    l_revert_vector        jsonb;
    l_new_trade_record_ids bigint[];
    l_date_id              int;
    l_load_batch_id        bigint;
    l_step_id              int;
begin
    l_step_id := 0;

    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete STARTED =====', 0,
                             'S'::char)
    into l_step_id;

    with ct as ( update genesis2.allocation_instruction ai
        set
            is_deleted = 'Y',
            delete_time = 'now'::timestamp,
            deleted_by_user_id = in_user_id,
            status = 'U'
        where alloc_instr_id = in_alloc_instr_id
        returning ai.created_by_user_id, ai.created_by_subsystem_id, ai.date_id)
    select ct.created_by_user_id, ct.created_by_subsystem_id, ct.date_id
    into l_user_id, l_system_id, l_date_id
    from ct;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'genesis2.allocation_instruction updated', 0, 'S'::char)
    into l_step_id;


--  raise info '%: l_user_id=%, l_system_id=%, date_id = %', clock_timestamp(),l_user_id, l_system_id, l_date_id ;

    if l_user_id is null and l_system_id = 'RPS'
    then
        l_new_trade_record_ids := array []::bigint[];
    else
        /* UNALLOCATE MANUAL ALLOCATION with reverting trade_record changes*/
        select ('{' || string_agg('"' || tr.trade_record_id || '":[{"clearing_account_number":"' ||
                                  coalesce(orig_tr.clearing_account_number, 'NULL') || '"
															  , "account_nickname":"' ||
                                  coalesce(orig_tr.account_nickname, 'NULL') || '"
															  , "street_account_name":"' ||
                                  coalesce(orig_tr.street_account_name, 'NULL') || '"
															  , "cmta":"' || coalesce(orig_tr.cmta, 'NULL') || '"
		      												  , "allocation_avg_price":"NULL"
															  , "trade_record_reason":"U"
															  , "user_id":' || in_user_id || '}]', ',') || '}')::jsonb
        into l_revert_vector
        from alloc_instr2trade_record aitr
                 inner join trade_record tr on aitr.trade_record_id = tr.trade_record_id and tr.is_busted = 'N' and
                                               tr.date_id = aitr.date_id and trade_record_reason = 'L'
                 inner join trade_record orig_tr
                            on tr.orig_trade_record_id = orig_tr.trade_record_id and tr.date_id = orig_tr.date_id
        where aitr.alloc_instr_id = in_alloc_instr_id
          and aitr.date_id = l_date_id;

        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_revert_vector defined ', 0, 'S'::char)
        into l_step_id;

        raise info 'Revert vector is %', l_revert_vector;

        if l_revert_vector is not null
        then
            l_new_trade_record_ids := dash360.ptm_process_trades(l_date_id, in_user_id, l_revert_vector);
--        then l_new_trade_record_ids:=trash.so_ptm_process_trades(l_date_id, in_user_id, l_revert_vector);

            select genesis2.load_log(l_load_batch_id::int, l_step_id, 'cardinality(l_new_trade_record_ids): ',
                                     cardinality(l_new_trade_record_ids), 'S'::char)
            into l_step_id;

            perform dash360.trade_record_update_ccru(in_user_id =>in_user_id, in_date_id => l_date_id,
                                                     in_trade_record_id =>l.trade_record_id, in_rate => l.rate,
                                                     in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
            from (select tr.trade_record_id::bigint,
                         tlbr.rate,
                         tr.last_qty * tlbr.rate                                                                                 as amount,
                         row_number()
                         over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
                  from genesis2.trade_record tr
                           inner join genesis2.trade_level_book_record tlbr
                                      on tlbr.date_id = tr.date_id and
                                         tlbr.trade_record_id = tr.orig_trade_record_id and
                                         book_record_type_id = 'CCRU'
                           inner join genesis2.book_record_creator brc
                                      on tlbr.book_record_creator_id = brc.book_record_creator_id
                  where tr.date_id = l_date_id
                    and tr.trade_record_id = any (array [l_new_trade_record_ids])) l
            where rn = 1;

        else
            select array_agg(trade_record_id::bigint)
            into l_new_trade_record_ids
            from alloc_instr2trade_record a
            where a.date_id = l_date_id
              and a.alloc_instr_id = in_alloc_instr_id;
        end if;
        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'After IF ', 0, 'S'::char)
        into l_step_id;

    end if;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_instruction_delete returning query', 0,
                             'S'::char)
    into l_step_id;

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id::bigint,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty::bigint                                         as exec_qty,
               i.display_instrument_id2,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                     as principal_amount,
               CCRU.rate                                                   as client_commission_rate,
               tr.blaze_account_alias,
               tr.orig_trade_record_id::bigint,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               tr.opt_customer_firm,
               case when tr.is_billed = 'R' then 'R'::char end             as reported_status,
               case
                   when true
                       and tr.is_billed = 'R'
                       then (select bar.db_create_time
                             from dash_reporting.bofa_allocation_report bar
                                      join genesis2.alloc_instr2trade_record aitr
                                           on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                      join genesis2.trade_record tri
                                           on tri.date_id = bar.date_id and tri.trade_record_id = aitr.trade_record_id
                             where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                               and tri.exec_id = tr.exec_id
                               and tri.is_billed = 'R'
                             order by 1
                             limit 1) end                                  as reported_time,
               CCRU.amount                                                 as client_commission_amount,
               tr.client_order_id,
               case
                   when true then (select fpo.order_status
                                   from staging.f_parent_order fpo
                                   where fpo.status_date_id = l_date_id
                                     and fpo.parent_order_id = tr.order_id
                                   limit 1) end::character                 as client_order_status
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate, l1.amount
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate,
                                                 tl.amount
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
                 left join lateral (select to_report, btr.db_create_time
                                    from dash_reporting.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and tr.trade_record_id = any (l_new_trade_record_ids);

end;

$function$
;

-- DROP FUNCTION dash360.get_data_for_allocation_drop_sg(int8, int4);

CREATE OR REPLACE FUNCTION dash360.get_data_for_allocation_drop_sg(in_alloc_instr_id bigint, in_date_id integer DEFAULT NULL::integer)
    RETURNS jsonb
    LANGUAGE plpgsql
AS
$function$
    -- 20251027 SO https://dashfinancial.atlassian.net/browse/DS-10634
    -- 20251119 SO https://dashfinancial.atlassian.net/browse/DS-10739
    -- 20251205 SO https://dashfinancial.atlassian.net/browse/DS-10739 New atrributes in the result json were added
    -- 20260217 SO https://dashfinancial.atlassian.net/browse/DS-11116 version for SG
    -- 20260223 SO https://dashfinancial.atlassian.net/browse/DS-11134 applied filter for is_busted for cancels only
    -- 20260227 SO https://dashfinancial.atlassian.net/browse/DS-11173 Add new output param
declare
    l_return_jsonb jsonb;
begin
    select into l_return_jsonb jsonb_build_object('tradeDate', ai.date_id,
                                                  'processTime', ai.create_time,
                                                  'noAllocs', aie.alloc_cnt,
                                                  'allocationEntries', aie.entries,
                                                  'AllocInstrId', ai.alloc_instr_id,
                                                  'instrumentTypeId', di.instrument_type_id
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
--                                  and tr.is_busted = 'N'
                                  and case when ai.is_deleted = 'Y' then true else tr.is_busted = 'N' end
                                  and (l1.rn = 1 or l1.rn is null)
        ) ccr on true

             join lateral (select count(*) as alloc_cnt,
                                  jsonb_agg(jsonb_build_object('allocAccount', ac.opt_occ_id,
                                                               'allocQty', aie.alloc_qty,
                                                               'clrFirm', ca.clearing_firm,
                                                               'actionableId', aie.occ_actionable_id,
                                                               'EquityBRID', ca.sg_equity_brid,
                                                               'OptionBRID', ca.sg_opt_brid,
                                                               'subAccount', ca.sg_sub_account_name,
                                                               'individualAllocID', aie.allocation_instruction_entry_id,
                                                               'salesTrader', ca.sg_sales_trader,
                                                               'sgMintAccount', ca.sg_mint_account,
                                                               'AllocEntryCCRURate', ccr.rate,
                                                               'AllocEntryCCRUTotalAmount',
                                                               ccr.amount * 1.0 * aie.alloc_qty / total_qty
                                            ))
                                           as entries
                           from genesis2.allocation_instruction_entry aie
                                    left join genesis2.sg_allocation_configuration ca
                                              on (ca.sg_alloc_config_id = aie.sg_alloc_config_id)
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = ai.alloc_instr_id
                             and aie.date_id = ai.date_id
                           limit 1) aie on true
             left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
             left join genesis2.option_series os on oc.option_series_id = os.option_series_id
    where true
      and ai.alloc_instr_id = in_alloc_instr_id
      and case when in_date_id is null then true else ai.date_id = in_date_id end;
    return l_return_jsonb;
end ;
$function$
;


DROP FUNCTION dash360.clearing_get_trades_by_trade_record_id(int4, _int8);

CREATE OR REPLACE FUNCTION dash360.clearing_get_trades_by_trade_record_id(in_date_id integer, in_trade_record_id bigint[])
    RETURNS TABLE
            (
                trade_record_id            bigint,
                orig_trade_record_id       bigint,
                trade_record_reason        character,
                is_busted                  character,
                trade_record_time          timestamp without time zone,
                account_id                 bigint,
                side                       character,
                open_close                 character,
                instrument_id              bigint,
                instrument_type_id         character,
                display_instrument_id      character varying,
                last_qty                   integer,
                last_px                    numeric,
                exec_broker                character varying,
                opt_customer_firm          character,
                clearing_account_number    character varying,
                sub_account                character varying,
                cmta                       character varying,
                real_exchange_id           character varying,
                remarks                    character varying,
                trade_liquidity_indicator  character varying,
                last_trade_date            timestamp without time zone,
                street_exec_broker         character varying,
                street_account_name        character varying,
                client_commission_rate     numeric,
                blaze_account_alias        character varying,
                branch_sequence_number     character varying,
                trade_text                 character varying,
                frequent_trader_id         character varying,
                date_id                    integer,
                box_additional_firm        character varying,
                cboe_reason_code           character varying,
                box_additional_client_memo character varying,
                alloc_instr_id             integer
            )
    LANGUAGE plpgsql
AS
$function$
begin
    -- VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
    -- AK 20230921 https://dashfinancial.atlassian.net/browse/DS-7299 has been chnaged cie.trade_record_id = tr.trade_record_id to cie.new_trade_record_id = tr.trade_record_id
    -- AK 20231129 https://dashfinancial.atlassian.net/browse/D360-12491 added cboe_reason_code field to return table
    -- PD 20240530 https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo to output
    -- OS 20260325 https://dashfinancial.atlassian.net/browse/DS-11311 add alloc_instr_id to clearing_select_trades_for_validation as return param
    return query
        select tr.trade_record_id::bigint,
               tr.orig_trade_record_id::bigint,
               tr.trade_record_reason,
               tr.is_busted,
               tr.trade_record_time,
               tr.account_id::bigint,
               tr.side,
               tr.open_close,
               i.instrument_id,
               i.instrument_type_id,
               i.display_instrument_id2 as display_instrument_id,
               tr.last_qty,
               tr.last_px,
               tr.exec_broker,
               tr.opt_customer_firm,
               tr.clearing_account_number,
               tr.sub_account,
               tr.cmta,
               e.real_exchange_id,
               tr.remarks,
               tr.trade_liquidity_indicator,
               i.last_trade_date,
               tr.street_exec_broker,
               tr.street_account_name,
               CCRU.rate                as client_commission_rate,
               tr.blaze_account_alias,
               tr.branch_sequence_number,
               tr.trade_text,
               tr.frequent_trader_id,
               tr.date_id,
               cie.box_additional_firm,
               cie.cboe_reason_code,
               cie.box_additional_client_memo,
               aitr.alloc_instr_id
        from trade_record tr
                 inner join instrument i on (tr.instrument_id = i.instrument_id)
                 left join exchange e on e.exchange_id = tr.exchange_id and e.is_active = 'Y'
                 left join clearing_instruction_entry cie on cie.new_trade_record_id = tr.trade_record_id and
                                                             cie.opt_customer_firm = tr.opt_customer_firm
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id
                                            and tl.date_id >= in_date_id) l1
                                    where rn = 1
            ) CCRU on true
                 left join lateral (select ar.alloc_instr_id
                                    from genesis2.alloc_instr2trade_record ar
                                    where ar.date_id = in_date_id
                                      and ar.trade_record_id = tr.trade_record_id
                                    limit 1) aitr on true
        where tr.date_id >= in_date_id
          and tr.is_busted = 'N'
          and tr.trade_record_id = any (in_trade_record_id);
end;
$function$
;


DROP FUNCTION dash360.allocations_create(int4, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.allocations_create(in_date_id integer, in_user_id integer,
                                                      in_change_vector character varying,
                                                      in_clearing_submitted_away character DEFAULT NULL::bpchar)
    RETURNS bigint
    LANGUAGE plpgsql
AS
$function$
    -- SY 20210319 Initial creation
    -- SY 20210420 DS-3363 Fix CCRU has been added
    -- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
    -- SY 20240813 https://dashfinancial.atlassian.net/browse/DS-8581 Reverted
    -- SY 20240816 https://dashfinancial.atlassian.net/browse/DS-8208 in_user_id has been propagated to f_get_clearing_account_id to make possible user_id autocreation save
    -- SY\SO 20250704 https://dashfinancial.atlassian.net/browse/DS-10177 providing alloc_instr_entry_id into alloc_instr2trade_record
    -- SO 20251220 https://dashfinancial.atlassian.net/browse/DS-10030
    -- SO 20260210 https://dashfinancial.atlassian.net/browse/DS-11079 add sg_allocation_configuration
    -- SO 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
declare
    l_change_vector        jsonb;
    l_new_trade_record_ids bigint[];
    scr                    record;
    l_alloc_instr          int;
    l_load_batch_id        bigint;
    l_step_id              int;
    l_row_cnt              int;


begin
    l_step_id := 0;
    select nextval('genesis2.allocation_instruction_alloc_instr_id_seq'::regclass) into l_alloc_instr;
    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create STARTED =====', 0, 'S'::char)
    into l_step_id;

    l_change_vector := in_change_vector::jsonb;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_change_vector converted to jsonb', 1, 'I'::char)
    into l_step_id;

    for scr in (select e.clearing_instr_id
                from clearing_instruction_entry e
                         inner join clearing_instruction ca
                                    on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
                where e.date_id = in_date_id
                  and ca.status in ('P', 'C')
                  and e.trade_record_id in (select jsonb_object_keys(l_change_vector)::bigint)
                limit 1)
        loop
            --   raise exception using message = 'S 167', detail = 'D 167', hint = 'H 167', errcode = 'P3333';

            raise exception 'Error: Clearing change request is in progress. Please wait till it is processed' using errcode = 'CLRIP', /*message='Can''t be allocated due to pending clearing',*/ hint = 'Please finish or reject clearing request before allocating it';
        end loop;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Before PTM', 1, 'I'::char)
    into l_step_id;

    l_new_trade_record_ids := dash360.ptm_process_trades(in_date_id, in_user_id, l_change_vector);

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'PTM DONE', cardinality(l_new_trade_record_ids),
                             'I'::char)
    into l_step_id;


    with tr as materialized
             (select tr.trade_record_id
                   , tr.account_id
                   , tr.instrument_id
                   , tr.last_qty
                   , tr.allocation_avg_price
                   , tr.open_close
                   , tr.side
                   , tr.street_account_name
                   , tr.account_nickname
                   , tr.cmta
                   , tr.clearing_account_number
                   , i.instrument_type_id
                   , wh.jsn ->> 'alloc_config_id' as alloc_config_id
              from genesis2.trade_record tr
                       inner join genesis2.instrument i on tr.instrument_id = i.instrument_id
                       join whole wh on (wh.jsn ->> 'trade_record_id')::int8 = tr.trade_record_id -- the temp table whole is created inside the dash360.ptm_process_trades (SO)
              where date_id = in_date_id
                and trade_record_id = any (l_new_trade_record_ids)
                and is_busted = 'N'),
         pre_aie as (select --l_alloc_instr,
                          -- in_date_id,
                         dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number,
                                                           tr.account_nickname, tr.street_account_name,
                                                           tr.instrument_type_id, in_user_id)                   as clearing_account_id
                          , tr.street_account_name
                          , tr.account_nickname
                          , sum(last_qty)                                                                       as last_qty
                          , nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as alloc_instr_entry_id
                          , array_agg(trade_record_id)                                                          as trade_record_ids
                          , alloc_config_id
                     from tr
                     group by clearing_account_id, street_account_name, account_nickname, alloc_config_id)
            ,
         aie as ( INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id,
                                                            occ_actionable_id,
                                                            account_nickname, alloc_qty,
                                                            allocation_instruction_entry_id, sg_alloc_config_id)
             select l_alloc_instr,
                    in_date_id,
                    clearing_account_id,
                    street_account_name,
                    account_nickname,
                    last_qty,
                    alloc_instr_entry_id,
                    alloc_config_id::int4
             from pre_aie
             returning *),
         a2tr as (INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id,
                                                        allocation_instruction_entry_id)
             select unnest(trade_record_ids), l_alloc_instr, in_date_id, l_load_batch_id, alloc_instr_entry_id
             from pre_aie
             /* inner join aie on aie.clearing_account_id = tr.clearing_account_id and
                                coalesce(tr.occ_actionable_id, '---') = coalesce(aie.occ_actionable_id, '---') and
                                coalesce(tr.account_nickname, '---') = coalesce(aie.account_nickname, '---') */ )
    INSERT
    INTO allocation_instruction
    (alloc_instr_id, date_id, create_time, account_id, instrument_id, total_qty, avg_px, open_close, side,
     created_by_user_id, dataset_id, clearing_submitted_away)
    select l_alloc_instr,
           in_date_id,
           clock_timestamp(),
           account_id,
           instrument_id,
           sum(last_qty),
           allocation_avg_price,
           open_close,
           side,
           in_user_id,
           l_load_batch_id,
           in_clearing_submitted_away

    from tr
    group by account_id, instrument_id, allocation_avg_price, open_close, side;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocation tables popultaed', l_row_cnt, 'I'::char)
    into l_step_id;


    -- Fix CCRU
--    select count(1)
    -- into l_cnt;
--	from (
    perform dash360.trade_record_update_ccru(in_user_id =>in_user_id, in_date_id => in_date_id,
                                             in_trade_record_id =>l.trade_record_id, in_rate => l.rate,
                                             in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
    from (select tr.trade_record_id::bigint,
                 tlbr.rate,
                 tr.last_qty * tlbr.rate                                                                                 as amount,
                 row_number()
                 over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
          from genesis2.trade_record tr
                   inner join genesis2.trade_level_book_record tlbr
                              on tlbr.date_id = tr.date_id and tlbr.trade_record_id = tr.orig_trade_record_id and
                                 book_record_type_id = 'CCRU'
                   inner join genesis2.book_record_creator brc
                              on tlbr.book_record_creator_id = brc.book_record_creator_id
          where tr.date_id = in_date_id
            and tr.trade_record_id = any (array [l_new_trade_record_ids])) l
    where rn = 1
--				) L2
    ;
    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'CCRU subscribed', 0, 'I'::char)
    into l_step_id;


    Perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id,
                                   in_row_cnt => 1,
                                   in_subscription_name => 'allocation_to_big_data',
                                   in_source_table_name => 'genesis2.allocation_instruction',
                                   in_date_id => in_date_id);

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocations subscribed', 0, 'I'::char)
    into l_step_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'DONE', 0, 'E'::char)
    into l_step_id;

    return l_alloc_instr;

exception
    when others then
        select genesis2.load_log(l_load_batch_id::int, l_step_id,
                                 left(sqlstate || ': ' || REPLACE(sqlerrm, ''::text, ''::text), 250), 0, 'E'::char)
        into l_step_id;
        -- RAISE notice '% %', sqlstate, sqlerrm;

        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create DONE ====', 0, 'E'::char)
        into l_step_id;

        PERFORM genesis2.load_error_log('allocations_create'::varchar, 'I'::char,
                                        REPLACE(sqlerrm, ''::text, ''::text)::varchar, l_load_batch_id::int);
        RAISE;

end;
$function$
;

DROP FUNCTION dash360.allocations_instruction_entries(int4, int4);

CREATE OR REPLACE FUNCTION dash360.allocations_instruction_entries(in_alloc_instr_id integer, in_date_id integer)
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
                sg_brid                         character varying,
                sg_sub_account_name             character varying,
                sg_mint_account                 character varying,
                sg_alloc_config_id              integer,
                allocation_instruction_entry_id bigint,
                clearing_submitted_away         character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SO: 20251103 https://dashfinancial.atlassian.net/browse/D360-16593
    -- SO: 20251119 https://dashfinancial.atlassian.net/browse/DS-10739 added sg_mint_account
    -- SO: 20260210 https://dashfinancial.atlassian.net/browse/DS-11079 added sg_allocation_configuration
    -- SO: 20260318 https://dashfinancial.atlassian.net/browse/DS-11271 Process clearing_submitted_away field in allocation workflows
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
               ca.sg_mint_account,
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


-- DROP FUNCTION dash360.get_sg_alloc_config(_int8, _int4, bool);

CREATE OR REPLACE FUNCTION dash360.get_sg_alloc_config(in_parent_account_id bigint[] DEFAULT NULL::integer[],
                                                       in_sg_alloc_config_id integer[] DEFAULT NULL::integer[],
                                                       in_include_deleted boolean DEFAULT false)
    RETURNS SETOF tp_sg_allocation_configuration
    LANGUAGE plpgsql
AS
$function$
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


-- DROP FUNCTION dash360.set_sg_alloc_config(int4, text, int4);

CREATE OR REPLACE FUNCTION dash360.set_sg_alloc_config(in_user_id integer, in_json text,
                                                       in_sg_alloc_config_id integer DEFAULT NULL::integer)
    RETURNS SETOF tp_sg_allocation_configuration
    LANGUAGE plpgsql
AS
$function$
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
