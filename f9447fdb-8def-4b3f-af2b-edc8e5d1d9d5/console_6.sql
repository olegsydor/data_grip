-- DROP FUNCTION trash.so_allocation_report2(int4, int4, text);

CREATE FUNCTION dash360.so_allocation_report2(in_start_date_id integer, in_end_date_id integer, in_exec_broker text DEFAULT '792'::text)
 RETURNS table (ret_row text)
 LANGUAGE plpgsql
AS $fn$
declare
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id           int4[];
    l_row_cnt                  int4;

begin
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from trash.allocation_report
    where date_id between in_start_date_id and in_end_date_id
    and to_report = 'report'; -- this condition looks excessive

    with base_ins as (
        insert into trash.allocation_report (last_qty, alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty,
                                             opt_is_fix_clfirm_processed, ftr_cmta, ca_cmta,
                                             opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
                                             occ_actionable_id, dataset, to_report)
            SELECT ftr.last_qty,
                   alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta                                     AS ftr_cmta,
                   ca.cmta                                      AS ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id                         as occ_actionable_id,
                   to_char(clock_timestamp(), 'YYYYMMDDHH24MI') as dataset,
                   case
                       when exists (select null
                                    from trash.allocation_report ar
                                    where ar.alloc_instr_id = ae.alloc_instr_id
                                      and to_report = 'report') then 'skip - current alloc_instr_id'
                       when trash.get_all_parent_alloc_instr_id(alin.alloc_instr_id, alin.date_id) &&
                            l_alloc_instr_id_reported then 'skip alloc_instr_id has been reported'
                       else 'report' end                        as to_report
            FROM genesis2.allocation_instruction_entry ae
                     JOIN genesis2.allocation_instruction alin
                          ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm,
                                                tr.last_qty
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and case
                                                                         when in_exec_broker is null then true
                                                                         else tr.exec_broker = in_exec_broker end
                                                                 and tr.exec_broker is not null
                                         where aitr.alloc_instr_id = alin.alloc_instr_id
                                           and aitr.date_id = alin.date_id
                                         limit 1
                ) ftr on true
                     JOIN genesis2.clearing_account ca
                          ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                              AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
                     JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                                   acc.opt_report_to_mpid = 'MLCB' AND
                                                   acc.trading_firm_id <> 'cantor')
                     JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                     JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                     JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
            WHERE alin.date_id between in_start_date_id and in_end_date_id
              and not exists (select null
                              from trash.allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;

    return l_row_cnt;
end;
$fn$
;
