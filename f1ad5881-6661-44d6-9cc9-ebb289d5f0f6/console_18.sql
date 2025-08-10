select staging.get_sg_account(256639, 'O', '733', 'EMLD');

select staging.get_sg_account(in_account_id => 263203, in_instrument_type => 'O', in_opt_exec_broker => '792',
                              in_exchange_id => 'BOX')

263201
263202
263209
263204
263208
263207
263206
263205
263203


create or replace function staging.get_sg_account(
    in_account_id int4,
    in_instrument_type bpchar,
    in_opt_exec_broker varchar,
    in_exchange_id varchar
)
    returns jsonb
    language plpgsql
as
$fx$
declare
    l_opt_customer_or_firm   bpchar;
    l_opt_is_fix_execbrok_pr bpchar;
    l_opt_is_fix_clfirm_pr   bpchar;
    l_opt_is_fix_custfirm_pr bpchar;
    l_new_model              char;
    l_trading_firm_id        text;
    l_eq_mpid                text;
    l_opt_occ_id             text;
    l_clearing_firm          text;
    l_sg_sub_account         text;
    l_sg_mint_account        text;
    l_sg_sales_trader_id     text;
    l_client_cust_or_firm    text;
    l_opt_exec_broker        text;
    l_return                 jsonb;

begin
    raise notice '1 - %', clock_timestamp();
    select
        -- acc.account_name accountname,
        acc.opt_customer_or_firm,
        acc.opt_is_fix_execbrok_processed,
        acc.opt_is_fix_clfirm_processed,
        acc.opt_is_fix_custfirm_processed,
        acc.trading_firm_id,
        acc.eq_mpid,
        acc.opt_occ_id,
        acc.use_new_model
    into l_opt_customer_or_firm, l_opt_is_fix_execbrok_pr, l_opt_is_fix_clfirm_pr, l_opt_is_fix_custfirm_pr, l_trading_firm_id,
        l_eq_mpid, l_opt_occ_id, l_new_model
    from staging.account acc
    where true
      and acc.account_id = in_account_id;
    raise notice '2 - %', clock_timestamp();
    -- ExecBroker(76)

    if l_opt_is_fix_execbrok_pr = 'N' then
        if l_new_model = 'Y' then
            select oe.opt_exec_broker
            into l_opt_exec_broker
            from staging.opt_exec_broker_config oe
                     inner join staging.account2opt_exec_broker_config ao
                                on ao.opt_exec_broker_config_id = oe.opt_exec_broker_config_id
            where oe.is_deleted = 'N'
              and ao.account_id = in_account_id
              and ao.is_default = 'Y';
        else
            select opt_exec_broker
            into l_opt_exec_broker
            from staging.opt_exec_broker oe
            where oe.is_deleted = 'N'
              and oe.account_id = in_account_id
              and oe.is_default = 'Y';
        end if;
    end if;
    raise notice '3 - %, l_new_model - %, l_opt_exec_broker - %', clock_timestamp(), l_new_model, l_opt_exec_broker;
-- II. CustomerOrFirm(204)
    IF l_opt_is_fix_clfirm_pr is distinct from 'N' THEN
        l_opt_is_fix_custfirm_pr := null;
    end if;

-- III. ClearingFirm(439)

    IF (in_instrument_type = 'E' or l_opt_is_fix_clfirm_pr != 'N' or in_opt_exec_broker is null) then
        l_clearing_firm := null;
    else
        if l_new_model = 'Y' then
            select tv.tag_value--, abc.account_id, ocp.exchange_id,  obc.opt_exec_broker
            into l_clearing_firm
            from staging.opt_exec_broker_config obc
                     join staging.account2opt_exec_broker_config abc
                          on abc.opt_exec_broker_config_id = obc.opt_exec_broker_config_id
                     join staging.exec_broker_config2exch_param ocp
                          on ocp.opt_exec_broker_config_id = obc.opt_exec_broker_config_id
                     join lateral (select tag_value
                                   from staging.specific_tag_value stv
                                   where stv.specific_tag_set_id = ocp.specific_tag_set_id
                                     and stv.tag_number = 439
                                   limit 1) tv on true
            where true
              and abc.account_id = in_account_id
              and obc.opt_exec_broker = l_opt_exec_broker
              and ocp.exchange_id = in_exchange_id
              and abc.is_default = 'Y';
        else
            select stv.tag_value
            into l_clearing_firm
            from staging.opt_exec_broker_old od
                     join staging.opt_exec_broker2exch_param_old ep
                          on ep.opt_exec_broker_id = od.opt_exec_broker_id
                     join lateral (select tag_value
                                   from staging.specific_tag_value stv
                                   where stv.specific_tag_set_id = ep.specific_tag_set_id
                                     and stv.tag_number = 439
                                   limit 1) stv on true
            where od.account_id = in_account_id
              and od.opt_exec_broker = l_opt_exec_broker
              and ep.exchange_id = in_exchange_id
              and od.is_default = 'Y'
              and od.is_deleted = 'N';
        end if;
    end if;
    raise notice '4 - %', clock_timestamp();

    --     IV. ActionableID(10440)

-- V. SG Account fields
    select --ch.account_id,
           coalesce(ch.sg_sub_account, pa.sg_sub_account),
           coalesce(ch.sg_mint_account, pa.sg_sub_account),
           coalesce(ch.sg_sales_trader_id, pa.sg_sub_account)
    into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from staging.sg_account ch
             left join staging.sg_account pa
                       on pa.account_id = ch.sg_parent_account_id
    where ch.account_id = in_account_id;
    raise notice '5 - %', clock_timestamp();

    select jsonb_build_object(
                   'opt_is_fix_clfirm_processed', l_opt_is_fix_clfirm_pr,
                   'opt_clearing_firm', l_clearing_firm,
                   'opt_is_fix_custfirm_processed', l_opt_is_fix_custfirm_pr,
                   'opt_cust_or_firm', l_opt_customer_or_firm,
                   'client_cust_or_firm', l_client_cust_or_firm,
                   'opt_is_fix_execbrok_processed', l_opt_is_fix_execbrok_pr,
                   'opt_exec_broker', l_opt_exec_broker,
                   'opt_occ_id', l_opt_occ_id,
                   'sg_sub_account', l_sg_sub_account,
                   'sg_mint_account', l_sg_mint_account,
                   'sg_sales_trader_id', l_sg_sales_trader_id
           )
    into l_return;
    raise notice '6 - %', clock_timestamp();
    return l_return;
end;
$fx$