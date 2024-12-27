alter table dash360.bofa_allocation_report drop column last_qty;
update dash360.bofa_allocation_report
set to_report = case
                    when to_report = 'report' then 'R'
                    when to_report = 'skip - alloc_instr_id has been reported before' then 'U'
                    else 'C'
    end;

alter table dash360.bofa_allocation_report
    alter column to_report type bpchar;
-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4);

select * from dash360.bofa_allocation_report;
drop function dash360.so_allocations_snapshot;
create function dash360.so_allocations_snapshot(in_account_ids bigint[] default '{}'::bigint[],
                                                in_date_id integer default public.get_dateid(current_date),
                                                in_reported_status bpchar(1) default null::bpchar(1))
    returns table
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                alloc_instr_id         integer,
                alloc_time             timestamp without time zone,
                is_allocated           boolean,
                is_bundle              boolean,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                username               character varying,
                blaze_account_alias    character varying,
                street_exec_time       timestamp without time zone,
                expiration_date        timestamp without time zone,
                opt_customer_firm      char,
                reported_status        bpchar,
                reported_time          timestamp,
                claimed_by             text,
                claim_status           text
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    --in_date_id = 20190301;
    -- VP 20231030 https://dashfinancial.atlassian.net/browse/DS-7465 [ALLOC] Return street_exec_time in dash360.allocations_snapshot()
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters and removed if-else condition for empty in_account_id
begin
    drop table if exists t_trade_record;
    create temp table t_trade_record
    as
    select atr.trade_record_id, br.to_report, br.alloc_instr_id, br.db_create_time
    from dash360.bofa_allocation_report br
             join genesis2.alloc_instr2trade_record atr
                  on atr.alloc_instr_id = br.alloc_instr_id and atr.date_id = br.date_id
    where br.date_id = in_date_id
    union all
    select btr.trade_record_id, 'R', 0, btr.db_create_time
    from dash360.bofa_trade_record btr
    where btr.date_id = in_date_id;

    create index on t_trade_record (trade_record_id);

    return query
        select tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
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
               coalesce(rep.to_report, 'N')                                as reported_status,
               rep.db_create_time                                          as reported_time,
               null::text                                                  as claimed_by,
               null::text                                                  as claim_status

        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 left join t_trade_record rep on rep.trade_record_id = tr.trade_record_id
                 left join genesis2.account acc on acc.account_id = tr.account_id
                 left join (select ai2tr.trade_record_id, a.alloc_instr_id
                            from genesis2.allocation_instruction a
                                     inner join genesis2.alloc_instr2trade_record ai2tr
                                                on (a.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = a.date_id)
                            where true
                              and case when in_account_ids = '{}' then true else a.account_id = any (in_account_ids) end
                              and a.date_id = in_date_id
                              and a.is_deleted = 'N') allocated_trades
                           on allocated_trades.trade_record_id = TR.TRADE_RECORD_ID
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
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
               null::bigint                   as trade_record_id,
               ai.account_id::integer,
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
               acc.opt_customer_or_firm,
               coalesce(rep.to_report, 'N')   as reported_status,
               rep.db_create_time             as reported_time,
               null::text                     as claimed_by,
               null::text                     as claim_status
        from genesis2.allocation_instruction ai
                 inner join genesis2.instrument i on (ai.instrument_id = i.instrument_id)
                 left join t_trade_record rep on rep.alloc_instr_id = ai.alloc_instr_id
                 left join genesis2.account acc on acc.account_id = ai.account_id
                 left join genesis2.user_identifier ui on ai.created_by_user_id = ui.user_id
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select sum(l1.rate * tr.last_qty) / nullif(sum(tr.last_qty), 0) as rate,
                                           case
                                               when count(distinct tr.blaze_account_alias) = 1
                                                   then max(tr.blaze_account_alias)
                                               when count(distinct tr.blaze_account_alias) > 1 then '-'
                                               else null
                                               end                                                  as blaze_account_alias
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

        where ai.date_id = in_date_id
          and case when in_account_ids = '{}' then true else ai.account_id = any (in_account_ids) end
          and ai.is_deleted = 'N'
          and case
                  when in_reported_status = 'R' then rep.to_report = 'R'
                  when in_reported_status = 'U' then rep.to_report in ('U', 'C')
                  when in_reported_status is null then true end;

