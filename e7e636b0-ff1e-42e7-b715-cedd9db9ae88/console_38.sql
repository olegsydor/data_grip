    select array_agg(account_id)
   from genesis2.account ac
    where true
      and ac.is_deleted <> 'Y'
      and ac.opt_report_to_mpid = 'MLCB'
      and ac.trading_firm_id <> 'cantor';

SELECT bar.* FROM dash_reporting.bofa_allocation_report AS bar
WHERE date_id = 20251201 and dataset = 26478839;

    select *
    from genesis2.allocation_instruction_entry ae
             join genesis2.allocation_instruction alin
                  on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
             left join lateral (select alloc_instr_ids
                                from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                             alin.date_id) as x(alloc_instr_ids)
                                limit 1) or_ai on true
             inner join lateral (select tr.cmta,
                                        tr.opt_customer_firm
                                 from genesis2.alloc_instr2trade_record aitr
                                          inner join genesis2.trade_record tr
                                                     on aitr.trade_record_id = tr.trade_record_id
                                                         and aitr.date_id = tr.date_id
                                                         and tr.is_busted = 'N'
                                                         and tr.exec_broker = :in_exec_broker
                                                         and tr.exec_broker is not null
                                 where aitr.alloc_instr_id = alin.alloc_instr_id
                                   and aitr.date_id = alin.date_id
                                 limit 1
        ) ftr on true
             join genesis2.clearing_account ca
                  on (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                      and ca.clearing_account_type = '1' and ca.market_type = 'O')
             join genesis2.account acc ON (acc.account_id = ca.account_id
        and case
                when :in_is_eod then true
                else acc.account_id != all ('{62939,263022,62810,62887,62923,63787,67949}') end
        )
             join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
             join genesis2.option_series os on os.option_series_id = oc.option_series_id
             join genesis2.instrument i on i.instrument_id = alin.instrument_id
             left join lateral (select ar.date_id
                                from dash_reporting.bofa_allocation_report ar
                                where ar.alloc_instr_id = ae.alloc_instr_id
                                  and to_report = 'R'
                                limit 1) ar on true
    where alin.date_id between :in_start_date_id and :in_end_date_id
      and ca.account_id in (select account_id
                            from genesis2.account ac
                            where true
                              and ac.is_deleted <> 'Y'
                              and ac.opt_report_to_mpid = 'MLCB'
                              and ac.trading_firm_id <> 'cantor')
      and ae.alloc_instr_id in (SELECT bar.alloc_instr_id
                                FROM dash_reporting.bofa_allocation_report AS bar
                                WHERE date_id = 20251201
                                  and dataset = 26478839)



    select * from allocation_instruction_entry
        where alloc_instr_id in (-307260699, -307260640)