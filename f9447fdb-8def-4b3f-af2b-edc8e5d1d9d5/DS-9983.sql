-- DROP FUNCTION dash360.get_trade_records_for_allocation(int4, _int4, bpchar, _varchar, _int8, _int8);


select *
from dash360.get_allocations(in_date_id := 20250505, in_account_ids := '{259133, 2525}', in_security_type := null,
                             in_root_symbol := '{}', in_trade_record_ids := '{}', in_alloc_instr_ids := '{}');

create or replace function dash360.get_allocations(in_date_id integer,
                                        in_account_ids integer[] DEFAULT '{}'::integer[],
                                        in_security_type character DEFAULT NULL::character(1),
                                        in_root_symbol character varying[] DEFAULT '{}'::character varying[],
                                        in_trade_record_ids bigint[] DEFAULT '{}'::bigint[],
                                        in_alloc_instr_ids bigint[] DEFAULT '{}'::bigint[])
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
    union all
    select btr.trade_record_id, to_report, 0, btr.db_create_time, 'T' as alloc_rep_type
    from dash_reporting.bofa_trade_record btr
    where btr.date_id = in_date_id;
--     raise notice '1 - %', clock_timestamp();

    analyze t_trade_record;
    create index on t_trade_record (trade_record_id);
    create index on t_trade_record (alloc_instr_id);
--     raise notice '2 - %', clock_timestamp();


    return query
        select tr.date_id::int4,                                                                                             -- 1
               tr.account_id::int4,
               tr.instrument_id::int8,
               tr.side::character,
               tr.open_close::character,                                                                                     -- 5
               tr.last_px                                                                               as avg_px,
               tr.last_qty::int4                                                                        as exec_qty,
               di.display_instrument_id,
               di.last_trade_date::date                                                                 as expiration_date,
               di.instrument_type_id,                                                                                        -- 10
               atr.alloc_instr_id,
               atr.create_time                                                                          as alloc_time,
               tr.cmta,
               tr.exec_broker::character varying,
               case di.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                                  as principal_amount, -- 15
               case
                   when ac.trading_firm_id = 'cornerstn' and di.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
                   else CCRU.rate end                                                                   as client_commission_rate,
               coalesce(ui.user_name, 'auto')::character varying                                        as user_name,
               tr.blaze_account_alias::character varying,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)::timestamp without time zone as street_exec_time,
               di.last_trade_date::timestamp without time zone                                          as expiration_time,  -- 20
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
               bas.claim_status::character                                                              as claim_status      -- 25
        from genesis2.trade_record tr
                 inner join genesis2.instrument di on (tr.instrument_id = di.instrument_id)
                 left join genesis2.account ac on ac.account_id = tr.account_id
                 left join (select ai2tr.trade_record_id,
                                   ai.alloc_instr_id,
                                   ai.date_id,
                                   ai.create_time,
                                   ai.created_by_user_id
                            from genesis2.allocation_instruction ai
                                     inner join genesis2.alloc_instr2trade_record ai2tr
                                                on (ai.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = ai.date_id)
                            where true
                              and case
                                      when in_account_ids = '{}' then true
                                      else ai.account_id = any (in_account_ids) end
                              and ai.date_id = in_date_id
                              and ai2tr.date_id = in_date_id
                              and ai.is_deleted = 'N') atr
                           on atr.trade_record_id = tr.trade_record_id
                 left join lateral (select rep.to_report, rep.db_create_time
                                    from t_trade_record rep
                                    where rep.trade_record_id = tr.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
                 left join lateral (select bas.claimed_by, bas.claim_status
                                    from dash_reporting.bofa_allocation_instruction_status bas
                                    where bas.alloc_instr_id = atr.alloc_instr_id
                                      and bas.date_id = atr.date_id
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
                 left join genesis2.user_identifier ui on atr.created_by_user_id = ui.user_id
        where tr.date_id = in_date_id
          and case when in_security_type is null then true else di.instrument_type_id = in_security_type end
          and case when coalesce(in_account_ids, '{}') = '{}' then true else tr.account_id = any (in_account_ids) end
          and case when in_root_symbol = '{}' then true else di.symbol = any (in_root_symbol) end
          and case when in_trade_record_ids = '{}' then true else tr.trade_record_id = any (in_trade_record_ids) end
          and case
                  when in_alloc_instr_ids = '{}' then true
                  else atr.alloc_instr_id = any (in_alloc_instr_ids) end
          and tr.is_busted = 'N'
--           and atr.alloc_instr_id is NULL
    ;
--     raise notice '3 - %', clock_timestamp();
end ;
$function$
;
