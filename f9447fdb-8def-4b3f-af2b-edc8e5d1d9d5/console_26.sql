select ai.date_id                                                                       as "75",
       ai.create_time                                                                   as "60",
       di.symbol                                                                        as "55",
       case when di.instrument_type_id = 'O' then 'OPT' else 'ES' end                   as "167",
       case when di.instrument_type_id = 'O' then oc.put_call end                       as "201",
       case when di.instrument_type_id = 'O' then oc.strike_price end                   as "202",
       case when di.instrument_type_id = 'O' then to_char(oc.maturity_day, 'FM00') end  as "205",
       case
           when di.instrument_type_id = 'O' then to_char(oc.maturity_year, 'FM0000') ||
                                                 to_char(oc.maturity_month, 'FM00') end as "200",
       ai.total_qty                                                                     as "53",
       ai.avg_px                                                                        as "6",
       "124",
       tr_arr as "NO_EXECS",
       *


from genesis2.allocation_instruction ai
         join lateral (select --count(*) as "NO_ALLOCS",
ca.occ_actionable_id as "79",
aie.alloc_qty as "80",
ca.clearing_account_number as "439",
aie.occ_actionable_id as "10440",



                       from genesis2.allocation_instruction_entry aie
                       join genesis2.clearing_account ca              on (ca.clearing_account_id = aie.clearing_account_id and ca.clearing_account_type = '1' and                  ca.market_type = 'O')
join
                       where aie.alloc_instr_id = ai.alloc_instr_id
                         and aie.date_id = ai.date_id
                       limit 1) aie on true
         join lateral (select count(*) as "124", jsonb_agg(jsonb_build_object('17', tr.exec_id, 'secondary_exch_exec_id',
                                                           tr.secondary_exch_exec_id, 'last_qty', tr.last_qty,
                                                           'leg_ref_id', tr.leg_ref_id)
                              ) as tr_arr
                       from genesis2.alloc_instr2trade_record aitr
                                join genesis2.trade_record tr
                                     on tr.trade_record_id = aitr.trade_record_id and tr.date_id = aitr.date_id
                       where aitr.alloc_instr_id = ai.alloc_instr_id
                         and aitr.date_id = ai.date_id
                         and aitr.allocation_instruction_entry_id = aie.allocation_instruction_entry_id
                       limit 1) aitr on true
         join genesis2.instrument di on di.instrument_id = ai.instrument_id
         join genesis2.account ac on ac.account_id = ai.account_id
         left join genesis2.option_contract oc on di.instrument_id = oc.instrument_id
         left join genesis2.option_series os on oc.option_series_id = os.option_series_id
where ai.date_id = 20251024
  and ai.alloc_instr_id = -298599144
-- group by 1 aie.allocation_instruction_entry_id) > 1
--                 having count(distinct



 account_id                    bigint not null
        constraint pk_account
            primary key,
    account_name                  varchar(30),
    eq_mpid                       varchar(4),
    eq_order_capacity             char,
    eq_commission                 numeric(12, 4),
    eq_commission_type            char,
    eq_is_validate_short_stock    char,
    opt_penny_commission          numeric(12, 4),
    opt_nickel_commission         numeric(12, 4),
    create_time                   timestamp,
    is_deleted                    char,
    delete_time                   timestamp,
    drop_copy_enabled             char,
    is_auto_allocate              char,
    eq_executing_service          varchar(4),
    opt_customer_or_firm          char,
    opt_is_dark_pool_eligible     char,
    is_clearing_enabled           char,
    max_day_order_value           numeric(20, 6),
    trading_firm_id               varchar(9)
        constraint fk_account_tr_firm
            references trading_firm
            deferrable initially deferred,
    is_risk_management_enabled    char,
    is_locked                     char,
    lock_time                     timestamp,
    account_class_id              char,
    eq_report_to_mpid             varchar(4),
    opt_report_to_mpid            varchar(4),
    opt_is_fix_execbrok_processed char,
    opt_is_fix_custfirm_processed char,
    opt_is_fix_clfirm_processed   char,
    bak_risk_limit                char,
    is_broker_dealer              char,
    broker_dealer_mpid            varchar(4),
    opt_executing_service         varchar(4),
    is_specific_allocated         char,
    oats_account_type_code        char,
    eq_reporting_avgpx_precision  smallint,
    client_dtc_number             varchar(4),
    nscc_commission_enabled       char,
    nscc_sec_fee_enabled          char,
    nscc_mpid                     varchar(4),
    account_demo_mnemonic         varchar(100),
    opt_is_baml_dma_eligible      char,
    opt_avg_px_account            varchar(10),
    eq_avg_px_account             varchar(10),
    eq_real_time_report_to_mpid   varchar(4),
    eq_nasdaq_act_drop            char,
    settlement_period             char,
    is_finra_member               char,
    pg_update_time                timestamp,
    is_option_auto_allocate       char,
    account_algo_alias            varchar(15),
    eq_rt_allocation_enabled      bpchar,
    crd_number                    varchar(10),
    opt_occ_id                    varchar(40),
    risk_account_group_id         bigint,
    is_intraday_auto_allocate     bpchar
);