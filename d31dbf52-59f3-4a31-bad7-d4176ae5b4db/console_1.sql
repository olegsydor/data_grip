select rt.routing_table_id,
       tf1.trading_firm_name,
       acc.account_name,
       rt.routing_table_name,
       case rt.intended_scope_of_use
           when 'A' then 'Account-specific'
           when 'D' then 'Platform-wide (default)'
           when 'T' then 'Trading firm-specific'
           end ::character varying             as intended_scope_of_use,
       case rt.owner
           when 'D' then 'DASH administrator'
           when 'T' then 'Trading firm manager'
           end ::character varying             as owner,
       tf.trading_firm_name                    as owner_trading_firm,
--       rt.is_active,
       rt.is_default::character,
       rt.routing_table_desc,
       case rt.account_class_id
           when 'S' then 'Standard'
           when 'H' then 'Hammer'
           when 'G' then 'Giveup'
           end ::character varying             as account_class,
       case rt.instr_class_id
           when 'PP' then 'Penny Premium'
           when 'PN' then 'Penny Non-Premium'
           when 'NP' then 'Nickel Premium'
           when 'NN' then 'Nickel Non-Premium'
           end ::character varying             as instrument_class,
       case rt.routing_table_type
           when 'C' then 'Specific for option instrument class'
           when 'L' then 'Specific for symbol list'
           when 'S' then 'Specific for option root symbol or equity symbol'
           when 'T' then 'Specific for instrument type'
           end ::character varying             as routing_table_type,
       case rt.instrument_type_id
           when 'O' then 'Option'
           when 'E' then 'Equity'
           when 'M' then 'Multileg'
           end ::character varying             as instrument_type,
       rt.root_symbol::character varying,
       rt.symbol_suffix::character varying,
       rt.symbol_list_id::character varying,
       case rt.capacity_group_id
           when 1 then 'Customer'
           when 2 then 'Pro Cust'
           when 3 then 'Non Cust'
           when 4 then 'Market Maker'
           when 21 then 'Firm'
           when 22 then 'Broker/Dealer'
           when 41 then 'JBO'
           when 42 then 'NTPH'
           end ::character varying             as capacity_group,
       rt.market_state,
       target_strategy_name::character varying as sub_strategy,
       rt.fee_sensitivity::int4,
       rta.num_of_orders,
       rta.num_of_accounts,
       rta.num_of_trading_firms,
       rta.total_order_qty,
       rta.total_exec_qty,
       rta.principal_amount,
       rta.last_routed_time,
       rta.last_trade_time,
       rta.min_routed_time,
       rta.min_trade_time
from dwh.d_routing_table rt
-- from staging.routing_table rt
         left join (select case when :p_mode = 'A' then co.account_id else null end               account_id,
                           case when :p_mode in ('T', 'A') then acc.trading_firm_id else null end trading_firm_id,
                           co.routing_table_id,
                           count(distinct (co.client_order_id))                                   num_of_orders,
                           count(distinct (co.account_id))                                        num_of_accounts,
                           count(distinct (acc.trading_firm_id))                                  num_of_trading_firms,
                           sum(co.order_qty)                                                      total_order_qty,
                           sum(ftr.exec_qty)                                                      total_exec_qty,
                           sum(ftr.principal_amount)                                              principal_amount,
                           max(co.process_time)                                                   last_routed_time,
                           max(ftr.trade_record_time)                                             last_trade_time,
                           min(co.process_time)                                                   min_routed_time,
                           min(ftr.trade_record_time)                                             min_trade_time
                    from dwh.client_order co
                             inner join dwh.d_account acc on acc.account_id = co.account_id
                             left join (select ftr.order_id,
                                               sum(ftr.last_qty)          exec_qty,
                                               max(ftr.trade_record_time) trade_record_time,
                                               sum(ftr.principal_amount)  principal_amount
                                        from dwh.flat_trade_record ftr
                                        where ftr.date_id between :p_start_status_date_id and :p_end_status_date_id
                                          and ftr.is_busted = 'N'
                                          and order_id > 0
--                      and case when p_client_ids = '{}' then 1=1 else ftr.client_id = any(p_client_ids) end
                                        group by ftr.order_id) ftr on co.order_id = ftr.order_id
                    where co.create_date_id between :p_start_status_date_id and :p_end_status_date_id
                      and co.parent_order_id is null
                      and co.multileg_reporting_type in ('1', '2')
--                  and (p_trading_firm_ids is null or acc.trading_firm_id=any(p_trading_firm_ids))
--                  and case when p_client_ids = '{}' then 1=1 else co.client_id_text = any(p_client_ids) end
                    group by 1, 2, 3) rta on rta.routing_table_id = rt.routing_table_id
         left join data_marts.d_sub_strategy ss on ss.sub_strategy_id = rt.target_strategy
         left join dwh.d_trading_firm tf on rt.owner_trading_firm_id = tf.trading_firm_id and tf.is_active
         left outer join dwh.d_account acc on acc.account_id = rta.account_id and acc.is_active
         left outer join dwh.d_trading_firm tf1 on tf1.trading_firm_id = rta.trading_firm_id and tf1.is_active
         left outer join dwh.d_target_strategy ts on ts.target_strategy_id = rt.target_strategy
