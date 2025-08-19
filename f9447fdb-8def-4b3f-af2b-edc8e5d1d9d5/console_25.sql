-- DROP FUNCTION genesis2.clearing_fix_trade_integrity(int4, int4);

CREATE OR REPLACE FUNCTION genesis2.clearing_fix_trade_integrity(in_clearing_instruction_id integer, in_date_id integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20250819 SO https://dashfinancial.atlassian.net/browse/DS-10289 moving error raising from PTM process into this function
declare
	row_cnt integer;
    l_busted_trades     text;
begin

    create temp table t_cte as
    select trade_record_id, orig_trade_record_id, trade_record_reason
    from genesis2.trade_record
    where date_id = in_date_id
      and orig_trade_record_id in (select coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                                   from genesis2.clearing_instruction_entry
                                   where clearing_instr_id = in_clearing_instruction_id
        --and date_id = in_date_id
    )
      and is_busted <> 'Y'
    union all
    select trade_record_id, orig_trade_record_id, trade_record_reason
    from genesis2.trade_record
    where date_id = in_date_id
      and trade_record_id in (select coalesce(new_trade_record_id, trade_record_id) as trade_record_id
                              from genesis2.clearing_instruction_entry
                              where clearing_instr_id = in_clearing_instruction_id
        --and date_id = in_date_id
    )
      and is_busted <> 'Y';

    select string_agg(distinct trade_record_id::text, ', ')
    into l_busted_trades
    from t_cte
    where trade_record_reason = 'S';

    if l_busted_trades is not null then
        raise exception 'trade_records % was\were busted before', l_busted_trades using ERRCODE = 'PTMNC';
    end if;

	update genesis2.genesis2.clearing_instruction_entry cie set trade_record_id = cte.trade_record_id
	from t_cte cte
	where cie.date_id = in_date_id
	and coalesce(cie.new_trade_record_id, cie.trade_record_id) = cte.orig_trade_record_id
	and cie.trade_record_id <> cte.trade_record_id;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;

	return row_cnt;

end;
$function$
;
