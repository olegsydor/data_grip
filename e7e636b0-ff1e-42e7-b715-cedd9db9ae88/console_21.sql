select * from staging.tlnd_inc_last_loaded_id;
-- DROP FUNCTION genesis2.rt_perform_fill_allocation_trade_record();

CREATE OR REPLACE FUNCTION genesis2.rt_perform_fill_allocation_trade_record()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20221109 OS https://dashfinancial.atlassian.net/browse/DS-5453
    -- 20230505 OS Moved from UAT after testing there
    -- 20230926 OS https://dashfinancial.atlassian.net/browse/DS-7320 fixing of issue related to conflict manual and auto allocation
    -- 20241118 OS https://dashfinancial.atlassian.net/browse/DS-9171 preventing selecting data if the previous run did it
declare
    l_min_alloc_instr_id int8;
    l_max_alloc_instr_id int8;
    l_date_id             int4;
    l_load_id             int4;
    l_step_id             int4;
    l_max_time            timestamp;
    l_row_cnt             int4;
    l_last_alloc_instr_id int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'perform_fill_allocation_trade_record started', 0, 'B')
    into l_step_id;

    select last_loaded_id
    into l_last_alloc_instr_id
    from staging.tlnd_inc_last_loaded_id
    where table_name = 'rt_allocation_trade_record';

    select coalesce(min(alloc_instr_id), l_last_alloc_instr_id)
    into l_min_alloc_instr_id
    from genesis2.rt_allocation_trade_record;

    select clock_timestamp() - interval '1 minute' into l_max_time;

    select coalesce(min(alloc_instr_id), 0)
    into l_max_alloc_instr_id
    from genesis2.allocation_instruction tr
    where tr.alloc_instr_id < l_min_alloc_instr_id
      and tr.create_time < l_max_time;

    select to_char(current_date, 'YYYYMMDD')::int4 into l_date_id;

    raise notice 'l_min_alloc_instr_id - %, l_max_alloc_instr_id - %, l_max_time - %', l_min_alloc_instr_id, l_max_alloc_instr_id, l_max_time;
    insert into genesis2.rt_allocation_trade_record
    (trade_record_id, trade_record_time, date_id, exch_exec_id, client_order_id, exchange_id, last_mkt,
     secondary_exch_exec_id, clearing_account_number, cusip, symbol, symbol_suffix, account_name, nscc_mpid,
     eq_commission_type, eq_commission, eq_order_capacity, trading_firm_id, oats_account_type_code, alloc_instr_id,
     clearing_account_id, alloc_qty, side, create_time, avg_px, misc_fee_rate, eq_mpid, eq_report_to_mpid, eq_reporting_avgpx_precision)

    select ftr.trade_record_id,
           ai.create_time,
           ftr.date_id,
           ftr.exch_exec_id,
           null::varchar(256) as client_order_id,
           null::varchar(6) as exchange_id,
           ftr.last_mkt,
           ftr.secondary_exch_exec_id,
           ca.clearing_account_number,
           lcl.cusip,
           gi.symbol,
           gi.symbol_suffix,
           ac.account_name,
           ac.nscc_mpid,
           ac.eq_commission_type,
           ac.eq_commission,
           ac.eq_order_capacity,
           ac.trading_firm_id,
           ac.oats_account_type_code,
           ae.alloc_instr_id,
           ae.clearing_account_id,
           ae.alloc_qty,
           ai.side,
           ai.create_time,
           ai.avg_px,
           mf.misc_fee_rate,
           exch.eq_mpid,
           ac.eq_report_to_mpid,
           ac.eq_reporting_avgpx_precision
    from genesis2.allocation_instruction_entry ae
             join lateral (select atr.alloc_instr_id,
                                  ftr.trade_record_id,
                                  ftr.trade_record_time,
                                  ftr.date_id,
                                  ftr.exch_exec_id,
                                  ftr.client_order_id,
                                  ftr.exchange_id,
                                  ftr.last_mkt,
                                  ftr.secondary_exch_exec_id,
                                  ftr.account_id,
                                  ftr.instrument_id
                           from genesis2.alloc_instr2trade_record atr
                                    join genesis2.trade_record ftr
                                         on ftr.trade_record_id = atr.trade_record_id and ftr.date_id = atr.date_id
                           where atr.alloc_instr_id = ae.alloc_instr_id
                             and ftr.is_busted = 'N'
                           limit 1) ftr on true
             join genesis2.mv_active_account_snapshot ac on ac.account_id = ftr.account_id
                      and coalesce(eq_rt_allocation_enabled, 'N') = 'Y'

             join genesis2.allocation_instruction ai
                  on (ai.alloc_instr_id = ftr.alloc_instr_id and ai.is_deleted <> 'Y' and ai.date_id = ftr.date_id)
             join genesis2.instrument gi on (ftr.instrument_id = gi.instrument_id)
             join genesis2.clearing_account ca
                  on (ae.clearing_account_id = ca.clearing_account_id and ca.market_type = 'E' and
                      ca.is_deleted::text <> 'Y')

             left join staging.cusip_list_import lcl on (lcl.symbol::text = gi.symbol::text and
                                                         coalesce(lcl.symbol_suffix, 'none') =
                                                         coalesce(gi.symbol_suffix, 'none'))
             left join genesis2.misc_fee_mv mf on (mf.account_id = ac.account_id and
                                                   coalesce(to_char(mf.end_date, 'YYYYMMDD'::text)::integer,
                                                            ftr.date_id + 1) > ftr.date_id)
             left join genesis2.exchange exch on (ftr.exchange_id = exch.exchange_id and exch.is_deleted = 'N')
    where true
--       and ftr.is_busted = 'N'
      and ae.alloc_qty > 0
      and gi.instrument_type_id = 'E'
--      and ae.alloc_instr_id = 571782
--       and ftr.trade_record_id > l_min_trade_record_id
--       and ftr.trade_record_id <= l_max_trade_record_id
     and ae.alloc_instr_id < l_min_alloc_instr_id
     and ae.alloc_instr_id >= l_max_alloc_instr_id
--      and ftr.date_id = l_date_id
-- and 1=2
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'perform_fill_allocation_trade_record finished', l_row_cnt,
                           'E')
    into l_step_id;

    if l_min_alloc_instr_id > l_max_alloc_instr_id then
        update staging.tlnd_inc_last_loaded_id
        set last_loaded_id   = l_max_alloc_instr_id,
            last_update_time = now(),
            last_date_id     = to_char(current_date, 'YYYYMMDD')
        where table_name = 'rt_allocation_trade_record';
    end if;

    return l_row_cnt;
end;
$function$
;

select * from genesis2.rt_perform_fill_allocation_trade_record()