select *
from dash360.get_trade_records_for_allocation(in_date_id := 20250429, in_account_ids := '{68488,24849,63425}',
                                              in_security_type := 'E',
                                              in_trade_record_ids := '{4152561582,4152597033,4152610217,4152610758,4152610759,4152629843,4152656809,4152673948,4152676829,4152696096}');
-- drop function dash360.get_trade_records_for_allocation;
create or replace function dash360.get_trade_records_for_allocation(in_date_id integer,
                                                         in_account_ids int4[] default '{}'::int4[],
                                                         in_security_type char default null::char,
                                                         in_root_symbol character varying[] default '{}'::character varying[],
                                                         in_trade_record_ids int8[] default '{}'::int8[],
                                                         in_alloc_instr_ids int8[] default '{}'::int8[])
    returns table
            (
                date_id            int4, -- 1
                trade_record_id    bigint, -- 2
                account_id         integer, -- 3
                instrument_id      bigint, -- 4
                side               character, -- 5
                open_close         character, -- 6
                symbol             character varying, -- 7
                exec_qty           integer, -- 8
                avg_px             numeric, -- 9
                expiration_date    date, -- 10
                instrument_type_id character, -- 11
                street_exec_time   timestamp without time zone, -- 12
                principal_amount   numeric, -- 13
                is_allocated       boolean, -- 14
                is_bundle          boolean, -- 15
                exec_broker        character varying, -- 16
                reported_status    character, -- 17
                reported_time      timestamp without time zone, -- 108
                last_trade_date    timestamp without time zone, -- 19
                opt_customer_firm  character -- 20

--                 display_instrument_id  character varying,
--                 alloc_instr_id         integer,
--                 alloc_time             timestamp without time zone,
--                 cmta                   character varying,
--                 principal_amount       numeric,
--                 client_commission_rate numeric,
--                 username               character varying,
--                 blaze_account_alias    character varying,
--                 reported_status        character,
--                 claimed_by             integer,
--                 claim_status           character
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- inherited from dash360.allocations_snapshot
    -- OS 20250430 https://dashfinancial.atlassian.net/browse/DS-9941
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
        select tr.date_id::int4,
               tr.trade_record_id::int8,
               tr.account_id::int4,
               tr.instrument_id::int8,
               tr.side::character,
               tr.open_close::character,
               di.symbol,
               tr.last_qty::int4                                                                        as exec_qty,
               tr.last_px                                                                               as avg_px,
               di.last_trade_date::date                                                                 as expiration_date,
               di.instrument_type_id::character,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)::timestamp without time zone as street_exec_time,
               case di.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                                  as principal_amount,
               false                                                                                    as is_allocated,
               false                                                                                    as is_bundle,
               tr.exec_broker::character varying,
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
               di.last_trade_date::timestamp without time zone,
               tr.opt_customer_firm::character

        /*
        i.display_instrument_id,
        null::int4                                                                               as alloc_instr_id,
        null::timestamp without time zone                                                        as alloc_time,
        tr.cmta::character varying,

        case
            when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(CCRU.rate, 0)
            else CCRU.rate end                                                                   as client_commission_rate,
        null::character varying                                                                  as user_name,
        tr.blaze_account_alias::character varying,

        ----------------
        i.last_trade_date                                                                        as expiration_date,


        bas.claimed_by::int4                                                                     as claimed_by,
        bas.claim_status::character                                                              as claim_status,
*/
        from genesis2.trade_record tr
                 inner join genesis2.instrument di on (tr.instrument_id = di.instrument_id)
                 left join genesis2.account ac on ac.account_id = tr.account_id
                 left join (select ai2tr.trade_record_id, a.alloc_instr_id, a.date_id
                            from genesis2.allocation_instruction a
                                     inner join genesis2.alloc_instr2trade_record ai2tr
                                                on (a.alloc_instr_id = ai2tr.alloc_instr_id and ai2tr.date_id = a.date_id)
                            where true
                              and case when in_account_ids = '{}' then false else a.account_id = any (in_account_ids) end
                              and a.date_id = in_date_id
                              and a.is_deleted = 'N') allocated_trades
                           on allocated_trades.trade_record_id = TR.TRADE_RECORD_ID
                 left join lateral (select rep.to_report, rep.db_create_time
                                    from t_trade_record rep
                                    where rep.trade_record_id = tr.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
        --                  left join lateral (select bas.claimed_by, bas.claim_status
--                                     from dash_reporting.bofa_allocation_instruction_status bas
--                                     where bas.alloc_instr_id = allocated_trades.alloc_instr_id
--                                       and bas.date_id = allocated_trades.date_id
--                                       and 1 = 2
--                                     limit 1) bas on true
--                  left join lateral (select L1.rate
--                                     from (SELECT row_number()
--                                                  over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
--                                                  tl.rate
--                                           FROM genesis2.trade_level_book_record tl
--                                                    inner join genesis2.book_record_creator cr
--                                                               on tl.book_record_creator_id = cr.book_record_creator_id
--                                           WHERE tl.date_id = in_date_id
--                                             AND book_record_type_id = 'CCRU'
--                                             and tl.trade_record_id = tr.trade_record_id) L1
--                                     where rn = 1) CCRU on true
        where tr.date_id = in_date_id
          and case when in_security_type is null then true else di.instrument_type_id = in_security_type end
          and case when coalesce(in_account_ids, '{}') = '{}' then false else tr.account_id = any (in_account_ids) end
          and case when in_root_symbol = '{}' then true else di.symbol = any (in_root_symbol) end
          and case when in_trade_record_ids = '{}' then true else tr.trade_record_id = any (in_trade_record_ids) end
          and case
                  when in_alloc_instr_ids = '{}' then true
                  else allocated_trades.alloc_instr_id = any (in_alloc_instr_ids) end
          and tr.is_busted = 'N'
--and false
          and allocated_trades.alloc_instr_id is NULL
    --           and case
--                   when in_reported_status = 'R' then rep.to_report = 'R'
--                   when in_reported_status = 'U' then rep.to_report in ('U', 'C')
--                   when in_reported_status is null then true end
    ;
--     raise notice '3 - %', clock_timestamp();

end ;
$function$
;
