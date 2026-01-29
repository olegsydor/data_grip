-- DROP FUNCTION dash360.allocations_instruction_trades(int4);

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
                client_commission_amount numeric(20, 8)
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
               tr.last_px                                                                   as avg_px,
               tr.last_qty                                                                  as exec_qty,
               i.display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               tr.cmta,
               tr.exec_broker,
               case i.instrument_type_id
                   when 'O' then tr.last_qty * tr.last_px * os.contract_multiplier
                   else tr.last_qty * tr.last_px
                   end                                                                      as principal_amount,
               CCRU.rate                                                                    as client_commission_rate,
               tr.blaze_account_alias,
               coalesce(tr.street_trade_record_time, tr.trade_record_time)                  as street_exec_time,
               ----------------
               i.last_trade_date                                                            as expiration_date,
               tr.opt_customer_firm,
--                coalesce(bar.to_report, btr.to_report)                      as reported_status,
               case when tr.is_billed = 'R' then 'R'::char end                              as reported_status,
               case
                   when tr.is_billed = 'R' then coalesce(/*bar.db_create_time,*/ (select bar.db_create_time
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
                        limit 1)) end                                                       as reported_time,
               null::int4                                                                   as claimed_by,
               null::character                                                              as claim_status,
               case when tr.is_billed = 'R' then true else false end                        as is_prev_reported,
               CCRU.amount                                                                  as client_commission_amount
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
select a.alloc_instr_id
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

        where tr.is_busted = 'N'
          and tr.date_id = :l_date_id
          and a.alloc_instr_id = in_alloc_instr_id;
select * from dash360.allocations_instruction_trades(in_alloc_instr_id := -107724)


-- compare 2 PROD
-- DROP FUNCTION dash360.trade_record_update_ccru(int4, int4, int8, numeric, numeric, int4);

-- DROP FUNCTION dash360.trade_record_update_ccru(int4, int4, int8, numeric, numeric, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.trade_record_update_ccru(in_user_id integer, in_date_id integer,
                                                            in_trade_record_id bigint, in_rate numeric,
                                                            in_amount numeric,
                                                            in_load_batch_id integer DEFAULT NULL::integer,
                                                            in_book_record_creator_id character varying DEFAULT 'MAN'::character varying)
    RETURNS integer
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY DS-2914 On conflich has been implemented due to miration to native parititoning
-- AK DS-10934 Add new parameter to procedure dash360.trade_record_update_ccru to add new param to se book_record_creator_id (SGDD or other)
declare
    l_cnt           int;
    l_date_id       int;
    l_load_batch_id int;
begin

    l_date_id := in_date_id;
    if in_load_batch_id is null
    then
        select nextval('load_batch_load_batch_id_seq'::regclass) into l_load_batch_id;
    else
        l_load_batch_id := in_load_batch_id;
    end if;


    insert into trade_level_book_record (trade_record_id, book_record_type_id, amount, book_record_creator_id, date_id,
                                         rate, load_batch_id, user_id, create_time, billing_entity)
    values (in_trade_record_id, 'CCRU', in_amount, in_book_record_creator_id, l_date_id, in_rate, l_load_batch_id,
            in_user_id, clock_timestamp(), '-1')
    on conflict (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id)
        do update set amount        = EXCLUDED.amount,
                      rate          = EXCLUDED.rate,
                      load_batch_id = EXCLUDED.load_batch_id,
                      user_id       = EXCLUDED.user_id,
                      create_time   = EXCLUDED.create_time;

    perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id, in_row_cnt => 1,
                                   in_subscription_name => 'big_data.flat_trade_record',
                                   in_source_table_name => 'trade_level_book_record', in_date_id => l_date_id);

    return l_load_batch_id;


exception
    when others then
        RAISE notice '% %', sqlstate, sqlerrm;
        raise;
        return -2;
end;
$function$
;
