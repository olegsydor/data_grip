-- DROP FUNCTION dash360.allocations_snapshot(_int8, int4);

CREATE OR REPLACE FUNCTION dash360.so_allocations_snapshot(in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                           in_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                           in_reported_status bpchar(1) default null::bpchar(1))
    RETURNS TABLE
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
                street_exec_time       timestamp without time zone
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
begin
    --in_date_id = 20190301;
    -- VP 20231030 https://dashfinancial.atlassian.net/browse/DS-7465 [ALLOC] Return street_exec_time in dash360.allocations_snapshot()
    -- OS 20241227 https://dashfinancial.atlassian.net/browse/DS-9337 Add new input and output parameters and removed if-else condition for empty in_account_id
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
               coalesce(tr.street_trade_record_time, tr.trade_record_time) as street_exec_time
        from genesis2.trade_record tr
                 inner join genesis2.instrument i on (tr.instrument_id = i.instrument_id)
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
        union all
        select a.date_id,
               null::bigint                   as trade_record_id,
               a.account_id::integer,
               a.instrument_id,
               a.side,
               a.open_close,
               a.avg_px,
               a.total_qty                    as exec_qty,
               i.display_instrument_id,
               --concat(split_part(i.display_instrument_id, ' ', 1), ' ', to_char(i.last_trade_date, 'DDMonYY'), ' ', split_part(i.display_instrument_id, ' ', 3))::character varying display_instrument_id,
               i.last_trade_date::date,
               i.instrument_type_id,
               a.alloc_instr_id,
               a.create_time                  as alloc_time,
               true                           as is_allocated,
               true                           as is_bundle,
               null                           as cmta,
               null                           as exec_broker,
               case i.instrument_type_id
                   when 'O' then a.total_qty * a.avg_px * os.contract_multiplier
                   else a.total_qty * a.avg_px
                   end                           principal_amount,
               case
                   when acc.trading_firm_id = 'cornerstn' and i.instrument_type_id = 'E' then coalesce(ccr.rate, 0)
                   else ccr.rate end          as client_commission_rate,
               coalesce(ui.user_name, 'auto') as user_name,
               ccr.blaze_account_alias,
               null                           as street_exec_time
        from genesis2.allocation_instruction a
                 inner join genesis2.instrument i on (a.instrument_id = i.instrument_id)
                 left join genesis2.account acc on acc.account_id = a.account_id
                 left join genesis2.user_identifier ui on a.created_by_user_id = ui.user_id
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
                                    where alt.alloc_instr_id = a.alloc_instr_id
                                      and tr.is_busted = 'N'
                                      and (l1.rn = 1 or l1.rn is null)
            ) ccr on true
        --		left join lateral (select sum(L1.amount)/nullif(sum(L1.amount/nullif(l1.rate,0)),0) as rate
--							from (SELECT row_number() over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn, tl.rate, tl.amount
--							        FROM trade_level_book_record tl
--							        inner join alloc_instr2trade_record  alt on tl.trade_record_id  = alt.trade_record_id
--							        inner join book_record_creator  cr on tl.book_record_creator_id  = cr.book_record_creator_id
--							        WHERE tl.date_id = in_date_id
--							        AND book_record_type_id ='CCRU'
--							        and alt.alloc_instr_id = a.alloc_instr_id  ) L1
--							where rn=1) ccr on true
        where a.date_id = in_date_id
          and case when in_account_ids = '{}' then true else a.account_id = any (in_account_ids) end
          and a.is_deleted = 'N';

end ;
$function$
;