end ;
$function$
;


select * from dash360.so_allocations_snapshot(in_account_ids := '{}', in_date_id := 20241224, in_reported_status := null);



-- DROP FUNCTION dash360.allocations_instruction_trades(int4);

create or replace function dash360.so_allocations_instruction_trades(in_alloc_instr_id integer)
    returns table
            (
                date_id                integer,
                trade_record_id        bigint,
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying,
                last_trade_date        date,
                instrument_type_id     character,
                cmta                   character varying,
                exec_broker            character varying,
                principal_amount       numeric,
                client_commission_rate numeric,
                blaze_account_alias    character varying,
                street_exec_time       timestamp without time zone,
                expiration_date        timestamp without time zone,
                opt_customer_firm      char,
                reported_status        bpchar,
                reported_time          timestamp,
                claimed_by             text,
                claim_status           text
            )
    language plpgsql
    cost 1
AS
$function$
    --l_date_id := in_date_id;
    --VP 20231101 https://dashfinancial.atlassian.net/browse/DS-7479
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters
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
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                        principal_amount,
               CCRU.rate                                                   as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               coalesce(bar.to_report, btr.to_report, 'N')                 as reported_status,
               coalesce(bar.db_create_time, btr.db_create_time)            as reported_time,
               null::text                                                  as claimed_by,
               null::text                                                  as claim_status

        from trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 inner join genesis2.alloc_instr2trade_record ai2tr on (ai2tr.trade_record_id = tr.trade_record_id)
                 inner join genesis2.allocation_instruction a on (a.alloc_instr_id = ai2tr.alloc_instr_id)
                 left join lateral (select 'R' as to_report, btr.db_create_time
                                    from dash360.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
                 left join lateral (select to_report, bar.db_create_time
                                    from dash360.bofa_allocation_report bar
                                    where bar.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bar.date_id = ai2tr.date_id
                                    limit 1) bar on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;

end;
$function$
;
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53720);
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -52631);
select * from dash360.so_allocations_instruction_trades(in_alloc_instr_id := -53737);

  select
    ai2tr.alloc_instr_id,

      tr.date_id,
               tr.trade_record_id::bigint,
               tr.account_id::integer,
               tr.instrument_id,
               tr.side,
               tr.open_close,
               tr.last_px                                                  as avg_px,
               tr.last_qty                                                 as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                        principal_amount,
               CCRU.rate                                                   as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time,
               ----------------
               i.last_trade_date                                           as expiration_date,
               tr.opt_customer_firm,
               coalesce(bar.to_report, btr.to_report, 'N')                 as reported_status,
               coalesce(bar.db_create_time, btr.db_create_time)            as reported_time,
               null::text                                                  as claimed_by,
               null::text                                                  as claim_status

        from trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
                 inner join genesis2.alloc_instr2trade_record ai2tr on (ai2tr.trade_record_id = tr.trade_record_id)
                 inner join genesis2.allocation_instruction a on (a.alloc_instr_id = ai2tr.alloc_instr_id)
                 left join lateral (select 'R' as to_report, btr.db_create_time
                                    from dash360.bofa_trade_record btr
                                    where btr.trade_record_id = tr.trade_record_id
                                      and btr.date_id = tr.date_id
                                    limit 1) btr on true
                 left join lateral (select to_report, bar.db_create_time
                                    from dash360.bofa_allocation_report bar
                                    where bar.alloc_instr_id = ai2tr.alloc_instr_id
                                      and bar.date_id = ai2tr.date_id
                                    limit 1) bar on true
                 left join genesis2.option_contract oc on i.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE tl.date_id = :l_date_id
                                            AND book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where tr.is_busted = 'N'
          and tr.date_id = :l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;