-- where rt.is_deleted = 'N'
where rt.routing_table_id in (20469,
                              21389,
                              13733,
                              12455,
                              12632,
                              16563,
                              19812,
                              24362,
                              18043,
                              15683,
                              16083,
                              12454,
                              24727,
                              11920,
                              19526,
                              23955,
                              10303,
                              24000,
                              23135,
                              24794)
  and rt.is_active;

select drt.routing_table_id
     , co.create_date_id
from dwh.d_routing_table drt
         left join lateral (select co.create_date_id
                            from dwh.client_order co
                            where drt.routing_table_id = co.routing_table_id
                              and co.routing_table_id is not null
                            and co.create_date_id > 20230101
                            order by create_date_id desc
                            limit 1) co on true
where drt.is_active;


select *
-- from dwh.d_routing_table rt
from staging.routing_table rt;

select * from dash360.report_routing_table_last_used_date();
drop function if exists trash.report_routing_table_usage;
create function dash360.report_routing_table_last_used_date()
    returns table
            (
                export_row text
            )
    language plpgsql
as
$fx$
    -- 20230707 SO https://dashfinancial.atlassian.net/browse/DEVREQ-3307
begin
    return query
        select 'Routing Table Name|Description|Security Type|Target Strategy|Fee Sensitivity|Scope|Account Class|Capacity Group|Routing Table Type|Instrument Class|Symbol List|Symbol|Symbol Suffix|Trading Firm|Account|Last Used Date';

    return query
        select coalesce(routing_table_name, '') || '|' ||
               coalesce(routing_table_desc, '') || '|' ||
               coalesce(instrument_type, '') || '|' ||
               coalesce(target_strategy, '') || '|' ||
               coalesce(fee_sensitivity::text, '') || '|' ||
               coalesce(routing_table_scope, '') || '|' ||
               coalesce(account_class, '') || '|' ||
               coalesce(capacity_group, '') || '|' ||
               coalesce(routing_table_type, '') || '|' ||
               coalesce(instrument_class, '') || '|' ||
               coalesce(symbol_list, '') || '|' ||
               coalesce(symbol, '') || '|' ||
               coalesce(symbol_sfx, '') || '|' ||
               coalesce(trading_firm_name, '') || '|' ||
               coalesce(account_name, '') || '|' ||
               coalesce(to_char(last_routed_time, 'MM/DD/YYYY'), '')
        from (select rt.routing_table_id                   as routing_table_id,
                     rt.routing_table_name                 as routing_table_name,
                     rt.routing_table_desc                 as routing_table_desc,
                     case
                         when rt.instrument_type_id = 'O' then 'Option'
                         when rt.instrument_type_id = 'E' then 'Equity'
                         when rt.instrument_type_id = 'M' then 'Multileg'
                         else rt.instrument_type_id end    as instrument_type,
                     ts.target_strategy_name               as target_strategy,
                     rt.fee_sensitivity                    as fee_sensitivity,
                     case
                         when rt.intended_scope_of_use = 'D' then 'Default'
                         when rt.intended_scope_of_use = 'A' then 'Account-specific'
                         when rt.intended_scope_of_use = 'T' then 'Trading firm-specific'
                         else rt.intended_scope_of_use end as routing_table_scope,
                     dac.account_class_name                as account_class,
                     dag.capacity_group_name               as capacity_group,
                     case
                         when rt.routing_table_type = 'C' then 'Instrument Class'
                         when rt.routing_table_type = 'T' then 'Global'
                         when rt.routing_table_type = 'S' then 'Symbol'
                         when rt.routing_table_type = 'L' then 'Symbol List'
                         else rt.routing_table_type end    as routing_table_type,
                     case
                         when rt.instr_class_id = 'NN' then 'Nickel Non-Premium'
                         when rt.instr_class_id = 'NP' then 'Nickel Premium'
                         when rt.instr_class_id = 'PN' then 'Penny Non-Premium'
                         when rt.instr_class_id = 'PP' then 'Penny Premium'
                         else rt.instr_class_id end        as instrument_class,
                     rt.symbol_list_id                     as symbol_list,
                     rt.root_symbol                        as symbol,
                     rt.symbol_suffix                      as symbol_sfx,
                     rta.account_id                        as account_id,
                     tf.trading_firm_name                  as trading_firm_name,
                     da.account_name                       as account_name,
                     rta.last_routed_time
              from dwh.d_routing_table rt
                       left join lateral (select co.account_id,
                                                 co.routing_table_id,
                                                 co.last_routed_time
                                          from trash.so_routing_max_time_usage co
                                          where co.routing_table_id = rt.routing_table_id
                                          limit 1
                  ) rta on true
                       left join dwh.d_account da on da.account_id = rta.account_id
                       left join dwh.d_account_class dac on da.account_class_id = dac.account_class_id
                       left join dwh.d_capacity_group dag on dag.capacity_group_id = rt.capacity_group_id
                       left outer join dwh.d_target_strategy ts on ts.target_strategy_id = rt.target_strategy
                       left outer join dwh.d_trading_firm tf on tf.trading_firm_id = da.trading_firm_id
              where rt.is_active) x;
