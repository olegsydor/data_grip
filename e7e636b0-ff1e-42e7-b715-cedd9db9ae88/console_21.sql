create temp table t_os as
select ftr.account_id, ftr.trade_record_id,
--            ai.create_time,
           ftr.date_id,
           ftr.exch_exec_id,
           null::varchar(256) as client_order_id,
           null::varchar(6) as exchange_id,
           ftr.last_mkt,
           ftr.secondary_exch_exec_id,
--            ca.clearing_account_number,
--            lcl.cusip,
           gi.symbol,
           gi.symbol_suffix,
--            ac.account_name,
--            ac.nscc_mpid,
--            ac.eq_commission_type,
--            ac.eq_commission,
--            ac.eq_order_capacity,
--            ac.trading_firm_id,
--            ac.oats_account_type_code,
           ae.alloc_instr_id,
           ae.clearing_account_id,
           ae.alloc_qty,
--            ai.side,
--            ai.create_time,
--            ai.avg_px,
--            mf.misc_fee_rate,
--            exch.eq_mpid,
--            ac.eq_report_to_mpid,
--            ac.eq_reporting_avgpx_precision
'' as nothing
    from genesis2.allocation_instruction_entry ae
        join lateral (select * from genesis2.alloc_instr2trade_record atr where atr.alloc_instr_id = ae.alloc_instr_id limit 1) atr on true
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
                           from genesis2.trade_record ftr
--                                          join genesis2.mv_active_account_snapshot ac on ac.account_id = ftr.account_id
--                        and coalesce(eq_rt_allocation_enabled, 'N') = 'Y'
                                         where ftr.trade_record_id = atr.trade_record_id and ftr.date_id = atr.date_id
                                                        and ftr.is_busted = 'N'
                           limit 1) ftr on true
--              join genesis2.mv_active_account_snapshot ac on ac.account_id = ftr.account_id
--                       and coalesce(eq_rt_allocation_enabled, 'N') = 'Y'

--              join genesis2.allocation_instruction ai
--                   on (ai.alloc_instr_id = ftr.alloc_instr_id and ai.is_deleted <> 'Y' and ai.date_id = ftr.date_id)
             join genesis2.instrument gi on (ftr.instrument_id = gi.instrument_id)
--              join genesis2.clearing_account ca
--                   on (ae.clearing_account_id = ca.clearing_account_id and ca.market_type = 'E' and
--                       ca.is_deleted::text <> 'Y')
--
--              left join staging.cusip_list_import lcl on (lcl.symbol::text = gi.symbol::text and
--                                                          coalesce(lcl.symbol_suffix, 'none') =
--                                                          coalesce(gi.symbol_suffix, 'none'))
--              left join genesis2.misc_fee_mv mf on (mf.account_id = ac.account_id and
--                                                    coalesce(to_char(mf.end_date, 'YYYYMMDD'::text)::integer,
--                                                             ftr.date_id + 1) > ftr.date_id)
--              left join genesis2.exchange exch on (ftr.exchange_id = exch.exchange_id and exch.is_deleted = 'N')
    where true
      and ae.alloc_qty > 0
      and gi.instrument_type_id = 'E'
     and ae.alloc_instr_id < -219245224
     and ae.alloc_instr_id >= -236166090;

select count(*), date_id--min(ae.date_id), max(ae.date_id)
from genesis2.allocation_instruction_entry ae
where ae.alloc_qty > 0
     and ae.alloc_instr_id < -219245224
     and ae.alloc_instr_id >= -236166090
group by date_id;


select * from genesis2.mv_active_account_snapshot ac
         where true
             and ac.account_id = 10423
                       and coalesce(eq_rt_allocation_enabled, 'N') = 'Y'
and ac