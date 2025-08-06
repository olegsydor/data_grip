with upd_busted as (update genesis2.trade_record tr
    set is_busted = case tr.is_busted when 'Y' then tr.is_busted else trml.is_busted end ,
        load_batch_id = trml.load_batch_id::int,
        blaze_account_alias = coalesce(trml.blaze_account_alias, tr.blaze_account_alias)
    from staging.trade_record_blaze7 trml
    where tr.trade_record_id = trml.trade_record_id
        and tr.date_id = trml.date_id
        and tr.date_id between in_start_date and in_end_date
        --				and tr.is_busted = 'N'
        --				and (trml.is_busted = 'Y' or trml.blaze_account_alias is not null)
        and case
                when tr.is_busted = 'N' and trml.is_busted is not null then true
                when (trml.blaze_account_alias is not null and tr.blaze_account_alias is null and tr.is_busted = 'N')
                    then true
                when (trml.blaze_account_alias is distinct from tr.blaze_account_alias and
                      trml.blaze_account_alias is not null and tr.is_busted = 'N' and
                      tr.account_id in (select account_id from genesis2.account where trading_firm_id = 'strategas') and
                      tr.orig_trade_record_id is null) then true
                else false end
        and trml.load_batch_id = in_load_batch_id
        and mapping_logic <> 99
    returning tr.trade_record_id as trade_record_id, tr.date_id as date_id, tr.is_busted as is_busted,tr.blaze_account_alias as blaze_account_alias)
select *
from upd_busted