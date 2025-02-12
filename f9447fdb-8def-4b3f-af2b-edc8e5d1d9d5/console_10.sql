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
where br.date_id = :in_date_id
union all
select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
from dash_reporting.bofa_trade_record btr
where btr.date_id = :in_date_id;

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
       null                           as exec_broker,
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
       null::boolean,
       ccr.exec_broker
from genesis2.allocation_instruction ai
         inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
         left join lateral (select rep.to_report, rep.db_create_time
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
                                                        where tl.date_id = :in_date_id
                                                          AND tl.book_record_type_id = 'CCRU'
                                                          and tl.trade_record_id = alt.trade_record_id) l1
                                               on true
                            where alt.alloc_instr_id = ai.alloc_instr_id
                              and tr.is_busted = 'N'
                              and (l1.rn = 1 or l1.rn is null)
    ) ccr on true

where ai.date_id = :in_date_id
--           and case when in_account_ids = '{}' then true else ai.account_id = any (in_account_ids) end
  and ai.is_deleted = 'N'
  and case
          when in_reported_status = 'R' then rep.to_report = 'R'
          when in_reported_status = 'U' then rep.to_report in ('U', 'C') -- C the same as U
          when in_reported_status is null then true end;


select tr.is_billed, atr.alloc_instr_id, atr.trade_record_id, *
from genesis2.alloc_instr2trade_record atr
         join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
where atr.date_id = 20250211
order by atr.alloc_instr_id;


select atr.alloc_instr_id, count(distinct tr.is_billed)
from genesis2.alloc_instr2trade_record atr
         join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
where atr.date_id = 20250211
group by atr.alloc_instr_id;

create function staging.get_fully_reported_trade(in_alloc_instr_id int4, in_trade_record_id int8, in_date_id int4)
    returns boolean
    language plpgsql
as
$fx$
declare

begin
    select count(distinct tr.is_billed)
    from genesis2.alloc_instr2trade_record atr
             join genesis2.trade_record tr on tr.trade_record_id = atr.trade_record_id and tr.date_id = atr.date_id
    where atr.date_id = in_date_id
      and atr.alloc_instr_id = in_alloc_instr_id
        an
end;
$fx$;


select *
from dash360.allocations_snapshot(in_date_id := 20250211);
select * from dash360.report_alloc_instr_trade_record(20250211, '733')

drop function if exists dash360.report_alloc_instr_trade_record;
create or replace function dash360.report_alloc_instr_trade_record(in_date_id integer, in_exec_broker text)
    returns table
        -- select
        -- exec_broker as "Exec Broker", type as "Type", account_name as "Account Name", alloc_instr_id # only as "Alloc Instr ID", trade_record_id as "Trade Record ID",
        -- sybmol as "Symbol", side  as "Side", open_close as "O/C", exec_qty as "Exec Qty", avg_px as "Avg Px", reported_status as "Reported Status",
        -- reported_time as "Reported Time", is_deleted as "Alloc is deleted", is_busted as "Trade is busted", deleted_by_user_name as "Deleted by User", deleted_time as "Deleted time"
        --
            (
                "Exec Broker"       text,
                "Type"              text,
                "Account Name"      text,
                "Trading Firm Name" text,
                "Alloc Instr ID"    int4,
                "Trade Record ID"   int8,
                "Symbol"            text,
                "Side"              text,
                "O/C"               text,
                "Exec Qty"          int4,
                "Avg Px"            numeric,
                "CMTA"              text,
                "OCC AID"           text,
                "Capacity"          text,
                "Reported Status"   text,
                "Reported Time"     timestamp,
                "Trade is busted"   bpchar,
                "Created Time"      timestamp,
                "Created by User"   text,
                "Alloc is deleted"  bpchar,
                "Deleted Time"      timestamp,
                "Deleted by User"   text
            )
    language plpgsql
as
$function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
    -- 2025-02-12 OS https://dashfinancial.atlassian.net/browse/DS-9572 add new columns
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker"
               'allocation',                                                            -- "Type"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID"
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty"
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"
               
               'Reported',                                                              -- "Reported Status"
               min(bar.db_create_time),                                                 -- "Reported Time"
               '',                                                                      -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted"
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name)                                                        -- "Deleted by User"

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and ui.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
        group by bar.alloc_instr_id

        union all


        select tr.exec_broker::varchar(32),                                                  -- "Exec Broker"
               'trade',                                                                      -- "Type"
               ac.account_name,                                                              -- "Account Name"
               tf.trading_firm_name,                                                         -- "Trading Firm Name"
               null,                                                                         -- "Alloc Instr ID"
               btr.trade_record_id,                                                          -- "Trade Record ID"
               di.display_instrument_id2,                                                    -- "Symbol"
               case tr.side when '1' then 'Buy' when '2' then 'Sell' end,                    -- "Side"
               case tr.open_close when 'O' then 'Open' when 'C' then 'Close' end,            -- "O/C"
               tr.last_qty,                                                                  -- "Exec Qty"
               tr.last_px,                                                                   -- "Avg Px"
               null,                                                                         -- "CMTA"
               null,                                                                         -- "OCC AID"
               concat_ws(': ', tr.opt_customer_firm, cst.customer_or_firm_name),             -- "Capacity"
               'Reported',                                                                   -- "Reported Status"
               coalesce((select bar.db_create_time
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
                         limit 1), tr.db_create_time),                                         -- "Reported Time"
               tr.is_busted,                                                                   -- "Trade is busted"
               null,                                                                           -- "Created Time"
               null,                                                                           -- "Created by User"
               null,                                                                           -- "Alloc is deleted"
               null,                                                                           -- "Deleted Time"
               null                                                                            -- "Deleted by User"

        from dash_reporting.bofa_trade_record btr
                 join genesis2.trade_record tr using (trade_record_id, date_id)
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = tr.instrument_id
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = tr.opt_customer_firm
        where btr.date_id = in_date_id
          and btr.to_report = 'R'
          and tr.exec_broker = in_exec_broker;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;


-- DROP FUNCTION dash360.report_alloc_instr_trade_record(int4, text);
select ai.*
from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and ui.is_deleted <> 'Y'
        where bar.date_id = :in_date_id
          and bar.to_report = 'R'