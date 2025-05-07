-- DROP FUNCTION dash360.get_trade_records_for_allocation(int4, _int4, bpchar, _varchar, _int8, _int8);
DROP FUNCTION dash360.get_allocations(int4, _int4, bpchar, _varchar, _int8);

DROP FUNCTION dash360.get_allocations(int4, _int4, bpchar, _varchar, _int8, _int8);

select *
from dash360.get_allocations(in_date_id := 20250505, in_account_ids := '{259133, 2525}', in_security_type := null,
                             in_root_symbol := '{}', in_alloc_instr_ids := '{}');

create or replace function dash360.get_allocations(in_date_id integer,
                                                   in_account_ids integer[] DEFAULT '{}'::integer[],
                                                   in_security_type character DEFAULT NULL::character(1),
                                                   in_root_symbol character varying[] DEFAULT '{}'::character varying[],
                                                   in_alloc_instr_ids bigint[] DEFAULT '{}'::bigint[]
)
    RETURNS TABLE
            (
                date_id                integer,                     -- 1
                account_id             integer,
                instrument_id          bigint,
                side                   character,
                open_close             character,                   -- 5
                avg_px                 numeric,
                exec_qty               integer,
                display_instrument_id  character varying(100),
                expiration_date        date,
                instrument_type_id     character,                   -- 10
                alloc_instr_id         int4,
                alloc_time             timestamp without time zone,
                cmta                   character varying(3),
                exec_broker            character varying,
                principal_amount       numeric,                     -- 15
                client_commission_rate numeric(14, 8),
                user_name              character varying,
                blaze_account_alias    character varying(250),
                street_exec_time       timestamp without time zone,
                expiration_time        timestamp without time zone, -- 20
                opt_customer_firm      character,
                reported_status        character,
                reported_time          timestamp without time zone,
                claimed_by             int4,
                claim_status           character                    -- 25
            )
    LANGUAGE plpgsql
AS
$function$
    -- inherited from dash360.allocations_snapshot
    -- inherited from https://dashfinancial.atlassian.net/browse/DS-9941
    -- OS 20250506 https://dashfinancial.atlassian.net/browse/DS-9983
begin
    --     raise notice '0 - %', clock_timestamp();
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
    --     union all
--     select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
--     from dash_reporting.bofa_trade_record btr
--     where btr.date_id = in_date_id
    ;
--     raise notice '1 - %', clock_timestamp();

    analyze t_trade_record;
    create index on t_trade_record (trade_record_id);
    create index on t_trade_record (alloc_instr_id);
--     raise notice '2 - %', clock_timestamp();


    return query
        select ai.date_id::int4,                                                      -- 1
               ai.account_id::int4,
               ai.instrument_id::int8,
               ai.side::character,
               ai.open_close::character,                                              -- 5
               ai.avg_px,
               ai.total_qty::int4                                as exec_qty,
               di.display_instrument_id,
               di.last_trade_date::date                          as expiration_date,
               di.instrument_type_id,                                                 -- 10
               ai.alloc_instr_id,
               ai.create_time                                    as alloc_time,
               null::character varying(3)                        as cmta,
               ccr.exec_broker::character varying,
               case di.instrument_type_id
                   when 'O' then ai.total_qty * ai.avg_px * os.contract_multiplier
                   else ai.total_qty * ai.avg_px
                   end                                           as principal_amount, -- 15
               case
                   when acc.trading_firm_id = 'cornerstn' and di.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end                             as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying as user_name,
               ccr.blaze_account_alias::character varying,
               null::timestamp without time zone                 as street_exec_time,
               di.last_trade_date::timestamp without time zone   as expiration_time,  -- 20
               null::character                                   as opt_customer_firm,
               rep.to_report                                     as reported_status,
               rep.db_create_time                                as reported_time,
               bas.claimed_by::int4                              as claimed_by,
               bas.claim_status::character                       as claim_status      -- 25
        from genesis2.allocation_instruction ai
                 join genesis2.instrument di on (ai.instrument_id = di.instrument_id)
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
                 join genesis2.account acc on acc.account_id = ai.account_id
                 left join genesis2.user_identifier ui on ai.created_by_user_id = ui.user_id
                 left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
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
                                                        on alt.trade_record_id = tr.trade_record_id --and alt.date_id = tr.date_id
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
                                      and alt.date_id = in_date_id
                                      and tr.date_id = in_date_id
                                    limit 1
            ) ccr on true
        where ai.date_id = in_date_id
          and case when coalesce(in_account_ids, '{}') = '{}' then false else ai.account_id = any (in_account_ids) end
          and case when in_security_type is null then true else di.instrument_type_id = in_security_type end
          and case
                  when in_alloc_instr_ids = '{}' then true
                  else ai.alloc_instr_id = any (in_alloc_instr_ids) end
          and case when in_root_symbol = '{}' then true else di.symbol = any (in_root_symbol) end
          and ai.is_deleted = 'N';
--     raise notice '3 - %', clock_timestamp();
end ;
$function$
;


select * from genesis2.allocation_instruction ai
                 join genesis2.instrument di on (ai.instrument_id = di.instrument_id)
                 left join lateral (select case
                                               when rep.to_report = 'U' and
                                                    staging.get_fully_reported_trade(rep.alloc_instr_id, :in_date_id) =
                                                    1 -- means that only one value is possible in related trade_records and it can be only R
                                                   then 'U'
                                               when rep.to_report = 'U' then 'W'
                                               else rep.to_report end as to_report,
                                           rep.db_create_time
                                    from t_trade_record rep
                                    where rep.alloc_instr_id = ai.alloc_instr_id
                                    limit 1) rep on true
                 join genesis2.account acc on acc.account_id = ai.account_id
                 left join genesis2.user_identifier ui on ai.created_by_user_id = ui.user_id
                 left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
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
                                                        on alt.trade_record_id = tr.trade_record_id --and alt.date_id = tr.date_id
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
                                      and alt.date_id = :in_date_id
                                      and tr.date_id = :in_date_id
                                    limit 1
            ) ccr on true
where date_id = 20250505
and ai.account_id = any('{259133, 2525}')