-- DROP FUNCTION dash360.clearing_complete_instruction(int4, int4, int4, bpchar, varchar, text);

CREATE OR REPLACE FUNCTION dash360.clearing_complete_instruction(in_date_id integer, in_user_id integer,
                                                                 in_instr_id integer, in_status character,
                                                                 in_remarks character varying DEFAULT NULL::character varying,
                                                                 in_change_vector text DEFAULT NULL::text)
    RETURNS TABLE
            (
                new_trade_record_id bigint,
                date_id             int,
                account_id          int8
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
        select tr.trade_record_id as new_trade_record_id, in_date_id as date_id, tr.account_id
        from genesis2.trade_record tr
        where tr.trade_record_id = any (l_inserted)
          and tr.date_id = in_date_id
          and l_inserted is not null;

end;
$function$
;
