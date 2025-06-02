alter function dash360.get_trade_records_for_allocation rename to get_trade_records_for_allocation_bkp;


-- DROP FUNCTION dash360.get_trade_records_for_allocation(int4, _int4, bpchar, _varchar, _int8, _int8);

CREATE OR REPLACE FUNCTION dash360.get_trade_records_for_allocation(in_date_id integer,
                                                                    in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                    in_security_type character DEFAULT NULL::character(1),
                                                                    in_root_symbol character varying[] DEFAULT '{}'::character varying[],
                                                                    in_trade_record_ids bigint[] DEFAULT '{}'::bigint[],
                                                                    in_alloc_instr_ids bigint[] DEFAULT '{}'::bigint[])
 RETURNS TABLE(date_id integer, trade_record_id bigint, account_id integer, instrument_id bigint, side character, open_close character, symbol character varying, exec_qty integer, avg_px numeric, expiration_date date, instrument_type_id character, street_exec_time timestamp without time zone, principal_amount numeric, is_allocated boolean, is_bundle boolean, exec_broker character varying, reported_status character, reported_time timestamp without time zone, last_trade_date timestamp without time zone, opt_customer_firm character)
 LANGUAGE plpgsql
 COST 1
AS $function$
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
        from genesis2.trade_record tr
                 inner join genesis2.instrument di on (tr.instrument_id = di.instrument_id)
                 left join genesis2.account ac on ac.account_id = tr.account_id

                 left join lateral (select ai2.trade_record_id, ai.alloc_instr_id, ai.date_id
                            from genesis2.allocation_instruction ai
                                     inner join genesis2.alloc_instr2trade_record ai2
                                                on (ai.alloc_instr_id = ai2.alloc_instr_id and ai2.date_id = ai.date_id)
                            where true
                              and ai2.trade_record_id = tr.trade_record_id
                              and ai2.date_id = in_date_id
                              and case
                                      when in_account_ids = '{}' then true
                                      else ai.account_id = any (in_account_ids) end
                              and ai.date_id = in_date_id
                              and case when ai.status in ('O', 'I') then false else true end
                              and case
                                      when in_alloc_instr_ids = '{}' then true
                                      else ai.alloc_instr_id = any (in_alloc_instr_ids) end
                              and ai.is_deleted = 'N') all_t on true

                 left join lateral (select ais.trade_record_id, ai.alloc_instr_id, ai.date_id
                            from genesis2.allocation_instruction ai
                                     inner join genesis2.alloc_instr2sent_trade_record ais
                                                on (ai.alloc_instr_id = ais.alloc_instr_id)
                            where true
                              and ais.trade_record_id = tr.trade_record_id
                              and case
                                      when in_account_ids = '{}' then true
                                      else ai.account_id = any (in_account_ids) end
                              and ai.date_id = in_date_id
                              and case when ai.status in ('O', 'I') then true else false end
                              and case
                                      when in_alloc_instr_ids = '{}' then true
                                      else ai.alloc_instr_id = any (in_alloc_instr_ids) end
                              and ai.is_deleted = 'N') all_sent on true
                 left join lateral (select rep.to_report, rep.db_create_time
                                    from t_trade_record rep
                                    where rep.trade_record_id = tr.trade_record_id
                                    limit 1) rep on true
                 left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
                 left join genesis2.option_series os on oc.option_series_id = os.option_series_id
        where tr.date_id = in_date_id
          and case when in_security_type is null then true else di.instrument_type_id = in_security_type end
          and case when coalesce(in_account_ids, '{}') = '{}' then true else tr.account_id = any (in_account_ids) end
          and case when in_root_symbol = '{}' then true else di.symbol = any (in_root_symbol) end
          and case when in_trade_record_ids = '{}' then true else tr.trade_record_id = any (in_trade_record_ids) end
          and case
                  when in_alloc_instr_ids = '{}' then true
                  else (all_t.alloc_instr_id = any (in_alloc_instr_ids)
                      or
                        all_sent.alloc_instr_id = any (in_alloc_instr_ids))
            end
          and tr.is_busted = 'N'
    ;
--     raise notice '3 - %', clock_timestamp();

end ;
$function$
;


select * from dash360.get_trade_records_for_allocation(in_date_id := 20250530,
                                                                    in_account_ids := '{262707,258653}',
                                                                    in_root_symbol := '{META,IBM,BABA}')