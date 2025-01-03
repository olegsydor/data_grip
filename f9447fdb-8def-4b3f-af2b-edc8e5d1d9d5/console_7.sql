-- accounts
select distinct tr.account_id, ac.trading_firm_id
from genesis2.trade_record tr
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         join genesis2.account ac on tr.account_id = ac.account_id
where tr.date_id = :in_date_id
  and di.instrument_type_id = 'O';


select * from dash360.allocation_trade_record_monitor(20241217);


-- DROP FUNCTION dash360.allocation_trade_record_monitor(int4, _int8);

CREATE OR REPLACE FUNCTION dash360.allocation_trade_record_monitor(in_date_id integer, in_account_ids bigint[] DEFAULT '{}'::bigint[])
    RETURNS TABLE
            (
                account_id                      bigint,
                trading_firm_id                 character varying,
                trades_cnt                      bigint,
                trades_qty                      bigint,
                trades_principal                numeric,
                trades_cnt_expiring             bigint,
                trades_qty_expiring             bigint,
                unallocated_trades_cnt          bigint,
                unallocated_trades_qty          bigint,
                unallocated_trades_principal    numeric,
                unallocated_trades_qty_expiring bigint,
                allocated_trades_cnt            bigint,
                allocated_trades_qty            bigint,
                allocated_trades_principal      numeric,
                allocated_trades_qty_expiring   bigint,
                unable_trades_cnt               bigint,
                unable_trades_qty               bigint,
                unable_trades_principal         numeric,
                unresolved                      integer,
                resolved                        integer
            )
    LANGUAGE plpgsql
AS
$function$
declare

begin

    drop table if exists tmp_trade_record_monitor;
    create temp table tmp_trade_record_monitor as
    select ac.account_id,
           ac.trading_firm_id,
           tr.trade_record_id,
           tr.last_qty,
           tr.last_px,
           tr.instrument_id,
           case
               when to_char(di.last_trade_date, 'YYYYMMDD')::int4 = in_date_id then true
               else false end         as expiring_today,
           case
               when al.alloc_instr_id is not null then 'allocated'
               else 'unallocated' end as is_alloc,
           case
               when un.alloc_instr_id is not null then true
               end                    as is_unable,
           bas.claim_status
    from genesis2.trade_record tr
             join genesis2.instrument di on di.instrument_id = tr.instrument_id
             join genesis2.account ac on tr.account_id = ac.account_id
             left join genesis2.alloc_instr2trade_record atr
                       on atr.trade_record_id = tr.trade_record_id and atr.date_id = in_date_id
             left join lateral (select atr.alloc_instr_id
                                from genesis2.allocation_instruction ai
                                where ai.alloc_instr_id = atr.alloc_instr_id
                                  and ai.is_deleted = 'N'
                                limit 1) al on true
             left join lateral ( select bar.alloc_instr_id
                                 from dash_reporting.bofa_allocation_report bar
                                 where bar.alloc_instr_id = atr.alloc_instr_id
                                   and bar.date_id = atr.date_id
                                   and bar.to_report <> 'report'
                                 limit 1) un on true
             left join dash_reporting.bofa_allocation_instruction_status bas
                       on bas.date_id = atr.date_id and bas.alloc_instr_id = atr.alloc_instr_id
    where true
      and tr.is_busted <> 'Y'
      and tr.date_id = in_date_id
      and di.instrument_type_id = 'O'
      and case when in_account_ids = '{}' then true else ac.account_id = any (in_account_ids) end;


    return query
        select trm.account_id,
               trm.trading_firm_id,
               --
               count(trm.trade_record_id)                                                       as trades_cnt,
               sum(trm.last_qty)                                                                as trades_qty,
               sum(trm.last_qty * trm.last_px)                                                  as trades_principal,
               sum(case when trm.expiring_today then 1 else 0 end)                              as trades_cnt_expiring,
               sum(case when trm.expiring_today then trm.last_qty else 0 end)                   as trades_qty_expiring,
               -- unallocated
               sum(case when trm.is_alloc = 'unallocated' then 1 else 0 end)                    as unallocated_trades_cnt,
               sum(case when trm.is_alloc = 'unallocated' then last_qty else 0 end)             as unallocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'unallocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as unallocated_trades_principal,
               sum(case when trm.is_alloc = 'unallocated' and expiring_today then 1 else 0 end) as unallocated_trades_qty_expiring,
               -- allocated
               sum(case when trm.is_alloc = 'allocated' then 1 else 0 end)                      as allocated_trades_cnt,
               sum(case when trm.is_alloc = 'allocated' then last_qty else 0 end)               as allocated_trades_qty,
               sum(case
                       when trm.is_alloc = 'allocated' then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as allocated_trades_principal,
               sum(case when trm.is_alloc = 'allocated' and expiring_today then 1 else 0 end)   as allocated_trades_qty_expiring,
               -- unable
               sum(case when trm.is_unable then 1 else 0 end)                                   as unable_trades_cnt,
               sum(case when trm.is_unable then last_qty else 0 end)                            as unable_trades_qty,
               sum(case
                       when trm.is_unable then last_qty * last_px * os.contract_multiplier
                       else 0 end)                                                              as unable_trades_principal,

               sum(case when trm.claim_status != 'R' then 1 else 0 end)::int4                   as unresolved,
               sum(case when trm.claim_status = 'R' then 1 else 0 end)::int4                    as resolved

-- select *
        from tmp_trade_record_monitor trm
                 left join genesis2.option_contract oc on oc.instrument_id = trm.instrument_id
                 left join genesis2.option_series os on os.option_series_id = oc.option_series_id
        group by trm.account_id, trm.trading_firm_id;
end;
$function$
;

select * from tmp_trade_record_monitor;

select * from genesis2.option_series