end;
$fx$;
comment on function dash360.report_routing_table_last_used_date is 'Last Used Date of Routing Table';



select distinct on (co.routing_table_id) co.account_id,
                                         co.routing_table_id,
                                         co.process_time last_routed_time
from dwh.d_routing_table rt
         join dwh.client_order co on (rt.routing_table_id = co.routing_table_id)
where true
  and rt.is_active
  and rt.routing_table_id = 401
  and co.parent_order_id is null
  and co.multileg_reporting_type in ('1', '2')
  and co.routing_table_id is not null
  and co.create_date_id > 20230303
order by co.routing_table_id, co.process_time desc;

select routing_table_id,
       null::int8 as account_id,
       null::timestamp as last_routed_time
into trash.so_routing_max_time_usage
from dwh.d_routing_table rt
where true
  and rt.is_active;

alter table trash.so_routing_max_time_usage add constraint routing_max_time_usage_pk primary key (routing_table_id);

select * from trash.so_routing_max_time_usage
where last_routed_time is not null;


-- the first loading
do
$$
    declare
        f_date_id int4;
        f_row_cnt int4;
    begin
        for f_date_id in
            select to_char(id, 'YYYYMMDD')::int4
            from generate_series('2021-01-01'::date, '2020-01-01'::date, interval '-1 day') as id
            loop
                begin
                    insert into trash.so_routing_max_time_usage (routing_table_id, account_id, last_routed_time)
                    select distinct on (co.routing_table_id) co.routing_table_id,
                                                             co.account_id   as account_id,
                                                             co.process_time as last_routed_time
                    from dwh.client_order co
                    where true
                      and co.routing_table_id in (select routing_table_id
                                                  from trash.so_routing_max_time_usage rt
                                                  where rt.last_routed_time is null)
                      and co.parent_order_id is null
                      and co.multileg_reporting_type in ('1', '2')
                      and co.routing_table_id is not null
                      and co.create_date_id = f_date_id
                    order by routing_table_id, last_routed_time desc
                    on conflict (routing_table_id) do update
                        set account_id       = excluded.account_id,
                            last_routed_time = excluded.last_routed_time;
                    get diagnostics f_row_cnt = row_count;
                    raise notice 'time: %, date_id: %, count of updated rows: %', clock_timestamp(), f_date_id, f_row_cnt;
                    commit;
                end;
            end loop;
    end;
$$;


select public.get_last_workdate(CURRENT_DATE);
select public.get_business_date_back(in_offset := 1)
-- daily_update

create function staging.update_routing_table_last_usage_date(in_start_date_id int4, in_end_date_id int4 default null)
returns int4
language plpgsql
insert into trash.so_routing_max_time_usage (routing_table_id, account_id, last_routed_time)
select distinct on (co.routing_table_id) co.routing_table_id,
                                         co.account_id   as account_id,
                                         co.process_time as last_routed_time
from dwh.client_order co
where true
  and co.routing_table_id in (select routing_table_id
                              from dwh.d_routing_table rt
                              where is_active)
  and co.parent_order_id is null
  and co.multileg_reporting_type in ('1', '2')
  and co.routing_table_id is not null
  and co.create_date_id = :f_date_id
order by routing_table_id, last_routed_time desc
on conflict (routing_table_id) do update
    set account_id       = excluded.account_id,
        last_routed_time = excluded.last_routed_time;


select *
from trash.reporting_getallocations(
--      in_trading_firm_id ,
--      in_account_ids ,
        in_date_begin := 20230705,
        in_date_end := 20230706);