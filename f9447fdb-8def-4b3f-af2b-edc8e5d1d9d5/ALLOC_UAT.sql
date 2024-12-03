SELECT alin.alloc_instr_id,
    ftr.trade_record_id,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select tr.trade_record_id,
                                    tr.cmta,
                                    tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where aitr.alloc_instr_id = alin.alloc_instr_id
                               and aitr.date_id = alin.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id;



select tr.trade_record_id,
       tr.cmta,
       tr.opt_customer_firm --, coalesce(tr.street_account_name,'') street_account_name
from genesis2.alloc_instr2trade_record aitr
         inner join genesis2.trade_record tr
                    on aitr.trade_record_id = tr.trade_record_id and
                       aitr.date_id = tr.date_id and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
where aitr.alloc_instr_id = -51641
  and aitr.date_id = :in_end_date_id

select trade_record_id , orig_trade_record_id , is_busted ,
trade_record_reason , secondary_order_id , secondary_exch_exec_id , last_qty , last_px , * from genesis2.trade_record tr
where tr.date_id = 20241129
and tr.trade_record_id in (
2346592823
,2346592824
,2346592826
)
or tr.orig_trade_record_id in (
2346592823
,2346592824
,2346592826
);

select * from genesis2.option_contract
where instrument_id = 180072313;


INSERT INTO genesis2.option_contract
(instrument_id, option_series_id, maturity_year, maturity_month, maturity_day, put_call, strike_price, opra_symbol, create_time, is_deleted, delete_time)
VALUES(180072313, 70, 2025, 3, 21, '1', 160.0000, 'AAPL  250321P00160000', '2024-01-31 21:18:35.898', 'N', NULL);


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by trade_record_id asc;


select trade_record_id,
       orig_trade_record_id,
       is_busted,
       trade_record_reason,
       secondary_order_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       *
from genesis2.trade_record tr
where tr.date_id = 20241129
  and tr.secondary_exch_exec_id = 'S09GVAB00000001'
  and tr.secondary_order_id = 'BKAA0009-20241129'
order by tr.trade_record_id asc;


SELECT alin.alloc_instr_id,
       ftr.trade_record_ids,
       ftr.origs,
       alin.side,
       ae.alloc_qty,
       alin.avg_px,
       acc.opt_is_fix_clfirm_processed,
       ftr.cmta                           AS ftr_cmta,
       ca.cmta                            AS ca_cmta,
       alin.date_id,
       os.min_tick_increment,
       acc.opt_penny_commission,
       acc.opt_nickel_commission,
       os.root_symbol,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       oc.strike_price,
       alin.open_close,
       acc.opt_is_fix_custfirm_processed,
       ftr.opt_customer_firm,
       acc.opt_customer_or_firm,
       coalesce(ae.occ_actionable_id, '') as occ_actionable_id --, ftr.street_account_name
-- select alin.instrument_id, *
FROM genesis2.allocation_instruction_entry ae
         JOIN genesis2.allocation_instruction alin
              ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
         inner join lateral (select
                                 aitr.alloc_instr_id, aitr.date_id,
                                 array_agg(tr.trade_record_id) as trade_record_ids,
                                 array_agg(tr.orig_trade_record_id) as origs,
                                    min(tr.cmta) as cmta,
                                    min(tr.opt_customer_firm) as opt_customer_firm--, coalesce(tr.street_account_name,'') street_account_name
                             from genesis2.alloc_instr2trade_record aitr
                                      inner join genesis2.trade_record tr
                                                 on aitr.trade_record_id = tr.trade_record_id and
                                                    aitr.date_id = tr.date_id
                                                        and tr.is_busted = 'N'
--                                                                       and tr.exec_broker = :in_exec_broker
                             where true
--                                  and aitr.alloc_instr_id = alin.alloc_instr_id
--                                and aitr.date_id = alin.date_id
                              and aitr.trade_record_id in (2346592826, 2346592949,2346592950,2346593040,2346593041,2346593042,2346593043,2346593044)
                             group by aitr.alloc_instr_id, aitr.date_id
                             limit 1) ftr on true
         JOIN genesis2.clearing_account ca
              ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/ AND
                  ca.clearing_account_type = '1' AND ca.market_type = 'O')
         JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                       acc.opt_report_to_mpid = 'MLCB' AND
                                       acc.trading_firm_id <> 'cantor')
         JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
         JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
         JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
WHERE alin.date_id between :in_start_date_id and :in_end_date_id;



select aitr.trade_record_id, *
from genesis2.allocation_instruction_entry ae
         join genesis2.allocation_instruction alin on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
         join genesis2.alloc_instr2trade_record aitr on aitr.alloc_instr_id = alin.alloc_instr_id
         join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
         join genesis2.clearing_account ca
              on (ca.clearing_account_id = ae.clearing_account_id
                  and ca.clearing_account_type = '1' and ca.market_type = 'O')
         join genesis2.account acc
              on (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and acc.opt_report_to_mpid = 'MLCB' and
                  acc.trading_firm_id <> 'cantor')
         join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
         join genesis2.option_series os on os.option_series_id = oc.option_series_id
         join genesis2.instrument i on i.instrument_id = alin.instrument_id
