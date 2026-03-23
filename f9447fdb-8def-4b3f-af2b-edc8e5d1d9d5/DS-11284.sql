-- DROP FUNCTION dash360.allocations_instruction_commission_rate(int4, int4);

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
                client_order_id          character varying(256),
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
                                           nullif(sum(tr.last_qty), 0)             as rate,
                                           sum(amount)                             as amount,
                                           array_agg(distinct tr.client_order_id)  as client_order_id,
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