where alin.date_id between :in_start_date_id and :in_end_date_id
order by aitr.trade_record_id;



create
    or replace
    function dash360.report_rps_ml_options_cmta(in_start_date_id integer, in_end_date_id integer,
                                                in_exec_broker text default '792'::text)
    returns table
            (
                first_orig_trade_record_id    int8,
                side                          bpchar(1),
                alloc_qty                     int4,
                avg_px                        numeric(14, 6),
                opt_is_fix_clfirm_processed   bpchar(1),
                ftr_cmta                      varchar(3),
                ca_cmta                       varchar(3),
                date_id                       int4,
                min_tick_increment            numeric(12, 4),
                opt_penny_commission          numeric(12, 4),
                opt_nickel_commission         numeric(12, 4),
                root_symbol                   varchar(10),
                put_call                      bpchar(1),
                maturity_year                 int2,
                maturity_month                int2,
                maturity_day                  int2,
                strike_price                  numeric(12, 4),
                open_close                    bpchar(1),
                opt_is_fix_custfirm_processed bpchar(1),
                opt_customer_firm             bpchar(1),
                opt_customer_or_firm          bpchar(1),
                occ_actionable_id             varchar
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id int;
    l_step_id int;
    row_cnt   int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_rps_ml_options_cmta STARTED ====', 0, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id,
                           'l_date_id size is =' || in_start_date_id::text || '-' || in_end_date_id::text, 1, 'O')
    into l_step_id;

-- Start
    return query
        SELECT ftr.first_orig_trade_record_id,
               qty.last_qty         as first_qty,
               alin.alloc_instr_id,
               ftr.last_qty,
               ae.alloc_qty,
               alin.side,
               alin.avg_px,
               acc.opt_is_fix_clfirm_processed,
               ftr.cmta             AS ftr_cmta,
               ca.cmta              AS ca_cmta,
               alin.date_id,
               os.min_tick_increment,
               acc.opt_penny_commission,
               acc.opt_nickel_commission,
               os.root_symbol,
               oc.put_call,
               oc.maturity_year,
               oc.maturity_month,
               oc.maturity_day,
               oc.strike_price,
               alin.open_close,
               acc.opt_is_fix_custfirm_processed,
               ftr.opt_customer_firm,
               acc.opt_customer_or_firm,
               ae.occ_actionable_id as occ_actionable_id --, ftr.street_account_name
        FROM genesis2.allocation_instruction_entry ae
                 JOIN genesis2.allocation_instruction alin
                      ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                 inner join lateral (select tr.cmta,
                                            tr.opt_customer_firm,-- coalesce(tr.street_account_name,'') street_account_name
                                            tr.last_qty,
                                            staging.last_orig_trade_record_id_today(tr.trade_record_id,
                                                                                    tr.date_id) as first_orig_trade_record_id
                                     from genesis2.alloc_instr2trade_record aitr
                                              inner join genesis2.trade_record tr
                                                         on aitr.trade_record_id = tr.trade_record_id
                                                             and aitr.date_id = tr.date_id
                                                             and tr.is_busted = 'N'
                                                             and case
                                                                     when :in_exec_broker is null then true
                                                                     else tr.exec_broker = :in_exec_broker end
                                     where aitr.alloc_instr_id = alin.alloc_instr_id
                                       and aitr.date_id = alin.date_id
                                     limit 1) ftr on true
                 join lateral (select last_qty
                               from genesis2.trade_record tr
                               where tr.trade_record_id = ftr.first_orig_trade_record_id
                               limit 1) qty on true
                 JOIN genesis2.clearing_account ca
                      ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                          AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
                 JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                               acc.opt_report_to_mpid = 'MLCB' AND acc.trading_firm_id <> 'cantor')
                 JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                 JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                 JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
        WHERE alin.date_id between :in_start_date_id and :in_end_date_id;

    GET DIAGNOSTICS row_cnt = ROW_COUNT;
    select public.load_log(l_load_id, l_step_id, 'COMPLETED', row_cnt, 'I')
    into l_step_id;

-- Finish

END;
$function$
;
select * from dash360.report_rps_ml_options_cmta(20241101,20241202)



-- DROP FUNCTION staging.last_orig_order(int8);

create function staging.last_orig_trade_record_id_today(in_trade_record_id bigint, in_date_id int4)
    returns bigint
    language plpgsql
as
$fn$
declare
    ret_trade_record_id int8;
begin
    with recursive total (trade_record_id, orig_trade_record_id) as
                       (select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                        where tr.orig_trade_record_id is not null
                          and tr.trade_record_id = in_trade_record_id
                          and tr.date_id = in_date_id

                        union all

                        select tr.trade_record_id, tr.orig_trade_record_id
                        from genesis2.trade_record tr
                                 join total on tr.trade_record_id = total.orig_trade_record_id
                        where tr.date_id = in_date_id)
    select trade_record_id
    into ret_trade_record_id
    from total
    where orig_trade_record_id is null
    limit 1;
    return ret_trade_record_id;
end;
$fn$
;


select staging.last_orig_trade_record_id_today(2346593043, 20241129);

select last_qty, * from trade_record where trade_record_id = 2346592826